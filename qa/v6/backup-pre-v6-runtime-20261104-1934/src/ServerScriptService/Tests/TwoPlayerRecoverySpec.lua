-- Explicit opt-in integration test. Run from a two-player Studio server.
-- Uses isolated geometry and in-memory profiles. Restart Play after completion.
return function()
    assert(game:GetService("RunService"):IsStudio(), "Studio test only")
    local players = game:GetService("Players"):GetPlayers()
    assert(#players == 2, "Start exactly two local clients")
    table.sort(players, function(a, b) return a.UserId < b.UserId end)
    local services = script.Parent.Parent.Services
    local config = table.clone(require(game.ReplicatedStorage.Shared.Config.GameConfig))
    config.BoardingSeconds, config.TravelSeconds, config.EscapeSeconds, config.DecisionSeconds = 1, 1, 10, 12
    local memory = {data = {}}
    for _, player in players do
        memory.data[player] = {Coins = 0, XP = 0, Level = 1, Stats = {Runs = 0, Escapes = 0, BestDepth = 0, FirstEscapeClaimed = true}}
    end
    function memory:Get(player) return self.data[player] end
    function memory:Mutate(player, callback) callback(self.data[player]); return true end
    function memory:Save() return true end
    local floors = require(services.FloorService).new({WorldName = "LastStopV4TwoPlayerTest", FloorOrigin = Vector3.new(2200, 0, 700)})
    floors:BuildWorld()
    local enemies = require(services.EnemyService).new()
    enemies:Start()
    local inventory = require(services.InventoryService).new()
    local economy = require(services.EconomyService).new(memory, config)
    local firstReward = economy:CalculateFloorReward(1, 5)
    local remotes = {}
    for _, remote in game.ReplicatedStorage.Remotes:GetChildren() do remotes[remote.Name] = remote end
    local expedition = require(services.ExpeditionService).new(config, floors, enemies, economy, memory, inventory, remotes, function(reason)
        print("[V4 TWO PLAYER] Finished", reason)
    end)
    local function waitFor(predicate, message, timeout)
        local deadline = os.clock() + (timeout or 20)
        repeat
            if predicate() then return end
            task.wait(.1)
        until os.clock() > deadline
        error("[V4 TWO PLAYER] Timed out " .. message .. " / " .. expedition.state)
    end
    local function interact(room, player, key)
        local entry = assert(room.targets[key], key)
        player.Character:PivotTo(CFrame.new(entry.part.Position + Vector3.new(0, 0, 3)))
        task.wait(.15)
        assert(room:_attemptInteraction(player, key), "Interaction rejected " .. key)
    end
    local function recoverRound(active)
        waitFor(function() return expedition.state == "Floor" end, "floor start")
        local room = expedition.floor
        print("[V4 TWO PLAYER] Testing", room.definition.Id, "active", #active)
        waitFor(function() return #enemies._enemies == 1 end, "monster spawn", 10)
        local stalker = enemies._enemies[1]
        local initial = stalker.root.Position
        waitFor(function() return (stalker.root.Position - initial).Magnitude > 2 end, "physical monster movement", 10)
        local victim = active[1]
        waitFor(function() return os.clock() - expedition.floorStartedAt >= config.StalkerArrivalGraceSeconds end, "arrival grace", 25)
        local humanoid = victim.Character:FindFirstChildOfClass("Humanoid")
        humanoid.Health = 100
        victim.Character:PivotTo(stalker.root.CFrame * CFrame.new(0, 0, -3))
        waitFor(function() return humanoid.Health < 100 end, "telegraphed monster hit", 8)
        assert(humanoid.Health <= 80, "Expected 20 damage")
        humanoid.Health = 100
        -- Keep the live enemy away while validating every objective and economy transition.
        stalker.root.Anchored = true
        stalker.root.CFrame = CFrame.new(floors._floorOrigin + Vector3.new(0, 8, -100))
        local originalStart = room.startedAt
        local subway = room.definition.Template == "AbandonedSubway"
        -- Subway: the train is Active from cycle 12 of 16 and stays in the track lane.
        room.startedAt = os.clock() - ((subway and 13 or 15) - room.seed % 7)
        local exposure = room.definition.Template == "Hospital" and Vector3.new(0, 3, -12)
            or subway and Vector3.new(0, .5, -32) or Vector3.new(20, .5, 20)
        victim.Character:PivotTo(CFrame.new(floors._floorOrigin + exposure))
        waitFor(function() return humanoid.Health < 100 end, "environmental hazard damage", 3)
        assert(humanoid.Health == (subway and 75 or 92), "Hazard must deal a bounded 25 (train) or 8 damage")
        humanoid.Health = 100
        room.startedAt = originalStart
        for key, entry in room.targets do
            local path = game:GetService("PathfindingService"):CreatePath({AgentRadius = 1.6, AgentHeight = 5, AgentCanJump = true})
            path:ComputeAsync(room.spawnCFrame.Position, entry.part.Position + Vector3.new(0, 0, 3))
            assert(path.Status == Enum.PathStatus.Success, "Objective route blocked " .. key)
            path:Destroy()
        end
        local player = active[1]
        assert(not room:_attemptInteraction(player, "Delivery"), "Accepted out-of-order delivery")
        local first, second
        for key, entry in room.targets do
            if entry.stage == 1 then first = key end
            if entry.stage == 2 then second = key end
        end
        interact(room, player, first)
        assert(not room:_attemptInteraction(player, first), "Duplicate milestone accepted")
        interact(room, player, second)
        interact(room, player, "ControlA")
        local teammate = active[2] or player
        interact(room, teammate, "ControlB")
        assert(room.progress == 3, "Paired controls failed")
        interact(room, player, "Sample")
        assert(player:GetAttribute("Carrying"), "Missing carried case")
        local activeCheck = room.context.isPlayerActive
        room.context.isPlayerActive = function(candidate) return candidate ~= player and activeCheck(candidate) end
        waitFor(function() return room.stage == 4 end, "lost-carrier recovery", 2)
        assert(room.progress == 3 and not player:GetAttribute("Carrying"), "Lost case did not reset safely")
        room.context.isPlayerActive = activeCheck
        interact(room, player, "Sample")
        interact(room, player, "Delivery")
        waitFor(function() return expedition.state == "Escape" end, "objective completion")
        assert(room.progress == 5 and not player:GetAttribute("Carrying"), "Case cleanup/progress failed")
        for index, member in active do member.Character:PivotTo(room.escapeCFrame * CFrame.new((index - 1) * 3, 0, 0)) end
        waitFor(function() return expedition.state == "Decision" end, "extraction")
        return room.model, room.definition.Id
    end
    local ok, err = xpcall(function()
        expedition:Start(players)
        local first, firstId = recoverRound(players)
        assert(expedition:RequestDecision(players[1], "Bank"))
        assert(expedition:RequestDecision(players[2], "Continue"))
        waitFor(function() return expedition.depth == 2 and expedition.state == "Floor" end, "second floor")
        assert(first.Parent == nil, "Old floor survived cleanup")
        assert(expedition.floorDefinition.Id ~= firstId, "Repeated consecutive floor")
        assert(economy:GetBankedCoins(players[1]) == firstReward and economy:GetBankedCoins(players[2]) == 0, "Independent banking failed")
        assert(expedition.unbanked[players[2]] == firstReward, "At-risk coins changed")
        assert(not expedition:RequestDecision(players[1], "Bank"), "Banker re-entered decision")
        recoverRound({players[2]})
        assert(expedition:RequestDecision(players[2], "Bank"))
        waitFor(function() return not expedition:IsRunning() end, "final bank")
        assert(economy:GetBankedCoins(players[2]) > firstReward and economy:GetBankedCoins(players[1]) == firstReward, "Second reward isolation failed")
        print("[LAST STOP V4] TWO PLAYER PASS / both floors, reachable objectives, physics, damage, teamwork, solo fallback, case delivery, independent BANK/CONTINUE")
    end, debug.traceback)
    enemies:Destroy()
    if expedition:IsRunning() then expedition:_end("QA cleanup") end
    local world = workspace:FindFirstChild("LastStopV4TwoPlayerTest")
    if world then world:Destroy() end
    assert(ok, err)
end
