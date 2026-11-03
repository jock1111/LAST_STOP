-- Persistent, server-owned player profile service. DataStore failures degrade to a
-- session profile; no client-supplied balance is ever accepted.
local DataStoreService = game:GetService("DataStoreService")

local ProfileService = {}
ProfileService.__index = ProfileService

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
	return profile
end

function ProfileService.new(config)
	local store
	local storeAvailable, storeError = pcall(function()
		store = DataStoreService:GetDataStore(config.ProfileStoreName)
	end)
	if not storeAvailable then
		warn("[ProfileService] DataStore unavailable; using session-only profiles:", storeError)
	end
	return setmetatable({
		_config = config,
		_store = store,
		_storeAvailable = storeAvailable,
		_profiles = {},
		_dirty = {},
	}, ProfileService)
end

function ProfileService:Load(player)
	local key = "p_" .. player.UserId
	local loaded
	local ok, err = self._storeAvailable, "DataStore unavailable"
	if self._storeAvailable then
		ok, err = pcall(function()
			loaded = self._store:GetAsync(key)
		end)
	end
	if not ok then
		warn("[ProfileService] load failed for", player.UserId, err)
	end
	local profile = normalise(loaded, self._config)
	self._profiles[player] = profile
	self._dirty[player] = not ok
	return profile
end

function ProfileService:Get(player)
	return self._profiles[player]
end

function ProfileService:Mutate(player, callback)
	local profile = self._profiles[player]
	if not profile then
		return false, "Profile not loaded"
	end
	callback(profile)
	self._dirty[player] = true
	return true, profile
end

function ProfileService:Save(player)
	local profile = self._profiles[player]
	if not profile or not self._dirty[player] then
		return true
	end
	if not self._storeAvailable then
		return false, "DataStore unavailable"
	end
	local key = "p_" .. player.UserId
	local snapshot = profile
	local ok, err = pcall(function()
		self._store:UpdateAsync(key, function()
			return snapshot
		end)
	end)
	if ok then
		self._dirty[player] = false
	else
		warn("[ProfileService] save failed for", player.UserId, err)
	end
	return ok, err
end

function ProfileService:Release(player)
	self:Save(player)
	self._profiles[player] = nil
	self._dirty[player] = nil
end

function ProfileService:SaveAll()
	for player in pairs(self._profiles) do
		self:Save(player)
	end
end

return ProfileService
