-- Authored models are immutable sources in ServerStorage. Only our Runtime
-- clones are disposable; never destroy LastStopWorld or its authored siblings.
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Pbr = require(script.Parent.PbrMaterialService)
local FloorService = {}
FloorService.__index = FloorService
local BUILD = "V4 / CONTAINMENT"
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
	require(script.Parent.EnvironmentService).UpgradeLobby(lobby)
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
local ObjectiveRoom = require(script.Parent.ObjectiveRoom)
function FloorService:CreateRoom(definition, seed)
    return ObjectiveRoom.new(self, definition, seed)
end
return FloorService
