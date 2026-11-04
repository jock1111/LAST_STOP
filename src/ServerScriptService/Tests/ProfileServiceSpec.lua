-- Automated safety tests for ProfileService. Uses an in-memory mock DataStore so
-- no real player accounts or destructive save operations are ever touched.
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

	local function makeStore(seedData)
		local data = {}
		for key, value in pairs(seedData or {}) do
			data[key] = deepClone(value)
		end
		local getFails, updateFails = false, false
		local store = {}
		function store:GetAsync(key)
			if getFails then
				error("GetAsync failed")
			end
			return deepClone(data[key])
		end
		function store:UpdateAsync(key, transform)
			if updateFails then
				error("UpdateAsync failed")
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
			raw = function(key) return deepClone(data[key]) end,
		}
	end

	local config = GameConfig
	local function player(id)
		return { UserId = id }
	end

	-- New player (no stored data) receives defaults and can be persisted once mutated.
	do
		local p1 = player(1)
		local store = makeStore()
		local service = ProfileService.new(config, store)
		local profile, sessionOnly = service:Load(p1)
		assert(sessionOnly == false, "New player must not be session-only")
		assert(profile.Coins == config.StarterCoins, "New player starts with starter coins")
		assert(profile.Level == 1, "New player starts at level 1")
		-- A fresh load is not dirty, so Save is a no-op until something changes.
		assert(service:Save(p1) == true, "New player save must be a successful no-op")
		assert(store.raw("p_1") == nil, "Nothing persisted before a mutation")
		service:Mutate(p1, function(p) p.Coins = 100 end)
		assert(service:Save(p1) == true, "New player profile must be savable after mutation")
		local saved = store.raw("p_1")
		assert(saved ~= nil, "New player data must be written to the store")
		assert(saved.Coins == 100, "Saved new-player data must be written")
	end

	-- Returning player loads existing progress unchanged.
	do
		local p2 = player(2)
		local store = makeStore({ ["p_2"] = { Version = 1, Coins = 420, XP = 150, Level = 2, Stats = { Escapes = 3 } } })
		local service = ProfileService.new(config, store)
		local profile, sessionOnly = service:Load(p2)
		assert(sessionOnly == false, "Returning player must not be session-only")
		assert(profile.Coins == 420, "Returning player keeps saved coins")
		assert(profile.Level == 2, "Returning player keeps saved level")
		assert(profile.Stats.Escapes == 3, "Returning player keeps saved stats")
	end

	-- Failed load: distinguished from a new player, never persisted over existing data.
	do
		local p3 = player(3)
		local store = makeStore({ ["p_3"] = { Version = 1, Coins = 999, XP = 0, Level = 5 } })
		store.setGetFail(true)
		local service = ProfileService.new(config, store)
		local profile, sessionOnly = service:Load(p3)
		assert(sessionOnly == true, "Failed load must be session-only")
		assert(profile.Coins == config.StarterCoins, "Session profile uses defaults locally only")
		service:Mutate(p3, function(p) p.Coins += 1000 end)
		local ok, err = service:Save(p3)
		assert(ok == false, "Failed-load save must be refused: " .. tostring(err))
		local saved = store.raw("p_3")
		assert(saved.Coins == 999, "Existing progress must not be overwritten after a failed load")
	end

	-- DataStore unavailable degrades to session-only and refuses to save.
	do
		local p4 = player(4)
		local service = ProfileService.new(config)
		assert(service._storeAvailable == false, "Missing store must be unavailable")
		local profile, sessionOnly = service:Load(p4)
		assert(sessionOnly == true, "Unavailable store must be session-only")
		local ok = service:Save(p4)
		assert(ok == false, "Session-only save must be refused")
	end

	-- Conflicting server ownership: a fresh lock held by another server is not
	-- readable or overwritable by this server.
	do
		local p5 = player(5)
		local store = makeStore({ ["p_5"] = { Version = 1, Coins = 10 } })
		local serviceA = ProfileService.new(config, store)
		local profileA, _ = serviceA:Load(p5)
		assert(profileA.Coins == 10, "First server reads existing data")
		local serviceB = ProfileService.new(config, store)
		serviceB._sessionId = "other-server-session-id"
		local profileB, sessionOnlyB = serviceB:Load(p5)
		assert(sessionOnlyB == true, "Conflicting server must be session-only")
		assert(profileB.Coins == config.StarterCoins, "Conflict must not expose stored data")
		local ok = serviceB:Save(p5)
		assert(ok == false, "Conflicting server must not save over another server's profile")
		assert(store.raw("p_5").Coins == 10, "Stored data must remain untouched by conflicting server")
	end

	-- Stale lock from a dead server can be reclaimed after the TTL.
	do
		local p6 = player(6)
		local store = makeStore({ ["p_6"] = { Version = 1, Coins = 77, _lock = { SessionId = "dead-server", Timestamp = os.time() - 700 } } })
		local serviceA = ProfileService.new(config, store)
		serviceA._sessionId = "reclaimer-server"
		local profileA, sessionOnlyA = serviceA:Load(p6)
		assert(sessionOnlyA == false, "Stale lock must be reclaimed")
		assert(profileA.Coins == 77, "Reclaimer reads existing data")
	end

	-- Save is idempotent: a grant is applied once and re-saving does not duplicate it.
	do
		local p7 = player(7)
		local store = makeStore({ ["p_7"] = { Version = 1, Coins = 10 } })
		local service = ProfileService.new(config, store)
		local profile, _ = service:Load(p7)
		service:Mutate(p7, function(p) p.Coins += 50 end)
		assert(service:Save(p7) == true, "First save must succeed")
		assert(store.raw("p_7").Coins == 60, "Grant must be applied exactly once")
		assert(service:Save(p7) == true, "Re-save with no mutation must be a no-op")
		assert(store.raw("p_7").Coins == 60, "Dirty flag must prevent re-application")
		service:Mutate(p7, function(p) p.Coins += 50 end)
		assert(service:Save(p7) == true, "Second save must succeed")
		assert(store.raw("p_7").Coins == 110, "Second grant must be applied exactly once")
	end

	-- Transient save failure retries and applies the grant once on recovery.
	do
		local p9 = player(9)
		local store = makeStore({ ["p_9"] = { Version = 1, Coins = 5 } })
		local service = ProfileService.new(config, store)
		local profile, _ = service:Load(p9)
		store.setUpdateFail(true)
		service:Mutate(p9, function(p) p.Coins += 5 end)
		local ok = service:Save(p9)
		assert(ok == false, "Save must fail while updates fail")
		assert(store.raw("p_9").Coins == 5, "Failed save must not persist partial state")
		store.setUpdateFail(false)
		assert(service:Save(p9) == true, "Save must succeed after transient failure recovers")
		assert(store.raw("p_9").Coins == 10, "Retried save must apply the grant once")
	end

	print("[ProfileServiceSpec] All profile-safety assertions passed.")
end
