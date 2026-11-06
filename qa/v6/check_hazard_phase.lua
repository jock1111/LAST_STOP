local Workspace = game:GetService("Workspace")
local world = Workspace:WaitForChild("LastStopWorld", 10)
local active = world and world:WaitForChild("Runtime", 10) and world.Runtime:WaitForChild("ActiveExpedition", 10)
local result = {phase = "none", trainZ = nil, elapsed = nil}
if active then
    for _, m in ipairs(active:GetChildren()) do
        if m:IsA("Model") and m:GetAttribute("FloorTheme") == "Subway" then
            result.phase = m:GetAttribute("HazardPhase")
            result.trainZ = m:GetAttribute("TrainZ")
            result.floorClock = m:GetAttribute("FloorClock") or m:GetAttribute("Elapsed")
            local train = m:FindFirstChild("Train")
            if train then result.trainPivot = tostring(train:GetPivot().Position) end
            break
        end
    end
end
return result
