local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local queue = remotes and remotes:FindFirstChild("RequestQueue")
assert(queue, "RequestQueue missing")
queue:FireServer()

local world = Workspace:WaitForChild("LastStopWorld", 15)
local runtime = world and world:WaitForChild("Runtime", 10)
local active = runtime and runtime:WaitForChild("ActiveExpedition", 10)
assert(active, "ActiveExpedition missing")

local floor
for _ = 1, 700 do
	for _, child in ipairs(active:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("FloorTheme") then
			floor = child
			break
		end
	end
	if floor then break end
	task.wait(0.1)
end

local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
return {
	queued = true,
	floor = floor and floor.Name or nil,
	theme = floor and floor:GetAttribute("FloorTheme") or nil,
	pivot = floor and tostring(floor:GetPivot().Position) or nil,
	playerPosition = root and tostring(root.Position) or nil,
}
