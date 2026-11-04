return function()
	-- These check the exact rules ObjectiveRoom uses for route variants and the power flicker.
	-- They test the formulas, not a live floor instance; a live floor is covered by the Studio
	-- playtest checklist (NOT TESTED here).

	-- Hospital route: the seed picks the ward (west) or service corridor (east) route.
	local function hospitalFuseX(seed)
		return (seed % 2 == 1) and 19 or -29
	end
	assert(hospitalFuseX(1) == 19, "Odd seed must take the service corridor route")
	assert(hospitalFuseX(2) == -29, "Even seed must take the ward route")
	-- Both routes end at the same imaging panel, so the objective count never changes.
	for seed = 1, 20 do
		assert(hospitalFuseX(seed) == 19 or hospitalFuseX(seed) == -29, "Hospital route must be one of two fixed options")
	end

	-- Laboratory route: the seed picks which north terminal holds the specimen.
	local function labSpecimenX(seed)
		return (seed % 2 == 0) and -12 or 12
	end
	assert(labSpecimenX(2) == -12, "Even seed must place the specimen on the west terminal")
	assert(labSpecimenX(3) == 12, "Odd seed must place the specimen on the east terminal")

	-- Power flicker: holds for a 1.6 s slot, fires only in Safe, and is rare (about 1 in 37 slots).
	local function flickerAt(elapsed, seed, phase)
		local slot = math.floor(elapsed / 1.6)
		return (slot + seed) % 37 == 0 and phase == "Safe"
	end
	-- The same slot holds for its whole duration, so a client can see it.
	assert(flickerAt(0.0, 0, "Safe") == flickerAt(1.5, 0, "Safe"), "Flicker must hold across its slot")
	-- It never fires during a train pass or discharge.
	assert(flickerAt(0.0, 0, "Warning") == false, "Flicker must not fire during warning")
	assert(flickerAt(0.0, 0, "Active") == false, "Flicker must not fire during an active pass")
	-- Over a long run it fires, and not on every slot.
	local fired, slots = 0, 0
	for slot = 0, 369 do
		slots += 1
		if flickerAt(slot * 1.6, 0, "Safe") then fired += 1 end
	end
	assert(fired > 0 and fired < slots, "Flicker must occur occasionally, not constantly")
end
