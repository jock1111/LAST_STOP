-- LAST STOP V7 — First-session onboarding.
--
-- Optional, contextual, non-blocking tips that explain the core loop to a
-- first-time player. Tips are delivered through a small FIFO queue so they
-- never overwrite each other or important gameplay messages. Returning players
-- (previously banked coins, or having entered a Floor in this session) skip the
-- tutorial. Progress is tracked session-locally; no ProfileService schema
-- changes are required. A dismiss button lets any player hide tutorials.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)

local Onboarding = {}
Onboarding.__index = Onboarding

-- Session-local tips already shown to this player. Survives respawns (the
-- LocalScript outlives the character) but resets when the player rejoins.
-- Never written to a profile.
local seenTips = setmetatable({}, { __mode = "k" })

-- Session-local flag: once a player has entered Floor state they are no longer
-- brand new, even if they never secured any coins (banked == 0). This prevents
-- a player who played but never BANKED from being reclassified as brand-new.
local hasEverFloored = setmetatable({}, { __mode = "k" })

local TIPS = {
	start_expedition = {
		priority = 1,
		condition = function(self, state) return state == "Lobby" end,
		text = "Press BOARD EXPEDITION to begin your first run into the facility.",
	},
	boarding = {
		priority = 2,
		condition = function(self, state) return state == "Boarding" end,
		text = "The elevator is boarding. Step inside before the doors close.",
	},
	objective_interact = {
		priority = 3,
		condition = function(self, state) return state == "Floor" end,
		text = "Head to the marked waypoint and hold E to interact with the objective.",
	},
	sprint = {
		priority = 4,
		condition = function(self, state) return state == "Floor" or state == "Escape" end,
		text = "Hold Shift to sprint. Your stamina drains while running.",
	},
	heal = {
		priority = 5,
		condition = function(self, state) return state == "Floor" or state == "Escape" end,
		text = "Press H to use your medkit and restore health.",
	},
	coins_at_risk = {
		priority = 6,
		condition = function(self, state, data) return (data.unbanked or 0) > 0 end,
		text = "Coins you collect are AT RISK until you BANK them at the checkpoint.",
	},
	bank_continue = {
		priority = 7,
		condition = function(self, state) return state == "Decision" end,
		text = "BANK to secure your haul, or CONTINUE and risk it on the next floor.",
	},
}

function Onboarding.new(player, showToast, dismissTutorials)
	local self = setmetatable({
		player = player,
		showToast = showToast,
		dismissTutorials = dismissTutorials,
		shown = seenTips[player] or {},
		queue = {},
		displaying = false,
		lastState = nil,
	}, Onboarding)
	seenTips[player] = self.shown
	return self
end

-- True when existing profile data or session state indicates this player has
-- played before. A player who entered Floor but never secured coins is still
-- returning; we track that via hasEverFloored.
function Onboarding:isReturning(data)
	if self.shown._hasEverFloored then return true end
	if hasEverFloored[self.player] then return true end
	return (data and data.banked or 0) > 0
end

function Onboarding:hasSeen(tipId)
	return self.shown[tipId] == true
end

function Onboarding:markSeen(tipId)
	self.shown[tipId] = true
end

-- Mark that this player has entered a Floor (they are no longer brand new).
function Onboarding:markFloored()
	hasEverFloored[self.player] = true
	self.shown._hasEverFloored = true
end

-- Disable all future tutorial tips for this player (dismiss action).
function Onboarding:disable()
	for tipId in pairs(TIPS) do
		self:markSeen(tipId)
	end
	self.queue = {}
end

-- Enqueue a tip if it is relevant and not yet shown. Higher priority tips are
-- shown first. Gameplay toasts (via showToast) take priority by simply not
-- being enqueued here.
function Onboarding:enqueue(tipId, state, data)
	if self:hasSeen(tipId) then return end
	if self:isReturning(data) then return end
	local tip = TIPS[tipId]
	if not tip then return end
	if tip.condition and not tip.condition(self, state, data) then return end
	table.insert(self.queue, { tipId = tipId, priority = tip.priority })
	table.sort(self.queue, function(a, b) return a.priority < b.priority end)
end

-- Show the next queued tip, one at a time. Nonblocking.
function Onboarding:flush()
	if self.displaying then return end
	if #self.queue == 0 then return end
	local entry = table.remove(self.queue, 1)
	self:markSeen(entry.tipId)
	self.displaying = true
	task.defer(function()
		if self.showToast then self.showToast("TIP · " .. TIPS[entry.tipId].text) end
		task.delay(4, function()
			self.displaying = false
			self:flush()
		end)
	end)
end

-- Call whenever the expedition state snapshot changes. Enqueues whichever tips
-- become relevant for the new state, then flushes the queue.
function Onboarding:update(state, data)
	if self.lastState == state then return end
	self.lastState = state
	if state == "Floor" then self:markFloored() end
	if self:isReturning(data) then return end
	self:enqueue("start_expedition", state, data)
	self:enqueue("boarding", state, data)
	self:enqueue("objective_interact", state, data)
	self:enqueue("sprint", state, data)
	self:enqueue("heal", state, data)
	self:enqueue("coins_at_risk", state, data)
	self:enqueue("bank_continue", state, data)
	self:flush()
end

function Onboarding:Destroy()
	seenTips[self.player] = nil
	hasEverFloored[self.player] = nil
end

return Onboarding
