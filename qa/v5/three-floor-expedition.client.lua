-- Studio-only three-floor normal-locomotion runner. No teleports or gameplay overrides.
task.spawn(function()
for floorIndex = 1, 3 do
workspace:SetAttribute("V5QADecision", floorIndex < 3 and "Continue" or (workspace:GetAttribute("V5QAFinalDecision") or "Bank"))
-- Execute in the Studio Client DataModel. Walks real navigation paths and
-- holds real prompts. The enemy, hazards, timers and economy remain active.
local player = game.Players.LocalPlayer
local evidence = Instance.new("Folder", workspace)
evidence.Name = "V5FullExpedition"
do
    local trace, startedAt = {}, os.clock()
    local controls = require(player.PlayerScripts.PlayerModule):GetControls()
    local camera = workspace.CurrentCamera
    local usedMedkit = false
    local role = workspace:GetAttribute("V5QATeamRole")
    local desiredDirection = Vector3.zero
    local runService = game:GetService("RunService")
    runService:BindToRenderStep("V5QATraversal", Enum.RenderPriority.Input.Value + 1, function()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:Move(desiredDirection, false) end
    end)
    local heartbeatMovement = runService.Heartbeat:Connect(function()
        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        if humanoid then humanoid:Move(desiredDirection, false) end
    end)
    local function hud() return player.PlayerGui.LastStopHUD.SafeArea end
    local function record(event)
        local h = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        table.insert(trace, {t = math.round((os.clock() - startedAt) * 10) / 10, event = event, health = h and h.Health or 0, state = hud().Mission.Brand.Text})
        evidence:SetAttribute("Trace", game.HttpService:JSONEncode(trace))
    end
    local function newPath()
        return game.PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true, WaypointSpacing = 3,
            Costs = require(game.ReplicatedStorage.Shared.Config.GameConfig).NavigationCosts})
    end
    local function walk(destination)
        local root, humanoid = player.Character.HumanoidRootPart, player.Character.Humanoid
        game.ReplicatedStorage.Remotes.RequestSprint:FireServer(true)
        local path = newPath()
        path:ComputeAsync(root.Position, destination)
        assert(path.Status == Enum.PathStatus.Success, "No navigation path")
        local points = path:GetWaypoints()
        for index = 2, #points do
            local point = points[index]
            if point.Action == Enum.PathWaypointAction.Jump then humanoid:ChangeState(Enum.HumanoidStateType.Jumping) end
            local deadline = os.clock() + 5
            local jumpAt = os.clock() + 1.5
            repeat
                task.wait(.05)
                local direction = Vector3.new(point.Position.X - root.Position.X, 0, point.Position.Z - root.Position.Z)
                desiredDirection = direction.Magnitude > .25 and direction.Unit * math.min(1, direction.Magnitude / 2) or Vector3.zero
                if os.clock() >= jumpAt then
                    humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                    jumpAt = os.clock() + 1.5
                end
                if humanoid.Health < 65 and not usedMedkit then
                    usedMedkit = true
                    game.ReplicatedStorage.Remotes.RequestMedkit:FireServer()
                end
            until humanoid.Health <= 0 or (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(point.Position.X, 0, point.Position.Z)).Magnitude < .85 or os.clock() > deadline
            desiredDirection = Vector3.zero
            assert(humanoid.Health > 0, "Died while walking")
            assert(os.clock() <= deadline, "Movement stuck at " .. tostring(root.Position))
        end
        path:Destroy()
        game.ReplicatedStorage.Remotes.RequestSprint:FireServer(false)
    end
    local function interact(target)
        local params = RaycastParams.new()
        local ignored = {player.Character, target}
        for _, teammate in game.Players:GetPlayers() do
            if teammate.Character then table.insert(ignored, teammate.Character) end
        end
        for _, child in target.Parent:GetChildren() do
            if child:GetAttribute("V4Stalker") then table.insert(ignored, child) end
        end
        params.FilterType, params.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, ignored
        params.RespectCanCollide = true
        local overlap = OverlapParams.new()
        overlap.FilterType, overlap.FilterDescendantsInstances = Enum.RaycastFilterType.Exclude, ignored
        local destination, shortestPath = nil, math.huge
        for _, offset in {Vector3.new(8, 0, 0), Vector3.new(-8, 0, 0), Vector3.new(0, 0, 8), Vector3.new(0, 0, -8),
            Vector3.new(6, 0, 0), Vector3.new(-6, 0, 0), Vector3.new(0, 0, 6), Vector3.new(0, 0, -6),
            Vector3.new(4, 0, 0), Vector3.new(-4, 0, 0), Vector3.new(0, 0, 4), Vector3.new(0, 0, -4)} do
            local candidate = target.Position + offset
            local hit = workspace:Raycast(candidate + Vector3.new(0, 4, 0), Vector3.new(0, -14, 0), params)
            if hit then
                local stand = hit.Position + Vector3.new(0, 3, 0)
                local head = stand + Vector3.new(0, 1.5, 0)
                local clear = math.abs(stand.Y - target.Position.Y) < 3
                for _, part in workspace:GetPartBoundsInBox(CFrame.new(stand + Vector3.new(0, .5, 0)), Vector3.new(3.2, 5, 3.2), overlap) do
                    if part.CanCollide then clear = false end
                end
                if clear and not workspace:Raycast(head, target.Position - head, params) then
                    local path = newPath()
                    path:ComputeAsync(player.Character.HumanoidRootPart.Position, stand)
                    if path.Status == Enum.PathStatus.Success then
                        local length, previous = 0, player.Character.HumanoidRootPart.Position
                        for _, waypoint in path:GetWaypoints() do
                            length += (waypoint.Position - previous).Magnitude
                            previous = waypoint.Position
                        end
                        if length < shortestPath then destination, shortestPath = stand, length end
                    end
                    path:Destroy()
                end
            end
        end
        assert(destination, "No visible standing area for " .. target.Name)
        record("walking to " .. target.Name)
        walk(destination)
        local root = player.Character.HumanoidRootPart
        assert((root.Position - target.Position).Magnitude < 10, "Outside prompt range")
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 1.5, 0), target.Position)
        task.wait(.3)
        local prompt = target.ProximityPrompt
        if not prompt.Enabled and (target.Name == "ControlA" or target.Name == "ControlB") then
            record("teammate completed " .. target.Name)
            return
        end
        assert(prompt.Enabled, "Out-of-order prompt " .. target.Name)
        player.Character.Humanoid:MoveTo(root.Position)
        task.wait(.4)
        record("hold " .. target.Name)
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + .4)
        prompt:InputHoldEnd()
        task.wait(.3)
        record("after " .. target.Name .. " / " .. hud().Mission.Objective.Text)
        if target.Name ~= "ControlA" and target.Name ~= "ControlB" and prompt.Enabled then
            local head = player.Character.Head.Position
            local hit = workspace:Raycast(head, target.Position - head, params)
            record("rejected at " .. tostring(root.Position) .. " / ray " .. (hit and hit.Instance:GetFullName() or "clear"))
            prompt:InputHoldBegin()
            task.wait(prompt.HoldDuration + .5)
            prompt:InputHoldEnd()
            task.wait(.4)
            assert(not prompt.Enabled, "Prompt did not advance " .. target.Name)
        end
    end
    local ok, err = xpcall(function()
        record("waiting for floor")
        if hud().Play.Visible then game.ReplicatedStorage.Remotes.RequestQueue:FireServer() end
        local room
        repeat
            task.wait(.2)
            room = hud().Mission.Brand.Text:find("FLOOR") and workspace.LastStopWorld.Runtime.ActiveExpedition:FindFirstChildOfClass("Model")
        until room or os.clock() - startedAt > 55
        assert(room, "Floor did not start")
        assert(room:WaitForChild("Delivery", 10), "Objective replication timed out")
        task.wait(.3)
        controls:Disable()
        record("entered " .. room.Name)
        local keys = {"Fuse", "Power", "ControlA", "ControlB", "Sample", "Delivery"}
        if room.Name == "FloodedLaboratory" then
            keys = room.PumpA.ProximityPrompt.Enabled and {"PumpA", "PumpB", "ControlA", "ControlB", "Sample", "Delivery"}
                or {"PumpB", "PumpA", "ControlA", "ControlB", "Sample", "Delivery"}
        end
        if role == "Secondary" then
            if room.Sample.ProximityPrompt.Enabled or room.Delivery.ProximityPrompt.Enabled then
                keys = {}
            else
                keys = {"ControlB"}
                local deadline = os.clock() + 100
                repeat task.wait(.2) until room.ControlB.ProximityPrompt.Enabled or os.clock() > deadline
                assert(room.ControlB.ProximityPrompt.Enabled, "Cooperative control did not unlock")
            end
        end
        for _, key in keys do
            if room[key].ProximityPrompt.Enabled then interact(room[key]) end
            if role and (key == "ControlA" or key == "ControlB") then
                local deadline, refreshAt = os.clock() + 35, os.clock() + 4
                while room[key].ProximityPrompt.Enabled and os.clock() < deadline do
                    task.wait(.1)
                    assert(player.Character.Humanoid.Health > 0, "Eliminated during teamwork")
                    if os.clock() > refreshAt then interact(room[key]); refreshAt = os.clock() + 4 end
                end
                assert(not room[key].ProximityPrompt.Enabled, "Teammate did not synchronize")
            end
        end
        if role == "Secondary" then
            walk(room.Markers.EntranceSpawn.Position)
            local deadline = os.clock() + 110
            repeat task.wait(.2) until hud().Mission.Brand.Text:find("ESCAPE") or os.clock() > deadline
        end
        assert(hud().Mission.Brand.Text:find("ESCAPE"), "Extraction did not open")
        walk(room.Markers.ElevatorReturnZone.Position)
        local deadline = os.clock() + 8
        repeat task.wait(.1) until hud().Decision.Visible or os.clock() > deadline
        assert(hud().Decision.Visible, "Decision did not open")
        local decision = workspace:GetAttribute("V5QADecision") or "Bank"
        record("extracted / " .. decision .. " requested")
        game.ReplicatedStorage.Remotes.RequestDecision:FireServer(decision)
        task.wait(3)
        if decision == "Continue" then
            assert(not hud().Play.Visible, "Continuer returned to lobby")
            record("CONTINUE accepted / " .. hud().Wallet.AtRisk.Text)
            return
        end
        record("BANK returned / " .. hud().Wallet.Secured.Text)
        assert(hud().Play.Visible, "Requeue unavailable")
        if workspace:GetAttribute("V5QAAutoQueue") ~= false then
            game.ReplicatedStorage.Remotes.RequestQueue:FireServer()
            record("queued another expedition")
        end
    end, debug.traceback)
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
    heartbeatMovement:Disconnect()
    runService:UnbindFromRenderStep("V5QATraversal")
    controls:Enable()
    game.ReplicatedStorage.Remotes.RequestSprint:FireServer(false)
    evidence:SetAttribute("Pass", ok)
    evidence:SetAttribute("Error", not ok and err or "")
    record(ok and "PASS" or "FAIL " .. tostring(err))
end
if evidence:GetAttribute("Pass") ~= true then break end
evidence.Name = "V5ChainedFloor" .. floorIndex
end
end)
return "Three-floor normal-locomotion chain started"
