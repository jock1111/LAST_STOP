-- Persistent, server-owned player profile service. DataStore failures degrade to a
-- session profile; no client-supplied balance is ever accepted. A failed load is
-- distinguished from a brand-new player, and a session profile is never persisted
-- over existing saved progress.
--
-- Session-lock lifecycle:
--   * Load atomically claims a lock (SessionId + timestamp) via UpdateAsync.
--     Only Load may reclaim an expired lock (stale timestamp).
--   * RenewLock refreshes the lock timestamp; requires exact SessionId match.
--   * Save writes an immutable snapshot; requires exact SessionId match.
--   * Release saves-and-unlocks atomically in one ownership-checked UpdateAsync.
--   * Concurrent saves for the same player are serialized via _saveInFlight.
--   * Per-profile mutation revision prevents lost updates during in-flight saves.
--   * Ownership loss blocks further persistent mutations and surfaces errors.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local ProfileService = {}
ProfileService.__index = ProfileService

local LOCK_TTL_SECONDS = 600
local LOCK_RENEW_INTERVAL_SECONDS = 300
local MAX_RENEWAL_FAILURES = 5
local LOAD_RETRIES = 3
local LOAD_RETRY_BASE_DELAY = 1
local SAVE_RETRIES = 3
local SAVE_RETRY_BASE_DELAY = 1

local function deepCopy(value)
	if type(value) ~= "table" then
		return value
	end
	local copy = {}
	for k, v in pairs(value) do
		copy[deepCopy(k)] = deepCopy(v)
	end
	return copy
end

local function defaultProfile(config)
	return {
		Version = config.Version,
		Coins = config.StarterCoins,
		XP = config.StarterXP,
		Level = 1,
		Equipment = { Flashlight = true, Scanner = true, Medkit = 1 },
		Stats = { Escapes = 0, BestDepth = 0, FirstEscapeClaimed = false },
	}
end

local function normalise(saved, config)
	local profile = defaultProfile(config)
	if type(saved) ~= "table" then
		return profile
	end
	profile.Version = math.max(tonumber(saved.Version) or 1, 1)
	profile.Coins = math.max(0, math.floor(tonumber(saved.Coins) or 0))
	profile.XP = math.max(0, math.floor(tonumber(saved.XP) or 0))
	profile.Level = math.max(1, math.floor(tonumber(saved.Level) or 1))
	if type(saved.Equipment) == "table" then
		profile.Equipment = deepCopy(saved.Equipment)
	end
	if type(saved.Stats) == "table" then
		for key, value in pairs(saved.Stats) do
			if type(value) == "boolean" or type(value) == "number" then
				profile.Stats[key] = value
			end
		end
	end
	if type(saved._lock) == "table" then
		profile._lock = {
			SessionId = saved._lock.SessionId,
			Timestamp = saved._lock.Timestamp,
		}
	end
	return profile
end

-- Strip session-lock metadata so a stored record never embeds a lock on a
-- save-and-unlock (release) operation.
local function storageSnapshot(profile)
	local s = deepCopy(profile)
	s._lock = nil
	return s
end

local function newSessionId()
	local ok, guid = pcall(function()
		return HttpService:GenerateGUID(false)
	end)
	if ok and type(guid) == "string" and #guid > 0 then
		return guid
	end
	return tostring(game.JobId or math.random(1000000, 9999999))
end

-- Probe whether a store is reachable without mutating data.
local function probeStore(store)
	local key = "_ps_probe_" .. tostring(math.random(1, 100000000))
	local ok = pcall(function()
		store:GetAsync(key)
	end)
	return ok
end

function ProfileService.new(config, store)
	local storeAvailable = false
	if not store then
		local ok, fetched = pcall(function()
			return DataStoreService:GetDataStore(config.ProfileStoreName)
		end)
		if ok then
			store = fetched
			storeAvailable = true
		else
			warn("[ProfileService] DataStore unavailable; using session-only profiles:", tostring(fetched))
		end
	else
		storeAvailable = probeStore(store)
		if not storeAvailable then
			warn("[ProfileService] Provided store unavailable; using session-only profiles")
		end
	end

	local self = setmetatable({
		_config = config,
		_store = store,
		_storeAvailable = storeAvailable,
		_sessionId = newSessionId(),
		_profiles = {},
		_dirty = {},
		_revision = {},
		_loadState = {}, -- "loaded" | "failed" | "sessionOnly"
		_saveInFlight = {},
		_ownershipLost = {},
		_renewalFailures = {},
		_renewalThread = nil,
		_shutdown = false,
	}, ProfileService)

	-- Background lock renewal so long-lived sessions never lose ownership.
	-- Shuts down cleanly when _shutdown is set.
	if storeAvailable then
		self._renewalThread = task.spawn(function()
			self:_renewalLoop()
		end)
	end

	return self
end

-- Atomically claims the session lock and returns the stored data. This is the
-- ONLY operation that may reclaim an expired lock (stale timestamp). Returns
-- (false, reason) when the store errors or another server owns a fresh lock.
function ProfileService:_claimAndRead(key, now)
	local lastErr
	for attempt = 1, LOAD_RETRIES do
		local ok, result = pcall(function()
			return self._store:UpdateAsync(key, function(existing)
				if type(existing) ~= "table" then
					existing = {}
				end
				local lock = existing._lock
				if type(lock) == "table" and lock.SessionId ~= self._sessionId then
					local age = now - (lock.Timestamp or 0)
					if age < LOCK_TTL_SECONDS then
						return nil -- Conflicting live ownership; do not touch.
					end
					-- Stale lock from a dead server: reclaim (claim only).
				end
				existing._lock = { SessionId = self._sessionId, Timestamp = now }
				return existing
			end)
		end)
		if ok then
			if result == nil then
				return false, "profile owned by another server"
			end
			return true, result
		end
		lastErr = tostring(result)
		task.wait(LOAD_RETRY_BASE_DELAY * attempt)
	end
	return false, lastErr
end

function ProfileService:Load(player)
	local key = "p_" .. player.UserId
	if not self._storeAvailable then
		local profile = defaultProfile(self._config)
		self._profiles[player] = profile
		self._revision[player] = 0
		self._loadState[player] = "sessionOnly"
		return profile, true
	end
	local now = os.time()
	local claimed, loaded = self:_claimAndRead(key, now)
	if not claimed then
		warn("[ProfileService] could not claim profile for", player.UserId, tostring(loaded))
		local profile = defaultProfile(self._config)
		self._profiles[player] = profile
		self._revision[player] = 0
		self._loadState[player] = "failed"
		return profile, true
	end
	local profile = normalise(loaded, self._config)
	self._profiles[player] = profile
	self._revision[player] = 0
	self._loadState[player] = "loaded"
	return profile, false
end

function ProfileService:Get(player)
	return self._profiles[player]
end

function ProfileService:IsSessionOnly(player)
	local state = self._loadState[player]
	return state == "sessionOnly" or state == "failed"
end

function ProfileService:IsOwnershipLost(player)
	return self._ownershipLost[player] == true
end

function ProfileService:Mutate(player, callback)
	local profile = self._profiles[player]
	if not profile then
		return false, "Profile not loaded"
	end
	if self._ownershipLost[player] then
		return false, "Ownership lost; refusing mutation"
	end
	callback(profile)
	-- A failed or session-only load must never be persisted over stored data.
	if self._loadState[player] == "loaded" then
		self._dirty[player] = true
		self._revision[player] = (self._revision[player] or 0) + 1
	end
	return true, profile
end

-- Refresh the lock timestamp so a long-lived session keeps ownership.
-- Requires an exact SessionId match; never reclaims another server's lock.
function ProfileService:RenewLock(player)
	local profile = self._profiles[player]
	if not profile then
		return false, "no profile"
	end
	if self._loadState[player] ~= "loaded" then
		return false, "not loaded"
	end
	if self._ownershipLost[player] then
		return false, "ownership lost"
	end
	if not self._storeAvailable then
		return false, "store unavailable"
	end
	local key = "p_" .. player.UserId
	local now = os.time()
	local ok, result = pcall(function()
		return self._store:UpdateAsync(key, function(existing)
			if type(existing) ~= "table" then
				existing = {}
			end
			local lock = existing._lock
			-- Exact SessionId match required; no reclaim in renewal.
			if type(lock) ~= "table" or lock.SessionId ~= self._sessionId then
				return nil
			end
			existing._lock = { SessionId = self._sessionId, Timestamp = now }
			return existing
		end)
	end)
	if ok and result ~= nil then
		self._renewalFailures[player] = 0
		return true
	end
	if ok and result == nil then
		self._ownershipLost[player] = true
	end
	local failures = (self._renewalFailures[player] or 0) + 1
	self._renewalFailures[player] = failures
	warn("[ProfileService] renewal failed for", player.UserId, "failures:", failures, "reason:", tostring(result))
	return false, "renewal failed or conflicted"
end

function ProfileService:_renewalLoop()
	while not self._shutdown do
		task.wait(LOCK_RENEW_INTERVAL_SECONDS)
		if self._shutdown then
			break
		end
		for player in pairs(self._profiles) do
			if self._loadState[player] == "loaded" and not self._ownershipLost[player] then
				local failures = self._renewalFailures[player] or 0
				if failures >= MAX_RENEWAL_FAILURES then
					-- Repeated renewal failures: treat as ownership lost.
					self._ownershipLost[player] = true
					warn("[ProfileService] ownership lost for", player.UserId,
						"after", failures, "consecutive renewal failures")
					continue
				end
				local ok, err = pcall(function()
					return self:RenewLock(player)
				end)
				if not ok then
					warn("[ProfileService] renewal threw for", player.UserId, tostring(err))
				end
			end
		end
	end
end

-- Persist an immutable snapshot of the profile. Requires exact SessionId match.
-- Clears dirty state only when the saved revision is still current (no newer
-- mutation happened while the save was in flight).
function ProfileService:_doSave(player)
	local profile = self._profiles[player]
	local key = "p_" .. player.UserId
	local now = os.time()
	-- Immutable snapshot: mutations after this point cannot alter what we save.
	local snapshot = storageSnapshot(profile)
	snapshot._lock = { SessionId = self._sessionId, Timestamp = now }
	local savingRevision = self._revision[player]
	local lastErr
	for attempt = 1, SAVE_RETRIES do
		local ok, result = pcall(function()
			return self._store:UpdateAsync(key, function(existing)
				if type(existing) ~= "table" then
					existing = {}
				end
				-- Exact SessionId match required; never reclaim during save.
				local lock = existing._lock
				if type(lock) ~= "table" or lock.SessionId ~= self._sessionId then
					return nil -- Conflict; another server owns it now.
				end
				return snapshot
			end)
		end)
		if ok then
			if result == nil then
				self._ownershipLost[player] = true
				lastErr = "conflicting profile ownership"
				break -- Do not retry on ownership loss; retrying cannot help.
			else
				-- Only clear dirty if no newer mutation happened during the save.
				if self._revision[player] == savingRevision then
					self._dirty[player] = false
				end
				return true
			end
		else
			lastErr = tostring(result)
			task.wait(SAVE_RETRY_BASE_DELAY * attempt)
		end
	end
	warn("[ProfileService] save failed after retries for", player.UserId, tostring(lastErr))
	return false, lastErr
end

function ProfileService:Save(player)
	local profile = self._profiles[player]
	if not profile then
		return true
	end
	if self._loadState[player] ~= "loaded" then
		return false, "Profile not safely loaded; refusing to save"
	end
	if self._ownershipLost[player] then
		return false, "Ownership lost; refusing to save"
	end
	if not self._dirty[player] then
		return true
	end
	if not self._storeAvailable then
		return false, "DataStore unavailable"
	end

	-- Serialize concurrent saves for the same player.
	if self._saveInFlight[player] then
		return true, "save queued"
	end

	self._saveInFlight[player] = true
	local ok, err = self:_doSave(player)
	self._saveInFlight[player] = nil
	-- Only re-save if the previous save succeeded and newer data was dirtied
	-- during the save window. A failed save must not spawn re-saves (would
	-- recurse infinitely on persistent failure).
	if ok then
		if self._dirty[player] then
			task.spawn(function()
				self:Save(player)
			end)
		end
	end
	return ok, err
end

-- Atomically saves the profile and clears the session lock in one
-- ownership-checked UpdateAsync. Used by Release on player departure.
function ProfileService:SaveAndRelease(player)
	local profile = self._profiles[player]
	if not profile then
		return true
	end
	if self._loadState[player] ~= "loaded" then
		return true
	end
	if self._ownershipLost[player] then
		return false, "Ownership lost; refusing save-and-release"
	end
	if not self._dirty[player] then
		-- Nothing to persist; just clear the lock.
		return self:_clearLock(player)
	end
	if not self._storeAvailable then
		return false, "DataStore unavailable"
	end

	local key = "p_" .. player.UserId
	local now = os.time()
	-- Snapshot with lock cleared so the stored record has no lock after release.
	local snapshot = storageSnapshot(profile)
	local savingRevision = self._revision[player]
	-- Track in-flight state so Release can coordinate with this operation.
	self._saveInFlight[player] = true
	local ok, result = pcall(function()
		return self._store:UpdateAsync(key, function(existing)
			if type(existing) ~= "table" then
				existing = {}
			end
			-- Exact SessionId match required; never reclaim during save-and-release.
			local lock = existing._lock
			if type(lock) ~= "table" or lock.SessionId ~= self._sessionId then
				return nil -- Conflict; another server owns it now.
			end
			return snapshot -- snapshot already has _lock = nil
		end)
	end)
	self._saveInFlight[player] = nil
	if ok and result ~= nil then
		if self._revision[player] == savingRevision then
			self._dirty[player] = false
		end
		return true
	end
	if ok and result == nil then
		self._ownershipLost[player] = true
	end
	local lastErr = result and tostring(result) or "unknown"
	warn("[ProfileService] save-and-release failed for", player.UserId, tostring(lastErr))
	return false, lastErr
end

function ProfileService:_clearLock(player)
	local key = "p_" .. player.UserId
	pcall(function()
		self._store:UpdateAsync(key, function(existing)
			if type(existing) ~= "table" then
				existing = {}
			end
			local lock = existing._lock
			if type(lock) == "table" and lock.SessionId == self._sessionId then
				existing._lock = nil -- Release ownership.
			end
			return existing
		end)
	end)
end

function ProfileService:Release(player)
	local profile = self._profiles[player]
	if not profile then
		return
	end

	-- Wait for any in-flight save to complete so we coordinate with it.
	local waited = 0
	while self._saveInFlight[player] do
		task.wait(0.05)
		waited += 0.05
		if waited > 30 then
			warn("[ProfileService] Release timed out waiting for in-flight save for", player.UserId)
			break
		end
	end

	local ok, err = true
	if self._loadState[player] == "loaded" and not self._ownershipLost[player] then
		if self._dirty[player] then
			-- Save-and-unlock atomically; never clears lock on save failure.
			ok, err = self:SaveAndRelease(player)
		else
			ok, err = true, self:_clearLock(player) or nil
		end
	end

	if not ok then
		-- Report persistent failure; do NOT clear the stored lock (protects
		-- against another server overwriting data). Profile memory is still
		-- cleaned up because the player has departed.
		warn("[ProfileService] Release save failed for", player.UserId, tostring(err))
	end

	self._profiles[player] = nil
	self._dirty[player] = nil
	self._revision[player] = nil
	self._loadState[player] = nil
	self._saveInFlight[player] = nil
	self._ownershipLost[player] = nil
	self._renewalFailures[player] = nil

	return ok, err
end

function ProfileService:SaveAll()
	for player in pairs(self._profiles) do
		pcall(function()
			self:Save(player)
		end)
	end
end

function ProfileService:Shutdown()
	self._shutdown = true
	self:SaveAll()
	for player in pairs(self._profiles) do
		if self._storeAvailable and self._loadState[player] == "loaded" and not self._ownershipLost[player] then
			pcall(function()
				if self._dirty[player] then
					self:SaveAndRelease(player)
				else
					self:_clearLock(player)
				end
			end)
		end
	end
end

return ProfileService
