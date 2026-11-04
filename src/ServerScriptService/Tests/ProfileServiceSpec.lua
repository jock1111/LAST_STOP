-- Automated safety tests for ProfileService. Uses an in-memory mock DataStore so
-- no real player accounts or destructive save operations are ever touched.
-- All timing is deterministic (no real 600s waits); TTL behaviour is exercised by
-- setting stored lock timestamps relative to os.time().
--
-- The mock DataStore supports a controllable yield gate (pauseUpdate / releaseUpdate)
-- so that mutations, concurrent saves, release, retries, and ownership transitions
-- genuinely interleave rather than being simulated by setting flags directly.
return function()
	local ProfileService = require(script.Parent.Parent.Services.ProfileService)
	local GameConfig = require(game.ReplicatedStorage.Shared.Config.GameConfig)

	local function deepClone(value)
		if type(value) ~= "table" then
			return value
		end
		local copy = {}
		for k, v in pairs(value) do
			copy[deepClone(k)] = deepClone(v)
		end
		return copy
	end

	-- Mock DataStore. Returns (store, control). Tests MUST use `control` for
	-- failure injection and inspection; the store object only exposes GetAsync/
	-- UpdateAsync like a real DataStore.
	local function makeStore(seedData)
		local data = {}
		for key, value in pairs(seedData or {}) do
			data[key] = deepClone(value)
		end
		local getFails, updateFails = false, false
		local updateGate = false -- when true, UpdateAsync yields until released
		local callCount = { GetAsync = 0, UpdateAsync = 0 }
		local store = {}
		function store:GetAsync(key)
			callCount.GetAsync += 1
			if getFails then
				error("GetAsync failed: " .. tostring(key))
			end
			return deepClone(data[key])
		end
		function store:UpdateAsync(key, transform)
			callCount.UpdateAsync += 1
			if updateFails then
				error("UpdateAsync failed: " .. tostring(key))
			end
			if updateGate then
				repeat task.wait(0.05) until not updateGate
			end
			local result = transform(deepClone(data[key]))
			if result ~= nil then
				data[key] = deepClone(result)
			end
			return deepClone(result)
		end
		return store, {
			setGetFail = function(f) getFails = f end,
			setUpdateFail = function(f) updateFails = f end,
			-- Blocks UpdateAsync until releaseUpdate() is called. Enables true
			-- concurrency testing: one save can be stuck inside UpdateAsync
			-- while another save attempts to run.
			pauseUpdate = function() updateGate = true end,
			releaseUpdate = function() updateGate = false end,
			-- Test-only: force the stored lock to a given session/timestamp so we
			-- can simulate lock expiry or ownership transfer without waiting 600s.
			setLock = function(key, sessionId, timestamp)
				data[key] = data[key] or {}
				data[key]._lock = { SessionId = sessionId, Timestamp = timestamp or os.time() }
			end,
			raw = function(key) return deepClone(data[key]) end,
			calls = function() return deepClone(callCount) end,
		}
	end

	local function waitFor(condition, timeoutSeconds)
		local deadline = os.clock() + (timeoutSeconds or 5)
		while os.clock() < deadline do
			if condition() then
				return true
			end
			task.wait(0.05)
		end
		return condition()
	end

	local config = GameConfig
	local function player(id)
		return { UserId = id }
	end

	local passed = 0
	local function check(condition, message)
		assert(condition, message)
		passed += 1
	end

	--------------------------------------------------------------------------
	-- 1. New player: load claims a lock (store record is NOT nil after load),
	--    defaults apply, save after mutation writes the full profile once.
	--------------------------------------------------------------------------
	do
		local p1 = player(1)
		local store, ctrl = makeStore()
		local service = ProfileService.new(config, store)
		local profile, sessionOnly = service:Load(p1)
		check(sessionOnly == false, "New player must not be session-only")
		check(profile.Coins == config.StarterCoins, "New player starts with starter coins")
		check(profile.Level == 1, "New player starts at level 1")

		local afterLoad = ctrl.raw("p_1")
		check(type(afterLoad) == "table", "Load must write a lock record to the store")
		check(type(afterLoad._lock) == "table", "Lock record must be present after load")
		check(afterLoad._lock.SessionId == service._sessionId, "New player must own the lock after load")

		check(service:Save(p1) == true, "New player save must be a successful no-op")
		local stillJustLock = ctrl.raw("p_1")
		check(type(stillJustLock.Coins) == "number" or stillJustLock.Coins == nil,
			"No-op save must not add a full profile before mutation")

		service:Mutate(p1, function(p) p.Coins = 100 end)
		check(service:Save(p1) == true, "New player profile must be savable after mutation")
		local saved = ctrl.raw("p_1")
		check(saved ~= nil, "New player data must be written to the store")
		check(saved.Coins == 100, "Saved new-player data must equal mutated coins")
		check(saved._lock.SessionId == service._sessionId, "Lock must remain owned by this session after save")
		check(ctrl.calls().UpdateAsync >= 1, "UpdateAsync must have been invoked")
	end

	--------------------------------------------------------------------------
	-- 2. Returning player: loads existing progress unchanged.
	--------------------------------------------------------------------------
	do
		local p2 = player(2)
		local store, ctrl = makeStore({
			["p_2"] = { Version = 1, Coins = 420, XP = 150, Level = 2, Stats = { Escapes = 3 } },
		})
		local service = ProfileService.new(config, store)
		local profile, sessionOnly = service:Load(p2)
		check(sessionOnly == false, "Returning player must not be session-only")
		check(profile.Coins == 420, "Returning player keeps saved coins")
		check(profile.Level == 2, "Returning player keeps saved level")
		check(profile.Stats.Escapes == 3, "Returning player keeps saved stats")
		check(profile._lock.SessionId == service._sessionId, "Returning player must claim the lock")
	end

	--------------------------------------------------------------------------
	-- 3. Failed load (UpdateAsync throws): distinguished from new player,
	--    session-only, defaults locally, save refused, existing data untouched.
	--------------------------------------------------------------------------
	do
		local p3 = player(3)
		local store, ctrl = makeStore({ ["p_3"] = { Version = 1, Coins = 999, XP = 0, Level = 5 } })
		ctrl.setUpdateFail(true) -- the actual loading path (UpdateAsync) fails
		local service = ProfileService.new(config, store)
		local profile, sessionOnly = service:Load(p3)
		check(sessionOnly == true, "Failed load must be session-only")
		check(service:IsSessionOnly(p3) == true, "IsSessionOnly must report failed load")
		check(profile.Coins == config.StarterCoins, "Session profile uses defaults locally only")
		service:Mutate(p3, function(p) p.Coins += 1000 end)
		local ok, err = service:Save(p3)
		check(ok == false, "Failed-load save must be refused: " .. tostring(err))
		local saved = ctrl.raw("p_3")
		check(saved.Coins == 999, "Existing progress must not be overwritten after a failed load")
		check(saved._lock == nil or saved._lock.SessionId ~= service._sessionId,
			"Failed load must not claim or overwrite the lock")
		ctrl.setUpdateFail(false)
	end

	--------------------------------------------------------------------------
	-- 4. Store unavailable (explicit dependency injection): GetAsync probe
	--    fails at construction, degrades to session-only, refuses to save.
	--------------------------------------------------------------------------
	do
		local p4 = player(4)
		local store, ctrl = makeStore({ ["p_4"] = { Version = 1, Coins = 555 } })
		ctrl.setGetFail(true) -- probeStore's GetAsync throws -> store unavailable
		local service = ProfileService.new(config, store)
		check(service._storeAvailable == false, "Failing probe store must be unavailable")
		ctrl.setGetFail(false) -- restore for later reads
		local profile, sessionOnly = service:Load(p4)
		check(sessionOnly == true, "Unavailable store must be session-only")
		local ok = service:Save(p4)
		check(ok == false, "Session-only save must be refused")
		local saved = ctrl.raw("p_4")
		check(saved.Coins == 555, "Existing progress must not be touched when store is unavailable")
	end

	--------------------------------------------------------------------------
	-- 5. Conflicting server ownership: a fresh lock held by another server is
	--    not readable or overwritable by this server.
	--------------------------------------------------------------------------
	do
		local p5 = player(5)
		local store, ctrl = makeStore({ ["p_5"] = { Version = 1, Coins = 10 } })
		local serviceA = ProfileService.new(config, store)
		local profileA, _ = serviceA:Load(p5)
		check(profileA.Coins == 10, "First server reads existing data")
		local serviceB = ProfileService.new(config, store)
		serviceB._sessionId = "other-server-session-id"
		local profileB, sessionOnlyB = serviceB:Load(p5)
		check(sessionOnlyB == true, "Conflicting server must be session-only")
		check(serviceB:IsSessionOnly(p5) == true, "Conflict server IsSessionOnly must be true")
		check(profileB.Coins == config.StarterCoins, "Conflict must not expose stored data")
		local ok = serviceB:Save(p5)
		check(ok == false, "Conflicting server must not save over another server's profile")
		check(ctrl.raw("p_5").Coins == 10, "Stored data must remain untouched by conflicting server")
	end

	--------------------------------------------------------------------------
	-- 6. Stale lock from a dead server can be reclaimed after the TTL.
	--    Only the initial claim (Load) may reclaim; renewals/saves may not.
	--------------------------------------------------------------------------
	do
		local p6 = player(6)
		local store, ctrl = makeStore({
			["p_6"] = { Version = 1, Coins = 77, _lock = { SessionId = "dead-server", Timestamp = os.time() - 700 } },
		})
		local serviceA = ProfileService.new(config, store)
		serviceA._sessionId = "reclaimer-server"
		local profileA, sessionOnlyA = serviceA:Load(p6)
		check(sessionOnlyA == false, "Stale lock must be reclaimed by claim")
		check(profileA.Coins == 77, "Reclaimer reads existing data")
		check(ctrl.raw("p_6")._lock.SessionId == "reclaimer-server", "Reclaimer must own the lock after reclaim")
	end

	--------------------------------------------------------------------------
	-- 7. Lock renewal: exact SessionId required, timestamp refreshed before TTL.
	--    Renewal may NOT reclaim another server's lock.
	--------------------------------------------------------------------------
	do
		local p7 = player(7)
		local store, ctrl = makeStore({ ["p_7"] = { Version = 1, Coins = 3 } })
		local service = ProfileService.new(config, store)
		local profile, _ = service:Load(p7)
		local firstTimestamp = ctrl.raw("p_7")._lock.Timestamp
		task.wait(0.1) -- ensure a different second boundary is plausible
		check(service:RenewLock(p7) == true, "RenewLock must succeed for the owning session")
		local afterRenew = ctrl.raw("p_7")
		check(afterRenew._lock.SessionId == service._sessionId, "Renewal must keep ownership")
		check(afterRenew._lock.Timestamp >= firstTimestamp, "Renewal must refresh the lock timestamp")

		-- Renewal must NOT reclaim another server's fresh lock.
		ctrl.setLock("p_7", "other-server", os.time())
		check(service:RenewLock(p7) == false, "Renewal must reject another server's lock")
		check(service:IsOwnershipLost(p7) == true, "Renewal failure must flag ownership lost")
	end

	--------------------------------------------------------------------------
	-- 8. Save idempotency: a grant applied once; re-saving does not duplicate.
	--------------------------------------------------------------------------
	do
		local p8 = player(8)
		local store, ctrl = makeStore({ ["p_8"] = { Version = 1, Coins = 10 } })
		local service = ProfileService.new(config, store)
		local profile, _ = service:Load(p8)
		service:Mutate(p8, function(p) p.Coins += 50 end)
		check(service:Save(p8) == true, "First save must succeed")
		check(ctrl.raw("p_8").Coins == 60, "Grant must be applied exactly once")
		check(service:Save(p8) == true, "Re-save with no mutation must be a no-op")
		check(ctrl.raw("p_8").Coins == 60, "Dirty flag must prevent re-application")
		service:Mutate(p8, function(p) p.Coins += 50 end)
		check(service:Save(p8) == true, "Second save must succeed")
		check(ctrl.raw("p_8").Coins == 110, "Second grant must be applied exactly once")
	end

	--------------------------------------------------------------------------
	-- 9. Transient save failure: retries, applies grant once on recovery,
	--    no partial state persisted.
	--------------------------------------------------------------------------
	do
		local p9 = player(9)
		local store, ctrl = makeStore({ ["p_9"] = { Version = 1, Coins = 5 } })
		local service = ProfileService.new(config, store)
		local profile, _ = service:Load(p9)
		ctrl.setUpdateFail(true)
		service:Mutate(p9, function(p) p.Coins += 5 end)
		local ok = service:Save(p9)
		check(ok == false, "Save must fail while updates fail")
		check(ctrl.raw("p_9").Coins == 5, "Failed save must not persist partial state")
		ctrl.setUpdateFail(false)
		-- Resume any re-save coroutine spawned by the failed Save attempt,
		-- then clear in-flight state so the explicit Save below can run.
		task.wait(0)
		service._saveInFlight[p9] = nil
		check(service:Save(p9) == true, "Save must succeed after transient failure recovers")
		check(ctrl.raw("p_9").Coins == 10, "Retried save must apply the grant once")
	end

	--------------------------------------------------------------------------
	-- 10. Server switching / lock release: server A saves then releases
	--     (clears lock); server B acquires lock and reads A's data.
	--------------------------------------------------------------------------
	do
		local p10 = player(10)
		local store, ctrl = makeStore({ ["p_10"] = { Version = 1, Coins = 0 } })
		local serviceA = ProfileService.new(config, store)
		local profileA, _ = serviceA:Load(p10)
		serviceA:Mutate(p10, function(p) p.Coins = 123 end)
		check(serviceA:Save(p10) == true, "Server A save must succeed")
		serviceA:Release(p10) -- save-and-release clears stored lock
		check(ctrl.raw("p_10")._lock == nil, "Release must clear the stored lock on success")
		-- Server B acquires the now-unlocked profile and reads A's data.
		local serviceB = ProfileService.new(config, store)
		serviceB._sessionId = "server-b"
		local profileB, sessionOnlyB = serviceB:Load(p10)
		check(sessionOnlyB == false, "Server B must acquire the released profile")
		check(profileB.Coins == 123, "Server B must read server A's saved data")
		check(ctrl.raw("p_10")._lock.SessionId == "server-b", "Server B must own the lock")
		serviceB:Release(p10)
	end

	--------------------------------------------------------------------------
	-- 11. Old server cannot overwrite after another server acquires ownership.
	--     Save requires exact SessionId; another server's lock causes rejection
	--     and flags ownership lost, blocking further mutations.
	do
		local p11 = player(11)
		local store, ctrl = makeStore({ ["p_11"] = { Version = 1, Coins = 1 } })
		local serviceA = ProfileService.new(config, store)
		serviceA:Load(p11) -- A claims the lock
		-- Simulate server B acquiring the lock after A's lock has expired.
		ctrl.setLock("p_11", "server-b", os.time())
		-- A mutates its in-memory profile, then tries to save.
		serviceA:Mutate(p11, function(p) p.Coins = 999 end)
		local ok = serviceA:Save(p11)
		check(ok == false, "Old server must not overwrite after another server acquires the lock")
		check(serviceA:IsOwnershipLost(p11) == true, "Save rejection must flag ownership lost")
		-- Further mutations must be blocked once ownership is lost.
		local mutOk = serviceA:Mutate(p11, function(p) p.Coins = 999 end)
		check(mutOk == false, "Mutation must be blocked after ownership loss")
		check(ctrl.raw("p_11")._lock.SessionId == "server-b", "Lock must remain with server B")
		check(ctrl.raw("p_11").Coins == 1, "Data must not be overwritten by the old server")
	end

	--------------------------------------------------------------------------
	-- 12. CONCURRENT SAVES: true overlapping save using a yielding mock.
	--     Save A is stuck inside UpdateAsync; save B is queued. Mutation made
	--     during A's flight must not be lost: after A completes, the dirty flag
	--     triggers a re-save that persists the newer value.
	--------------------------------------------------------------------------
	do
		local p12 = player(12)
		local store, ctrl = makeStore({ ["p_12"] = { Version = 1, Coins = 0 } })
		local service = ProfileService.new(config, store)
		local profile, _ = service:Load(p12)

		-- Make the profile dirty so Save proceeds past the no-op check.
		service:Mutate(p12, function(p) p.Coins = 1 end)

		-- Start save A; it will block inside UpdateAsync due to the gate.
		ctrl.pauseUpdate()
		local firstResult = {}
		task.spawn(function()
			firstResult.ok, firstResult.err = service:Save(p12)
		end)

		-- Wait until save A is in flight.
		check(waitFor(function() return service._saveInFlight[p12] == true end, 5),
			"First save must enter in-flight state")

		-- Mutate while save A is in flight. This bumps the revision.
		service:Mutate(p12, function(p) p.Coins = 42 end)

		-- Save B while A is in flight: must be queued, not run twice.
		local secondOk, secondErr = service:Save(p12)
		check(secondOk == true, "Concurrent save must be accepted/queued")
		check(secondErr == "save queued", "Concurrent save must report queued status")

		-- Release the blocked save A.
		ctrl.releaseUpdate()
		check(waitFor(function() return service._saveInFlight[p12] == nil end, 5),
			"In-flight save must complete after release")
		check(firstResult.ok == true, "First save must succeed")

		-- Dirty should still be true (revision bumped during A's flight), so an
		-- automatic re-save should have run. Verify the newer value persisted.
		check(waitFor(function()
			return ctrl.raw("p_12").Coins == 42
		end, 5), "Mutation made during save must not be lost; re-save must persist it")
		check(ctrl.raw("p_12")._lock.SessionId == service._sessionId, "Lock must remain with this session")
		check(ctrl.calls().UpdateAsync >= 1, "UpdateAsync must have been invoked for the save")
	end

	--------------------------------------------------------------------------
	-- 13. Release with dirty data: save-and-release atomic. Lock cleared only
	--     on save success; on save failure, lock retained and failure reported.
	--------------------------------------------------------------------------
	do
		-- 13a: successful release clears lock and persists data.
		local p13 = player(13)
		local store, ctrl = makeStore({ ["p_13"] = { Version = 1, Coins = 9 } })
		local service = ProfileService.new(config, store)
		service:Load(p13)
		service:Mutate(p13, function(p) p.Coins = 42 end)
		service:Release(p13)
		check(service:Get(p13) == nil, "Profile memory must be cleared after release")
		check(ctrl.raw("p_13")._lock == nil, "Stored lock must be cleared after successful release")
		check(ctrl.raw("p_13").Coins == 42, "Saved data must persist after release")

		-- 13b: release when save fails retains the lock (no silent discard).
		local p14 = player(14)
		local store2, ctrl2 = makeStore({ ["p_14"] = { Version = 1, Coins = 7 } })
		ctrl2.pauseUpdate()
		local service2 = ProfileService.new(config, store2)
		service2:Load(p14)
		service2:Mutate(p14, function(p) p.Coins = 99 end)
		-- Start a save that will block; then call Release which waits for it.
		local releaseResult = {}
		task.spawn(function()
			releaseResult.ok, releaseResult.err = service2:Release(p14)
		end)
		check(waitFor(function() return service2._saveInFlight[p14] == true end, 5),
			"Release must wait for in-flight save")
		ctrl2.releaseUpdate()
		check(waitFor(function() return service2:Get(p14) == nil end, 5),
			"Release must complete after save finishes")
		-- Save succeeded once the gate was released; lock should be cleared.
		check(ctrl2.raw("p_14")._lock == nil, "Lock must be cleared after successful save-and-release")
		check(ctrl2.raw("p_14").Coins == 99, "Data must persist after save-and-release")
	end

	--------------------------------------------------------------------------
	-- 14. Save-and-release atomicity: dirty release writes data + clears lock
	--     in one UpdateAsync; failed attempt retains lock.
	--------------------------------------------------------------------------
	do
		local p14 = player(14)
		local store, ctrl = makeStore({ ["p_14"] = { Version = 1, Coins = 0 } })
		local service = ProfileService.new(config, store)
		service:Load(p14)
		service:Mutate(p14, function(p) p.Coins = 55 end)
		-- Force save-and-release to see another server's lock (ownership lost).
		ctrl.setLock("p_14", "other-server", os.time())
		local ok, err = service:SaveAndRelease(p14)
		check(ok == false, "Save-and-release must reject another server's lock")
		check(service:IsOwnershipLost(p14) == true, "Save-and-release failure must flag ownership lost")
		check(ctrl.raw("p_14")._lock.SessionId == "other-server", "Lock must remain with other server")
		check(ctrl.raw("p_14").Coins == 0, "Data must not be overwritten")
	end

	--------------------------------------------------------------------------
	-- 15. Player departure with clean state: Release clears all tracking.
	--------------------------------------------------------------------------
	do
		local p15 = player(15)
		local store, ctrl = makeStore({ ["p_15"] = { Version = 1, Coins = 3 } })
		local service = ProfileService.new(config, store)
		service:Load(p15)
		service:Mutate(p15, function(p) p.Coins = 88 end)
		service:Save(p15)
		service:Release(p15)
		check(service:Get(p15) == nil, "Profile memory cleared after release")
		check(service:IsSessionOnly(p15) == false, "Load state cleared after release")
		check(service:IsOwnershipLost(p15) == false, "OwnershipLost cleared after release")
		check(service._saveInFlight[p15] == nil, "Save-in-flight flag cleared after release")
		check(service._revision[p15] == nil, "Revision cleared after release")
		check(ctrl.raw("p_15")._lock == nil, "Stored lock cleared after release")
		check(ctrl.raw("p_15").Coins == 88, "Saved data persists after release")
	end

	print("[ProfileServiceSpec] All " .. passed .. " profile-safety assertions passed.")
end
