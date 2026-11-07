-- Server-local matchmaking for the vertical slice. It supports solo starts and
-- batches up to twelve queued players; cross-server queues belong in Milestone B.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MatchmakingService = {}
MatchmakingService.__index = MatchmakingService

function MatchmakingService.new(config, remotes, canQueue, onStart, onToast)
	return setmetatable({
		_config = config,
		_remotes = remotes,
		_canQueue = canQueue,
		_onStart = onStart,
		_onToast = onToast,
		_queue = {},
		_queued = {},
		_countdown = nil,
		_running = false,
		_stopped = false,
	}, MatchmakingService)
end

function MatchmakingService:IsQueued(player)
	return self._queued[player] == true
end

function MatchmakingService:RequestJoin(player)
	if self._running then
		return false, "An expedition is already running in this server. Please wait."
	end
	if not self._canQueue(player) then
		return false, "Your profile is still loading."
	end
	if self._queued[player] then
		return true, "Already queued."
	end
	self._queued[player] = true
	table.insert(self._queue, player)
	if not self._countdown then
		self._countdown = self._config.LobbyQueueCountdown
	end
	self:_broadcastCountdown()
	return true, "Queued for the next elevator."
end

function MatchmakingService:Remove(player)
	self._queued[player] = nil
	for index = #self._queue, 1, -1 do
		if self._queue[index] == player then
			table.remove(self._queue, index)
		end
	end
	if #self._queue == 0 then
		self._countdown = nil
	end
	self:_broadcastCountdown()
end

function MatchmakingService:_broadcastCountdown()
	local remaining = self._countdown or 0
	-- Only queued players see the countdown; it disappears for everyone else.
	for _, player in ipairs(self._queue) do
		if self._remotes and self._remotes.QueueCountdown then
			self._remotes.QueueCountdown:FireClient(player, remaining)
		end
	end
end

function MatchmakingService:_startQueuedGroup()
	if self._running or #self._queue == 0 then
		return
	end
	local group = {}
	while #group < self._config.MaxExpeditionPlayers and #self._queue > 0 do
		local player = table.remove(self._queue, 1)
		self._queued[player] = nil
		if player.Parent and self._canQueue(player) then
			table.insert(group, player)
		end
	end
	self._countdown = #self._queue > 0 and self._config.LobbyQueueCountdown or nil
	self:_broadcastCountdown()
	if #group > 0 then
		self._running = true
		self._onStart(group, function()
			self._running = false
		end)
	end
end

function MatchmakingService:Start()
	task.spawn(function()
		while not self._stopped do
			task.wait(1)
			if not self._running and self._countdown then
				self._countdown -= 1
				self:_broadcastCountdown()
				if self._countdown <= 0 then
					self:_startQueuedGroup()
				end
			end
		end
	end)
end

function MatchmakingService:Destroy()
	self._stopped = true
end

return MatchmakingService
