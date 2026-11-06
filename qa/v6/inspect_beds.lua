local Workspace = game:GetService("Workspace")
local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local active = runtime and runtime:FindFirstChild("ActiveExpedition")
local floor
for _, child in ipairs(active and active:GetChildren() or {}) do
	if child:IsA("Model") and child:GetAttribute("FloorTheme") then floor = child; break end
end
assert(floor, "no floor")

local beds = {}
for _, value in ipairs(floor:GetDescendants()) do
	if value:IsA("Model") and value.Name == "PatientBed" then
		local parts = {}
		for _, part in ipairs(value:GetChildren()) do
			if part:IsA("BasePart") then
				local pbr = part:FindFirstChild("PbrMaterial")
				table.insert(parts, {
					name = part.Name,
					size = tostring(part.Size),
					position = tostring(part.Position),
					material = tostring(part.Material),
					variant = part.MaterialVariant,
					color = tostring(part.Color),
					pbr = pbr and pbr.Value or nil,
				})
			end
		end
		table.insert(beds, { position = tostring(value:GetPivot().Position), parts = parts })
	end
end
return beds
