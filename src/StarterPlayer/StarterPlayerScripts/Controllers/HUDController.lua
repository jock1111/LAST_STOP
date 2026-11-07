local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local HUD = {}
HUD.__index = HUD
local palette = {ink = Color3.fromRGB(12, 22, 29), line = Color3.fromRGB(63, 86, 94),
    white = Color3.fromRGB(226, 237, 232), muted = Color3.fromRGB(143, 167, 172),
    cyan = Color3.fromRGB(92, 210, 202), amber = Color3.fromRGB(242, 176, 84), red = Color3.fromRGB(224, 101, 96)}

local function panel(parent, name, size, position)
    local frame = Instance.new("Frame")
    frame.Name, frame.Size, frame.Position = name, size, position
    frame.BackgroundColor3, frame.BackgroundTransparency, frame.BorderSizePixel = palette.ink, .12, 0
    frame.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius, corner.Parent = UDim.new(0, 8), frame
    local stroke = Instance.new("UIStroke")
    stroke.Color, stroke.Transparency, stroke.Parent = palette.line, .45, frame
    return frame
end
local function label(parent, name, text, size, position, fontSize, color)
    local textLabel = Instance.new("TextLabel")
    textLabel.Name, textLabel.Text, textLabel.Size, textLabel.Position = name, text, size, position
    textLabel.Font, textLabel.TextSize = Enum.Font.GothamMedium, fontSize or 14
    textLabel.TextColor3, textLabel.BackgroundTransparency = color or palette.white, 1
    textLabel.TextXAlignment, textLabel.TextYAlignment = Enum.TextXAlignment.Left, Enum.TextYAlignment.Center
    textLabel.Parent = parent
    return textLabel
end
local function button(parent, name, text, position, size, color, callback)
    local control = Instance.new("TextButton")
    control.Name, control.Text, control.Position, control.Size = name, text, position, size
    control.BackgroundColor3, control.TextColor3, control.BorderSizePixel = color or palette.cyan, palette.ink, 0
    control.Font, control.TextSize, control.AutoButtonColor = Enum.Font.GothamBold, 14, true
    control.Parent = parent
    local corner = Instance.new("UICorner")
    corner.CornerRadius, corner.Parent = UDim.new(0, 7), control
    if callback then control.Activated:Connect(callback) end
    return control
end

function HUD.new(player, callbacks)
    local self = setmetatable({player = player, callbacks = callbacks, state = "Lobby", connections = {},
        queueCountdown = 0, objectivePosition = nil, objectiveStage = 0}, HUD)
    local gui = Instance.new("ScreenGui")
    gui.Name, gui.ResetOnSpawn, gui.ZIndexBehavior = "LastStopHUD", false, Enum.ZIndexBehavior.Sibling
    gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
    gui.Parent = player:WaitForChild("PlayerGui")
    self.gui = gui
    local root = Instance.new("Frame")
    root.Name, root.Size, root.BackgroundTransparency, root.Parent = "SafeArea", UDim2.fromScale(1, 1), 1, gui
    self.root = root
    label(root, "Build", "V7 / FIRST SESSION", UDim2.fromOffset(150, 16), UDim2.new(0, 14, 1, -20), 9, palette.muted)
    self.mission = panel(root, "Mission", UDim2.fromOffset(348, 150), UDim2.fromOffset(22, 70))
    self.brand = label(self.mission, "Brand", "LAST STOP   /   RESEARCH TRANSIT", UDim2.new(1, -28, 0, 20), UDim2.fromOffset(14, 10), 10, palette.cyan)
    self.title = label(self.mission, "Floor", "TERMINUS CONCOURSE", UDim2.new(1, -28, 0, 26), UDim2.fromOffset(14, 31), 16)
    self.stageLabel = label(self.mission, "Stage", "", UDim2.new(1, -28, 0, 26), UDim2.fromOffset(14, 53), 11, palette.muted)
    self.objective = label(self.mission, "Objective", "Board an expedition. Bring your team home.", UDim2.new(1, -28, 0, 48), UDim2.fromOffset(14, 72), 13, palette.muted)
    self.objective.TextWrapped = true
    self.segments = {}
    for index = 1, 5 do
        local segment = Instance.new("Frame")
        segment.BorderSizePixel, segment.BackgroundColor3 = 0, palette.line
        segment.Position, segment.Size = UDim2.new((index - 1) / 5, 14, 1, -13), UDim2.new(.2, -8, 0, 3)
        segment.Parent = self.mission
        table.insert(self.segments, segment)
    end
    local wallet = panel(root, "Wallet", UDim2.fromOffset(200, 70), UDim2.new(1, -222, 0, 70))
    self.coins = label(wallet, "Secured", "SECURED   0", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 7), 13, palette.cyan)
    self.risk = label(wallet, "AtRisk", "AT RISK   0", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 34), 13, palette.amber)
    self.vitals = panel(root, "Vitals", UDim2.fromOffset(200, 74), UDim2.new(1, -222, 0, 152))
    self.vitals.Visible = false
    self.healthLabel = label(self.vitals, "Health", "VITALS   100", UDim2.new(1, -24, 0, 20), UDim2.fromOffset(12, 6), 11)
    self.health = Instance.new("Frame")
    self.health.Position, self.health.Size = UDim2.fromOffset(12, 29), UDim2.fromOffset(176, 4)
    self.health.BackgroundColor3, self.health.BorderSizePixel, self.health.Parent = palette.cyan, 0, self.vitals
    label(self.vitals, "StaminaTitle", "STAMINA", UDim2.new(1, -24, 0, 16), UDim2.fromOffset(12, 39), 9, palette.muted)
    self.stamina = self.health:Clone()
    self.stamina.Position, self.stamina.BackgroundColor3, self.stamina.Parent = UDim2.fromOffset(12, 61), palette.amber, self.vitals
    self.playButton = button(root, "Play", "BOARD EXPEDITION   →", UDim2.new(.5, -120, 1, -86), UDim2.fromOffset(240, 50), palette.cyan, callbacks.queue)
    self.countdownLabel = label(root, "QueueCountdown", "ELEVATOR DEPARTS IN 0s", UDim2.fromOffset(220, 26), UDim2.new(.5, -110, 1, -144), 12, palette.amber)
    self.countdownLabel.Visible = false
    self.countdownLabel.TextXAlignment = Enum.TextXAlignment.Center
    self.medkitButton = button(root, "Medkit", "MEDKIT  /  H", UDim2.new(1, -220, 1, -85), UDim2.fromOffset(150, 48), palette.cyan, callbacks.medkit)
    self.medkitButton.Visible = false
    self.sprintButton = button(root, "Sprint", "RUN", UDim2.new(1, -150, 1, -190), UDim2.fromOffset(72, 54), palette.cyan)
    self.sprintButton.Visible = false
    local sprintInput
    table.insert(self.connections, self.sprintButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            sprintInput = input
            callbacks.sprint(true)
        end
    end))
    table.insert(self.connections, UserInputService.InputEnded:Connect(function(input)
        if input == sprintInput then
            sprintInput = nil
            callbacks.sprint(false)
        end
    end))
    table.insert(self.connections, UserInputService.WindowFocusReleased:Connect(function()
        sprintInput = nil
        callbacks.sprint(false)
    end))
    self.carry = label(root, "Carrying", "", UDim2.fromOffset(380, 30), UDim2.new(.5, -190, 1, -128), 13, palette.amber)
    self.carry.TextXAlignment = Enum.TextXAlignment.Center
    self.hazard = label(root, "Hazard", "", UDim2.new(.5, 0, 0, 36), UDim2.new(.25, 0, 0, 20), 14, palette.amber)
    self.hazard.TextXAlignment = Enum.TextXAlignment.Center
    self.toast = panel(root, "Toast", UDim2.fromOffset(440, 54), UDim2.new(.5, -220, 0, 220))
    self.toastText = label(self.toast, "Message", "", UDim2.new(1, -30, 1, 0), UDim2.fromOffset(15, 0), 13)
    self.toastText.TextWrapped = true
    self.toast.Visible = false
    self.decision = panel(root, "Decision", UDim2.fromOffset(490, 300), UDim2.new(.5, -245, .5, -150))
    self.decision.Visible = false
    label(self.decision, "Eyebrow", "EXPEDITION CHECKPOINT", UDim2.fromOffset(430, 26), UDim2.fromOffset(28, 22), 11, palette.cyan)
    label(self.decision, "Heading", "How far will you go?", UDim2.fromOffset(430, 40), UDim2.fromOffset(28, 52), 27)
    self.decisionSummary = label(self.decision, "Summary", "", UDim2.fromOffset(430, 70), UDim2.fromOffset(28, 101), 15, palette.muted)
    self.decisionSummary.TextWrapped = true
    self.countdown = label(self.decision, "Countdown", "", UDim2.fromOffset(430, 20), UDim2.fromOffset(28, 177), 12, palette.amber)
    button(self.decision, "Bank", "BANK & RETURN", UDim2.fromOffset(28, 223), UDim2.fromOffset(210, 50), palette.cyan, function() callbacks.decision("Bank") end)
    button(self.decision, "Continue", "CONTINUE ↓", UDim2.fromOffset(251, 223), UDim2.fromOffset(210, 50), palette.amber, function() callbacks.decision("Continue") end)
    -- Results breakdown panel (shown when an expedition ends).
    self.results = panel(root, "Results", UDim2.fromOffset(420, 260), UDim2.new(.5, -210, .5, -130))
    self.results.Visible = false
    label(self.results, "Eyebrow", "EXPEDITION RESULTS", UDim2.fromOffset(430, 26), UDim2.fromOffset(28, 22), 11, palette.cyan)
    self.resultsTitle = label(self.results, "Title", "", UDim2.fromOffset(430, 40), UDim2.fromOffset(28, 50), 24, palette.white)
    self.resultsLine1 = label(self.results, "Line1", "", UDim2.fromOffset(430, 24), UDim2.fromOffset(28, 96), 13, palette.cyan)
    self.resultsLine2 = label(self.results, "Line2", "", UDim2.fromOffset(430, 24), UDim2.fromOffset(28, 120), 13, palette.amber)
    self.resultsLine3 = label(self.results, "Line3", "", UDim2.fromOffset(430, 24), UDim2.fromOffset(28, 144), 13, palette.muted)
    self.resultsLine4 = label(self.results, "Line4", "", UDim2.fromOffset(430, 24), UDim2.fromOffset(28, 168), 13, palette.muted)
    self.resultsHint = label(self.results, "Hint", "", UDim2.fromOffset(430, 24), UDim2.fromOffset(28, 200), 12, palette.muted)
    -- Subtle wayfinder: screen-edge arrow pointing at the current objective.
    self.wayfinder = Instance.new("Frame")
    self.wayfinder.Name, self.wayfinder.Size, self.wayfinder.BackgroundTransparency = "Wayfinder", UDim2.fromOffset(20, 20), .35
    self.wayfinder.BorderSizePixel, self.wayfinder.Visible = 0, false
    local arrow = Instance.new("ImageLabel")
    arrow.Name, arrow.Size, arrow.BackgroundTransparency = "Arrow", UDim2.fromScale(1, 1), 1
    arrow.Image, arrow.ImageColor3 = "rbxassetid://5693079641", palette.cyan
    arrow.Position, arrow.Parent = UDim2.fromScale(0, 0), self.wayfinder
    local corner = Instance.new("UICorner")
    corner.CornerRadius, corner.Parent = UDim.new(1, 0), self.wayfinder
    self.wayfinder.Parent = root
    -- Context-sensitive interaction cue.
    self.interactCue = label(root, "InteractCue", "HOLD  E  TO  INTERACT", UDim2.fromOffset(200, 24), UDim2.new(.5, -100, 0, 200), 12, palette.cyan)
    self.interactCue.Visible = false
    self.interactCue.TextXAlignment = Enum.TextXAlignment.Center
    local function responsive()
        local camera = workspace.CurrentCamera
        if not camera then return end
        local mobile = UserInputService.TouchEnabled or camera.ViewportSize.X < 750
        local portrait = camera.ViewportSize.X < 480
        self.mission.Size = UDim2.fromOffset(mobile and 280 or 348, mobile and 136 or 150)
        self.mission.Position = UDim2.fromOffset(14, mobile and 58 or 70)
        self.title.TextSize, self.objective.TextSize = mobile and 13 or 16, mobile and 11 or 13
        wallet.Position = UDim2.new(1, -174, 0, mobile and 58 or 70)
        wallet.Size = UDim2.fromOffset(160, 70)
        self.vitals.Position = UDim2.new(1, -174, 0, mobile and 140 or 152)
        self.vitals.Size = UDim2.fromOffset(160, 74)
        local toastWidth = math.min(440, camera.ViewportSize.X * .66)
        self.toast.Size = UDim2.fromOffset(toastWidth, 54)
        self.toast.Position = UDim2.new(.5, -toastWidth / 2, 0, mobile and 184 or 220)
        local scale = self.decision:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", self.decision)
        scale.Scale = math.min(1, (camera.ViewportSize.X - 30) / 490)
        self.decision.Position = UDim2.new(.5, -245 * scale.Scale, .5, -150 * scale.Scale)
        self.medkitButton.Position = UDim2.new(1, mobile and -310 or -220, 1, mobile and -62 or -85)
        if portrait then
            self.mission.Size = UDim2.new(1, -28, 0, 136)
            wallet.Position, wallet.Size = UDim2.fromOffset(14, 206), UDim2.fromOffset(160, 70)
            self.vitals.Position = UDim2.new(1, -174, 0, 206)
            self.toast.Position = UDim2.new(.05, 0, 0, 270)
            self.toast.Size = UDim2.new(.9, 0, 0, 54)
            self.hazard.Position, self.hazard.Size = UDim2.new(.05, 0, 0, 330), UDim2.new(.9, 0, 0, 48)
            self.hazard.TextSize, self.hazard.TextWrapped = 11, true
            self.medkitButton.Position = UDim2.new(0, 14, 1, -218)
            self.carry.Position = UDim2.new(.5, -190, 1, -318)
            self.countdownLabel.Position = UDim2.new(.5, -110, 0, 188)
        else
            self.carry.Position = UDim2.new(.5, -190, 1, -128)
            self.hazard.Position, self.hazard.Size = UDim2.new(.25, 0, 0, 20), UDim2.new(.5, 0, 0, 36)
            self.hazard.TextSize, self.hazard.TextWrapped = mobile and 11 or 14, true
            self.medkitButton.Position = UDim2.new(1, mobile and -310 or -220, 1, mobile and -62 or -85)
            self.countdownLabel.Position = UDim2.new(.5, -110, 1, -144)
        end
    end
    workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(responsive)
    workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(responsive)
    responsive()
    table.insert(self.connections, RunService.Heartbeat:Connect(function(dt)
        local character = player.Character
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local health = humanoid and humanoid.Health or 0
        self.healthLabel.Text = "VITALS   " .. math.ceil(health)
        self.health.Size = UDim2.new(math.clamp(health / 100, 0, 1), -24 * math.clamp(health / 100, 0, 1), 0, 4)
        local energy = (player:GetAttribute("Stamina") or 100) / 100
        self.stamina.Size = UDim2.new(energy, -24 * energy, 0, 4)
        self.carry.Text = player:GetAttribute("Carrying") and "CARRYING  /  " .. player:GetAttribute("Carrying") .. "   •   SPRINT DISABLED" or ""
        if self.deadline then self.countdown.Text = "DECISION CLOSES IN " .. math.max(0, self.deadline - os.time()) .. "s" end
        -- Update queue countdown display.
        if self.queueCountdown and self.queueCountdown > 0 then
            self.countdownLabel.Text = "ELEVATOR DEPARTS IN " .. math.ceil(self.queueCountdown) .. "s"
            self.countdownLabel.Visible = true
        else
            self.countdownLabel.Visible = false
        end
        -- Wayfinder: subtle screen-edge arrow toward the current objective.
        self:updateWayfinder(dt)
        -- Interaction cue when close to the current objective target.
        self:updateInteractCue(character)
        local world = workspace:FindFirstChild("LastStopWorld")
        local runtime = world and world:FindFirstChild("Runtime")
        local folder = runtime and runtime:FindFirstChild("ActiveExpedition")
        local floor = folder and folder:FindFirstChildOfClass("Model")
        local phase = floor and floor:GetAttribute("HazardPhase")
        local subway = floor and floor:GetAttribute("FloorTheme") == "Subway"
        local flicker = floor and floor:GetAttribute("PowerFlicker") == true
        self.hazard.Text = self.state == "Floor" and phase == "Warning" and (subway and "⚠  TRAIN APPROACHING — CLEAR THE TRACK" or "⚠  DISCHARGE INCOMING — REACH A SAFE ROUTE")
            or self.state == "Floor" and phase == "Active" and (subway and "⚠  TRAIN PASSING — STAY OFF THE TRACK" or "⚠  DISCHARGE ACTIVE — STAY CLEAR")
            or self.state == "Floor" and flicker and "⚡  POWER FLICKER — LIGHTS FAILING"
            or ""
    end))
    return self
end

-- Called by the client bootstrap when the QueueCountdown remote fires.
function HUD:setQueueCountdown(seconds)
    self.queueCountdown = seconds or 0
end

-- Update the subtle screen-edge wayfinder pointing at the current objective.
function HUD:updateWayfinder(dt)
    local camera = Workspace.CurrentCamera
    if not camera then self.wayfinder.Visible = false return end
    local character = self.player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not self.objectivePosition then
        self.wayfinder.Visible = false
        return
    end
    local direction = (self.objectivePosition - root.Position).Unit
    local cameraDirection = camera.CFrame.LookVector
    local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
    local flatCam = Vector3.new(cameraDirection.X, 0, cameraDirection.Z).Unit
    local dot = flatDir:Dot(flatCam)
    -- Only show when the objective is off-screen (behind or to the side).
    if dot > .82 then
        self.wayfinder.Visible = false
        return
    end
    -- Screen-space angle around the camera's forward axis.
    local right = camera.CFrame.RightVector
    local up = Vector3.new(0, 1, 0)
    local screenX = flatDir:Dot(right)
    local screenY = flatDir:Dot(up)
    local angle = math.atan2(-screenX, screenY)
    local radius = 140
    local cx, cy = camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2
    local px = cx + math.sin(angle) * radius
    local py = cy - math.cos(angle) * radius
    -- Clamp to screen edges.
    local margin = 30
    px = math.clamp(px, margin, camera.ViewportSize.X - margin)
    py = math.clamp(py, margin, camera.ViewportSize.Y - margin)
    self.wayfinder.Position = UDim2.fromOffset(px - 10, py - 10)
    self.wayfinder.Rotation = math.deg(angle) - 90
    self.wayfinder.Visible = true
end

-- Show a brief interaction cue when standing near the current objective target.
function HUD:updateInteractCue(character)
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not root or not self.objectivePosition then
        self.interactCue.Visible = false
        return
    end
    local dist = (root.Position - self.objectivePosition).Magnitude
    if dist <= 14 then
        self.interactCue.Visible = true
    else
        self.interactCue.Visible = false
    end
end

function HUD:ApplyState(data)
    self.state = data.state or self.state
    self.title.Text = string.upper(data.floorName or "TERMINUS CONCOURSE")
    self.objective.Text = data.objective or "Board an expedition. Bring your team home."
    self.brand.Text = "LAST STOP   /   " .. string.upper(self.state) .. (data.depth and data.depth > 0 and "   /   " .. string.format("%02d", data.depth) or "")
    self.coins.Text, self.risk.Text = "SECURED   " .. (data.banked or 0), "AT RISK   " .. (data.unbanked or 0)
    self.decision.Visible = self.state == "Decision"
    self.decisionSummary.Text = string.format("%d coins are still at risk. Bank this haul, or descend for a larger reward. Your choice is individual.", data.unbanked or 0)
    self.deadline = data.decisionDeadline or self.deadline
    self.playButton.Visible = self.state == "Lobby" or self.state == "Results" or self.state == "Ended"
    self.medkitButton.Visible = self.state == "Floor" or self.state == "Escape"
    self.sprintButton.Visible = UserInputService.TouchEnabled and self.medkitButton.Visible
    self.vitals.Visible = self.medkitButton.Visible
    -- Objective stage + wayfinding data.
    self.objectiveStage = data.objectiveStage or 0
    self.objectivePosition = data.objectivePosition
    if self.objectiveStage and self.objectiveStage > 0 then
        self.stageLabel.Text = string.format("STAGE %d / 5", math.clamp(self.objectiveStage, 1, 5))
        self.stageLabel.Visible = true
    else
        self.stageLabel.Visible = false
    end
    for index, segment in self.segments do segment.BackgroundColor3 = index <= (data.progress or 0) and palette.cyan or palette.line end
    if self.state == "Escape" then self.objective.Text = "EXTRACTION OPEN. Return inside the elevator now." end
    if self.state == "Results" then
        self.title.Text = data.result == "BANKED" and "HAUL SECURED" or "EXPEDITION ENDED"
        self.objective.Text = data.message or "Board another expedition when you are ready."
        self:showResults(data)
    else
        self.results.Visible = false
    end
    if data.message then self:ShowToast(data.message) end

    -- Frame the lobby camera when the player is back at the concourse so the
    -- Results / lobby screen always shows the environment rather than a blank
    -- viewport during the character reload that follows a bank or death.
    local camera = workspace.CurrentCamera
    if camera then
        if data.state == "Results" or data.state == "Lobby" or data.state == "Ended" then
            task.defer(function() self:FrameLobby() end)
        elseif data.state == "Floor" or data.state == "Escape" or data.state == "Decision" or data.state == "Boarding" or data.state == "Travel" then
            self:EnsureGameplayCamera()
        end
    end
end

-- Detailed results breakdown shown at the end of an expedition.
function HUD:showResults(data)
    self.results.Visible = true
    local result = data.result
    local earned = data.earned or 0
    local secured = data.secured or (data.banked or 0)
    local lost = data.lost or 0
    local xp = data.xpEarned or 0
    if result == "BANKED" then
        self.resultsTitle.Text = "HAUL SECURED"
        self.resultsLine1.Text = string.format("COINS EARNED THIS RUN:   %d", earned)
        self.resultsLine2.Text = string.format("COINS SECURED (BANKED):   %d", secured)
        self.resultsLine3.Text = string.format("XP EARNED:   %d", xp)
        self.resultsLine4.Text = ""
        self.resultsHint.Text = "Your haul is safe. Press BOARD EXPEDITION to descend again — deeper floors pay more."
    else
        self.resultsTitle.Text = "EXPEDITION ENDED"
        self.resultsLine1.Text = string.format("COINS AT RISK LOST:   %d", lost)
        self.resultsLine2.Text = string.format("COINS SECURED (BANKED):   %d", secured)
        self.resultsLine3.Text = string.format("XP EARNED:   %d", xp)
        self.resultsLine4.Text = ""
        self.resultsHint.Text = "Unbanked coins are lost on failure. Bank early to lock in progress."
    end
end

function HUD:EnsureGameplayCamera()
    local camera = workspace.CurrentCamera
    if not camera then return end
    camera.CameraType = Enum.CameraType.Custom
    local character = self.player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local root = character and character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not root then return end
    if camera.CameraSubject ~= humanoid then
        camera.CameraSubject = humanoid
    end
    local focus = camera.Focus
    local expected = root.Position + Vector3.new(0, humanoid.HipHeight + 1.5, 0)
    if not focus or (focus.Position - expected).Magnitude > 8 then
        camera.CameraSubject = nil
        task.defer(function()
            if camera.Parent and humanoid.Parent then
                camera.CameraSubject = humanoid
            end
        end)
    end
end
function HUD:FrameLobby()
	local camera = workspace.CurrentCamera
	if not camera then return end
	local target = nil
	local world = workspace:FindFirstChild("LastStopWorld")
	if world then
		local lobby = world:FindFirstChild("Lobby")
		if lobby then
			target = lobby:FindFirstChild("LobbySpawnPoint") or lobby:FindFirstChild("ElevatorSocket")
		end
	end
	local root = self.player.Character and self.player.Character:FindFirstChild("HumanoidRootPart")
	local lookAt = (target and target.Position) or (root and root.Position)
	if not lookAt then return end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = CFrame.lookAt(lookAt + Vector3.new(14, 11, 14), lookAt)
end
function HUD:ShowToast(message)
    self.toastText.Text, self.toast.Visible = tostring(message), true
    self.toastGeneration = (self.toastGeneration or 0) + 1
    local generation = self.toastGeneration
    task.delay(4, function()
        if self.toast.Parent and generation == self.toastGeneration then self.toast.Visible = false end
    end)
end
function HUD:Destroy()
    self.callbacks.sprint(false)
    for _, connection in ipairs(self.connections) do
        connection:Disconnect()
    end
    self.gui:Destroy()
end
return HUD
