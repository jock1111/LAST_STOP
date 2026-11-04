-- Persistent, server-owned player profile service. DataStore failures degrade to a
-- session profile; no client-supplied balance is ever accepted. A failed load is
-- distinguished from a brand-new player, and a session profile is never persisted
-- over existing saved progress.
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local ProfileService = {}
ProfileService.__index = ProfileService

local LOCK_TTL_SECONDS = 600
local LOAD_RETRIES = 3
local LOAD_RETRY_BASE_DELAY = 1
local SAVE_RETRIES = 3
local SAVE_RETRY_BASE_DELAY = 1

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
		profile.Equipment = saved.Equipment
	end
	if type(saved.Stats) == "table" then
		for key, value in pairs(saved.Stats) do
			if type(value) == "boolean" or type(value) == "number" then
				profile.Stats[key] = value
			end
		end
	end
	-- Preserve session-lock metadata so conflicting servers cannot overwrite.
	if type(saved._lock) == "table" then
		profile._lock = {
			SessionId = saved._lock.SessionId,
			Timestamp = saved._lock.Timestamp,
		}
	end
	return profile
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
		storeAvailable = true
	end
	return setmetatable({
		_config = config,
		_store = store,
		_storeAvailable = storeAvailable,
		_sessionId = newSessionId(),
		_profiles = {},
		_dirty = {},
		_loadState = {}, -- "loaded" | "failed" | "sessionOnly"
	}, ProfileService)
end

-- Atomically claims the session lock and returns the stored data. Returns
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
					-- Stale lock from a dead server: reclaim.
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
		self._loadState[player] = "sessionOnly"
		return profile, true
	end
	local now = os.time()
	local claimed, loaded = self:_claimAndRead(key, now)
	if not claimed then
		warn("[ProfileService] could not claim profile for", player.UserId, tostring(loaded))
		local profile = defaultProfile(self._config)
		self._profiles[player] = profile
		self._loadState[player] = "failed"
		return profile, true
	end
	local profile = normalise(loaded, self._config)
	self._profiles[player] = profile
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

function ProfileService:Mutate(player, callback)
	local profile = self._profiles[player]
	if not profile then
		return false, "Profile not loaded"
	end
	callback(profile)
	-- A failed or session-only load must never be persisted over stored data.
	if self._loadState[player] == "loaded" then
		self._dirty[player] = true
	end
	return true, profile
end

function ProfileService:Save(player)
	local profile = self._profiles[player]
	if not profile then
		return true
	end
	if self._loadState[player] ~= "loaded" then
		-- Never persist a session-only or failed-load profile over existing data.
		return false, "Profile not safely loaded; refusing to save"
	end
	if not self._dirty[player] then
		return true
	end
	if not self._storeAvailable then
		return false, "DataStore unavailable"
	end
	local key = "p_" .. player.UserId
	local now = os.time()
	if type(profile._lock) ~= "table" then
		profile._lock = {}
	end
	profile._lock.SessionId = self._sessionId
	profile._lock.Timestamp = now
	local snapshot = profile
	local lastErr
	for attempt = 1, SAVE_RETRIES do
		local ok, result = pcall(function()
			return self._store:UpdateAsync(key, function(existing)
				-- Re-verify ownership before overwriting.
				if type(existing) == "table" and type(existing._lock) == "table" then
					if existing._lock.SessionId ~= self._sessionId then
						local age = now - (existing._lock.Timestamp or 0)
						if age < LOCK_TTL_SECONDS then
							return nil -- Conflict; another server owns it now.
						end
					end
				end
				return snapshot
			end)
		end)
		if ok then
			if result == nil then
				lastErr = "conflicting profile ownership"
				task.wait(SAVE_RETRY_BASE_DELAY * attempt)
			else
				self._dirty[player] = false
				return true
			end
		else
			lastErr = tostring(result)
			task.wait(SAVE_RETRY_BASE_DELAY * attempt)
		end
	end
	warn("[ProfileService] save failed after retries for", player.UserId, lastErr)
	return false, lastErr
end

function ProfileService:Release(player)
	self:Save(player)
	self._profiles[player] = nil
	self._dirty[player] = nil
	self._loadState[player] = nil
end

function ProfileService:SaveAll()
	for player in pairs(self._profiles) do
		self:Save(player)
	end
end

return ProfileService
