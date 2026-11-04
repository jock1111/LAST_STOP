local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local PhysicsService = game:GetService("PhysicsService")
local SubwayCycle = require(game:GetService("ReplicatedStorage").Shared.Util.SubwayCycle)
local EnemyService = {}
EnemyService.__index = EnemyService
local Stalker = {}
Stalker.__index = Stalker

function Stalker.new(parent, patrol, context)
    local assets = ServerStorage.LastStopAssets
    local model = assets.Stalker:Clone()
    local root = model.HumanoidRootPart
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    for _, item in model:GetDescendants() do
        if item:IsA("BasePart") then item.Transparency, item.CastShadow = 1, false end
        if item:IsA("Light") or item:IsA("BillboardGui") then item:Destroy() end
    end
    local skin = assets.StalkerSkin:Clone()
    skin.Name = "CreatureVisual"
    local visualFrame, visualSize = skin:GetBoundingBox()
    local desiredCenter = root.CFrame * CFrame.new(0, visualSize.Y / 2 - 5, 0)
    skin:PivotTo(desiredCenter * visualFrame:Inverse() * skin:GetPivot())
    skin.Parent = model
    for _, part in skin:GetDescendants() do
        if part:IsA("BasePart") then
            part.Anchored, part.CanCollide, part.CanTouch, part.Massless = false, false, false, true
            local weld = Instance.new("WeldConstraint")
            weld.Part0, weld.Part1, weld.Parent = root, part, part
        end
    end
    model:PivotTo(CFrame.new(patrol[1]))
    model:SetAttribute("V4Stalker", true)
    model:SetAttribute("AIState", "Patrol")
    model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
    model.Parent = parent
    humanoid.WalkSpeed, humanoid.DisplayDistanceType = 7, Enum.HumanoidDisplayDistanceType.None
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") then part.CollisionGroup = "LastStopEnemy" end
    end
    root:SetNetworkOwner(nil)
    local self = setmetatable({model = model, root = root, humanoid = humanoid, context = context,
        patrolPoints = patrol, patrolIndex = 2, lastPath = 0, generation = 0, attackAt = -10,
        state = "Patrol", think = 0, memoryUntil = 0, lastPosition = root.Position, stuckTime = 0,
        random = Random.new(), alertUntil = 0, lurkUntil = 0}, Stalker)
    self.moveConnection = humanoid.MoveToFinished:Connect(function(reached)
        if self.destroyed then return end
        if reached and self.waypoints then self.waypointIndex += 1; self:_nextWaypoint()
        else self.lastPath = 0 end
    end)
    return self
end

function Stalker:_setState(state)
    if self.state == state then return end
    self.state = state
    self.model:SetAttribute("AIState", state)
    self.model:SetAttribute("StateChangedAt", workspace:GetServerTimeNow())
end

function Stalker:_canSee(root)
    local params = RaycastParams.new()
    params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, {self.model}
    local origin = self.root.Position + Vector3.new(0, 1, 0)
    local hit = workspace:Raycast(origin, root.Position - origin, params)
    return not hit or hit.Instance:IsDescendantOf(root.Parent)
end

function Stalker:_pickPatrolIndex()
    -- Random next point that is never the one just reached, so routes vary per run.
    return SubwayCycle.PickPatrolIndex(self.random, #self.patrolPoints, self.patrolIndex)
end

function Stalker:_nextWaypoint()
    local point = self.waypoints and self.waypoints[self.waypointIndex]
    if not point then return end
    if point.Action == Enum.PathWaypointAction.Jump then self.humanoid.Jump = true end
    self.humanoid:MoveTo(point.Position)
end

function Stalker:_pathTo(position)
    if self.computing or os.clock() - self.lastPath < 1 then return end
    self.lastPath = os.clock()
    self.generation += 1
    local generation = self.generation
    self.computing = true
    task.spawn(function()
        local path = PathfindingService:CreatePath({AgentRadius = 1.6, AgentHeight = 8, AgentCanJump = true, WaypointSpacing = 5})
        local ok = pcall(function() path:ComputeAsync(self.root.Position, position) end)
        self.computing = false
        if self.destroyed or generation ~= self.generation then path:Destroy(); return end
        if self.blockedConnection then self.blockedConnection:Disconnect() end
        if self.path then self.path:Destroy() end
        self.path = path
        if ok and path.Status == Enum.PathStatus.Success then
            self.waypoints, self.waypointIndex = path:GetWaypoints(), 2
            self.blockedConnection = path.Blocked:Connect(function(index)
                if index >= self.waypointIndex then self.lastPath = 0 end
            end)
            self:_nextWaypoint()
        else
            self.waypoints = nil
            self.humanoid:MoveTo(self.root.Position)
        end
    end)
end

function Stalker:_attack(player)
    self.attackAt = os.clock()
    self:_setState("Windup")
    self.humanoid:MoveTo(self.root.Position)
    self.humanoid.WalkSpeed = 0
    task.delay(.85, function()
        if self.destroyed then return end
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if root and (root.Position - self.root.Position).Magnitude < 5.3 and self:_canSee(root) then
            self.context.damagePlayer(player, 20, "Stalker")
        end
        self:_setState("Recovery")
        task.delay(.65, function()
            if not self.destroyed then self:_setState("Search"); self.lastPath = 0 end
        end)
    end)
end

function Stalker:Update(dt)
    if self.destroyed or not self.root.Parent then return end
    self.think += dt
    if self.think < .2 then return end
    local elapsed = self.think
    self.think = 0
    if self.state == "Windup" or self.state == "Recovery" then return end
    local player, target, distance = nil, nil, 66
    local noisePosition
    for _, candidate in self.context.getActivePlayers() do
        local character = candidate.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local health = character and character:FindFirstChildOfClass("Humanoid")
        if root and health and health.Health > 0 then
            local range = (root.Position - self.root.Position).Magnitude
            local direction = root.Position - self.root.Position
            local inCone = range < 15 or direction.Unit:Dot(self.root.CFrame.LookVector) > -.25
            if range < distance and inCone and self:_canSee(root) then
                player, target, distance = candidate, root, range
            elseif range < 38 and (candidate:GetAttribute("NoiseUntil") or 0) > workspace:GetServerTimeNow() then
                noisePosition = root.Position
            end
        end
    end
    if target then
        self.lastSeen, self.memoryUntil = target.Position, os.clock() + 7
        if distance < 5.2 and os.clock() - self.attackAt > 2.8 then self:_attack(player); return end
        -- Fair counterplay: a sighting first shows a short, visible Alert (the stalker
        -- stops and turns) before it commits to the chase.
        if self.state ~= "Chase" then
            if self.state ~= "Alert" then
                self:_setState("Alert")
                self.alertUntil = os.clock() + .7
                self.waypoints = nil
                self.humanoid:MoveTo(self.root.Position)
            end
            if os.clock() < self.alertUntil then return end
        end
        self:_setState("Chase")
        self.humanoid.WalkSpeed = 13
        self.waypoints = nil
        self.humanoid:MoveTo(target.Position)
    elseif self.lastSeen and os.clock() < self.memoryUntil then
        self:_setState("Search")
        self.humanoid.WalkSpeed = 10
        self:_pathTo(self.lastSeen)
    elseif noisePosition then
        self:_setState("Investigate")
        self.humanoid.WalkSpeed = 9
        self.lastSeen, self.memoryUntil = noisePosition, os.clock() + 4
        self:_pathTo(noisePosition)
    else
        local point = self.patrolPoints[self.patrolIndex] or self.patrolPoints[1]
        if (self.root.Position - point).Magnitude < 6 then
            self.patrolIndex = self:_pickPatrolIndex()
            self.lastPath = 0
            -- Sometimes the stalker stops and listens for a few seconds before moving on.
            if self.random:NextNumber() < .35 then self.lurkUntil = os.clock() + self.random:NextNumber(2, 4) end
        end
        if os.clock() < self.lurkUntil then
            self:_setState("Lurk")
            self.humanoid.WalkSpeed = 0
            self.humanoid:MoveTo(self.root.Position)
        else
            self:_setState("Patrol")
            self.humanoid.WalkSpeed = 7
            self:_pathTo(self.patrolPoints[self.patrolIndex])
        end
    end
    if (not target or distance > 5.3) and (self.root.Position - self.lastPosition).Magnitude < .15 then
        self.stuckTime += elapsed
    else
        self.stuckTime = 0
    end
    self.lastPosition = self.root.Position
    if self.stuckTime > 2 then
        self.humanoid.Jump = true
        self.lastPath, self.stuckTime = 0, 0
        self.patrolIndex = self.patrolIndex % #self.patrolPoints + 1
    end
end

function Stalker:Destroy()
    self.destroyed, self.generation = true, self.generation + 1
    self.moveConnection:Disconnect()
    if self.blockedConnection then self.blockedConnection:Disconnect() end
    if self.path then self.path:Destroy() end
    self.model:Destroy()
end
function EnemyService.new()
    for _, name in {"LastStopPlayers", "LastStopEnemy"} do
        if not PhysicsService:IsCollisionGroupRegistered(name) then PhysicsService:RegisterCollisionGroup(name) end
    end
    PhysicsService:CollisionGroupSetCollidable("LastStopPlayers", "LastStopEnemy", false)
    return setmetatable({_enemies = {}}, EnemyService)
end
function EnemyService:SpawnStalker(parent, patrol, context)
    local enemy = Stalker.new(parent, patrol, context)
    table.insert(self._enemies, enemy)
    return enemy
end
function EnemyService:Start()
    self._connection = RunService.Heartbeat:Connect(function(dt)
        for _, enemy in self._enemies do enemy:Update(dt) end
    end)
end
function EnemyService:Clear()
    for _, enemy in self._enemies do enemy:Destroy() end
    table.clear(self._enemies)
end
function EnemyService:Destroy()
    self:Clear()
    if self._connection then self._connection:Disconnect() end
end
return EnemyService
