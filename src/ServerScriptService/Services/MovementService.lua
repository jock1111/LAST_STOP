local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PhysicsService = game:GetService("PhysicsService")
local Movement = {}

function Movement.Start(remote, allowed)
    local requests, stamina, exhausted, lastRequest = {}, {}, {}, {}
    if not PhysicsService:IsCollisionGroupRegistered("LastStopPlayers") then PhysicsService:RegisterCollisionGroup("LastStopPlayers") end
    local function characterAdded(character)
        local function assign(part)
            if part:IsA("BasePart") then part.CollisionGroup = "LastStopPlayers" end
        end
        for _, part in character:GetDescendants() do assign(part) end
        character.DescendantAdded:Connect(assign)
    end
    local function playerAdded(player)
        player.CharacterAdded:Connect(characterAdded)
        if player.Character then characterAdded(player.Character) end
    end
    Players.PlayerAdded:Connect(playerAdded)
    for _, player in Players:GetPlayers() do playerAdded(player) end
    remote.OnServerEvent:Connect(function(player, sprinting, ...)
        if select("#", ...) ~= 0 or type(sprinting) ~= "boolean" then return end
        if sprinting and os.clock() - (lastRequest[player] or 0) < .06 then return end
        lastRequest[player] = os.clock()
        requests[player] = sprinting and allowed(player)
    end)
    local accumulator = 0
    RunService.Heartbeat:Connect(function(dt)
        accumulator += dt
        if accumulator < .1 then return end
        local step = math.min(accumulator, .3)
        accumulator = 0
        for _, player in Players:GetPlayers() do
            local character = player.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local active = allowed(player)
            local energy = stamina[player] or 100
            local velocity = root and root.AssemblyLinearVelocity or Vector3.zero
            local moving = Vector3.new(velocity.X, 0, velocity.Z).Magnitude > 1.5
            local sprint = active and requests[player] and moving and not exhausted[player] and not player:GetAttribute("Carrying")
            energy = math.clamp(energy + (sprint and -24 or 16) * step, 0, 100)
            if energy <= 0 then exhausted[player] = true end
            if energy >= 30 then exhausted[player] = false end
            stamina[player] = energy
            player:SetAttribute("Stamina", math.floor(energy))
            player:SetAttribute("Sprinting", sprint == true)
            if humanoid and humanoid.Health > 0 then
                humanoid.WalkSpeed = player:GetAttribute("Carrying") and 12 or sprint and 23 or 16
            end
            if sprint then player:SetAttribute("NoiseUntil", workspace:GetServerTimeNow() + 1) end
            if not active then requests[player] = nil end
        end
    end)
    Players.PlayerRemoving:Connect(function(player)
        requests[player], stamina[player], exhausted[player], lastRequest[player] = nil, nil, nil, nil
    end)
end
return Movement
