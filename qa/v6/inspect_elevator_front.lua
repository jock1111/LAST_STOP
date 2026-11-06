local Workspace = game:GetService("Workspace")
local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local lobby = runtime and runtime:FindFirstChild("Lobby")
local elevator = lobby and lobby:FindFirstChild("CentralElevator")
assert(elevator, "no elevator")
local names = { "FloorDisplay", "IndicatorBezel", "IndicatorDot1", "IndicatorDot2", "IndicatorDot3", "IndicatorRing1", "IndicatorRing2", "IndicatorRing3", "MechanicalHeader", "DoorLeft", "DoorRight", "CabinInstruction" }
local result = {}
for _, name in ipairs(names) do
	local part = elevator:FindFirstChild(name, true)
	if part then
		result[name] = { position = tostring(part.Position), size = tostring(part.Size) }
	end
end
return result
