-- A completed floor's delayed work must never affect a later CONTINUE floor.
return function()
    local Expedition = require(script.Parent.Parent.Services.ExpeditionService)
    local config = table.clone(require(game.ReplicatedStorage.Shared.Config.GameConfig))
    config.TravelSeconds, config.FloorTimeLimitSeconds = 0, .3
    local floors = {}
    function floors:CreateRoom()
        return {Initialize = function() end, Start = function() end,
            spawnCFrame = CFrame.new(), patrolPoints = {Vector3.zero}}
    end
    local expedition = Expedition.new(config, floors, {}, {}, {}, {}, {})
    expedition.active = {[{Parent = true}] = true}
    expedition._token, expedition.state, expedition.seed = 1, "Travel", 1
    expedition._broadcast, expedition._movePlayer = function() end, function() end
    expedition._chooseFloor = function() return {Id = "TimerFixture", Target = 1} end
    local failures = 0
    expedition._failCurrentFloor = function() failures += 1 end
    expedition:_beginNextFloor(1)
    task.wait(.1)
    expedition.floor = {} -- The first floor was cleaned up during CONTINUE.
    task.wait(.35)
    expedition._token += 1
    assert(failures == 0, "Previous floor timeout sealed a later floor")
    expedition:_beginNextFloor(2)
    task.wait(.4)
    expedition._token += 1 -- Cancel deferred Stalker callbacks owned by the fixture.
    assert(failures == 1, "Current floor timeout did not run")
end
