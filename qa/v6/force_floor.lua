local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FloorConfig = require(ReplicatedStorage.Shared.Config.FloorConfig)
local target = ReplicatedStorage:GetAttribute("QA_ForceFloor") or "FloodedLaboratory"
for _, floor in ipairs(FloorConfig.Floors) do
    floor.Weight = floor.Template == target and 100 or 0
end
return {forced = target}
