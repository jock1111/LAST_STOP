-- LAST STOP V7 — First-session onboarding.
--
-- Optional, contextual, non-blocking tips that explain the core loop to a
-- first-time player. Returning players (detected from existing profile data)
-- skip the tutorial entirely. Progress is tracked session-locally so a player
-- never sees the same tip twice in one sitting, without any ProfileService
-- schema changes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Onboarding = {}
Onboarding.__index = Onboarding

-- Session-local set of tip IDs already shown to this player. Keyed by Player
-- object so it survives respawns (the LocalScript outlives the character) but
-- resets when the player rejoins. Never written to a profile.
local seenTips = setmetatable({}, { __mode = "k" })

local TIPS = {
	start_expedition = {
		condition = function(self, state) return state == "Lobby" end,
		text = "Press BOARD EXPEDITION to begin your first run into the facility.",
	},
	boarding = {
		condition = function(self, state) return state == "Boarding" end,
		text = "The elevator is boarding. Step inside before the doors close.",
	},
	objective_interact = {
		condition = function(self, state) return state == "Floor" end,
		text = "Head to the marked waypoint and hold E to interact with the objective.",
	},
	sprint = {
		condition = function(self, state) return state == "Floor" or state == "Escape" end,
		text = "Hold Shift to sprint. Your stamina drains while running.",
	},
	heal = {
		condition = function(self, state) return state == "Floor" or state == "Escape" end,
		text = "Press H to use your medkit and restore health.",
	},
	coins_at_risk = {
		condition = function(self, state, data) return (data.unbanked or 0) > 0 end,
		text = "Coins you collect are AT RISK until you BANK them at the checkpoint.",
	},
	bank_continue = {
		condition = function(self, state) return state == "Decision" end,
		text = "BANK to secure your haul, or CONTINUE and risk it on the next floor.",
	},
}

function Onboarding.new(player, showToast)
	local self = setmetatable({
		player = player,
		showToast = showToast,
		shown = seenTips[player] or {},
		lastState = nil,
	}, Onboarding)
	seenTips[player] = self.shown
	return self
end

-- True when existing profile data indicates this player has played before.
-- No ProfileService schema changes; we only read what EconomyService already
-- exposes through the banked-coins snapshot field.
function Onboarding:isReturning(data)
	return (data and data.banked or 0) > 0
end

function Onboarding:hasSeen(tipId)
	return self.shown[tipId] == true
end

function Onboarding:markSeen(tipId)
	self.shown[tipId] = true
end

-- Show a contextual tip once, as a short toast that does not block gameplay.
function Onboarding:show(tipId, state, data)
	if self:hasSeen(tipId) then return end
	local tip = TIPS[tipId]
	if not tip then return end
	if tip.condition and not tip.condition(self, state, data) then return end
	self:markSeen(tipId)
	task.defer(function()
		if self.showToast then self.showToast("TIP · " .. tip.text) end
	end)
end

-- Call whenever the expedition state snapshot changes. Fires whichever tip
-- becomes relevant for the new state, each at most once per session.
function Onboarding:update(state, data)
	if self.lastState == state then return end
	self.lastState = state
	if self:isReturning(data) then return end
	self:show("start_expedition", state, data)
	self:show("boarding", state, data)
	self:show("objective_interact", state, data)
	self:show("sprint", state, data)
	self:show("heal", state, data)
	self:show("coins_at_risk", state, data)
	self:show("bank_continue", state, data)
end

function Onboarding:Destroy()
	seenTips[self.player] = nil
end

return Onboarding
