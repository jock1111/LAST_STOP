-- Move player close to the current objective to capture interaction prompt.
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

local objPos = floor:GetAttribute("ObjectivePositionX") and Vector3.new(
    floor:GetAttribute("ObjectivePositionX"),
    floor:GetAttribute("ObjectivePositionY"),
    floor:GetAttribute("ObjectivePositionZ")
)
if not objPos then
    -- Find the first enabled ProximityPrompt
    for _, d in ipairs(floor:GetDescendants()) do
        if d:IsA("ProximityPrompt") and d.Parent:GetAttribute("ObjectiveKey") and d.Enabled then
            objPos = d.Parent.Position
            break
        end
    end
end

if objPos then
    root.CFrame = CFrame.new(objPos + Vector3.new(0, 0, 3))
    return {moved = true, position = tostring(objPos)}
end
return {error = "no objective position"}
