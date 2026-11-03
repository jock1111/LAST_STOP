-- Paste into a fresh Studio SERVER Command Bar. Uses the production factory.
assert(game:GetService("RunService"):IsStudio(), "Studio only")
local player = assert(game.Players:GetPlayers()[1], "A local player is required")
local character = assert(player.Character)
local root = character:WaitForChild("HumanoidRootPart")
local previousFrame, previousAnchored = character:GetPivot(), root.Anchored
local world = Instance.new("Model")
world.Name, world.Parent = "LastStopStalkerRecoveryTest", workspace
local platform = Instance.new("Part")
platform.Size, platform.CFrame = Vector3.new(80, 1, 80), CFrame.new(1800, -.5, 700)
platform.Anchored, platform.Parent = true, world
local service = require(game.ServerScriptService.Services.EnemyService).new()
local ok, failure = xpcall(function()
    local enemy = service:SpawnStalker(world, {Vector3.new(1800, 5, 700), Vector3.new(1800, 5, 680)}, {
        getActivePlayers = function() return {player} end,
        damagePlayer = function() error("Attack cooldown should prevent damage in this fixture") end,
    })
    enemy.root.Anchored, root.Anchored = true, true
    character:PivotTo(CFrame.new(1800, 3, 697))
    enemy.attackAt, enemy.lastPosition, enemy.stuckTime = math.huge, enemy.root.Position, 2.1
    enemy.humanoid.Jump = false
    enemy:Update(.21)
    assert(enemy.state == "Chase" and enemy.stuckTime == 0 and not enemy.humanoid.Jump,
        "Stationary contact during attack cooldown must not trigger recovery jumps")
    print("V4_CLOSE_RANGE_RECOVERY_PASS", enemy.stuckTime, enemy.humanoid.Jump)

    character:PivotTo(CFrame.new(1800, 3, 690))
    enemy.stuckTime, enemy.humanoid.Jump = 2.1, false
    enemy:Update(.21)
    assert(enemy.humanoid.Jump, "A genuinely stuck approach should retain obstacle recovery")
    print("V4_DISTANT_RECOVERY_PASS", enemy.humanoid.Jump)

    local frame, size = enemy.model.CreatureVisual:GetBoundingBox()
    local bottom = frame.Position.Y - size.Y / 2
    assert(math.abs(bottom) < .05, "Imported bind mesh must meet the floor plane")
    print("V4_BIND_GROUND_PASS", bottom)
end, debug.traceback)
service:Destroy()
world:Destroy()
character:PivotTo(previousFrame)
root.Anchored = previousAnchored
assert(ok, failure)
print("V4_STALKER_RECOVERY_REGRESSION_PASS")
