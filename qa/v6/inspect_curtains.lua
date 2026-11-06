local Workspace = game:GetService("Workspace")
local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local active = runtime and runtime:FindFirstChild("ActiveExpedition")
local floor
for _, child in ipairs(active and active:GetChildren() or {}) do
	if child:IsA("Model") and child:GetAttribute("FloorTheme") then floor = child; break end
end
assert(floor, "no floor")

local results = {}
for _, value in ipairs(floor:GetDescendants()) do
	if value:IsA("BasePart") and (value.Name == "CurtainTrack" or value.Name == "FadedCurtainFold" or value.Name:find("Curtain")) then
		table.insert(results, {
			name = value.Name,
			size = tostring(value.Size),
			position = tostring(value.Position),
			material = tostring(value.Material),
			color = tostring(value.Color),
			transparency = value.Transparency,
			canCollide = value.CanCollide,
			parent = value.Parent and value.Parent.Name,
			pbr = value:GetAttribute("PbrMaterial") or (value:FindFirstChild("PbrMaterial") and "StringValue"),
		})
	end
end
return { count = #results, parts = results }
