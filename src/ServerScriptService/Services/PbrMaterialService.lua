-- Creates only verified, owner-uploaded PBR MaterialVariants. Empty entries in
-- ArtTheme are intentionally ignored: an unverified texture ID must never
-- become a production dependency.
local MaterialService = game:GetService("MaterialService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArtTheme = require(ReplicatedStorage.Shared.ArtTheme)

local PbrMaterialService = {}

local function validContentId(value)
	return typeof(value) == "string" and value ~= ""
end

local function isComplete(definition)
	return definition
		and validContentId(definition.ColorMap)
		and validContentId(definition.NormalMap)
		and validContentId(definition.RoughnessMap)
		and validContentId(definition.MetalnessMap)
end

function PbrMaterialService:Configure()
	local configured = {}
	for name, definition in pairs(ArtTheme.Pbr) do
		if isComplete(definition) then
			local variant = MaterialService:FindFirstChild(name)
			if variant and not variant:IsA("MaterialVariant") then
				warn(("[LAST STOP] Cannot create PBR material %s: name is already occupied."):format(name))
			elseif not variant then
				variant = Instance.new("MaterialVariant")
				variant.Name = name
				variant.Parent = MaterialService
			end

			if variant then
				variant.BaseMaterial = definition.BaseMaterial
				variant.ColorMap = definition.ColorMap
				variant.NormalMap = definition.NormalMap
				variant.RoughnessMap = definition.RoughnessMap
				variant.MetalnessMap = definition.MetalnessMap
				configured[name] = true
			end
		end
	end
	return configured
end

function PbrMaterialService:Apply(root)
	local configured = self:Configure()
	if not next(configured) then
		return false
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("BasePart") then
			local materialName = descendant:GetAttribute("PbrMaterial")
			local definition = materialName and ArtTheme.Pbr[materialName]
			if definition and configured[materialName] then
				descendant.Material = definition.BaseMaterial
				descendant.MaterialVariant = materialName
			end
		end
	end

	return true
end

return PbrMaterialService
