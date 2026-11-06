local Workspace = game:GetService("Workspace")
local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local active = runtime and runtime:FindFirstChild("ActiveExpedition")
local floor
for _, child in ipairs(active and active:GetChildren() or {}) do
	if child:IsA("Model") and child:GetAttribute("FloorTheme") then floor = child; break end
end
assert(floor, "no floor")

local curtains = {}
local discharge
local undercarriage
local blanket
local overhead = {}
for _, value in ipairs(floor:GetDescendants()) do
	if value:IsA("BasePart") then
		if value.Name == "PrivacyCurtain" or value.Name == "CurtainPleat" or value.Name == "CurtainHem" or value.Name == "CurtainTrack" then
			table.insert(curtains, {
				name = value.Name,
				size = tostring(value.Size),
				position = tostring(value.Position),
				material = tostring(value.Material),
				transparency = value.Transparency,
				color = tostring(value.Color),
				canCollide = value.CanCollide,
				canQuery = value.CanQuery,
			})
		elseif value.Name == "Wayfinding" and value.Parent and value.Parent.Name == "ClinicalDressing" then
			discharge = {
				position = tostring(value.Position),
				size = tostring(value.Size),
				cframe = tostring(value.CFrame),
				text = value:FindFirstChildOfClass("SurfaceGui") and value:FindFirstChildOfClass("SurfaceGui"):FindFirstChildOfClass("TextLabel").Text or nil,
			}
		elseif value.Name == "Undercarriage" then
			undercarriage = { material = tostring(value.Material), variant = value.MaterialVariant, pbr = value:FindFirstChild("PbrMaterial") and value.PbrMaterial.Value or nil }
		elseif value.Name == "FoldedBlanket" then
			blanket = { material = tostring(value.Material), color = tostring(value.Color) }
		elseif value.Name == "OverheadWayfinding" then
			table.insert(overhead, { position = tostring(value.Position), size = tostring(value.Size) })
		end
	end
end

return {
	curtainCount = #curtains,
	curtains = curtains,
	discharge = discharge,
	undercarriage = undercarriage,
	blanket = blanket,
	overhead = overhead,
}
