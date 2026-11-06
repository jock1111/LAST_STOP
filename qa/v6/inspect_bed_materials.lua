local Workspace = game:GetService("Workspace")
local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local active = runtime and runtime:FindFirstChild("ActiveExpedition")
local floor
for _, child in ipairs(active and active:GetChildren() or {}) do
	if child:IsA("Model") and child:GetAttribute("FloorTheme") then floor = child; break end
end
assert(floor, "no floor")

local materialNames = {}
for _, item in ipairs(Enum.Material:GetEnumItems()) do
	materialNames[item.Value] = item.Name
end

local beds = {}
for _, value in ipairs(floor:GetDescendants()) do
	if value:IsA("BasePart") and (value.Name == "Mattress" or value.Name == "Undercarriage" or value.Name == "FoldedBlanket") then
		table.insert(beds, {
			name = value.Name,
			material = tostring(value.Material),
			materialValue = value.Material.Value,
			materialName = materialNames[value.Material.Value] or "?",
			materialVariant = value.MaterialVariant,
			color = tostring(value.Color),
			size = tostring(value.Size),
		})
		if #beds >= 9 then break end
	end
end

return { beds = beds, materials = materialNames }
