-- One vertical-slice enemy: a readable Stalker. The FSM is server-owned and
-- performs only non-lethal hits so a bad path never produces an instant kill.
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")

local EnemyService = {}
EnemyService.__index = EnemyService

local Stalker = {}
Stalker.__index = Stalker

local function createStalkerModel(position)
	local model = Instance.new("Model")
	model.Name = "Stalker"
	local root = Instance.new("Part")
	root.Name = "HumanoidRootPart"
	root.Size = Vector3.new(2, 3, 2)
	root.CFrame = CFrame.new(position)
	root.Anchored = true
	root.CanCollide = false
	root.Color = Color3.fromRGB(18, 18, 21)
	root.Material = Enum.Material.Slate
	root.Parent = model
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Shape = Enum.PartType.Ball
	head.Size = Vector3.new(1.6, 1.6, 1.6)
	head.CFrame = root.CFrame * CFrame.new(0, 2.1, 0)
	head.CanCollide = false
	head.Color = Color3.fromRGB(221, 68, 68)
	head.Material = Enum.Material.Neon
	head.Parent = model
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = root
	weld.Part1 = head
	weld.Parent = root
	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.WalkSpeed = 11
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.Parent = model
	model.PrimaryPart = root
	return model, humanoid, root
end

function Stalker.new(parent, patrolPoints, context)
	local model, humanoid, root = createStalkerModel(patrolPoints[1])
	model.Parent = parent
	return setmetatable({
		model = model,
		humanoid = humanoid,
		root = root,
		patrolPoints = patrolPoints,
		context = context,
		state = "Patrol",
		patrolIndex = 1,
		lastAttack = {},
		lastPathAt = 0,
		goal = patrolPoints[1],
		destroyed = false,
	}, Stalker)
end

function Stalker:_setState(nextState)
	if self.state ~= nextState then
		self.state = nextState
		self.model:SetAttribute("AIState", nextState)
	end
end

function Stalker:_canSee(root)
	local origin = self.root.Position + Vector3.new(0, 1.5, 0)
	local direction = root.Position - origin
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { self.model }
	local result = workspace:Raycast(origin, direction, params)
	return not result or result.Instance:IsDescendantOf(root.Parent)
end

function Stalker:_findTarget()
	local chosen, chosenDistance
	for _, player in ipairs(self.context.getActivePlayers()) do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health > 0 then
			local distance = (root.Position - self.root.Position).Magnitude
			if distance <= 60 and (not chosenDistance or distance < chosenDistance) and self:_canSee(root) then
				chosen = player
				chosenDistance = distance
			end
		end
	end
	return chosen, chosenDistance
end

function Stalker:_moveToward(position)
	if os.clock() - self.lastPathAt < 1 then
		return
	end
	self.lastPathAt = os.clock()
	local path = PathfindingService:CreatePath({ AgentRadius = 2, AgentHeight = 5, AgentCanJump = true })
	local success = pcall(function()
		path:ComputeAsync(self.root.Position, position)
	end)
	if success and path.Status == Enum.PathStatus.Success then
		local waypoints = path:GetWaypoints()
		local nextWaypoint = waypoints[math.min(2, #waypoints)]
		if nextWaypoint then
			self.goal = nextWaypoint.Position
			return
		end
	end
	self.goal = position
end

function Stalker:Step(deltaTime)
	if self.destroyed or not self.root.Parent then
		return
	end
	if self.goal then
		local offset = self.goal - self.root.Position
		local distanceToGoal = offset.Magnitude
		if distanceToGoal > 0.05 then
			local nextPosition = self.root.Position + offset.Unit * math.min(11 * (deltaTime or 0.05), distanceToGoal)
			local lookAt = Vector3.new(self.goal.X, nextPosition.Y, self.goal.Z)
			self.root.CFrame = CFrame.lookAt(nextPosition, lookAt)
		end
	end
	local target, distance = self:_findTarget()
	if target then
		self:_setState("Chase")
		local targetRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
		if targetRoot then
			self:_moveToward(targetRoot.Position)
		end
		if distance and distance <= 4 then
			local now = os.clock()
			if now - (self.lastAttack[target] or 0) >= 2 then
				self.lastAttack[target] = now
				self:_setState("Attack")
				self.context.damagePlayer(target, 15, "Stalker")
			end
		end
	else
		self:_setState("Patrol")
		local point = self.patrolPoints[self.patrolIndex]
		if (self.root.Position - point).Magnitude < 4 then
			self.patrolIndex = (self.patrolIndex % #self.patrolPoints) + 1
			point = self.patrolPoints[self.patrolIndex]
		end
		self:_moveToward(point)
	end
end

function Stalker:Destroy()
	self.destroyed = true
	if self.model then
		self.model:Destroy()
	end
end

function EnemyService.new()
	return setmetatable({ _enemies = {} }, EnemyService)
end

function EnemyService:SpawnStalker(parent, patrolPoints, context)
	local stalker = Stalker.new(parent, patrolPoints, context)
	table.insert(self._enemies, stalker)
	return stalker
end

function EnemyService:Start()
	self._connection = RunService.Heartbeat:Connect(function(deltaTime)
		for _, enemy in ipairs(self._enemies) do
			enemy:Step(deltaTime)
		end
	end)
end

function EnemyService:Clear()
	for _, enemy in ipairs(self._enemies) do
		enemy:Destroy()
	end
	table.clear(self._enemies)
end

function EnemyService:Destroy()
	self:Clear()
	if self._connection then
		self._connection:Disconnect()
	end
end

return EnemyService
