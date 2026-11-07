-- Server-owned expedition state machine. The client receives snapshots for UI
-- only; it never supplies damage, coins, objective progress, or escape status.
local FloorConfig = require(game:GetService("ReplicatedStorage").Shared.Config.FloorConfig)

local ExpeditionService = {}
ExpeditionService.__index = ExpeditionService

-- Fixed reward for the optional hidden stash in each floor (server-owned).
local HIDDEN_LOOT_COINS = 35

local function inBox(position, cframe, size)
	local localPosition = cframe:PointToObjectSpace(position)
	local half = size * 0.5
	return math.abs(localPosition.X) <= half.X
		and math.abs(localPosition.Y) <= half.Y
		and math.abs(localPosition.Z) <= half.Z
end

local function characterRoot(player)
	local character = player.Character
	return character and character:FindFirstChild("HumanoidRootPart")
end

local function characterHumanoid(player)
	local character = player.Character
	return character and character:FindFirstChildOfClass("Humanoid")
end

function ExpeditionService.new(config, floorService, enemyService, economyService, profileService, inventoryService, remotes, onFinished)
	return setmetatable({
		_config = config,
		_floorService = floorService,
		_enemyService = enemyService,
		_economyService = economyService,
		_profileService = profileService,
		_inventoryService = inventoryService,
		_remotes = remotes,
		_onFinished = onFinished,
		state = "Idle",
		_token = 0,
		active = {},
		allPlayers = {},
		unbanked = {},
		pendingXP = {},
		votes = {},
		recentFloorIds = {},
		connections = {},
		_banked = {},
		depth = 0,
		floor = nil,
		floorDefinition = nil,
	}, ExpeditionService)
end

function ExpeditionService:IsRunning()
	return self.state ~= "Idle" and self.state ~= "Ended"
end

function ExpeditionService:_activePlayers()
	local result = {}
	for player in pairs(self.active) do
		if player.Parent then
			table.insert(result, player)
		end
	end
	return result
end

function ExpeditionService:_activeCount()
	return #self:_activePlayers()
end

function ExpeditionService:_send(player, patch)
	if not player.Parent then
		return
	end
	local payload = {
		state = self.state,
		depth = self.depth,
		floorName = self.floorDefinition and self.floorDefinition.Name or "Lobby",
		objective = self.floor and self.floor.objective or (self.floorDefinition and self.floorDefinition.Prompt or "Queue for an expedition."),
		progress = self.floor and select(1, self.floor:ObjectiveProgress()) or 0,
		target = self.floorDefinition and self.floorDefinition.Target or 0,
		unbanked = self.unbanked[player] or 0,
		banked = self._economyService:GetBankedCoins(player),
		coinsEarned = self.unbanked[player] or 0,
		xpEarned = self.pendingXP[player] or 0,
		activePlayers = self:_activeCount(),
		seed = self.seed,
	}
	for key, value in pairs(patch or {}) do
		payload[key] = value
	end
	if self.state == "Floor" and self.floor then
		payload.objectiveStage = self.floor:CurrentObjectiveStage()
		local objPos = self.floor:CurrentObjectivePosition()
		if objPos then
			payload.objectivePositionX = objPos.X
			payload.objectivePositionY = objPos.Y
			payload.objectivePositionZ = objPos.Z
		end
	end
	player:SetAttribute("LastStopSnapshot", game:GetService("HttpService"):JSONEncode(payload))
	self._remotes.StateChanged:FireClient(player, payload)
end

function ExpeditionService:_broadcast(patch)
	for _, player in ipairs(self:_activePlayers()) do
		self:_send(player, patch)
	end
end

function ExpeditionService:SyncState(player)
	if not self.active[player] then return false end
	self:_send(player, {decisionDeadline = self.decisionDeadline})
	return true
end

function ExpeditionService:_toast(player, text)
	if player.Parent then
		self._remotes.Toast:FireClient(player, text)
	end
end

function ExpeditionService:_setState(nextState, patch)
	self.state = nextState
	self:_broadcast(patch)
end

function ExpeditionService:_movePlayer(player, cframe)
	task.spawn(function()
		if not player.Parent then
			return
		end
		local character = player.Character
		if not character then
			player:LoadCharacter()
			character = player.CharacterAdded:Wait()
		end
		local root = character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5)
		if root then
			character:PivotTo(cframe)
		local root = character:FindFirstChild("HumanoidRootPart")
		if root then
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
		end
		end
	end)
end

function ExpeditionService:_returnToLobby(player)
	local lobby = self._floorService.lobby
	if lobby then
		task.spawn(function()
			if not player.Parent then return end
			local previousCharacter = player.Character
			-- A player can leave between the parent check and LoadCharacter(),
			-- especially when a Studio play session stops. Do not let that race
			-- turn an otherwise-clean expedition teardown into an Output error.
			local loaded = pcall(function()
				if player.Parent then
					player:LoadCharacter()
				end
			end)
			if not loaded or not player.Parent then
				return
			end

			local character = player.Character
			for _ = 1, 120 do
				if not player.Parent then
					return
				end
				if character and character ~= previousCharacter then
					break
				end
				task.wait()
				character = player.Character
			end
			if not character or character == previousCharacter then return end
			local root = character and (character:FindFirstChild("HumanoidRootPart") or character:WaitForChild("HumanoidRootPart", 5))
			if root then
				character:PivotTo(lobby.LobbySpawn)
			end
		end)
	end
end

function ExpeditionService:_watchPlayer(player)
	local function watchCharacter(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid", 5)
		if humanoid then
			table.insert(self.connections, humanoid.Died:Connect(function()
				self:OnPlayerDied(player, "You were overwhelmed.")
			end))
		end
	end
	if player.Character then
		watchCharacter(player.Character)
	end
	table.insert(self.connections, player.CharacterAdded:Connect(watchCharacter))
end

function ExpeditionService:Start(players)
	assert(not self:IsRunning(), "An expedition is already running")
	self._token += 1
	local token = self._token
	self.state = "Boarding"
	self.depth = 0
	self.seed = (os.time() + math.random(1, 1000000)) % 2147483647
	self.active = {}
	self.allPlayers = {}
	self.unbanked = {}
	self.pendingXP = {}
		self.votes = {}
		self._banked = {}
		self.recentFloorIds = {}
	self.floor = nil
	self.floorDefinition = nil
	for _, player in ipairs(players) do
		self.active[player] = true
		self.allPlayers[player] = true
		self.unbanked[player] = 0
		self.pendingXP[player] = 0
		self._inventoryService:BeginRun(player)
		self:_watchPlayer(player)
		self:_movePlayer(player, self._floorService.lobby.BoardCFrame)
	end
	self._floorService:SetLobbyElevator(true, "BOARD NOW")
	self:_broadcast({ message = "Board the elevator. Departure is imminent." })
	print("[LAST STOP] Expedition seed", self.seed, "players", #players)
	task.spawn(function()
		if not self:_wait(self._config.BoardingSeconds, token) then
			return
		end
		self._floorService:SetLobbyElevator(false, "DESCENDING")
		self:_beginNextFloor(token)
	end)
end

function ExpeditionService:_wait(seconds, token, predicate)
	local finishAt = os.clock() + seconds
	while os.clock() < finishAt do
		if self._token ~= token or not self:IsRunning() then
			return false
		end
		if predicate and predicate() then
			return true
		end
		task.wait(0.2)
	end
	return self._token == token and self:IsRunning()
end

function ExpeditionService:_chooseFloor()
	local candidates = {}
	for _, definition in ipairs(FloorConfig.Floors) do
		local recent = false
		for _, recentId in ipairs(self.recentFloorIds) do
			if recentId == definition.Id then
				recent = true
				break
			end
		end
		if not recent then
			table.insert(candidates, definition)
		end
	end
	if #candidates == 0 then
		candidates = FloorConfig.Floors
	end
	local totalWeight = 0
	for _, definition in ipairs(candidates) do
		totalWeight += definition.Weight
	end
	local random = Random.new(self.seed + self.depth * 104729)
	local roll = random:NextNumber(0, totalWeight)
	for _, definition in ipairs(candidates) do
		roll -= definition.Weight
		if roll <= 0 then
			return definition
		end
	end
	return candidates[#candidates]
end

function ExpeditionService:_beginNextFloor(token)
	if self._token ~= token or self:_activeCount() == 0 then
		self:_end("No eligible players remain.")
		return
	end
	self:_setState("Travel", { message = "Descending..." })
	if not self:_wait(self._config.TravelSeconds, token) then
		return
	end
	self.depth += 1
	self.floorDefinition = self:_chooseFloor()
	table.insert(self.recentFloorIds, self.floorDefinition.Id)
	if #self.recentFloorIds > self._config.RecentFloorWindow then
		table.remove(self.recentFloorIds, 1)
	end
	self.floor = self._floorService:CreateRoom(self.floorDefinition, self.seed + self.depth)
	self.floor:Initialize({
        getActivePlayers = function() return self:_activePlayers() end,
        damagePlayer = function(player, amount, source) self:DamagePlayer(player, amount, source) end,
        notify = function(player, message) self:_toast(player, message) end,
        changed = function(message) self:_broadcast({message = message}) end,
		interactionDistance = self._config.InteractionDistance,
		isPlayerActive = function(player)
			return self.state == "Floor" and self.active[player] == true
		end,
		onObjectiveStep = function(player, key)
			self:_onObjectiveStep(player, key)
		end,
		onHiddenLoot = function(player)
			self:_onHiddenLoot(player)
		end,
	})
	self.floor:Start()
	local startedFloor = self.floor
	self.floorStartedAt = os.clock()
	for index, player in ipairs(self:_activePlayers()) do
		self:_movePlayer(player, self.floor.spawnCFrame * CFrame.new((((index - 1) % 4) - 1.5) * 3, 0, (math.floor((index - 1) / 4) - 1) * 3))
	end
	self:_setState("Floor", { message = self.floorDefinition.Prompt })
	task.delay(5, function()
		if self._token == token and self.state == "Floor" and self.floor == startedFloor then
			self._enemyService:SpawnStalker(self.floor.model, self.floor.patrolPoints, {
				getActivePlayers = function() return self:_activePlayers() end,
				canTargetPlayer = function(player) return not self:_isStalkerProtected(player) end,
				damagePlayer = function(player, amount, source) self:DamagePlayer(player, amount, source) end,
			})
			self:_broadcast({ message = "Something is moving in the dark." })
		end
	end)
	task.delay(self._config.FloorTimeLimitSeconds, function()
		if self._token == token and self.state == "Floor" and self.floor == startedFloor then
			self:_failCurrentFloor("The floor sealed before the objective was completed.")
		end
	end)
end

function ExpeditionService:_onObjectiveStep(player, key)
	if self.state ~= "Floor" or not self.floor then
		return
	end
	local progress, target = self.floor:ObjectiveProgress()
	self:_broadcast({ message = player.DisplayName .. " advanced the objective (" .. progress .. "/" .. target .. ")." })
	if progress >= target then
		task.spawn(function()
			self:_completeCurrentFloor()
		end)
	end
end

function ExpeditionService:_onHiddenLoot(player)
	if self.state ~= "Floor" or not self.floor or self.unbanked[player] == nil then
		return
	end
	-- Fixed server-side reward; the client only reports the touch, never the amount.
	local reward = HIDDEN_LOOT_COINS
	self.unbanked[player] += reward
	self:_toast(player, "Hidden stash found: +" .. reward .. " unbanked coins.")
	self:_broadcast({ message = player.DisplayName .. " found a hidden stash." })
end

function ExpeditionService:_completeCurrentFloor()
	if self.state ~= "Floor" or not self.floor then
		return
	end
	local progress = select(1, self.floor:ObjectiveProgress())
	if progress < self.floorDefinition.Target then
		return
	end
	self.floor:Complete()
	self._enemyService:Clear()
	local coins, xp = self._economyService:CalculateFloorReward(self.depth, progress)
	for _, player in ipairs(self:_activePlayers()) do
		self.unbanked[player] += coins
		self.pendingXP[player] += xp
	end
	self:_enterEscape(self._token, coins)
end

function ExpeditionService:_isInEscapeRegion(player)
	if not self.floor then
		return false
	end
	local root = characterRoot(player)
	local humanoid = characterHumanoid(player)
	return root ~= nil and humanoid ~= nil and humanoid.Health > 0
		and inBox(root.Position, self.floor.escapeCFrame, self.floor.escapeSize)
end

function ExpeditionService:_enterEscape(token, coins)
	if self._token ~= token or self.state ~= "Floor" then
		return
	end
	self:_setState("Escape", { message = "Objective complete. Return to the elevator: +" .. coins .. " at risk." })
	local allSafe = self:_wait(self._config.EscapeSeconds, token, function()
		for _, player in ipairs(self:_activePlayers()) do
			if not self:_isInEscapeRegion(player) then
				return false
			end
		end
		return self:_activeCount() > 0
	end)
	if self._token ~= token or self.state ~= "Escape" then
		return
	end
	for _, player in ipairs(self:_activePlayers()) do
		if not self:_isInEscapeRegion(player) then
			self:_eliminate(player, "You missed the elevator and lost your at-risk haul.")
		end
	end
	if self:_activeCount() == 0 then
		self:_end("No one made the elevator.")
		return
	end
	self:_enterDecision(token)
end

function ExpeditionService:_enterDecision(token)
	if self._token ~= token or self:_activeCount() == 0 then
		return
	end
	self.votes = {}
	self.decisionDeadline = os.time() + self._config.DecisionSeconds
	self:_setState("Decision", {
		message = "BANK to secure your haul, or CONTINUE and keep it at risk.",
		decisionDeadline = self.decisionDeadline,
	})
	self:_wait(self._config.DecisionSeconds, token, function()
		for _, player in ipairs(self:_activePlayers()) do
			if not self.votes[player] then
				return false
			end
		end
		return true
	end)
	if self._token ~= token or self.state ~= "Decision" then
		return
	end
	local continuers = {}
	for _, player in ipairs(self:_activePlayers()) do
		if self.votes[player] == "Continue" then
			table.insert(continuers, player)
		else
			self:_bankAndReturn(player)
		end
	end
	if #continuers == 0 then
		self:_end("All surviving players banked their rewards.")
		return
	end
	if self.floor then
		-- The elevator in the old room is about to be removed. Transfer survivors
		-- to the persistent cabin before travel so gravity cannot kill continuers.
		for index, player in ipairs(continuers) do
			self:_movePlayer(player, self._floorService.lobby.BoardCFrame * CFrame.new((index - 1) * 2, 0, 0))
		end
		self.floor:Cleanup()
		self.floor = nil
	end
	self:_beginNextFloor(token)
end

function ExpeditionService:RequestDecision(player, decision)
	if self.state ~= "Decision" or not self.active[player] then
		return false, "There is no active bank decision."
	end
	if decision ~= "Bank" and decision ~= "Continue" then
		return false, "Invalid decision."
	end
	self.votes[player] = decision
	self:_toast(player, decision == "Bank" and "You will bank at this stop." or "You will continue with your haul at risk.")
	return true
end

function ExpeditionService:RequestMedkit(player)
	return self._inventoryService:UseMedkit(player, function(candidate)
		return candidate == player and self.active[player] == true and (self.state == "Floor" or self.state == "Escape")
	end)
end

function ExpeditionService:_bankAndReturn(player)
	if not self.active[player] then
		return
	end
	if self._banked[player] then
		return
	end
	self._banked[player] = true
	local atRisk = self.unbanked[player] or 0
	local xpThisRun = self.pendingXP[player] or 0
	local secured = self._economyService:Bank(player, atRisk, xpThisRun, self.depth)
	self.active[player] = nil
	self.unbanked[player] = 0
	self.pendingXP[player] = 0
	self._inventoryService:EndRun(player)
	self:_send(player, { state = "Results", result = "BANKED", secured = secured,
		earned = atRisk, xpEarned = xpThisRun,
		message = "Secured " .. secured .. " coins." })
	self:_returnToLobby(player)
	self._floorService:SetLobbyElevator(true, "LAST STOP")
end

function ExpeditionService:_eliminate(player, reason)
	if not self.active[player] then
		return
	end
	local lost = self.unbanked[player] or 0
	local xpThisRun = self.pendingXP[player] or 0
	self.active[player] = nil
	self.unbanked[player] = 0
	self.pendingXP[player] = 0
	self._inventoryService:EndRun(player)
	self:_send(player, { state = "Results", result = "LOST", lost = lost,
		xpEarned = xpThisRun, message = reason })
	self:_returnToLobby(player)
	self._floorService:SetLobbyElevator(true, "LAST STOP")
end

function ExpeditionService:_isStalkerProtected(player)
	local root = characterRoot(player)
	if not self.floor or not root then return true end
	return os.clock() - self.floorStartedAt < self._config.StalkerArrivalGraceSeconds
		or (root.Position - self.floor.spawnCFrame.Position).Magnitude < self._config.StalkerArrivalSafeRadius
end

function ExpeditionService:DamagePlayer(player, amount, source)
	if not self.active[player] or (self.state ~= "Floor" and self.state ~= "Escape") then
		return
	end
	if type(amount) ~= "number" or amount <= 0 or amount > 30 then
		return
	end
	if source == "Stalker" and self:_isStalkerProtected(player) then return end
	local humanoid = characterHumanoid(player)
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(amount)
		self:_toast(player, source .. " hit you for " .. amount .. ".")
	end
end

function ExpeditionService:OnPlayerDied(player, reason)
	if not self.active[player] then
		return
	end
	self:_eliminate(player, reason)
	if self:_activeCount() == 0 then
		self:_end("The expedition has no survivors.")
	end
end

function ExpeditionService:OnPlayerRemoving(player)
	if self.active[player] then
		self:_eliminate(player, "You disconnected and lost unbanked rewards.")
		if self:_activeCount() == 0 then
			self:_end("The expedition has no survivors.")
		end
	end
end

function ExpeditionService:_failCurrentFloor(reason)
	if self.floor then
		self.floor:Fail()
	end
	for _, player in ipairs(self:_activePlayers()) do
		self:_eliminate(player, reason)
	end
	self:_end(reason)
end

function ExpeditionService:_end(reason)
	if self.state == "Ended" or self.state == "Idle" then
		return
	end
	self._token += 1
	self._enemyService:Clear()
	if self.floor then
		self.floor:Cleanup()
		self.floor = nil
	end
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)
	self.state = "Ended"
	for player in pairs(self.allPlayers) do
		if player.Parent and self.active[player] then
			self:_eliminate(player, reason)
		end
	end
	self.active = {}
	if self._onFinished then
		self._onFinished(reason)
	end
end

function ExpeditionService:Destroy()
	self:_end("Server shutdown")
end

return ExpeditionService
