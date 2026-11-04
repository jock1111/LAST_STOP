return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local SubwayCycle = require(ReplicatedStorage.Shared.Util.SubwayCycle)

	-- Phases follow a 16 s period: Safe 0-9, Warning 9-12, Active 12-16.
	local phase = SubwayCycle.Phase(0, 0)
	assert(phase == "Safe", "Cycle start must be Safe")
	assert(select(1, SubwayCycle.Phase(10, 0)) == "Warning", "Expected Warning at 10 s")
	assert(select(1, SubwayCycle.Phase(13, 0)) == "Active", "Expected Active at 13 s")
	assert(select(1, SubwayCycle.Phase(16, 0)) == "Safe", "Cycle must wrap at the period")

	-- The per-run offset shifts the schedule but keeps the same period.
	assert(select(1, SubwayCycle.Phase(13, 4)) == "Safe", "Offset must shift the active window")

	-- Only an Active train has a track position; otherwise it is parked far away.
	assert(SubwayCycle.TrainZ(13, "Active") == -32, "Train should be on the track while Active")
	assert(SubwayCycle.TrainZ(5, "Safe") == -200, "Parked train must be off the track")

	-- Exposure: inside the lane and near the train's Z only.
	assert(SubwayCycle.Exposed(Vector3.new(0, 0, -32), -32), "Player in the lane under the train must be exposed")
	assert(not SubwayCycle.Exposed(Vector3.new(20, 0, -32), -32), "Player beside the lane must be safe")
	assert(not SubwayCycle.Exposed(Vector3.new(0, 0, 40), -32), "Player far down the track must be safe")

	-- Stalker patrol choice: the next waypoint is always different from the current one.
	local seeded = Random.new(7)
	for _ = 1, 200 do
		local current = seeded:NextInteger(1, 4)
		local next = SubwayCycle.PickPatrolIndex(seeded, 4, current)
		assert(next >= 1 and next <= 4, "Patrol index out of range")
		assert(next ~= current, "Stalker must pick a different waypoint")
	end
	assert(SubwayCycle.PickPatrolIndex(seeded, 1, 1) == 1, "Single waypoint must return 1")
end
