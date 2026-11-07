local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FloorConfig = require(ReplicatedStorage.Shared.Config.FloorConfig)
local t = {}
for _, f in ipairs(FloorConfig.Floors) do table.insert(t, f.Template .. "=" .. f.Weight) end
return {weights = table.concat(t, ","), attr = ReplicatedStorage:GetAttribute("QA_ForceFloor")}
