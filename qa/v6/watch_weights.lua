local ReplicatedStorage = game:GetService("ReplicatedStorage")
local FloorConfig = require(ReplicatedStorage.Shared.Config.FloorConfig)
local weights = {}
for _, f in ipairs(FloorConfig.Floors) do table.insert(weights, f.Template .. "=" .. f.Weight) end
return table.concat(weights, ",")
