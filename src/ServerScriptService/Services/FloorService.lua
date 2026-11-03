-- Builds original primitive-geometry rooms at runtime. This avoids unreviewed
-- free models and gives every floor a common lifecycle interface.
local TweenService = game:GetService("TweenService")

local FloorService = {}
FloorService.__index = FloorService

local CHARCOAL = Color3.fromRGB(37, 42, 49)
local CYAN = Color3.fromRGB(73, 212, 210)
local RED = Color3.fromRGB(220, 67, 67)

local function part(parent, name, size, cframe, color, material)
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
	instance.Parent = parent
	return instance
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
	self:SetLobbyElevator(true, "LAST STOP")
	return self.lobby
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
