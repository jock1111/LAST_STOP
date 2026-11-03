local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local Environment = require(script.Parent.EnvironmentService)
local Room = {}
Room.__index = Room

function Room.new(floorService, definition, seed)
    return setmetatable({_floorService = floorService, definition = definition, seed = seed,
        connections = {}, targets = {}, progress = 0, stage = 1, destroyed = false}, Room)
end

function Room:Initialize(context) self.context = context end

function Room:_notify(player, text)
    if self.context.notify then self.context.notify(player, text) end
end

function Room:_setObjective(text)
    self.objective = text
    self.model:SetAttribute("Objective", text)
    if self.context.changed then self.context.changed(text) end
end

function Room:_target(name, position, action, caption, stage, hold)
    local cframe = self.model:GetPivot() * CFrame.new(position)
    local target = Environment.Part(self.model, name, Vector3.new(1.2, 1.2, .5), cframe,
        Color3.fromRGB(244, 174, 76), Enum.Material.Neon)
    target.CanCollide = false
    target:SetAttribute("ObjectiveKey", name)
    local light = Instance.new("PointLight")
    light.Color, light.Range, light.Brightness, light.Parent = target.Color, 9, .7, target
    local prompt = Instance.new("ProximityPrompt")
    prompt.ActionText, prompt.ObjectText = action, caption
    prompt.HoldDuration, prompt.MaxActivationDistance, prompt.RequiresLineOfSight = hold or 1.2, 10, true
    prompt.KeyboardKeyCode, prompt.GamepadKeyCode, prompt.Parent = Enum.KeyCode.E, Enum.KeyCode.ButtonX, target
    self.targets[name] = {part = target, prompt = prompt, stage = stage}
    local holds = {}
    table.insert(self.connections, prompt.PromptButtonHoldBegan:Connect(function(player)
        if self:_valid(player, target) then holds[player] = os.clock() end
    end))
    table.insert(self.connections, prompt.Triggered:Connect(function(player)
        local started = holds[player]
        holds[player] = nil
        if started and os.clock() - started >= prompt.HoldDuration - .15 then
            self:_attemptInteraction(player, name)
        end
    end))
    return target
end

function Room:_valid(player, target)
    local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
    if not root or not self.context.isPlayerActive(player) or (root.Position - target.Position).Magnitude > 12 then return false end
    local parameters = RaycastParams.new()
    parameters.FilterType = Enum.RaycastFilterType.Exclude
    parameters.FilterDescendantsInstances = {player.Character}
    local head = player.Character:FindFirstChild("Head")
    local origin = head and head.Position or root.Position + Vector3.new(0, 1.5, 0)
    local hit = workspace:Raycast(origin, target.Position - origin, parameters)
    return not hit or hit.Instance == target
end

function Room:_carry(player, kind)
    self.carrier = player
    self.carriedKind = kind
    player:SetAttribute("Carrying", kind)
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if root then
        local prop = Environment.Mesh(character, "container", root.CFrame * CFrame.new(0, -.2, -1.8), Vector3.new(1.5, 1.5, 1.5))
        prop.Name, prop.Anchored, prop.CanCollide, prop.Massless = "CarriedObjective", false, false, true
        local weld = Instance.new("WeldConstraint")
        weld.Part0, weld.Part1, weld.Parent = root, prop, prop
        self.carriedProp = prop
    end
end

function Room:_clearCarry()
    if self.carrier then self.carrier:SetAttribute("Carrying", nil) end
    if self.carriedProp then self.carriedProp:Destroy() end
    self.carrier, self.carriedProp = nil, nil
end

function Room:_advance(player, key)
    self.progress += 1
    self.stage += 1
    for _, entry in self.targets do
        entry.prompt.Enabled = entry.stage == self.stage
        entry.part.Transparency = entry.stage < self.stage and .8 or 0
    end
    self:_setObjective(self.instructions[self.stage] or "Return to the elevator. Stay together.")
    self.context.onObjectiveStep(player, key)
end

function Room:_attemptInteraction(player, key)
    local entry = self.targets[key]
    if self.destroyed or self.completed or not entry or entry.stage ~= self.stage or not entry.prompt.Enabled then return false end
    if not self:_valid(player, entry.part) then return false end
    if key == "ControlA" or key == "ControlB" then
        local now = os.clock()
        self.controls[key] = {player = player, time = now}
        local other = self.controls[key == "ControlA" and "ControlB" or "ControlA"]
        local activeCount = #self.context.getActivePlayers()
        local window = activeCount > 1 and 10 or 22
        if not other or not self.context.isPlayerActive(other.player) or now - other.time > window then
            self:_notify(player, activeCount > 1 and "Signal held for 10 seconds. A teammate must operate the other control." or "Signal held for 22 seconds. Reach the other control.")
            entry.part.Color = Color3.fromRGB(92, 210, 202)
            return true
        end
        if activeCount > 1 and other.player == player then
            self:_notify(player, "Two operators required. Ask a teammate to use the other control.")
            return false
        end
        self:_advance(player, "SynchronizedControls")
    elseif key == "Fuse" or key == "Sample" then
        local kind = self.definition.Template == "Hospital" and "Archive case" or "Sealed sample"
        self:_carry(player, key == "Fuse" and "Power cell" or kind)
        self:_advance(player, key)
    elseif key == "Power" or key == "Delivery" then
        if self.carrier ~= player then
            self:_notify(player, "The teammate carrying the case must deliver it here.")
            return false
        end
        self:_clearCarry()
        self:_advance(player, key)
    else
        self:_advance(player, key)
    end
    return true
end

function Room:Start()
    local assets = game:GetService("ServerStorage").LastStopAssets
    local laboratory = self.definition.Template == "FloodedLaboratory"
    self.model = laboratory and Environment.BuildLaboratory() or Environment.UpgradeHospital(assets.Floors.Hospital:Clone())
    self.model:PivotTo(CFrame.new(self._floorService._floorOrigin))
    self.model.Name = self.definition.Template
    self.model:SetAttribute("SourceTemplate", "ServerStorage.LastStopAssets / " .. self.definition.Template)
    self.model:SetAttribute("FloorTheme", laboratory and "Laboratory" or "Hospital")
    self.model:SetAttribute("HazardPhase", "Safe")
    self.model.Parent = self._floorService._activeFolder
    local markers = self.model.Markers
    self.spawnCFrame = markers.EntranceSpawn.CFrame
    self.escapeCFrame, self.escapeSize = markers.ElevatorReturnZone.CFrame, markers.ElevatorReturnZone.Size
    local elevator = assets.Elevator:Clone()
    elevator:PivotTo(markers.ElevatorSocket.CFrame)
    elevator.Name, elevator.Parent = "ReturnElevator", self.model
    for _, side in {"Left", "Right"} do
        local door = elevator["Door" .. side]
        local shift = CFrame.new(side == "Left" and -9.8 or 9.8, 0, 0)
        door.CFrame *= shift
        for _, part in door:GetDescendants() do
            if part:IsA("BasePart") then part.CFrame *= shift end
        end
    end
    self.patrolPoints = {markers.EnemySpawn.Position}
    for _, point in markers.PatrolPaths:GetChildren() do table.insert(self.patrolPoints, point.Position) end
    self.controls = {}
    if laboratory then
        local westFirst = self.seed % 2 == 0
        self.instructions = {westFirst and "Restart pump A on the west catwalk." or "Restart pump B on the east catwalk.",
            westFirst and "Restart pump B on the east catwalk." or "Restart pump A on the west catwalk.",
            "Synchronize controls A + B. Two players have 10 seconds. Solo has 22 seconds.",
            "Retrieve the sealed specimen at the north terminal.", "Carry the specimen to the elevator receiver. You move more slowly."}
        self:_target("PumpA", Vector3.new(-37, 3, 38), "Restart pump", "WEST / PUMP A", westFirst and 1 or 2, 3)
        self:_target("PumpB", Vector3.new(37, 3, 38), "Restart pump", "EAST / PUMP B", westFirst and 2 or 1, 3)
        self:_target("ControlA", Vector3.new(-9, 3, 0), "Hold signal", "CONTROL A", 3, 1)
        self:_target("ControlB", Vector3.new(9, 3, 0), "Hold signal", "CONTROL B", 3, 1)
        self:_target("Sample", Vector3.new(0, 4.8, -43), "Secure specimen", "SEALED SPECIMEN", 4, 2)
        self:_target("Delivery", Vector3.new(4, 3, 46), "Deliver specimen", "ELEVATOR RECEIVER", 5, 2)
    else
        local old = self.model:FindFirstChild("ObjectiveSockets")
        if old then old:Destroy() end
        self.instructions = {"Find the emergency power cell in the west ward.", "Carry the power cell to the imaging distribution panel.",
            "Synchronize ward and imaging controls. Use separate operators in a team.",
            "Recover the quarantined archive case.", "Carry the archive case back to the elevator receiver."}
        local random = Random.new(self.seed)
        self:_target("Fuse", Vector3.new(random:NextInteger(0, 1) == 0 and -29 or -19, 3.1, -1), "Take power cell", "EMERGENCY POWER", 1)
        self:_target("Power", Vector3.new(29, 4.2, 17), "Install power cell", "IMAGING / POWER", 2, 2)
        self:_target("ControlA", Vector3.new(-13, 3, 5), "Hold signal", "WARD / CONTROL A", 3, 1)
        self:_target("ControlB", Vector3.new(13, 3, 9), "Hold signal", "IMAGING / CONTROL B", 3, 1)
        self:_target("Sample", Vector3.new(25, 4.1, -23), "Recover archive case", "QUARANTINED ARCHIVE", 4, 2)
        self:_target("Delivery", Vector3.new(4, 3, 28), "Deliver archive", "ELEVATOR RECEIVER", 5, 2)
    end
    for _, entry in self.targets do entry.prompt.Enabled = entry.stage == self.stage end
    self:_setObjective(self.instructions[1])
    self.startedAt = os.clock()
    task.spawn(function() self:_hazards(laboratory) end)
end

function Room:_hazards(laboratory)
    local lastDamage = {}
    while not self.destroyed and self.model and not self.completed do
        local elapsed = os.clock() - self.startedAt
        local cycle = (elapsed + self.seed % 7) % 18
        local phase = cycle > 14 and "Active" or cycle > 10 and "Warning" or "Safe"
        self.model:SetAttribute("HazardPhase", phase)
        local water = self.model:FindFirstChild("FloodWater")
        if water then
            water.Color = phase == "Active" and Color3.fromRGB(48, 110, 122) or Color3.fromRGB(32, 87, 95)
            water.Material = Enum.Material.Glass
        end
        for _, player in self.context.getActivePlayers() do
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            if self.carrier == player and (not root or not self.context.isPlayerActive(player)) then
                self:_clearCarry()
                -- Re-open the pickup after death/disconnect without resetting earned milestones.
                self.stage = self.stage - 1
                self.progress = self.progress - 1
                for _, entry in self.targets do entry.prompt.Enabled = entry.stage == self.stage end
                self:_setObjective(self.instructions[self.stage])
            end
            if root and phase == "Active" and os.clock() - (lastDamage[player] or 0) > 1.2 then
                local localPosition = self.model:GetPivot():PointToObjectSpace(root.Position)
                local exposed = laboratory and localPosition.Y < 1.8
                    or not laboratory and math.abs(localPosition.X) < 5 and localPosition.Z < 0 and localPosition.Z > -24
                if exposed then
                    lastDamage[player] = os.clock()
                    self.context.damagePlayer(player, 8, laboratory and "Electrified floodwater" or "Containment discharge")
                end
            end
        end
        -- A disconnected carrier is absent from the active-player iteration.
        if self.carrier and not self.context.isPlayerActive(self.carrier) then
            self:_clearCarry()
            self.stage -= 1
            self.progress -= 1
            for _, entry in self.targets do entry.prompt.Enabled = entry.stage == self.stage end
            self:_setObjective(self.instructions[self.stage])
        end
        task.wait(.25)
    end
end

function Room:ObjectiveProgress() return self.progress, self.definition.Target end
function Room:Complete() self.completed = true; self.model:SetAttribute("Complete", true); self:_clearCarry() end
function Room:Fail() self.completed = true; self.model:SetAttribute("Failed", true); self:_clearCarry() end
function Room:Cleanup()
    self.destroyed = true
    self:_clearCarry()
    for _, connection in self.connections do connection:Disconnect() end
    table.clear(self.connections)
    if self.model then self.model:Destroy(); self.model = nil end
    table.clear(self.targets)
end

return Room
