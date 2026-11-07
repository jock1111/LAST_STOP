local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("RemoteNames"))
-- In PlayerScripts, sibling folders may replicate a frame after this
-- LocalScript. Waiting prevents a client startup race in Studio and live play.
local controllers = script.Parent:WaitForChild("Controllers")
local HUDController = require(controllers:WaitForChild("HUDController"))
local InputController = require(controllers:WaitForChild("InputController"))
local Onboarding = require(controllers:WaitForChild("OnboardingController"))

local soundscape = require(controllers:WaitForChild("SoundscapeController")).new()
local player = Players.LocalPlayer
local remoteFolder = ReplicatedStorage:WaitForChild("Remotes")
local remotes = {}
for key, name in pairs(RemoteNames) do
	remotes[key] = remoteFolder:WaitForChild(name)
end

local hud = HUDController.new(player, {
	queue = function()
		remotes.RequestQueue:FireServer()
	end,
	decision = function(decision)
		remotes.RequestDecision:FireServer(decision)
	end,
	medkit = function()
		remotes.RequestMedkit:FireServer()
	end,
	sprint = function(pressed)
		remotes.RequestSprint:FireServer(pressed)
	end,
	hideTutorials = function()
		onboarding:disable()
		hud:HideTutorials()
	end,
	showTutorialsButton = function(available)
		hud:ShowTutorialsButton(available)
	end,
})

local input = InputController.new(function()
	remotes.RequestMedkit:FireServer()
end)

local onboarding = Onboarding.new(player, function(text)
	hud:ShowToast(text)
end, function()
	onboarding:disable()
	hud:HideTutorials()
end)

remotes.StateChanged.OnClientEvent:Connect(function(state)
	if type(state) == "table" then
		hud:ApplyState(state)
		soundscape:ApplyState(state)
		onboarding:update(state.state, state)
		-- Show the dismiss-tutorials button to first-time players in the lobby.
		if state.state == "Lobby" and not onboarding:isReturning(state) then
			hud:ShowTutorialsButton(true)
		else
			hud:ShowTutorialsButton(false)
		end
	end
end)

remotes.Toast.OnClientEvent:Connect(function(message)
	hud:ShowToast(message)
end)
remotes.QueueCountdown.OnClientEvent:Connect(function(seconds)
	hud:setQueueCountdown(seconds)
end)
-- Recover the authoritative state after listeners are ready and after respawn.
-- A Results event can arrive while the character/GUI is being recreated.
player.CharacterAdded:Connect(function()
	remotes.RequestState:FireServer()
end)
remotes.RequestState:FireServer()

-- Resources are intentionally retained for the lifetime of this player session.
player.AncestryChanged:Connect(function(_, parent)
	if not parent then
		input:Destroy()
		hud:Destroy()
		onboarding:Destroy()
	end
end)

require(controllers:WaitForChild("CreatureController")).Start()

pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Health, false) end)
