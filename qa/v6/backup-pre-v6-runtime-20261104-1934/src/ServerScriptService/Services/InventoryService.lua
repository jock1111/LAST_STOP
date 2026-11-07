-- Minimal vertical-slice equipment: a real togglable flashlight and one server
-- validated medkit per expedition. Broader equipment ships in Milestone B.
local InventoryService = {}
InventoryService.__index = InventoryService

local function makeFlashlight()
	local tool = Instance.new("Tool")
	tool.Name = "LastStopFlashlight"
	tool.ToolTip = "Flashlight"
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.5, 0.5, 2)
	handle.Color = Color3.fromRGB(45, 52, 58)
	handle.Material = Enum.Material.Metal
	handle.Parent = tool
	local beam = Instance.new("SpotLight")
	beam.Name = "Beam"
	beam.Enabled = false
	beam.Angle = 55
	beam.Range = 45
	beam.Brightness = 2
	beam.Color = Color3.fromRGB(210, 245, 255)
	beam.Face = Enum.NormalId.Front
	beam.Parent = handle
	tool.Activated:Connect(function()
		beam.Enabled = not beam.Enabled
	end)
	return tool
end

function InventoryService.new()
	return setmetatable({ _medkits = {} }, InventoryService)
end

function InventoryService:BeginRun(player)
	self._medkits[player] = 1
	player:SetAttribute("LastStopMedkits", 1)
	local backpack = player:FindFirstChildOfClass("Backpack")
	if backpack and not backpack:FindFirstChild("LastStopFlashlight") then
		makeFlashlight().Parent = backpack
	end
end

function InventoryService:UseMedkit(player, allowed)
	if not allowed(player) then
		return false, "Medkits can only be used during a floor."
	end
	if (self._medkits[player] or 0) <= 0 then
		return false, "No medkits remaining."
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid.Health <= 0 or humanoid.Health >= humanoid.MaxHealth then
		return false, "You do not need a medkit yet."
	end
	self._medkits[player] -= 1
	player:SetAttribute("LastStopMedkits", self._medkits[player])
	humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + 35)
	return true, "Medkit used."
end

function InventoryService:EndRun(player)
	self._medkits[player] = nil
	player:SetAttribute("LastStopMedkits", nil)
	for _, container in ipairs({ player:FindFirstChildOfClass("Backpack"), player.Character }) do
		local tool = container and container:FindFirstChild("LastStopFlashlight")
		if tool then
			tool:Destroy()
		end
	end
end

return InventoryService
