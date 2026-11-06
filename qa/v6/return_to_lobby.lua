local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
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

control:FireServer("kill")
local deadline = os.clock() + 30
while os.clock() < deadline do
	local text = displayText()
	local empty = #active:GetChildren() == 0
	if empty and (text == "LAST STOP" or text == "B0 / CONCOURSE") then
		task.wait(1.5)
		local dots = {}
		for i = 1, 3 do
			local dot = elevator:FindFirstChild("IndicatorDot" .. i, true)
			dots[i] = dot and tostring(dot.Color) or "missing"
		end
		return { display = displayText(), dots = table.concat(dots, ","), activeChildren = #active:GetChildren() }
	end
	task.wait(0.2)
end
return { display = displayText(), activeChildren = #active:GetChildren(), timedOut = true }
