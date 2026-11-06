local Workspace = game:GetService("Workspace")
local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local active = runtime and runtime:FindFirstChild("ActiveExpedition")
local floor
for _, child in ipairs(active and active:GetChildren() or {}) do
	if child:IsA("Model") and child:GetAttribute("FloorTheme") then floor = child; break end
end
assert(floor, "no floor")

local function bounds(instance)
	local min, max
	for _, value in ipairs(instance:GetDescendants()) do
		if value:IsA("BasePart") then
			local p = value.Position
			min = min and Vector3.new(math.min(min.X, p.X), math.min(min.Y, p.Y), math.min(min.Z, p.Z)) or p
			max = max and Vector3.new(math.max(max.X, p.X), math.max(max.Y, p.Y), math.max(max.Z, p.Z)) or p
		end
	end
	if not min then return nil end
	return tostring((min + max) * 0.5), tostring(max - min)
end

local top = {}
for _, child in ipairs(floor:GetChildren()) do
	table.insert(top, child.ClassName .. " / " .. child.Name)
end

local rooms = {}
local roomsFolder = floor:FindFirstChild("Rooms")
if roomsFolder then
	for _, child in ipairs(roomsFolder:GetChildren()) do
		local center, size = bounds(child)
		table.insert(rooms, { name = child.Name, center = center, size = size, descendants = #child:GetDescendants() })
	end
end

local markers = {}
local markerFolder = floor:FindFirstChild("Markers")
if markerFolder then
	for _, child in ipairs(markerFolder:GetChildren()) do
		if child:IsA("BasePart") then
			table.insert(markers, { name = child.Name, position = tostring(child.Position), size = tostring(child.Size) })
		end
	end
end

local function findPart(name)
	local value = floor:FindFirstChild(name, true)
	if not value then return nil end
	local center, size = bounds(value)
	return { className = value.ClassName, name = value.Name, center = center, size = size }
end

return {
	top = top,
	rooms = rooms,
	markers = markers,
	spawn = findPart("EntranceSpawn"),
	identifier = findPart("HospitalIdentifier"),
	nurses = findPart("NursesStation"),
	wardBed = findPart("PatientBed"),
	curtainTrack = findPart("CurtainTrack"),
}
