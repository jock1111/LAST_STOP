-- LAST STOP Milestone A server bootstrap. Place as a Script in ServerScriptService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local RemoteNames = require(ReplicatedStorage.Shared.Config.RemoteNames)
local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)
local ProfileService = require(script.Parent.Services.ProfileService)
local EconomyService = require(script.Parent.Services.EconomyService)
local FloorService = require(script.Parent.Services.FloorService)
local PbrMaterialService = require(script.Parent.Services.PbrMaterialService)
local EnemyService = require(script.Parent.Services.EnemyService)
local InventoryService = require(script.Parent.Services.InventoryService)
local MatchmakingService = require(script.Parent.Services.MatchmakingService)
local ExpeditionService = require(script.Parent.Services.ExpeditionService)

local function ensureRemotes()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end
	local remotes = {}
	for key, name in pairs(RemoteNames) do
		local remote = folder:FindFirstChild(name)
		if not remote then
			remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = folder
		end
		assert(remote:IsA("RemoteEvent"), "Remote " .. name .. " must be a RemoteEvent")
		remotes[key] = remote
	end
	return remotes
end

local remotes = ensureRemotes()
local profiles = ProfileService.new(GameConfig)
local economy = EconomyService.new(profiles, GameConfig)
local floors = FloorService.new()
local enemyService = EnemyService.new()
local inventory = InventoryService.new()
local lobby = floors:BuildWorld()
PbrMaterialService:Apply(lobby.Model)
enemyService:Start()

Lighting.Brightness = 2
Lighting.ClockTime = 0
Lighting.Ambient = Color3.fromRGB(96, 108, 114)
Lighting.OutdoorAmbient = Color3.fromRGB(20, 25, 31)
Lighting.FogColor = Color3.fromRGB(34, 43, 51)
Lighting.FogEnd = 350
Lighting.GlobalShadows = true
-- LightingStyle is saved in default.project.json (Studio-only capability).
Lighting.EnvironmentDiffuseScale = 0.6
Lighting.EnvironmentSpecularScale = 0.6

local function effect(className, name, properties)
	local instance = Lighting:FindFirstChild(name)
	if not instance then
		instance = Instance.new(className)
		instance.Name = name
		instance.Parent = Lighting
	end
	for property, value in pairs(properties) do
		instance[property] = value
	end
	return instance
end

effect("Atmosphere", "LastStopAtmosphere", {
	Density = 0.12,
	Offset = 0.15,
	Color = Color3.fromRGB(145, 169, 182),
	Decay = Color3.fromRGB(38, 55, 65),
	Glare = 0,
	Haze = 1.15,
})
effect("ColorCorrectionEffect", "LastStopGrade", {
	Brightness = -0.03,
	Contrast = 0.12,
	Saturation = -0.08,
	TintColor = Color3.fromRGB(214, 235, 242),
})
effect("BloomEffect", "LastStopBloom", {
	Intensity = 0.18,
	Size = 28,
	Threshold = 1.6,
})

local limiter = RateLimiter.new(GameConfig.RemoteRateLimit.Count, GameConfig.RemoteRateLimit.WindowSeconds)
local currentExpedition = nil
local matchmaking

local function toast(player, message)
	remotes.Toast:FireClient(player, message)
end

local function moveToLobby(player)
	player.RespawnLocation = lobby.SpawnLocation
	task.spawn(function()
		local character = player.Character or player.CharacterAdded:Wait()
		local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
		if root then
			task.wait(.2) -- Allow the engine to finish initial spawn placement.
			if not player.Parent then return end
			character:PivotTo(lobby.LobbySpawn)
		end
	end)
end

local function canQueue(player)
	return profiles:Get(player) ~= nil and (not currentExpedition or not currentExpedition:IsRunning())
end

matchmaking = MatchmakingService.new(GameConfig, canQueue, function(group, finished)
	local expedition
	expedition = ExpeditionService.new(
		GameConfig,
		floors,
		enemyService,
		economy,
		profiles,
		inventory,
		remotes,
		function(reason)
			if currentExpedition == expedition then
				currentExpedition = nil
			end
			finished()
			print("[LAST STOP] Expedition ended:", reason)
		end
	)
	currentExpedition = expedition
	expedition:Start(group)
end, toast)

require(script.Parent.Services.MovementService).Start(remotes.RequestSprint, function(player)
    return currentExpedition and (currentExpedition.state == "Floor" or currentExpedition.state == "Escape") and currentExpedition.active[player] == true
end)
local function remotelyAllowed(remoteName, player)
	if not limiter:Allow(remoteName .. ":" .. player.UserId) then
		toast(player, "Too many requests. Please wait a moment.")
		return false
	end
	return true
end

remotes.RequestQueue.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 0 or not remotelyAllowed("Queue", player) then
		return
	end
	local ok, message = matchmaking:RequestJoin(player)
	toast(player, message)
end)
remotes.RequestState.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 0 or not remotelyAllowed("State", player) then return end
	if currentExpedition and currentExpedition:SyncState(player) then return end
	local snapshot = player:GetAttribute("LastStopSnapshot")
	if snapshot then
		local ok, data = pcall(game:GetService("HttpService").JSONDecode, game:GetService("HttpService"), snapshot)
		if ok and data.state == "Results" then remotes.StateChanged:FireClient(player, data); return end
	end
	remotes.StateChanged:FireClient(player, {
		state = "Lobby", floorName = "Terminus Concourse", progress = 0, unbanked = 0,
		banked = economy:GetBankedCoins(player), objective = "Board an expedition. Bring your team home.",
	})
end)

remotes.RequestDecision.OnServerEvent:Connect(function(player, decision, ...)
	if select("#", ...) ~= 0 or type(decision) ~= "string" or #decision > 10 or not remotelyAllowed("Decision", player) then
		return
	end
	if not currentExpedition then
		return
	end
	local ok, message = currentExpedition:RequestDecision(player, decision)
	if not ok then
		toast(player, message)
	end
end)

remotes.RequestMedkit.OnServerEvent:Connect(function(player, ...)
	if select("#", ...) ~= 0 or not remotelyAllowed("Medkit", player) then
		return
	end
	if currentExpedition then
		local ok, message = currentExpedition:RequestMedkit(player)
		toast(player, message)
	end
end)

lobby.QueuePrompt.Triggered:Connect(function(player)
	local ok, message = matchmaking:RequestJoin(player)
	toast(player, message)
end)

local function onPlayerAdded(player)
	local profile, sessionOnly = profiles:Load(player)
	player:SetAttribute("LastStopProfileLoaded", true)
	if sessionOnly then
		toast(player, "Your profile could not be loaded from the cloud. This session's progress will not be saved.")
	end
	moveToLobby(player)
	toast(player, "Welcome to LAST STOP. Queue at the terminal or press PLAY.")
end

Players.PlayerAdded:Connect(onPlayerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(onPlayerAdded, player)
end

Players.PlayerRemoving:Connect(function(player)
	matchmaking:Remove(player)
	if currentExpedition then
		currentExpedition:OnPlayerRemoving(player)
	end
	limiter:Forget("Queue:" .. player.UserId)
	limiter:Forget("State:" .. player.UserId)
	limiter:Forget("Decision:" .. player.UserId)
	limiter:Forget("Medkit:" .. player.UserId)
	profiles:Release(player)
end)

task.spawn(function()
	while task.wait(GameConfig.AutosaveSeconds) do
		profiles:SaveAll()
	end
end)

game:BindToClose(function()
	if currentExpedition then
		currentExpedition:Destroy()
	end
	profiles:Shutdown()
end)

matchmaking:Start()
