local ExpeditionService = require(game:GetService("ServerScriptService").Services.ExpeditionService)
local FloorConfig = require(game:GetService("ReplicatedStorage").Shared.Config.FloorConfig)
local fake = {recentFloorIds = {}, depth = 1, seed = 12345}
local picks = {}
for i = 1, 5 do
    fake.seed = 1000 + i
    local def = ExpeditionService._chooseFloor(fake)
    table.insert(picks, def.Template)
end
local weights = {}
for _, f in ipairs(FloorConfig.Floors) do table.insert(weights, f.Template .. "=" .. f.Weight) end
return {picks = picks, weights = table.concat(weights, ",")}
