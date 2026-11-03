-- Paste into the Studio CLIENT Command Bar after starting a fresh Play session.
-- Exercises the normal remotes and ProximityPrompt input methods. Positions
-- and camera framing are scripted. Use a disposable Studio profile.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
task.spawn(function()
    local player = game.Players.LocalPlayer
    local remotes = game.ReplicatedStorage.Remotes
    local active = workspace.LastStopWorld.Runtime.ActiveExpedition
    local camera = workspace.CurrentCamera
    local function waitFor(predicate, label, timeout)
        local deadline = os.clock() + (timeout or 60)
        repeat
            local value = predicate()
            if value then return value end
            task.wait(.1)
        until os.clock() > deadline
        error("V4_NORMAL_ENTRY timed out " .. label)
    end
    local function frameFloor(floor)
        camera = workspace.CurrentCamera
        local lab = floor:GetAttribute("FloorTheme") == "Laboratory"
        local origin = floor:GetPivot()
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = origin * (lab and CFrame.lookAt(Vector3.new(18, 9, 40), Vector3.new(0, 5, -28))
            or CFrame.lookAt(Vector3.new(2, 6, 25), Vector3.new(0, 5, -20)))
    end
    local function input(floor, key)
        camera = workspace.CurrentCamera
        local target = assert(floor:FindFirstChild(key), key)
        local prompt = assert(target:FindFirstChildOfClass("ProximityPrompt"), key)
        assert(prompt.Enabled, "Disabled prompt " .. key)
        player.Character:PivotTo(CFrame.new(target.Position + Vector3.new(0, 0, 3)))
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.lookAt(target.Position + Vector3.new(0, 1.5, 5), target.Position)
        local root = player.Character.HumanoidRootPart
        root.AssemblyLinearVelocity = Vector3.zero
        task.wait(.35)
        prompt:InputHoldBegin()
        task.wait(prompt.HoldDuration + .4)
        prompt:InputHoldEnd()
        task.wait(.3)
        print("V4_NORMAL_INPUT", floor.Name, key, "carrying", player:GetAttribute("Carrying"))
    end
    local function diagnostics(floor)
        task.spawn(function()
            task.wait(7)
            local success, failure = 0, 0
            -- Instances retain mesh/audio content types. Empty optional map
            -- properties are reported by Roblox and do not name an asset.
            game:GetService("ContentProvider"):PreloadAsync({floor, game.MaterialService, game.SoundService}, function(id, status)
                if id == "" then return end
                if status == Enum.AssetFetchStatus.Success then success += 1 else failure += 1; warn("V4_ASSET_FAILED", id, status) end
            end)
            print("V4_ASSET_FETCH", floor.Name, success, failure)
            local monster = floor:FindFirstChild("Stalker")
            local count, posed = 0, 0
            if monster then
                for _, bone in monster:GetDescendants() do
                    if bone:IsA("Bone") then
                        count += 1
                        local x, y, z = bone.Transform:ToOrientation()
                        if math.abs(x) + math.abs(y) + math.abs(z) > .001 then posed += 1 end
                    end
                end
                local bone = monster:FindFirstChild("Clav_L", true)
                local before = bone.Transform
                task.wait(.6)
                local x, y, z = before:ToObjectSpace(bone.Transform):ToOrientation()
                print("V4_BONES", count, posed, "delta", x, y, z)
                local root = monster.HumanoidRootPart
                print("V4_MONSTER_AUDIO", root.StalkerBreath.IsLoaded, root.StalkerThreat.IsLoaded)
            end
        end)
        local times, elapsed = {}, 0
        local connection
        connection = game:GetService("RunService").RenderStepped:Connect(function(dt)
            elapsed += dt
            table.insert(times, dt)
            if elapsed >= 10 then
                connection:Disconnect()
                table.sort(times)
                print("V4_PERFORMANCE", floor.Name, #times / elapsed, times[math.ceil(#times * .95)] * 1000,
                    game:GetService("Stats"):GetTotalMemoryUsageMb(), camera.ViewportSize)
            end
        end)
    end
    camera.CameraType = Enum.CameraType.Custom
    camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
    remotes.RequestQueue:FireServer()
    local previous
    for round = 1, 2 do
        local floor = waitFor(function()
            local model = active:FindFirstChildOfClass("Model")
            return model and model ~= previous and model:FindFirstChild("Markers") and model
        end, "floor " .. round, 90)
        previous = floor
        task.wait(1)
        frameFloor(floor)
        diagnostics(floor)
        print("V4_READY_WIDE", floor.Name)
        task.wait(25)
        local monster = floor:FindFirstChild("Stalker")
        if monster then
            camera = workspace.CurrentCamera
            local origin = floor:GetPivot()
            local lab = floor:GetAttribute("FloorTheme") == "Laboratory"
            camera.CFrame = CFrame.lookAt(origin:PointToWorldSpace(Vector3.new(4, 6, lab and 49 or 38)), monster.HumanoidRootPart.Position)
            print("V4_READY_STALKER", floor.Name)
            task.wait(20)
        end
        frameFloor(floor)
        if floor:GetAttribute("FloorTheme") == "Laboratory" then
            local first = floor.PumpA:FindFirstChildOfClass("ProximityPrompt").Enabled and "PumpA" or "PumpB"
            input(floor, first)
            input(floor, first == "PumpA" and "PumpB" or "PumpA")
        else
            input(floor, "Fuse")
            input(floor, "Power")
        end
        input(floor, "ControlA")
        input(floor, "ControlB")
        input(floor, "Sample")
        assert(player:GetAttribute("Carrying"), "Normal input did not collect the case")
        camera = workspace.CurrentCamera
        camera.CameraType = Enum.CameraType.Custom
        camera.CameraSubject = player.Character:FindFirstChildOfClass("Humanoid")
        print("V4_READY_CARRY", floor.Name)
        task.wait(10)
        input(floor, "Delivery")
        waitFor(function() return floor:GetAttribute("Complete") end, "completed floor", 5)
        local marker = floor.Markers.ElevatorReturnZone
        player.Character:PivotTo(marker.CFrame)
        player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.zero
        local gui = player.PlayerGui.LastStopHUD.SafeArea
        waitFor(function() return gui.Decision.Visible end, "bank decision", 10)
        print("V4_READY_DECISION", round)
        task.wait(15)
        remotes.RequestDecision:FireServer(round == 1 and "Continue" or "Bank")
    end
    print("V4_NORMAL_ENTRY_PASS", "Two full floors through prompt input, extraction, CONTINUE, BANK")
end)
