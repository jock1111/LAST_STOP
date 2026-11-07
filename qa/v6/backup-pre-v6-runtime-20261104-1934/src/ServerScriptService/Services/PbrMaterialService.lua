-- MaterialVariants are authored in default.project.json. BaseMaterial and map
-- properties require Studio/plugin capability and must never be written by a
-- live server script. Runtime only assigns the saved variant to cloned parts.
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
			assert(variant and variant:IsA("MaterialVariant"),
				("[LAST STOP] Missing saved MaterialService.%s; rebuild default.project.json"):format(name))
			-- Map reads are also Plugin-protected. The offline build audit checks IDs.
			configured[name] = true
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
			local tag = descendant:FindFirstChild("PbrMaterial")
			local materialName = descendant:GetAttribute("PbrMaterial") or (tag and tag.Value)
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
