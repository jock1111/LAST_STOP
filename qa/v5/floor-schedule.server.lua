-- Temporary Studio-only selector. Start ExecuteMultiplayerTestAsync(2,
-- "V5_FINAL_SCHEDULED"), then insert this Script in the SERVER DataModel.
-- This file is outside the Rojo project and is absent from LAST_STOP.rbxlx.
if not game:GetService("RunService"):IsStudio()
    or game:GetService("StudioTestService"):GetTestArgs() ~= "V5_FINAL_SCHEDULED" then return end
local Expedition = require(game.ServerScriptService.Services.ExpeditionService)
local definitions = require(game.ReplicatedStorage.Shared.Config.FloorConfig).Floors
function Expedition:_chooseFloor()
    self.qaFloorIndex = (self.qaFloorIndex or 0) % #definitions + 1
    return definitions[self.qaFloorIndex]
end
