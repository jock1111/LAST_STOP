-- Authored models are immutable sources in ServerStorage. Only our Runtime
-- clones are disposable; never destroy LastStopWorld or its authored siblings.
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Pbr = require(script.Parent.PbrMaterialService)
local FloorService = {}
FloorService.__index = FloorService
local BUILD = "RECOVERY V3 / AUTHORED HOSPITAL"
local function need(parent, name, class)
	local child = parent:FindFirstChild(name)
	assert(child and child:IsA(class), ("[LAST STOP] Missing %s %s.%s; run node tools/build-prefabs.mjs then rojo build default.project.json."):format(class,parent:GetFullName(),name))
	return child
end
local function library() return need(ServerStorage,"LastStopAssets","Folder") end
local function clone(parent,name) return need(parent,name,"Model"):Clone() end
local function marker(model,name) return need(need(model,"Markers","Folder"),name,"BasePart") end
local function display(part,text)
	for _, v in ipairs(part:GetDescendants()) do if v:IsA("TextLabel") then v.Text=text end end
end
local function prepareDoors(model)
	local result={}
	for _, side in ipairs({"Left","Right"}) do
		local door=need(model,"Door"..side,"BasePart")
		for _, v in ipairs(door:GetDescendants()) do
			if v:IsA("BasePart") then
				v.Anchored,v.CanCollide,v.Massless=false,false,true
				local w=Instance.new("WeldConstraint")
				w.Part0,w.Part1,w.Parent=door,v,v
			end
		end
		result[side]=door
	end
	return result
end
function FloorService.new(options)
	options=options or {}
	return setmetatable({_worldName=options.WorldName or "LastStopWorld",_floorOrigin=options.FloorOrigin or Vector3.new(0,0,700),_doorTweens={},_doorGeneration=0},FloorService)
end
function FloorService:BuildWorld()
	local lobby,elevator=clone(library(),"Lobby"),clone(library(),"Elevator")
	local spawn,socket=marker(lobby,"EntranceSpawn"),marker(lobby,"ElevatorSocket")
	marker(lobby,"RoomBounds")
	elevator:PivotTo(socket.CFrame)
	elevator.Name,elevator.Parent="CentralElevator",lobby
	local board,zone=marker(elevator,"EntranceSpawn"),marker(elevator,"ElevatorReturnZone")
	local doors=prepareDoors(elevator)
	local prompt=Instance.new("ProximityPrompt")
	prompt.ActionText,prompt.ObjectText="Board expedition","Deep access terminal"
	prompt.MaxActivationDistance,prompt.RequiresLineOfSight,prompt.Parent=12,true,need(lobby,"QueueConsole","BasePart")
	local world=workspace:FindFirstChild(self._worldName)
	if not world then world=Instance.new("Folder");world.Name=self._worldName;world.Parent=workspace end
	local old=world:FindFirstChild("Runtime")
	if old then old:Destroy() end
	local runtime,active=Instance.new("Folder"),Instance.new("Folder")
	runtime.Name,runtime.Parent="Runtime",world
	active.Name,active.Parent,lobby.Parent="ActiveExpedition",runtime,runtime
	lobby:SetAttribute("BuildVersion",BUILD)
	lobby:SetAttribute("SourceTemplate","ServerStorage.LastStopAssets.Lobby")
	Pbr:Apply(lobby)
	self._world,self._runtime,self._activeFolder=world,runtime,active
	self.lobby={Model=lobby,QueuePrompt=prompt,LobbySpawn=spawn.CFrame,SpawnLocation=need(lobby,"LobbySpawnPoint","SpawnLocation"),BoardCFrame=board.CFrame,
		BoardRegionCFrame=zone.CFrame,BoardRegionSize=zone.Size,Doors=doors,
		DoorClosed={Left=doors.Left.CFrame,Right=doors.Right.CFrame},
		DoorOpen={Left=doors.Left.CFrame*CFrame.new(-9.8,0,0),Right=doors.Right.CFrame*CFrame.new(9.8,0,0)},
		Display=need(elevator,"FloorDisplay","BasePart")}
	workspace:SetAttribute("LastStopBuild",BUILD)
	self:SetLobbyElevator(true,"B0 / CONCOURSE")
	print("[LAST STOP] "..BUILD.." loaded prefab Lobby + Elevator")
	return self.lobby
end
function FloorService:SetLobbyElevator(open,text)
	if not self.lobby then return end
	self._doorGeneration+=1
	local generation=self._doorGeneration
	for _, t in ipairs(self._doorTweens) do t:Cancel() end
	table.clear(self._doorTweens)
	if not open then
		local params=OverlapParams.new()
		params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,{self.lobby.Model}
		local deadline=os.clock()+2
		while os.clock()<deadline do
			local blocked=false
			for _, p in ipairs(workspace:GetPartBoundsInBox(self.lobby.BoardRegionCFrame*CFrame.new(0,0,8.5),Vector3.new(19,12,2),params)) do
				if p.Parent and p.Parent:FindFirstChildOfClass("Humanoid") then blocked=true;break end
			end
			if not blocked then break end
			task.wait(.1)
			if generation~=self._doorGeneration then return end
		end
	end
	local positions=open and self.lobby.DoorOpen or self.lobby.DoorClosed
	for side,door in pairs(self.lobby.Doors) do
		door.CanCollide=false -- No crushing during a synchronized travel transition.
		local t=TweenService:Create(door,TweenInfo.new(.85,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{CFrame=positions[side]})
		table.insert(self._doorTweens,t);t:Play()
	end
	if text then display(self.lobby.Display,text) end
end
local Room={}
Room.__index=Room
function Room:Initialize(context) self.context=context end
function Room:Start()
	assert(self.context,"Initialize the floor before Start")
	assert(self.definition.Template=="Hospital","[LAST STOP] No prefab configured; recovery slice requires Template=Hospital")
	local model=clone(need(library(),"Floors","Folder"),"Hospital")
	model:PivotTo(CFrame.new(self._floorService._floorOrigin))
	local spawn,zone=marker(model,"EntranceSpawn"),marker(model,"ElevatorReturnZone")
	marker(model,"RoomBounds")
	local enemy=marker(model,"EnemySpawn")
	local sockets=need(model,"ObjectiveSockets","Folder")
	local targets={}
	for _, v in ipairs(sockets:GetDescendants()) do
		if v:IsA("BasePart") and v:FindFirstChild("ObjectiveCaption") then table.insert(targets,v) end
	end
	table.sort(targets,function(a,b) return a.Name<b.Name end)
	assert(#targets==self.definition.Target,"[LAST STOP] Hospital requires three record props in ObjectiveSockets")
	self.model,self.targets,self.connections=model,{},{}
	self.spawnCFrame,self.escapeCFrame,self.escapeSize=spawn.CFrame,zone.CFrame,zone.Size
	local elevator=clone(library(),"Elevator")
	elevator:PivotTo(marker(model,"ElevatorSocket").CFrame)
	elevator.Name,elevator.Parent="ReturnElevator",model
	for side,door in pairs(prepareDoors(elevator)) do door.CFrame*=CFrame.new(side=="Left" and -9.8 or 9.8,0,0) end
	display(need(elevator,"FloorDisplay","BasePart"),"01 / CLINICAL ARCHIVE")
	for index,target in ipairs(targets) do
		local key=self.definition.Id.."_"..index
		target:SetAttribute("ObjectiveKey",key);target:SetAttribute("Used",false)
		self.targets[key]=target
		local prompt=Instance.new("ProximityPrompt")
		prompt.ActionText,prompt.ObjectText="Recover record",target.ObjectiveCaption.Value
		prompt.HoldDuration,prompt.MaxActivationDistance,prompt.RequiresLineOfSight=.8,self.context.interactionDistance,true
		prompt.KeyboardKeyCode,prompt.GamepadKeyCode,prompt.Parent=Enum.KeyCode.E,Enum.KeyCode.ButtonX,target
		table.insert(self.connections,prompt.Triggered:Connect(function(player) self:_attemptInteraction(player,key) end))
	end
	local patrol=need(need(model,"Markers","Folder"),"PatrolPaths","Folder"):GetChildren()
	table.sort(patrol,function(a,b) return a.Name<b.Name end)
	self.patrolPoints={enemy.Position}
	for _, point in ipairs(patrol) do assert(point:IsA("BasePart"));table.insert(self.patrolPoints,point.Position) end
	model.Name,model.Parent="Hospital",self._floorService._activeFolder
	model:SetAttribute("SourceTemplate","ServerStorage.LastStopAssets.Floors.Hospital")
	Pbr:Apply(model)
	return self
end
function Room:_attemptInteraction(player,key)
	local target=self.targets[key]
	if not target or target:GetAttribute("Used") or not self.context.isPlayerActive(player) then return end
	local character=player.Character
	local root=character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position-target.Position).Magnitude>self.context.interactionDistance then return end
	local params=RaycastParams.new()
	params.FilterType,params.FilterDescendantsInstances=Enum.RaycastFilterType.Exclude,{character}
	local hit=workspace:Raycast(root.Position,target.Position-root.Position,params)
	if hit and hit.Instance~=target and not hit.Instance:IsDescendantOf(target.Parent) then return end
	target:SetAttribute("Used",true)
	local prompt=target:FindFirstChildOfClass("ProximityPrompt")
	if prompt then prompt.Enabled=false end
	target.Color=Color3.fromRGB(99,216,213)
	TweenService:Create(target,TweenInfo.new(.25),{Transparency=.85,CFrame=target.CFrame*CFrame.new(0,.8,0)}):Play()
	self.context.onObjectiveStep(player,key)
end
function Room:ObjectiveProgress()
	local used=0
	for _, target in pairs(self.targets) do if target:GetAttribute("Used") then used+=1 end end
	return used,self.definition.Target
end
function Room:Complete() self.completed=true;if self.model then self.model:SetAttribute("Complete",true) end end
function Room:Fail() if self.model then self.model:SetAttribute("Failed",true) end end
function Room:Cleanup()
	for _, c in ipairs(self.connections) do c:Disconnect() end
	table.clear(self.connections)
	if self.model then self.model:Destroy();self.model=nil end
	self.targets={}
end
function FloorService:CreateRoom(definition,seed)
	return setmetatable({_floorService=self,definition=definition,seed=seed,targets={},connections={}},Room)
end
return FloorService
