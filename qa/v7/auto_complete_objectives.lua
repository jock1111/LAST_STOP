-- Auto-complete objectives using fireproximityprompt.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer
local character = player.Character
local root = character and character:FindFirstChild("HumanoidRootPart")
if not root then return {error = "no root"} end

local world = Workspace:WaitForChild("LastStopWorld", 10)
local runtime = world and world:WaitForChild("Runtime", 10)
local folder = runtime and runtime:WaitForChild("ActiveExpedition", 10)
local floor = folder and folder:FindFirstChildOfClass("Model")
if not floor then return {error = "no floor"} end

local prompts = {}
for _, d in ipairs(floor:GetDescendants()) do
    if d:IsA("ProximityPrompt") and d.Parent:GetAttribute("ObjectiveKey") then
        table.insert(prompts, {prompt = d, part = d.Parent, key = d.Parent:GetAttribute("ObjectiveKey")})
    end
end
table.sort(prompts, function(a, b) return a.key < b.key end)

local result = {floor = floor.Name, prompts = {}}
for _, entry in ipairs(prompts) do
    root.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 0, 3))
    task.wait(0.4)
    local ok, err = pcall(function()
        fireproximityprompt(entry.prompt)
    end)
    table.insert(result.prompts, {key = entry.key, fired = ok, error = ok and nil or tostring(err)})
    task.wait(0.5)
end
return result
