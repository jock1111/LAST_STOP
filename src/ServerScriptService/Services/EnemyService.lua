-- Original articulated Stalker prefab. Humanoid physics follows full paths;
-- the server owns targeting, windup, damage, gait and cleanup.
local PathfindingService=game:GetService("PathfindingService")
local RunService=game:GetService("RunService")
local ServerStorage=game:GetService("ServerStorage")
local Pbr=require(script.Parent.PbrMaterialService)
local EnemyService={}
EnemyService.__index=EnemyService
local Stalker={}
Stalker.__index=Stalker

function Stalker.new(parent,patrol,context)
	local template=ServerStorage:WaitForChild("LastStopAssets"):FindFirstChild("Stalker")
	assert(template and template:IsA("Model"),"[LAST STOP] Missing authored Stalker prefab; rebuild assets/prefabs")
	local model=template:Clone()
	model:PivotTo(CFrame.new(patrol[1]))
	model.Parent=parent
	local root=model:FindFirstChild("HumanoidRootPart")
	local humanoid=model:FindFirstChildOfClass("Humanoid")
	assert(root and humanoid,"[LAST STOP] Stalker rig requires HumanoidRootPart + Humanoid")
	pcall(function() root:SetNetworkOwner(nil) end)
	Pbr:Apply(model)
	local self=setmetatable({model=model,root=root,humanoid=humanoid,patrolPoints=patrol,context=context,
		state="Patrol",patrolIndex=2,connections={},motors={},lastPath=0,pathToken=0,attackAt=0,clock=0},Stalker)
	for _, v in ipairs(model:GetDescendants()) do
		if v:IsA("Motor6D") then self.motors[v]={base=v.C0,name=v.Name} end
	end
	table.insert(self.connections,humanoid.MoveToFinished:Connect(function(reached)
		if self.destroyed then return end
		if reached and self.waypoints then self.waypointIndex+=1;self:_nextWaypoint()
		else self.lastPath=0 end
	end))
	return self
end
function Stalker:_setState(state)
	self.state=state;self.model:SetAttribute("AIState",state)
end
function Stalker:_canSee(root)
	local params=RaycastParams.new()
	params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,{self.model}
	local origin=self.root.Position+Vector3.new(0,1.5,0)
	local hit=workspace:Raycast(origin,root.Position-origin,params)
	return not hit or hit.Instance:IsDescendantOf(root.Parent)
end
function Stalker:_target()
	local chosen,distance=nil,60
	for _, player in ipairs(self.context.getActivePlayers()) do
		local character=player.Character
		local root=character and character:FindFirstChild("HumanoidRootPart")
		local humanoid=character and character:FindFirstChildOfClass("Humanoid")
		if root and humanoid and humanoid.Health>0 then
			local d=(root.Position-self.root.Position).Magnitude
			if d<distance and self:_canSee(root) then chosen,distance=player,d end
		end
	end
	return chosen,distance
end
function Stalker:_nextWaypoint()
	local waypoint=self.waypoints and self.waypoints[self.waypointIndex]
	if not waypoint then return end
	if waypoint.Action==Enum.PathWaypointAction.Jump then self.humanoid.Jump=true end
	self.humanoid:MoveTo(waypoint.Position)
end
function Stalker:_pathTo(position)
	if self.computing or os.clock()-self.lastPath<1.2 then return end
	self.lastPath=os.clock();self.pathToken+=1
	local token=self.pathToken
	self.computing=true
	task.spawn(function()
		local path=PathfindingService:CreatePath({AgentRadius=1.6,AgentHeight=8,AgentCanJump=false,WaypointSpacing=5})
		local ok=pcall(function() path:ComputeAsync(self.root.Position,position) end)
		self.computing=false
		if self.destroyed or token~=self.pathToken then path:Destroy();return end
		if self.blockedConnection then self.blockedConnection:Disconnect();self.blockedConnection=nil end
		if self.path then self.path:Destroy();self.path=nil end
		if ok and path.Status==Enum.PathStatus.Success then
			self.path=path;self.waypoints=path:GetWaypoints();self.waypointIndex=2
			self.blockedConnection=path.Blocked:Connect(function(index)
				if index>=self.waypointIndex then self.lastPath=0 end
			end)
			self:_nextWaypoint()
		else
			path:Destroy()
			-- Physics/collision remains authoritative when no path exists.
			self.waypoints=nil;self.humanoid:MoveTo(self.root.Position)
		end
	end)
end
function Stalker:Step(dt)
	if self.destroyed or not self.root.Parent then return end
	self.clock+=dt
	local velocity=self.root.AssemblyLinearVelocity
	local moving=Vector3.new(velocity.X,0,velocity.Z).Magnitude>1
	local swing=moving and math.sin(self.clock*6)*.42 or math.sin(self.clock*1.5)*.025
	for motor,info in pairs(self.motors) do
		local angle=0
		if info.name=="Left Hip" or info.name=="Right Shoulder" then angle=swing end
		if info.name=="Right Hip" or info.name=="Left Shoulder" then angle=-swing end
		if self.state=="Attack" and info.name=="Right Shoulder" then angle=-1.3 end
		motor.C0=info.base*CFrame.Angles(angle,0,0)
	end
	self.think=(self.think or 0)+dt
	if self.think<.15 then return end
	self.think=0
	if self.state=="Attack" then return end
	local player,distance=self:_target()
	if player then
		local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if not root then return end
		if distance<5 and os.clock()-self.attackAt>2.8 then
			self.attackAt=os.clock();self:_setState("Attack")
			self.humanoid:MoveTo(self.root.Position)
			task.delay(.65,function()
				if self.destroyed then return end
				local target=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
				if target and (target.Position-self.root.Position).Magnitude<5.5 and self:_canSee(target) then self.context.damagePlayer(player,15,"Stalker") end
				self:_setState("Chase");self.lastPath=0
			end)
		else
			self:_setState("Chase");self.humanoid.WalkSpeed=12;self:_pathTo(root.Position)
		end
	else
		self:_setState("Patrol");self.humanoid.WalkSpeed=8
		local point=self.patrolPoints[self.patrolIndex] or self.patrolPoints[1]
		local offset=self.root.Position-point
		if Vector3.new(offset.X,0,offset.Z).Magnitude<4 then self.patrolIndex=self.patrolIndex%#self.patrolPoints+1;self.lastPath=0 end
		self:_pathTo(self.patrolPoints[self.patrolIndex])
	end
end
function Stalker:Destroy()
	self.destroyed=true;self.pathToken+=1
	for _, c in ipairs(self.connections) do c:Disconnect() end
	if self.blockedConnection then self.blockedConnection:Disconnect() end
	if self.path then self.path:Destroy() end
	self.model:Destroy()
end
function EnemyService.new() return setmetatable({_enemies={}},EnemyService) end
function EnemyService:SpawnStalker(parent,patrol,context)
	local enemy=Stalker.new(parent,patrol,context);table.insert(self._enemies,enemy);return enemy
end
function EnemyService:Start()
	self._connection=RunService.Heartbeat:Connect(function(dt) for _, enemy in ipairs(self._enemies) do enemy:Step(dt) end end)
end
function EnemyService:Clear() for _, enemy in ipairs(self._enemies) do enemy:Destroy() end;table.clear(self._enemies) end
function EnemyService:Destroy() self:Clear();if self._connection then self._connection:Disconnect() end end
return EnemyService
