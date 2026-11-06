local Workspace = game:GetService("Workspace")
local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local active = runtime and runtime:FindFirstChild("ActiveExpedition")
local floor
for _, child in ipairs(active and active:GetChildren() or {}) do
	if child:IsA("Model") and child:GetAttribute("FloorTheme") then floor = child; break end
end
assert(floor, "no floor")

local result = {}
for _, value in ipairs(floor:GetDescendants()) do
	if value:IsA("BasePart") and (value.Name == "FoldedBlanket" or value.Name == "Mattress" or value.Name == "BlanketStripe") then
		local pbr = value:FindFirstChild("PbrMaterial")
		table.insert(result, {
			name = value.Name,
			parent = value.Parent.Name,
			parentClass = value.Parent.ClassName,
			ancestors = value:GetFullName(),
			size = tostring(value.Size),
			position = tostring(value.Position),
			material = tostring(value.Material),
			variant = value.MaterialVariant,
			color = tostring(value.Color),
			pbr = pbr and pbr.Value or nil,
		})
	end
end
return result
