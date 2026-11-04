-- Explicit Studio QA. Uses the authored rooms and live navigation/physics.
-- Run asynchronously from MCP or the server Command Bar. No profile writes.
return function()
    assert(game:GetService("RunService"):IsStudio(), "Studio QA only")
    local services = script.Parent.Parent.Services
    local floors = require(services.FloorService).new({WorldName = "LastStopV5RecoveryQA", FloorOrigin = Vector3.new(3200, 0, 700)})
    local definitions = require(game.ReplicatedStorage.Shared.Config.FloorConfig).Floors
    local navigation = game:GetService("PathfindingService")
    local report = {routes = {}, extractionRoutes = {}, patrol = {}}
    local enemies = require(services.EnemyService).new()
    local room
    local ok, err = xpcall(function()
        floors:BuildWorld()
        for _, definition in definitions do
            room = floors:CreateRoom(definition, 42)
            room:Initialize({getActivePlayers = function() return {} end, isPlayerActive = function() return false end})
            room:Start()
            task.wait(1)
            local socket = room.model.Markers.ElevatorSocket.Position
            local doorway = room.model.ReturnElevator.Threshold.Position
            assert((doorway - socket).Unit:Dot((room.spawnCFrame.Position - socket).Unit) > .5,
                definition.Id .. " elevator faces away from the playable room")
            local excluded = {room.model.Markers}
            for _, entry in room.targets do table.insert(excluded, entry.part) end
            local train = room.model:FindFirstChild("Train")
            if train then
                table.insert(excluded, train)
                for _, part in train:GetDescendants() do
                    if part:IsA("BasePart") then assert(not part.CanCollide, "Train collision can fling players") end
                end
            end
            local params = RaycastParams.new()
            params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, excluded
            params.RespectCanCollide = true
            for key, entry in room.targets do
                local reachable
                for _, offset in {Vector3.new(0, 0, 4), Vector3.new(4, 0, 0), Vector3.new(-4, 0, 0), Vector3.new(0, 0, -4)} do
                    local candidate = entry.part.Position + offset
                    local hit = workspace:Raycast(candidate + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), params)
                    if hit and hit.Instance.CanCollide and math.abs(hit.Position.Y - entry.part.Position.Y) < 7 then
                        local stand = hit.Position + Vector3.new(0, 3, 0)
                        local path = navigation:CreatePath({AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = true})
                        path:ComputeAsync(room.spawnCFrame.Position, stand)
                        local points = path:GetWaypoints()
                        local endpoint = points[#points]
                        if path.Status == Enum.PathStatus.Success and endpoint and (endpoint.Position - stand).Magnitude < 4 then
                            reachable = {floor = definition.Id, key = key, ground = hit.Instance.Name, endpointDistance = (endpoint.Position - stand).Magnitude, waypoints = #points}
                        end
                        path:Destroy()
                        if reachable then break end
                    end
                    task.wait()
                end
                assert(reachable, definition.Id .. " has no grounded route to " .. key)
                table.insert(report.routes, reachable)
            end
            local extraction = navigation:CreatePath({AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = true})
            extraction:ComputeAsync(room.spawnCFrame.Position, room.escapeCFrame.Position)
            local points = extraction:GetWaypoints()
            local endpoint = points[#points]
            assert(extraction.Status == Enum.PathStatus.Success and endpoint, definition.Id .. " extraction route blocked")
            local delta = endpoint.Position - room.escapeCFrame.Position
            assert(Vector3.new(delta.X, 0, delta.Z).Magnitude < 3, "Navigation projected outside the elevator")
            table.insert(report.extractionRoutes, {floor = definition.Id, waypoints = #points})
            extraction:Destroy()
            room:Cleanup()
            room = nil
        end
        room = floors:CreateRoom(definitions[1], 44)
        room:Initialize({getActivePlayers = function() return {} end, isPlayerActive = function() return false end})
        room:Start()
        local stalker = enemies:SpawnStalker(room.model, room.patrolPoints, {getActivePlayers = function() return {} end})
        stalker.random = Random.new(3)
        enemies:Start()
        local start = stalker.root.Position
        local maximumDistance, listeningSamples = 0, 0
        for index = 1, 120 do
            task.wait(.5)
            maximumDistance = math.max(maximumDistance, (stalker.root.Position - start).Magnitude)
            if stalker.state == "Lurk" then
                listeningSamples += 1
                assert(stalker.stuckTime == 0 and stalker.waypoints == nil, "Listening triggered movement/stuck recovery")
            end
            table.insert(report.patrol, {t = index * .5, state = stalker.state, position = tostring(stalker.root.Position), stuck = stalker.stuckTime})
        end
        assert(maximumDistance > 20, "Patrol failed to move through the room")
        assert(listeningSamples > 0, "Listening regression was not exercised")
        report.maximumPatrolDistance, report.listeningSamples = maximumDistance, listeningSamples
    end, debug.traceback)
    enemies:Destroy()
    if room then room:Cleanup() end
    local world = workspace:FindFirstChild("LastStopV5RecoveryQA")
    if world then world:Destroy() end
    report.pass, report.error = ok, not ok and err or nil
    print("[LAST STOP V5] Gameplay recovery QA", ok and "PASS" or err)
    return report
end
