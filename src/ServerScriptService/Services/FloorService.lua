-- Builds original primitive-geometry rooms at runtime. This avoids unreviewed
-- free models and gives every floor a common lifecycle interface.
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ArtTheme = require(ReplicatedStorage.Shared.ArtTheme)

local FloorService = {}
FloorService.__index = FloorService

local PALETTE = ArtTheme.Palette
local CHARCOAL = PALETTE.BlueGray
local CYAN = PALETTE.Cyan
local RED = PALETTE.Alarm

local function part(parent, name, size, cframe, color, material, properties)
	local instance = Instance.new("Part")
	instance.Name = name
	instance.Anchored = true
	instance.CanCollide = true
	instance.Size = size
	instance.CFrame = cframe
	instance.Color = color or CHARCOAL
	instance.Material = material or Enum.Material.Metal
	instance.TopSurface = Enum.SurfaceType.Smooth
	instance.BottomSurface = Enum.SurfaceType.Smooth
	if properties then
		local pbrMaterial = properties.PbrMaterial
		for property, value in pairs(properties) do
			if property ~= "PbrMaterial" then
				instance[property] = value
			end
		end
		if pbrMaterial then
			instance:SetAttribute("PbrMaterial", pbrMaterial)
		end
	end
	instance.Parent = parent
	return instance
end

local function surfaceText(parent, face, text, color, textSize)
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SurfaceSign"
	gui.Face = face or Enum.NormalId.Front
	gui.CanvasSize = Vector2.new(800, 260)
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Adornee = parent
	gui.Parent = parent
	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = color or PALETTE.OffWhite
	textLabel.TextStrokeTransparency = 0.75
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextSize = textSize or 54
	textLabel.TextWrapped = true
	textLabel.Parent = gui
	return gui
end

local function industrialLamp(parent, position, color, brightness, range)
	local housing = part(parent, "CeilingFixture", Vector3.new(4, 0.35, 1.2), CFrame.new(position), Color3.fromRGB(40, 48, 55), Enum.Material.Metal)
	local tube = part(parent, "LightTube", Vector3.new(3.3, 0.18, 0.5), CFrame.new(position - Vector3.new(0, 0.28, 0)), color, Enum.Material.Neon, { CanCollide = false })
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = range or 20
	light.Brightness = brightness or 1.5
	light.Shadows = true
	light.Parent = tube
	return housing, tube
end

local function pipeRun(parent, startPosition, length, axis, color)
	local rotation = axis == "X" and CFrame.Angles(0, 0, math.rad(90)) or CFrame.Angles(math.rad(90), 0, 0)
	local pipe = part(parent, "ServicePipe", Vector3.new(1.1, length, 1.1), CFrame.new(startPosition) * rotation, color or PALETTE.Steel, Enum.Material.Metal)
	pipe.Shape = Enum.PartType.Cylinder
	for distance = -length / 2 + 3, length / 2 - 3, 6 do
		local offset = axis == "X" and Vector3.new(distance, 0, 0) or Vector3.new(0, 0, distance)
		local collar = part(parent, "PipeClamp", Vector3.new(1.45, 0.28, 1.45), CFrame.new(startPosition + offset) * rotation, Color3.fromRGB(39, 46, 51), Enum.Material.Metal)
		collar.Shape = Enum.PartType.Cylinder
	end
	return pipe
end

local function bench(parent, position, direction)
	local model = Instance.new("Model")
	model.Name = "TransitBench"
	model.Parent = parent
	local facing = direction or CFrame.new()
	part(model, "Seat", Vector3.new(8, 0.55, 1.7), CFrame.new(position) * facing, Color3.fromRGB(42, 52, 58), Enum.Material.Metal)
	part(model, "Back", Vector3.new(8, 2.2, 0.35), CFrame.new(position + Vector3.new(0, 1.15, 0.66)) * facing, PALETTE.Steel, Enum.Material.Metal)
	for _, x in ipairs({ -3.1, 0, 3.1 }) do
		part(model, "SeatDivider", Vector3.new(0.16, 1.45, 1.85), CFrame.new(position + Vector3.new(x, 0.6, 0)) * facing, Color3.fromRGB(24, 29, 34), Enum.Material.Metal)
	end
	for _, x in ipairs({ -3.25, 3.25 }) do
		part(model, "BenchLeg", Vector3.new(0.32, 2.1, 0.32), CFrame.new(position + Vector3.new(x, -1.05, 0)) * facing, PALETTE.Steel, Enum.Material.Metal)
	end
	return model
end

local function wallPanel(parent, position, width, height, rotation, labelText)
	local panel = part(parent, "RecessedWallPanel", Vector3.new(width, height, 0.35), CFrame.new(position) * (rotation or CFrame.new()), Color3.fromRGB(33, 43, 50), Enum.Material.Metal)
	local inset = part(parent, "PanelInset", Vector3.new(width - 0.5, height - 0.5, 0.16), panel.CFrame * CFrame.new(0, 0, -0.22), Color3.fromRGB(20, 27, 33), Enum.Material.SmoothPlastic)
	if labelText then
		surfaceText(inset, Enum.NormalId.Front, labelText, PALETTE.OffWhite, 34)
	end
	return panel
end

local function label(parent, text, cframe, color)
	local board = Instance.new("BillboardGui")
	board.Name = "Sign"
	board.Size = UDim2.fromOffset(300, 70)
	board.AlwaysOnTop = true
	board.StudsOffset = Vector3.new(0, 4, 0)
	board.Adornee = parent
	board.Parent = parent
	local textLabel = Instance.new("TextLabel")
	textLabel.BackgroundTransparency = 1
	textLabel.Size = UDim2.fromScale(1, 1)
	textLabel.Font = Enum.Font.GothamBold
	textLabel.TextScaled = true
	textLabel.Text = text
	textLabel.TextColor3 = color or CYAN
	textLabel.TextStrokeTransparency = 0.55
	textLabel.Parent = board
	return board
end

local function addLight(parent, position, color, brightness)
	local anchor = part(parent, "LightAnchor", Vector3.new(1, 1, 1), CFrame.new(position), color, Enum.Material.Neon)
	anchor.CanCollide = false
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 22
	light.Brightness = brightness or 2
	light.Parent = anchor
	return anchor
end

local RoomRuntime = {}
RoomRuntime.__index = RoomRuntime

function RoomRuntime.new(floorService, definition, seed)
	return setmetatable({
		_floorService = floorService,
		definition = definition,
		seed = seed,
		context = nil,
		model = nil,
		targets = {},
		connections = {},
		completed = false,
	}, RoomRuntime)
end

function RoomRuntime:Initialize(context)
	self.context = context
end

function RoomRuntime:_createObjective(parent, key, position, caption)
	local terminal = part(parent, key, Vector3.new(3, 4, 2), CFrame.new(position), self.definition.Accent, Enum.Material.Neon)
	terminal:SetAttribute("ObjectiveKey", key)
	terminal:SetAttribute("Used", false)
	label(terminal, caption, terminal.CFrame, self.definition.Accent)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Interact"
	prompt.ObjectText = caption
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = 0.75
	prompt.MaxActivationDistance = self.context.interactionDistance
	prompt.RequiresLineOfSight = true
	prompt.Parent = terminal
	self.targets[key] = terminal
	table.insert(self.connections, prompt.Triggered:Connect(function(player)
		self:_attemptInteraction(player, key)
	end))
end

function RoomRuntime:_attemptInteraction(player, key)
	local target = self.targets[key]
	if not target or target:GetAttribute("Used") then
		return
	end
	if not self.context.isPlayerActive(player) then
		return
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or (root.Position - target.Position).Magnitude > self.context.interactionDistance then
		return
	end
	target:SetAttribute("Used", true)
	target.Color = Color3.fromRGB(100, 255, 160)
	self.context.onObjectiveStep(player, key)
end

function RoomRuntime:Start()
	assert(self.context, "RoomRuntime must be initialized before Start")
	local model = Instance.new("Model")
	model.Name = self.definition.Id
	model.Parent = self._floorService._activeFolder
	self.model = model

	local origin = self._floorService._floorOrigin
	part(model, "Floor", Vector3.new(76, 2, 96), CFrame.new(origin), CHARCOAL, Enum.Material.Concrete)
	part(model, "NorthWall", Vector3.new(76, 18, 2), CFrame.new(origin + Vector3.new(0, 9, -47)), Color3.fromRGB(25, 28, 32))
	part(model, "SouthWall", Vector3.new(76, 18, 2), CFrame.new(origin + Vector3.new(0, 9, 47)), Color3.fromRGB(25, 28, 32))
	part(model, "WestWall", Vector3.new(2, 18, 96), CFrame.new(origin + Vector3.new(-37, 9, 0)), Color3.fromRGB(25, 28, 32))
	part(model, "EastWall", Vector3.new(2, 18, 96), CFrame.new(origin + Vector3.new(37, 9, 0)), Color3.fromRGB(25, 28, 32))
	part(model, "Ceiling", Vector3.new(76, 2, 96), CFrame.new(origin + Vector3.new(0, 18, 0)), Color3.fromRGB(27, 31, 35))
	for _, x in ipairs({ -26, 0, 26 }) do
		addLight(model, origin + Vector3.new(x, 15, 0), self.definition.Accent, 2)
	end

	-- The elevator is visually part of every room and its invisible region is the
	-- server-validated escape destination after the objective completes.
	local elevator = Instance.new("Model")
	elevator.Name = "ReturnElevator"
	elevator.Parent = model
	part(elevator, "CabinFloor", Vector3.new(18, 1, 14), CFrame.new(origin + Vector3.new(0, 1, 36)), Color3.fromRGB(20, 23, 28))
	part(elevator, "CabinBack", Vector3.new(18, 12, 1), CFrame.new(origin + Vector3.new(0, 7, 42)), Color3.fromRGB(46, 51, 58))
	part(elevator, "CabinLeft", Vector3.new(1, 12, 14), CFrame.new(origin + Vector3.new(-9, 7, 36)), Color3.fromRGB(46, 51, 58))
	part(elevator, "CabinRight", Vector3.new(1, 12, 14), CFrame.new(origin + Vector3.new(9, 7, 36)), Color3.fromRGB(46, 51, 58))
	local escapePad = part(elevator, "SafeRegion", Vector3.new(16, 1, 12), CFrame.new(origin + Vector3.new(0, 1.5, 36)), Color3.fromRGB(73, 212, 210), Enum.Material.Neon)
	escapePad.Transparency = 0.55
	label(escapePad, "RETURN ELEVATOR", escapePad.CFrame, CYAN)
	self.escapeCFrame = CFrame.new(origin + Vector3.new(0, 5, 36))
	self.escapeSize = Vector3.new(16, 10, 12)
	self.spawnCFrame = CFrame.new(origin + Vector3.new(0, 4, 30))

	local targetPositions = {
		origin + Vector3.new(-22, 3, -18),
		origin + Vector3.new(0, 3, -8),
		origin + Vector3.new(22, 3, -18),
	}
	for index = 1, self.definition.Target do
		local word = self.definition.ObjectiveType == "Collect" and "Record Case" or "System Terminal"
		self:_createObjective(model, self.definition.Id .. "_" .. index, targetPositions[index], word .. " " .. index)
	end

	if self.definition.Id == "FloodedLab" then
		local water = part(model, "RisingWaterVisual", Vector3.new(70, 1, 55), CFrame.new(origin + Vector3.new(0, 1.6, -12)), Color3.fromRGB(48, 134, 205), Enum.Material.Glass)
		water.Transparency = 0.4
	elseif self.definition.Id == "Lockdown" then
		for _, x in ipairs({ -14, 14 }) do
			local laser = part(model, "SecurityLaser", Vector3.new(1, 0.3, 54), CFrame.new(origin + Vector3.new(x, 5, -4)), RED, Enum.Material.Neon)
			laser.CanCollide = false
		end
	end

	self.patrolPoints = {
		origin + Vector3.new(-25, 2, -25), origin + Vector3.new(25, 2, -25),
		origin + Vector3.new(25, 2, 20), origin + Vector3.new(-25, 2, 20),
	}
	return self
end

function RoomRuntime:ObjectiveProgress()
	local used = 0
	for _, target in pairs(self.targets) do
		if target:GetAttribute("Used") then
			used += 1
		end
	end
	return used, self.definition.Target
end

function RoomRuntime:Complete()
	self.completed = true
	if self.model then
		self.model:SetAttribute("Complete", true)
	end
end

function RoomRuntime:Fail()
	if self.model then
		self.model:SetAttribute("Failed", true)
	end
end

function RoomRuntime:Cleanup()
	for _, connection in ipairs(self.connections) do
		connection:Disconnect()
	end
	table.clear(self.connections)
	if self.model then
		self.model:Destroy()
		self.model = nil
	end
	self.targets = {}
end

function FloorService.new()
	return setmetatable({
		_world = nil,
		_activeFolder = nil,
		_floorOrigin = Vector3.new(0, 0, 700),
		lobby = nil,
	}, FloorService)
end

function FloorService:BuildWorld()
	local existing = workspace:FindFirstChild("LastStopWorld")
	if existing then
		existing:Destroy()
	end
	local world = Instance.new("Folder")
	world.Name = "LastStopWorld"
	world.Parent = workspace
	self._world = world
	self._activeFolder = Instance.new("Folder")
	self._activeFolder.Name = "ActiveExpedition"
	self._activeFolder.Parent = world
	local lobby = Instance.new("Model")
	lobby.Name = "Lobby"
	lobby.Parent = world
	part(lobby, "StationFloor", Vector3.new(120, 2, 90), CFrame.new(0, 0, 0), Color3.fromRGB(35, 39, 44), Enum.Material.Concrete)
	part(lobby, "StationBack", Vector3.new(120, 24, 2), CFrame.new(0, 12, -44), Color3.fromRGB(25, 28, 32))
	for _, x in ipairs({ -45, -20, 20, 45 }) do
		addLight(lobby, Vector3.new(x, 18, -12), CYAN, 2)
	end
	local elevator = Instance.new("Model")
	elevator.Name = "CentralElevator"
	elevator.Parent = lobby
	part(elevator, "CabinFloor", Vector3.new(22, 1, 18), CFrame.new(0, 1, 0), Color3.fromRGB(19, 22, 27))
	part(elevator, "BackWall", Vector3.new(22, 16, 1), CFrame.new(0, 8, 8.5), Color3.fromRGB(46, 51, 58))
	part(elevator, "LeftWall", Vector3.new(1, 16, 18), CFrame.new(-10.5, 8, 0), Color3.fromRGB(46, 51, 58))
	part(elevator, "RightWall", Vector3.new(1, 16, 18), CFrame.new(10.5, 8, 0), Color3.fromRGB(46, 51, 58))
	local leftDoor = part(elevator, "DoorLeft", Vector3.new(10, 12, 1), CFrame.new(-5, 7, -8.5), Color3.fromRGB(57, 64, 72))
	local rightDoor = part(elevator, "DoorRight", Vector3.new(10, 12, 1), CFrame.new(5, 7, -8.5), Color3.fromRGB(57, 64, 72))
	local sign = part(elevator, "FloorDisplay", Vector3.new(8, 2, 0.5), CFrame.new(0, 12, 8), CYAN, Enum.Material.Neon)
	label(sign, "LAST STOP", sign.CFrame, Color3.fromRGB(15, 25, 29))
	local queueConsole = part(lobby, "QueueConsole", Vector3.new(5, 4, 3), CFrame.new(28, 3, 10), CYAN, Enum.Material.Metal)
	label(queueConsole, "PLAY", queueConsole.CFrame, CYAN)
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Queue Expedition"
	prompt.ObjectText = "Last Stop Terminal"
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 12
	prompt.Parent = queueConsole
	self.lobby = {
		Model = lobby,
		QueuePrompt = prompt,
		BoardCFrame = CFrame.new(0, 5, 0),
		LobbySpawn = CFrame.new(0, 5, 25),
		BoardRegionCFrame = CFrame.new(0, 6, 0),
		BoardRegionSize = Vector3.new(20, 12, 16),
		Doors = { Left = leftDoor, Right = rightDoor },
		DoorOpen = { Left = CFrame.new(-14, 7, -8.5), Right = CFrame.new(14, 7, -8.5) },
		DoorClosed = { Left = leftDoor.CFrame, Right = rightDoor.CFrame },
		Display = sign,
	}
	self:_decorateLobby(lobby, elevator)
	self:SetLobbyElevator(true, "LAST STOP")
	return self.lobby
end

-- This is runtime-authored on purpose: FloorService owns LastStopWorld and
-- safely clears/rebuilds it every server start. Handmade scene geometry would
-- otherwise be deleted by the lifecycle cleanup.
function FloorService:_decorateLobby(lobby, elevator)
	local architecture = Instance.new("Model")
	architecture.Name = "ArtDirectedConcourse"
	architecture.Parent = lobby

	-- Layered floor: inset steel panels, amber platform edge and a rail trench.
	part(architecture, "ConcourseSurface", Vector3.new(116, 0.22, 84), CFrame.new(0, 1.1, 0), PALETTE.Concrete, Enum.Material.Concrete)
	for x = -52, 52, 13 do
		for z = -30, 34, 16 do
			local panel = part(architecture, "FloorPlate", Vector3.new(11.4, 0.12, 13.6), CFrame.new(x, 1.28, z), Color3.fromRGB(41, 50, 56), Enum.Material.Metal)
			panel.Reflectance = 0.03
		end
	end
	part(architecture, "PlatformEdge", Vector3.new(112, 0.16, 1.2), CFrame.new(0, 1.35, -26), PALETTE.Amber, Enum.Material.Neon, { CanCollide = false })
	part(architecture, "PlatformEdgeInset", Vector3.new(112, 0.16, 2.1), CFrame.new(0, 1.22, -28), Color3.fromRGB(30, 35, 39), Enum.Material.Metal)
	for x = -54, 54, 6 do
		part(architecture, "RailSleeper", Vector3.new(3.2, 0.45, 7.5), CFrame.new(x, 1.32, -35), Color3.fromRGB(48, 40, 34), Enum.Material.WoodPlanks)
	end
	for _, z in ipairs({ -33, -37 }) do
		local rail = part(architecture, "Rail", Vector3.new(112, 0.26, 0.32), CFrame.new(0, 1.7, z), PALETTE.Steel, Enum.Material.Metal)
		rail.Reflectance = 0.12
	end
	part(architecture, "TrackVoid", Vector3.new(116, 3.2, 13), CFrame.new(0, -0.15, -35), Color3.fromRGB(13, 18, 23), Enum.Material.Slate)

	-- The concourse shell is deliberately multi-layered: primary walls, recessed
	-- panels, ceiling coffers, beams, lamps, vents, pipes and cable trays.
	part(architecture, "Ceiling", Vector3.new(120, 1.4, 90), CFrame.new(0, 23, 0), PALETTE.VoidNavy, Enum.Material.Metal)
	for _, x in ipairs({ -55, -33, -11, 11, 33, 55 }) do
		part(architecture, "CeilingBeam", Vector3.new(2.4, 2.2, 86), CFrame.new(x, 21.5, 0), Color3.fromRGB(36, 46, 53), Enum.Material.Metal)
	end
	for _, z in ipairs({ -38, -13, 12, 37 }) do
		part(architecture, "CeilingRib", Vector3.new(112, 1.1, 1.2), CFrame.new(0, 21.8, z), Color3.fromRGB(35, 45, 52), Enum.Material.Metal)
	end
	for _, x in ipairs({ -50, -25, 0, 25, 50 }) do
		industrialLamp(architecture, Vector3.new(x, 19.8, 16), PALETTE.OffWhite, 1.45, 19)
		industrialLamp(architecture, Vector3.new(x, 19.8, -8), Color3.fromRGB(127, 202, 208), 1.1, 16)
	end

	part(architecture, "WestStructuralWall", Vector3.new(3, 22, 88), CFrame.new(-58, 11, 0), Color3.fromRGB(31, 40, 46), Enum.Material.Concrete)
	part(architecture, "EastStructuralWall", Vector3.new(3, 22, 88), CFrame.new(58, 11, 0), Color3.fromRGB(31, 40, 46), Enum.Material.Concrete)
	part(architecture, "RearStructuralWall", Vector3.new(116, 22, 3), CFrame.new(0, 11, -43), Color3.fromRGB(30, 38, 44), Enum.Material.Concrete)
	for _, x in ipairs({ -50, -35, -20, 20, 35, 50 }) do
		part(architecture, "SupportColumn", Vector3.new(3.2, 19, 3.2), CFrame.new(x, 10.5, -17), Color3.fromRGB(49, 59, 64), Enum.Material.Metal)
		part(architecture, "ColumnBase", Vector3.new(4.4, 0.7, 4.4), CFrame.new(x, 1.65, -17), Color3.fromRGB(25, 31, 36), Enum.Material.Metal)
		part(architecture, "ColumnBand", Vector3.new(3.45, 0.45, 3.45), CFrame.new(x, 11, -17), PALETTE.Amber, Enum.Material.Neon, { CanCollide = false })
	end
	for _, x in ipairs({ -43, -24, 24, 43 }) do
		wallPanel(architecture, Vector3.new(x, 9, -41.35), 13, 12, CFrame.new(), x < 0 and "SERVICE / 07" or "NORTHBOUND")
	end
	for _, z in ipairs({ -26, -2, 22 }) do
		wallPanel(architecture, Vector3.new(-56.35, 8, z), 13, 10, CFrame.Angles(0, math.rad(90), 0), nil)
		wallPanel(architecture, Vector3.new(56.35, 8, z), 13, 10, CFrame.Angles(0, math.rad(-90), 0), nil)
	end

	-- Transit props: benches, gates, console bank, barriers, bins, service pipe,
	-- ventilation and cable hardware all use controlled primitive geometry.
	bench(architecture, Vector3.new(-37, 2.6, 25), CFrame.Angles(0, math.rad(180), 0))
	bench(architecture, Vector3.new(37, 2.6, 25), CFrame.Angles(0, math.rad(180), 0))
	bench(architecture, Vector3.new(-38, 2.6, -8), CFrame.new())
	for _, x in ipairs({ -20, -14, 14, 20 }) do
		local gate = part(architecture, "TicketGate", Vector3.new(2.3, 3, 2.6), CFrame.new(x, 2.55, 31), Color3.fromRGB(39, 53, 60), Enum.Material.Metal)
		local reader = part(architecture, "GateReader", Vector3.new(0.7, 0.32, 0.65), CFrame.new(x, 4.1, 30.45), CYAN, Enum.Material.Neon, { CanCollide = false })
		local gateLight = Instance.new("PointLight")
		gateLight.Color = CYAN
		gateLight.Range = 6
		gateLight.Brightness = 0.45
		gateLight.Parent = reader
	end
	for _, x in ipairs({ -47, 47 }) do
		local bin = part(architecture, "WasteBin", Vector3.new(2.3, 3.4, 2.3), CFrame.new(x, 2.85, 12), Color3.fromRGB(35, 45, 49), Enum.Material.Metal)
		part(architecture, "WasteBinLid", Vector3.new(2.6, 0.25, 2.6), bin.CFrame * CFrame.new(0, 1.82, 0), PALETTE.Steel, Enum.Material.Metal)
	end
	for _, x in ipairs({ -48, 48 }) do
		local barrier = part(architecture, "MaintenanceBarrier", Vector3.new(9, 2.8, 0.35), CFrame.new(x, 2.6, -24), PALETTE.Amber, Enum.Material.Metal)
		for stripe = -3, 3, 2 do
			part(architecture, "BarrierStripe", Vector3.new(0.65, 2.65, 0.08), barrier.CFrame * CFrame.new(stripe, 0, -0.23) * CFrame.Angles(0, 0, math.rad(35)), PALETTE.VoidNavy, Enum.Material.SmoothPlastic, { CanCollide = false })
		end
	end
	pipeRun(architecture, Vector3.new(-48, 18.5, 35), 66, "X", Color3.fromRGB(85, 98, 99))
	pipeRun(architecture, Vector3.new(48, 18, -4), 53, "Z", Color3.fromRGB(69, 82, 89))
	for _, x in ipairs({ -40, -8, 8, 40 }) do
		local vent = part(architecture, "CeilingVent", Vector3.new(9, 0.28, 4), CFrame.new(x, 21.15, 35), Color3.fromRGB(31, 40, 45), Enum.Material.Metal)
		for blade = -3, 3, 1.5 do
			part(architecture, "VentSlat", Vector3.new(0.15, 0.18, 3.3), vent.CFrame * CFrame.new(blade, -0.22, 0), PALETTE.Steel, Enum.Material.Metal, { CanCollide = false })
		end
	end

	-- The elevator gets a separate hero treatment: threshold, layered frame,
	-- recessed ceiling, physical button pedestal, floor indicator and sign.
	local frame = Instance.new("Model")
	frame.Name = "ElevatorHeroDetail"
	frame.Parent = elevator
	part(frame, "Threshold", Vector3.new(25, 0.3, 2), CFrame.new(0, 1.32, -9.1), PALETTE.Steel, Enum.Material.Metal)
	part(frame, "DoorHeader", Vector3.new(26, 2.1, 1.4), CFrame.new(0, 14.9, -8.9), Color3.fromRGB(34, 45, 52), Enum.Material.Metal)
	part(frame, "OuterFrameLeft", Vector3.new(2.2, 15, 1.1), CFrame.new(-12, 8, -8.8), Color3.fromRGB(39, 51, 58), Enum.Material.Metal)
	part(frame, "OuterFrameRight", Vector3.new(2.2, 15, 1.1), CFrame.new(12, 8, -8.8), Color3.fromRGB(39, 51, 58), Enum.Material.Metal)
	part(frame, "CabinCeiling", Vector3.new(20, 0.65, 15), CFrame.new(0, 15.2, 0), Color3.fromRGB(24, 31, 37), Enum.Material.Metal)
	for _, x in ipairs({ -6, 0, 6 }) do
		industrialLamp(frame, Vector3.new(x, 14.7, 0), PALETTE.OffWhite, 1.0, 10)
	end
	for _, x in ipairs({ -8, -4, 4, 8 }) do
		part(frame, "FloorInlay", Vector3.new(2.4, 0.11, 13), CFrame.new(x, 1.52, 0), Color3.fromRGB(30, 39, 44), Enum.Material.Metal, { CanCollide = false })
	end
	local displayHousing = part(frame, "FloorIndicatorHousing", Vector3.new(7.2, 2.7, 0.45), CFrame.new(0, 12.5, 8.05), Color3.fromRGB(20, 28, 33), Enum.Material.Metal)
	surfaceText(displayHousing, Enum.NormalId.Back, "LAST\nSTOP", CYAN, 46)
	local buttonPedestal = part(frame, "CallPanelHousing", Vector3.new(1.5, 4.6, 0.6), CFrame.new(8.8, 6, -6.9), Color3.fromRGB(43, 52, 57), Enum.Material.Metal)
	local emergencyButton = part(frame, "EmergencyButton", Vector3.new(0.72, 0.72, 0.16), CFrame.new(8.8, 6.6, -7.28), RED, Enum.Material.Neon, { CanCollide = false })
	local callButton = part(frame, "CallButton", Vector3.new(0.72, 0.72, 0.16), CFrame.new(8.8, 5.1, -7.28), CYAN, Enum.Material.Neon, { CanCollide = false })
	surfaceText(buttonPedestal, Enum.NormalId.Front, "HELP\n  ◉\n  ◌", PALETTE.OffWhite, 20)
	for _, side in ipairs({ -1, 1 }) do
		local stripe = part(frame, "SafetyStripe", Vector3.new(0.7, 11.2, 0.12), CFrame.new(side * 10.25, 7, -9.08), PALETTE.Amber, Enum.Material.Neon, { CanCollide = false })
		stripe.Transparency = 0.18
	end

	local routeSign = part(architecture, "RouteSign", Vector3.new(34, 3.8, 0.45), CFrame.new(0, 17, 24), Color3.fromRGB(20, 31, 37), Enum.Material.Metal)
	surfaceText(routeSign, Enum.NormalId.Front, "LAST STOP  //  PLATFORM  01", PALETTE.OffWhite, 42)
	local signLight = Instance.new("SurfaceLight")
	signLight.Face = Enum.NormalId.Front
	signLight.Color = CYAN
	signLight.Range = 10
	signLight.Brightness = 0.55
	signLight.Parent = routeSign

	-- These material tags are inert until ArtTheme contains verified Roblox
	-- image IDs. PbrMaterialService resolves them into MaterialVariants after
	-- BuildWorld, keeping the runtime geometry and asset pipeline reproducible.
	local concreteSurfaces = {
		ConcourseSurface = true,
		WestStructuralWall = true,
		EastStructuralWall = true,
		RearStructuralWall = true,
	}
	local metalSurfaces = {
		FloorPlate = true,
		CabinFloor = true,
		BackWall = true,
		LeftWall = true,
		RightWall = true,
		DoorLeft = true,
		DoorRight = true,
		Threshold = true,
		DoorHeader = true,
		OuterFrameLeft = true,
		OuterFrameRight = true,
		CabinCeiling = true,
		FloorInlay = true,
	}
	for _, descendant in ipairs(lobby:GetDescendants()) do
		if descendant:IsA("BasePart") then
			if concreteSurfaces[descendant.Name] then
				descendant:SetAttribute("PbrMaterial", "ChippedConcrete")
			elseif metalSurfaces[descendant.Name] then
				descendant:SetAttribute("PbrMaterial", "MetalPlate")
			end
		end
	end
	architecture:SetAttribute("PropTypes", 22)
end

function FloorService:SetLobbyElevator(open, displayText)
	if not self.lobby then return end
	local target = open and self.lobby.DoorOpen or self.lobby.DoorClosed
	for side, door in pairs(self.lobby.Doors) do
		TweenService:Create(door, TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target[side] }):Play()
	end
	local sign = self.lobby.Display
	local board = sign and sign:FindFirstChildOfClass("BillboardGui")
	local text = board and board:FindFirstChildOfClass("TextLabel")
	if text and displayText then
		text.Text = displayText
	end
end

function FloorService:CreateRoom(definition, seed)
	return RoomRuntime.new(self, definition, seed)
end

return FloorService
