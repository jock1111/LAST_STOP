-- Explicit Studio fixture for the real room hazard loop, without profile writes.
return function()
    assert(game:GetService("RunService"):IsStudio(), "Studio QA only")
    local services = script.Parent.Parent.Services
    local floors = require(services.FloorService).new({WorldName = "LastStopTrainQA", FloorOrigin = Vector3.new(4200, 0, 700)})
    floors:BuildWorld()
    local definition
    for _, item in require(game.ReplicatedStorage.Shared.Config.FloorConfig).Floors do
        if item.Template == "AbandonedSubway" then definition = item end
    end
    local room = floors:CreateRoom(assert(definition), 42)
    local character = Instance.new("Model", workspace)
    character.Name = "TrainExposureFixture"
    local root = Instance.new("Part", character)
    root.Name, root.Anchored, root.CanCollide = "HumanoidRootPart", true, false
    local candidate = {Character = character}
    local hits, mode = {}, "Track"
    room:Initialize({
        isPlayerActive = function() return true end,
        getActivePlayers = function()
            local z = room.model and room.model:GetAttribute("TrainZ") or 0
            local offset = mode == "Platform" and Vector3.new(22, 3, z) or mode == "Above" and Vector3.new(0, 12, z) or Vector3.new(0, 3, z)
            root.CFrame = CFrame.new(floors._floorOrigin + offset)
            return {candidate}
        end,
        damagePlayer = function(_, amount, source)
            assert(amount == 25 and source == "Passing train", "Unexpected train damage")
            table.insert(hits, {amount = amount, time = os.clock(), phase = room.model:GetAttribute("HazardPhase")})
        end,
    })
    local ok, err = xpcall(function()
        room:Start()
        room.startedAt = os.clock() - 8
        task.wait(3.5)
        assert(#hits == 0, "Train damaged during warning")
        task.wait(5)
        assert(#hits == 1, "A pass must damage each player exactly once")
        mode = "Platform"
        room.startedAt = os.clock() - 28
        task.wait(4.5)
        assert(#hits == 1, "Platform was damaged")
        mode = "Above"
        room.startedAt = os.clock() - 44
        task.wait(4.5)
        assert(#hits == 1, "Player above train was damaged")
        for _, part in room.model.Train:GetDescendants() do
            if part:IsA("BasePart") then assert(not part.CanCollide, "Collidable train") end
        end
    end, debug.traceback)
    room:Cleanup()
    character:Destroy()
    workspace.LastStopTrainQA:Destroy()
    return {pass = ok, error = not ok and err or nil, hits = hits}
end
