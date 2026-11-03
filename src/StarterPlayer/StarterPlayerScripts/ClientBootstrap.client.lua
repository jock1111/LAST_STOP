local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RemoteNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"):WaitForChild("RemoteNames"))
local HUDController = require(script.Parent.Controllers.HUDController)
local InputController = require(script.Parent.Controllers.InputController)

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
})

local input = InputController.new(function()
	remotes.RequestMedkit:FireServer()
end)

remotes.StateChanged.OnClientEvent:Connect(function(state)
	if type(state) == "table" then
		hud:ApplyState(state)
	end
end)

remotes.Toast.OnClientEvent:Connect(function(message)
	hud:ShowToast(message)
end)

-- Resources are intentionally retained for the lifetime of this player session.
player.AncestryChanged:Connect(function(_, parent)
	if not parent then
		input:Destroy()
		hud:Destroy()
	end
end)
