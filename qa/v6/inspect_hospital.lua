local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local active = runtime and runtime:FindFirstChild("ActiveExpedition")
local floor
for _, child in ipairs(active and active:GetChildren() or {}) do
	if child:IsA("Model") and child:GetAttribute("FloorTheme") then floor = child; break end
end

local rooms = {}
if floor then
	for _, child in ipairs(floor:GetChildren()) do
		if child:IsA("Model") then
			local ok, pivot = pcall(function() return child:GetPivot() end)
			table.insert(rooms, {
				name = child.Name,
				pivot = ok and tostring(pivot.Position) or nil,
				parts = #child:GetDescendants(),
			})
		end
	end
end

local results = ReplicatedStorage:FindFirstChild("QA_V6_Results")
local lobby = runtime and runtime:FindFirstChild("Lobby")
local elevator = lobby and lobby:FindFirstChild("CentralElevator")
local display = elevator and elevator:FindFirstChild("FloorDisplay")
local displayText = ""
if display then
	for _, value in ipairs(display:GetDescendants()) do
		if value:IsA("TextLabel") then displayText = value.Text end
	end
end

local dots = {}
for i = 1, 3 do
	local dot = elevator and elevator:FindFirstChild("IndicatorDot" .. i, true)
	dots[i] = dot and tostring(dot.Color) or nil
end

return {
	floor = floor and floor.Name or nil,
	theme = floor and floor:GetAttribute("FloorTheme") or nil,
	rooms = rooms,
	display = displayText,
	dots = dots,
	results = results and results.Value or nil,
}
