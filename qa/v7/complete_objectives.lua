-- Complete all objectives by triggering ProximityPrompts.
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

local result = {floor = floor.Name, stage = floor:GetAttribute("ObjectiveStage"), actions = {}}

-- Find all ProximityPrompts on objective targets, sorted by stage.
local prompts = {}
for _, d in ipairs(floor:GetDescendants()) do
    if d:IsA("ProximityPrompt") and d.Parent:GetAttribute("ObjectiveKey") then
        local stage = d.Parent:GetAttribute("ObjectiveStage") or 0
        table.insert(prompts, {prompt = d, part = d.Parent, key = d.Parent:GetAttribute("ObjectiveKey"), stage = stage})
    end
end
table.sort(prompts, function(a, b) return a.stage < b.stage end)

for _, entry in ipairs(prompts) do
    -- Move player close to the prompt
    root.CFrame = CFrame.new(entry.part.Position + Vector3.new(0, 0, 3))
    task.wait(0.5)
    -- Try fireproximityprompt
    local ok, err = pcall(function()
        fireproximityprompt(entry.prompt)
    end)
    table.insert(result.actions, {key = entry.key, stage = entry.stage, fired = ok, error = ok and nil or tostring(err)})
    task.wait(0.5)
end
return result
