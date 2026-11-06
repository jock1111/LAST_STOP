-- Runs three real matchmaking/expedition cycles through the client remote.
-- The final cycle is left on the floor so visual QA can capture the hospital.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local remotes = ReplicatedStorage:WaitForChild("Remotes", 15)
local queue = remotes:WaitForChild("RequestQueue", 15)
local control = ReplicatedStorage:WaitForChild("QA_V6_Control", 15)
local world = Workspace:WaitForChild("LastStopWorld", 15)
local runtime = world:WaitForChild("Runtime", 15)
local active = runtime:WaitForChild("ActiveExpedition", 15)
local lobby = runtime:WaitForChild("Lobby", 15)
local elevator = lobby:WaitForChild("CentralElevator", 15)
local display = elevator:WaitForChild("FloorDisplay", 15)

local function displayText()
	for _, value in ipairs(display:GetDescendants()) do
		if value:IsA("TextLabel") then return value.Text end
	end
	return ""
end

local function dotColors()
	local values = {}
	for i = 1, 3 do
		local dot = elevator:FindFirstChild("IndicatorDot" .. i, true)
		values[i] = dot and tostring(dot.Color) or "missing"
	end
	return table.concat(values, ",")
end

local function doorPositions()
	local left = elevator:FindFirstChild("DoorLeft", true)
	local right = elevator:FindFirstChild("DoorRight", true)
	return left and tostring(left.Position) or "missing", right and tostring(right.Position) or "missing"
end

local function currentFloor()
	for _, child in ipairs(active:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("FloorTheme") then return child end
	end
	return nil
end

local function waitFor(predicate, seconds, label)
	local deadline = os.clock() + seconds
	while os.clock() < deadline do
		local value = predicate()
		if value then return value end
		task.wait(0.2)
	end
	error(("timeout waiting for %s (display=%s)"):format(label, displayText()))
end

local function waitForLiveCharacter()
	return waitFor(function()
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root then return root end
		return nil
	end, 20, "live character")
end

local cycles = {}
for cycle = 1, 3 do
	waitForLiveCharacter()
	-- Let the previous expedition fully release matchmaking before queueing.
	waitFor(function() return currentFloor() == nil end, 15, "empty active expedition")
	task.wait(1)

	local before = displayText()
	queue:FireServer()

	local boarding = waitFor(function()
		local text = displayText()
		if text == "BOARD NOW" or text == "DESCENDING" then return text end
		return nil
	end, 45, "boarding display")
	local boardingDots = dotColors()
	local boardingLeft, boardingRight = doorPositions()

	local floor = waitFor(currentFloor, 45, "floor spawn")
	local floorText = displayText()
	local floorDots = dotColors()
	local floorLeft, floorRight = doorPositions()
	local root = waitForLiveCharacter()

	local record = {
		cycle = cycle,
		before = before,
		boarding = boarding,
		boardingDots = boardingDots,
		boardingLeft = boardingLeft,
		boardingRight = boardingRight,
		floor = floor.Name,
		floorTheme = floor:GetAttribute("FloorTheme"),
		floorText = floorText,
		floorDots = floorDots,
		floorLeft = floorLeft,
		floorRight = floorRight,
		playerPosition = tostring(root.Position),
	}
	table.insert(cycles, record)
	control:FireServer("cycle", ("cycle-%d:%s:%s"):format(cycle, floor.Name, floorText))

	if cycle < 3 then
		control:FireServer("kill")
		waitFor(function()
			return currentFloor() == nil and #active:GetChildren() == 0
		end, 30, "lobby return")
		task.wait(2)
		record.returnedDisplay = displayText()
		record.returnedDots = dotColors()
		record.returnedLeft, record.returnedRight = doorPositions()
	end
end

return cycles
