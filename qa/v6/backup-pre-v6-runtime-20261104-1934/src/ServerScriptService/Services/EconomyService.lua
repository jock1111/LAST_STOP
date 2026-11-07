local EconomyConfig = require(game:GetService("ReplicatedStorage").Shared.Config.EconomyConfig)

local EconomyService = {}
EconomyService.__index = EconomyService

function EconomyService.new(profileService, gameConfig)
	return setmetatable({ _profiles = profileService, _gameConfig = gameConfig }, EconomyService)
end

function EconomyService:CalculateFloorReward(depth, objectiveProgress)
	local multiplier = math.min(
		1 + math.max(0, depth - 1) * EconomyConfig.DepthMultiplierStep,
		EconomyConfig.MaxDepthMultiplier
	)
	local gross = EconomyConfig.BaseFloorCoins + EconomyConfig.TeamCompletionBonus
		+ EconomyConfig.ObjectiveBonus + objectiveProgress * EconomyConfig.XPPerObjectiveStep
	return math.floor(gross * multiplier), math.floor(EconomyConfig.XPPerFloor * multiplier)
end

function EconomyService:Bank(player, unbanked, pendingXP, depth)
	if unbanked <= 0 then
		return 0
	end
	local granted = 0
	self._profiles:Mutate(player, function(profile)
		profile.Coins += unbanked
		profile.XP += math.max(0, pendingXP or 0)
		profile.Level = math.max(1, math.floor(profile.XP / 100) + 1)
		profile.Stats.Escapes += 1
		profile.Stats.BestDepth = math.max(profile.Stats.BestDepth or 0, depth)
		if not profile.Stats.FirstEscapeClaimed then
			profile.Stats.FirstEscapeClaimed = true
			profile.Coins += self._gameConfig.FirstEscapeBonus
			granted = unbanked + self._gameConfig.FirstEscapeBonus
		else
			granted = unbanked
		end
	end)
	self._profiles:Save(player)
	return granted
end

function EconomyService:GetBankedCoins(player)
	local profile = self._profiles:Get(player)
	return profile and profile.Coins or 0
end

return EconomyService
