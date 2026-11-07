local Workspace = game:GetService("Workspace")
local world = Workspace:WaitForChild("LastStopWorld", 10)
local runtime = world and world:WaitForChild("Runtime", 10)
local folder = runtime and runtime:WaitForChild("ActiveExpedition", 10)
local floor = folder and folder:FindFirstChildOfClass("Model")
local result = {floor = floor and floor.Name, stage = nil, targets = {}}
if floor then
    result.stage = floor:GetAttribute("ObjectiveStage")
    -- find the room object via script context is hard; check targets directly
    for _, d in ipairs(floor:GetDescendants()) do
        if d:GetAttribute("ObjectiveKey") then
            table.insert(result.targets, {
                name = d.Name, key = d:GetAttribute("ObjectiveKey"),
                position = d.Position and tostring(d.Position) or "nil",
                parent = d.Parent and d.Parent.Name or "nil",
            })
        end
    end
end
-- try JSON encode of a vector3
local ok, json = pcall(function() return game:GetService("HttpService"):JSONEncode({x = Vector3.new(1,2,3)}) end)
result.jsonVec3Ok = ok
result.jsonVec3 = json
return result
