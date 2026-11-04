-- Pure timing rules for the abandoned subway train pass. Server-only logic reads
-- these; the client never decides whether a train is passing or who is hit.
local SubwayCycle = {}

SubwayCycle.Period = 16
SubwayCycle.WarningStart = 9
SubwayCycle.ActiveStart = 12

-- Returns "Safe", "Warning" or "Active" for an elapsed time and a per-run offset.
function SubwayCycle.Phase(elapsed, offset)
	local cycle = (elapsed + offset) % SubwayCycle.Period
	if cycle > SubwayCycle.ActiveStart then
		return "Active", cycle
	elseif cycle > SubwayCycle.WarningStart then
		return "Warning", cycle
	end
	return "Safe", cycle
end

-- Train Z position along the track while Active; parked far away otherwise.
function SubwayCycle.TrainZ(cycle, phase)
	if phase ~= "Active" then
		return -200
	end
	return -86 + (cycle - SubwayCycle.ActiveStart) * 54
end

-- A player is hit when inside the track lane and close to the train's Z.
function SubwayCycle.Exposed(localPosition, trainZ)
	return math.abs(localPosition.X) < 6 and math.abs(localPosition.Z - trainZ) < 12
end

-- Random next patrol waypoint that is never the one just reached.
function SubwayCycle.PickPatrolIndex(random, count, current)
	if count <= 1 then return 1 end
	local index = random:NextInteger(1, count - 1)
	if index >= current then index += 1 end
	return index
end

return SubwayCycle
