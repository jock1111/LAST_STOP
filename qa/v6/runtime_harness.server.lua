-- QA-only harness. Inserted into the Studio place for the V6 acceptance run and
-- never included in the Rojo source tree. It does not write profiles or assets.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local LogService = game:GetService("LogService")
local HttpService = game:GetService("HttpService")

local report = {
	startedAt = os.time(),
	checks = {},
	events = {},
	travelSamples = {},
	floorSnapshots = {},
	cycles = {},
}
local results = Instance.new("StringValue")
results.Name = "QA_V6_Results"
results.Parent = ReplicatedStorage

local function save()
	results.Value = HttpService:JSONEncode(report)
end

local function check(name, ok, detail)
	table.insert(report.checks, { name = name, ok = ok and true or false, detail = tostring(detail or "") })
	print(string.format("[QA_V6] %s %s :: %s", ok and "PASS" or "FAIL", name, tostring(detail or "")))
	save()
end

local world = workspace:WaitForChild("LastStopWorld", 30)
local runtime = world and world:WaitForChild("Runtime", 15)
local active = runtime and runtime:WaitForChild("ActiveExpedition", 15)
local lobby = runtime and runtime:WaitForChild("Lobby", 15)
check("Runtime lobby present", lobby ~= nil, lobby and lobby:GetFullName() or "missing")
if not lobby then
	report.finished = true
	save()
	return
end

-- Force the hospital template for visual acceptance while keeping every
-- objective/route seed and gameplay path untouched.
local floorConfig = require(ReplicatedStorage.Shared.Config.FloorConfig)
for _, floor in ipairs(floorConfig.Floors) do
	floor.Weight = floor.Template == "Hospital" and 100 or 0
end
check("Hospital template forced for visual run", true, "weights Hospital=100, others=0")

local elevator = lobby:WaitForChild("CentralElevator", 15)
local display = elevator and elevator:WaitForChild("FloorDisplay", 10)
local left = elevator and elevator:WaitForChild("DoorLeft", 10)
local right = elevator and elevator:WaitForChild("DoorRight", 10)
local zone = elevator and elevator:FindFirstChild("ElevatorReturnZone", true)
check("Elevator display/doors/zone", display and left and right and zone,
	string.format("display=%s left=%s right=%s zone=%s", tostring(display ~= nil), tostring(left ~= nil), tostring(right ~= nil), tostring(zone ~= nil)))
if not (display and left and right and zone) then
	report.finished = true
	save()
	return
end

task.wait(2) -- Let the initial open tween finish before measuring.

local FloorService = require(ServerScriptService.Services.FloorService)
local qa = FloorService.new({ WorldName = "LastStopV6IndicatorQA" })
local openLeft, openRight = left.CFrame, right.CFrame
qa.lobby = {
	Model = lobby,
	Doors = { Left = left, Right = right },
	DoorClosed = { Left = openLeft * CFrame.new(9.8, 0, 0), Right = openRight * CFrame.new(-9.8, 0, 0) },
	DoorOpen = { Left = openLeft, Right = openRight },
	Display = display,
	BoardRegionCFrame = zone.CFrame,
	BoardRegionSize = zone.Size,
}
for i = 1, 3 do
	local dot = elevator:FindFirstChild("IndicatorDot" .. i, true)
	local ring = elevator:FindFirstChild("IndicatorRing" .. i, true)
	if dot then table.insert(qa._indicatorDots, dot) end
	if ring then table.insert(qa._indicatorRings, ring) end
end
check("Three indicator dots and rings", #qa._indicatorDots == 3 and #qa._indicatorRings == 3,
	string.format("dots=%d rings=%d", #qa._indicatorDots, #qa._indicatorRings))

local amber = Color3.fromRGB(246, 168, 66)
local cyan = Color3.fromRGB(92, 210, 202)
local dark = Color3.fromRGB(24, 36, 44)
local function colorName(color)
	if color == amber then return "amber" end
	if color == cyan then return "cyan" end
	if color == dark then return "dark" end
	return tostring(color)
end
local function dotColors()
	local values = {}
	for i = 1, 3 do
		local dot = qa._indicatorDots[i]
		values[i] = dot and colorName(dot.Color) or "missing"
	end
	return table.concat(values, ",")
end
local function ringTransparency()
	local values = {}
	for i = 1, 3 do
		local ring = qa._indicatorRings[i]
		values[i] = ring and string.format("%.2f", ring.Transparency) or "missing"
	end
	return table.concat(values, ",")
end
local function allColorsValid()
	for i = 1, 3 do
		local dot, ring = qa._indicatorDots[i], qa._indicatorRings[i]
		if not dot or typeof(dot.Color) ~= "Color3" then return false, "dot " .. i end
		if ring and typeof(ring.Color) ~= "Color3" then return false, "ring " .. i end
	end
	return true, "all Color3"
end
local function displayText()
	for _, value in ipairs(display:GetDescendants()) do
		if value:IsA("TextLabel") then return value.Text end
	end
	return ""
end
local function doorOffsets()
	return (left.CFrame.Position - qa.lobby.DoorClosed.Left.Position).Magnitude,
		(right.CFrame.Position - qa.lobby.DoorClosed.Right.Position).Magnitude
end
local function currentFloor()
	for _, child in ipairs(active:GetChildren()) do
		if child:IsA("Model") and child:GetAttribute("FloorTheme") then return child end
	end
	return nil
end

-- ---------------------------------------------------------------- unit checks
qa:SetLobbyElevator(true, "QA OPEN")
task.wait(1.2)
local openText = displayText()
local openValid, openDetail = allColorsValid()
local openLeftOffset, openRightOffset = doorOffsets()
check("OPEN display text", openText == "QA OPEN", openText)
check("OPEN indicator mode", qa._indicatorMode == "open", qa._indicatorMode)
check("OPEN dot colours", dotColors() == "amber,dark,dark", dotColors())
check("OPEN colours are Color3", openValid, openDetail)
check("OPEN doors displaced from closed", openLeftOffset > 9.5 and openRightOffset > 9.5,
	string.format("left=%.2f right=%.2f", openLeftOffset, openRightOffset))

qa:SetLobbyElevator(false, "QA TRAVEL")
task.wait(0.2)
local travelText = displayText()
local travelColors1 = dotColors()
task.wait(0.35)
local travelColors2 = dotColors()
local travelValid, travelDetail = allColorsValid()
local travelPaletteOk = true
for i = 1, 3 do
	local color = qa._indicatorDots[i] and qa._indicatorDots[i].Color
	if color ~= amber and color ~= cyan then travelPaletteOk = false end
end
check("TRAVEL display text", travelText == "QA TRAVEL", travelText)
check("TRAVEL indicator mode", qa._indicatorMode == "travel", qa._indicatorMode)
check("TRAVEL chase changes colours", travelColors1 ~= travelColors2, travelColors1 .. " -> " .. travelColors2)
check("TRAVEL colours are Color3", travelValid, travelDetail)
check("TRAVEL palette only amber/cyan", travelPaletteOk, dotColors())
task.wait(1.2)
local closedLeftOffset, closedRightOffset = doorOffsets()
check("TRAVEL doors closed", closedLeftOffset < 0.2 and closedRightOffset < 0.2,
	string.format("left=%.2f right=%.2f", closedLeftOffset, closedRightOffset))

-- A stale travel task must not overwrite a newer OPEN state or its display.
qa:SetLobbyElevator(false, "QA RACE TRAVEL A")
task.wait(0.1)
qa:SetLobbyElevator(true, "QA RACE OPEN")
task.wait(2.0)
check("Race A display preserved", displayText() == "QA RACE OPEN", displayText())
check("Race A mode open", qa._indicatorMode == "open", qa._indicatorMode)
check("Race A steady colours", dotColors() == "amber,dark,dark", dotColors())

-- Two stale travel tasks must not overwrite the newest TRAVEL state.
qa:SetLobbyElevator(false, "QA RACE TRAVEL B")
task.wait(0.1)
qa:SetLobbyElevator(true, "QA RACE OPEN B")
task.wait(0.1)
qa:SetLobbyElevator(false, "QA RACE CLOSED B")
task.wait(2.0)
local raceValid, raceDetail = allColorsValid()
check("Race B display preserved", displayText() == "QA RACE CLOSED B", displayText())
check("Race B mode travel", qa._indicatorMode == "travel", qa._indicatorMode)
check("Race B colours are Color3", raceValid, raceDetail)

-- Hand the live doors back to the real service in its normal idle state.
qa:SetLobbyElevator(true, "B0 / CONCOURSE")
task.wait(1.0)
check("Lobby restored to idle", displayText() == "B0 / CONCOURSE", displayText())

-- ------------------------------------------------------------- live monitoring
local control = Instance.new("RemoteEvent")
control.Name = "QA_V6_Control"
control.Parent = ReplicatedStorage
control.OnServerEvent:Connect(function(player, action, label)
	if action == "kill" then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.Health = 0 end
	elseif action == "cycle" then
		table.insert(report.cycles, { t = math.floor(os.clock() * 100) / 100, label = tostring(label or "") })
		save()
	elseif action == "regressions" then
		if report.regressions and report.regressions.startedAt then return end
		report.regressions = { startedAt = os.time() }
		save()
		task.spawn(function()
			local specs = {
				{ name = "GameplayRecoverySpec", module = script.Parent.Tests.GameplayRecoverySpec },
				{ name = "TrainHazardSpec", module = script.Parent.Tests.TrainHazardSpec },
			}
			for _, spec in ipairs(specs) do
				local loaded, specFunction = pcall(require, spec.module)
				if not loaded then
					report.regressions[spec.name] = { pass = false, error = tostring(specFunction) }
					check(spec.name, false, "load failed: " .. tostring(specFunction))
				else
					local ran, value = pcall(specFunction)
					local passed = ran and type(value) == "table" and value.pass == true
					local detail, errorText
					if ran and type(value) == "table" then
						detail, errorText = value.error or "completed", value.error
					else
						detail, errorText = tostring(value), tostring(value)
					end
					report.regressions[spec.name] = { pass = passed, error = errorText }
					check(spec.name, passed, detail)
				end
				save()
			end
			report.regressions.finished = true
			save()
			print("[QA_V6] regressions finished")
		end)
	elseif action == "finish" then
		local errors = {}
		local cutoff = report.startedAt * 1000 - 5000
		for _, entry in ipairs(LogService:GetLogHistory()) do
			if entry.messageType == Enum.MessageType.MessageError and entry.timestamp >= cutoff then
				local message = tostring(entry.message)
				if not message:find("ProfileService") and not message:find("DataStore") and not message:find("QA_V6") then
					table.insert(errors, message)
				end
			end
		end
		report.errors = errors
		check("No unexpected Output errors", #errors == 0, #errors .. " error(s)")
		report.finished = true
		report.finishedAt = os.time()
		save()
	end
end)
report.controlReady = true
save()

local lastDisplay, lastFloorName = nil, nil
local lastTravelSequence = nil
local monitorStop = false
task.spawn(function()
	while not monitorStop do
		local floorModel = currentFloor()
		local text = displayText()
		local floorName = floorModel and floorModel.Name or nil
		if text ~= lastDisplay or floorName ~= lastFloorName then
			lastDisplay, lastFloorName = text, floorName
			table.insert(report.events, {
				t = math.floor(os.clock() * 10) / 10,
				display = text,
				floor = floorName,
				dots = dotColors(),
			})
			if floorModel then
				table.insert(report.floorSnapshots, {
					name = floorModel.Name,
					theme = floorModel:GetAttribute("FloorTheme"),
					pivot = tostring(floorModel:GetPivot().Position),
					children = #floorModel:GetDescendants(),
				})
			end
			save()
		end
		if text:find("DESCENDING") or text:find("TRAVEL") then
			local sequence = dotColors()
			if sequence ~= lastTravelSequence then
				lastTravelSequence = sequence
				if #report.travelSamples < 40 then
					table.insert(report.travelSamples, {
						t = math.floor(os.clock() * 100) / 100,
						display = text,
						dots = sequence,
						rings = ringTransparency(),
					})
					save()
				end
			end
		end
		task.wait(0.1)
	end
end)

print("[QA_V6] harness ready")
