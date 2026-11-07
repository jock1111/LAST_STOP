return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local EconomyService = require(script.Parent.Parent.Services.EconomyService)
	local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)

	local fakeProfiles = {}
	local economy = EconomyService.new(fakeProfiles, { FirstEscapeBonus = 50 })
	local depthOneCoins, depthOneXP = economy:CalculateFloorReward(1, 3)
	assert(depthOneCoins == 80, "Expected 80 coins at depth 1 with three objective steps")
	assert(depthOneXP == 25, "Expected 25 XP at depth 1")
	local depthTenCoins = select(1, economy:CalculateFloorReward(10, 3))
	assert(depthTenCoins > depthOneCoins, "Depth multiplier must increase rewards")

	local limiter = RateLimiter.new(2, 60)
	assert(limiter:Allow("player"), "First request should pass")
	assert(limiter:Allow("player"), "Second request should pass")
	assert(not limiter:Allow("player"), "Third request must be blocked")
	limiter:Forget("player")
	assert(limiter:Allow("player"), "Forget must clear a player's bucket")
end
