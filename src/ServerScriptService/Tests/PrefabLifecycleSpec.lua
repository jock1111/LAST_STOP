-- Studio integration test: real Instances, two clean room cycles and a world
-- rebuild. Sources and sibling authored art must survive every cycle.
return function()
	local storage=game:GetService("ServerStorage")
	local FloorService=require(script.Parent.Parent.Services.FloorService)
	local definition=require(game.ReplicatedStorage.Shared.Config.FloorConfig).Floors[1]
	local assets=storage:WaitForChild("LastStopAssets")
	local before={}
	for _, template in ipairs({assets.Lobby,assets.Elevator,assets.Floors.Hospital,assets.Stalker}) do before[template]=#template:GetDescendants() end
	local world=Instance.new("Folder")
	world.Name="LastStopPrefabLifecycleTest";world.Parent=workspace
	local sentinel=Instance.new("Folder")
	sentinel.Name="AuthoredSiblingMustSurvive";sentinel.Parent=world
	local floors=FloorService.new({WorldName=world.Name,FloorOrigin=Vector3.new(1500,0,700)})
	local ok,err=xpcall(function()
		for run=1,2 do
			local lobby=floors:BuildWorld()
			assert(lobby.Model~=assets.Lobby and lobby.Model:GetAttribute("SourceTemplate"),"Lobby must be a tagged clone")
			assert(lobby.SpawnLocation:IsA("SpawnLocation"),"Engine spawn must target the concourse")
			assert(sentinel.Parent==world,"BuildWorld deleted authored sibling art")
			local room=floors:CreateRoom(definition,run)
			room:Initialize({interactionDistance=12,isPlayerActive=function() return false end,onObjectiveStep=function() error("No simulated players should interact") end})
			room:Start()
			assert(room.model~=assets.Floors.Hospital and room.model:GetAttribute("SourceTemplate"),"Hospital must clone the authored model")
			assert(room.model.Rooms:FindFirstChild("PatientWard") and room.model.Rooms:FindFirstChild("Archive"),"Hospital spaces missing")
			assert(#room.patrolPoints>=5 and room.escapeSize.X==18,"Hospital markers were not bound")
			local progress,total=room:ObjectiveProgress()
			assert(progress==0 and total==3,"A new round must reset objectives")
			local clone=room.model
			room:Cleanup()
			assert(clone.Parent==nil and next(room.targets)==nil,"Round cleanup must remove only the active clone")
			for template,count in pairs(before) do assert(template:IsDescendantOf(storage) and #template:GetDescendants()==count,"Source prefab mutated or deleted") end
		end
	end,debug.traceback)
	world:Destroy()
	assert(ok,err)
	print("[LAST STOP] Prefab lifecycle PASS: two rounds, objective reset, source preservation, authored sibling preservation")
end
