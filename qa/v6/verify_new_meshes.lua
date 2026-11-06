local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local world = Workspace:WaitForChild("LastStopWorld", 10)
local active = world and world:WaitForChild("Runtime", 10) and world.Runtime:WaitForChild("ActiveExpedition", 10)
local floor = active and active:FindFirstChildWhichIsA("Model", true)
-- find the floor model with FloorTheme
local target
if active then
    for _, m in ipairs(active:GetChildren()) do
        if m:IsA("Model") and m:GetAttribute("FloorTheme") then target = m break end
    end
end
local wanted = {"specimen-canister","containment-vessel","pump-machine","research-console","subway-train-car","station-bench","signal-post","subway-track-section"}
local found = {}
if target then
    for _, d in ipairs(target:GetDescendants()) do
        if d:IsA("MeshPart") then
            for _, n in ipairs(wanted) do
                if d.Name == n then found[n] = (found[n] or 0) + 1 end
            end
        end
    end
end
local snapshot = ReplicatedStorage:GetAttribute("LastStopSnapshot")
return {floor = target and target.Name, theme = target and target:GetAttribute("FloorTheme"), meshCounts = found, snapshot = snapshot}
