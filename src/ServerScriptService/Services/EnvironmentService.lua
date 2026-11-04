local ServerStorage = game:GetService("ServerStorage")
local Environment = {}
local cyan = Color3.fromRGB(92, 210, 202)
local amber = Color3.fromRGB(246, 168, 66)
local dark = Color3.fromRGB(24, 36, 44)
local meshLibrary

function Environment.Part(parent, name, size, cframe, color, material)
    local part = Instance.new("Part")
    part.Name, part.Size, part.CFrame = name, size, cframe
    part.Color, part.Material = color or dark, material or Enum.Material.Metal
    if part.Material == Enum.Material.Metal then part.MaterialVariant = "MetalPlate" end
    part.Anchored, part.TopSurface, part.BottomSurface = true, Enum.SurfaceType.Smooth, Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

function Environment.Mesh(parent, name, cframe, size)
    meshLibrary = meshLibrary or ServerStorage.LastStopAssets:WaitForChild("Environment")
    local source = meshLibrary:FindFirstChild(name, true)
    assert(source and source:IsA("MeshPart"), "Missing imported mesh " .. name)
    local mesh = source:Clone()
    mesh.Anchored, mesh.CanTouch = true, false
    mesh.CFrame = cframe
    if size then mesh.Size = size end
    if name == "floor-panel" or name == "wall" or name == "wall-window" or name == "rail" or name == "pipe" or name == "container" or name == "container-tall" then
        mesh.TextureID = ""
        mesh.Material, mesh.MaterialVariant = Enum.Material.Metal, "PaintedSteel"
        mesh.Color = Color3.fromRGB(145, 165, 171)
    end
    mesh.Parent = parent
    return mesh
end

function Environment.Sign(parent, text, position, size, color, yaw)
    local board = Environment.Part(parent, "Wayfinding", size or Vector3.new(12, 2, .12),
        CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0), dark)
    local gui = Instance.new("SurfaceGui")
    gui.Face, gui.CanvasSize, gui.LightInfluence = Enum.NormalId.Front, Vector2.new(1024, 160), .15
    gui.Parent = board
    local label = Instance.new("TextLabel")
    label.Size, label.BackgroundTransparency = UDim2.fromScale(1, 1), 1
    label.Font, label.TextScaled, label.Text = Enum.Font.GothamMedium, true, text
    label.TextColor3, label.Parent = color or cyan, gui
    return board
end

function Environment.Light(parent, position, color, range)
    local housing = Environment.Part(parent, "RecessedLuminaire", Vector3.new(5, .3, 1.2), CFrame.new(position), dark)
    local strip = Environment.Part(parent, "Diffuser", Vector3.new(4.5, .12, .7), CFrame.new(position - Vector3.new(0, .22, 0)), color, Enum.Material.Neon)
    strip.CanCollide = false
    local light = Instance.new("PointLight")
    light.Color, light.Brightness, light.Range, light.Shadows = color, 1.6, range or 22, false
    light.Parent = strip
    return housing
end

function Environment.UpgradeLobby(model)
    local art = Instance.new("Folder")
    art.Name, art.Parent = "ImportedConcourse", model
    for _, x in {-38, 38} do
        for z = -24, 24, 8 do
            local panel = Environment.Mesh(art, "wall-window", CFrame.new(x, 8, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(8, 16, 2.4))
            panel.CanCollide = false
        end
    end
    for _, x in {-25, 25} do
        Environment.Mesh(art, "display-wall-wide", CFrame.new(x, 6, -32), Vector3.new(12, 8, 3))
        Environment.Light(art, Vector3.new(x, 14, -24), cyan, 28)
        for z = -12, 12, 12 do
            Environment.Mesh(art, "container-tall", CFrame.new(x > 0 and 34 or -34, 3.6, z))
        end
    end
    Environment.Mesh(art, "computer-system", CFrame.new(14, 2.4, -11))
    model.QueueConsole.Transparency = 1
    for z = -8, 24, 8 do
        local floor = Environment.Mesh(art, "floor-panel", CFrame.new(0, -.4, z), Vector3.new(14, .8, 8))
        floor.CanCollide = false
    end
    Environment.Sign(art, "CONTAINMENT TRANSIT  /  AUTHORIZED CREW", Vector3.new(0, 13, -16), Vector3.new(25, 1.8, .15))
end

local function leak(parent, position, color)
    local source = Environment.Part(parent, "PipeLeak", Vector3.one * .1, CFrame.new(position))
    source.Transparency, source.CanCollide, source.CanQuery = 1, false, false
    local emitter = Instance.new("ParticleEmitter")
    emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
    emitter.Color, emitter.LightEmission = ColorSequence.new(color), .3
    emitter.Size = NumberSequence.new(.08)
    emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, .4), NumberSequenceKeypoint.new(1, 1)})
    emitter.Lifetime, emitter.Speed, emitter.Rate = NumberRange.new(.6, .9), NumberRange.new(9, 13), 12
    emitter.Acceleration, emitter.EmissionDirection = Vector3.new(0, -18, 0), Enum.NormalId.Bottom
    emitter.SpreadAngle, emitter.Parent = Vector2.new(3, 3), source
end

function Environment.UpgradeHospital(model)
    local origin = model:GetPivot()
    local identifier = model:FindFirstChild("HospitalIdentifier", true)
    if identifier then identifier.CFrame = origin * CFrame.new(0, 10.5, 33.5) end
    local art = Instance.new("Folder")
    art.Name, art.Parent = "ImportedArchitecture", model
    local replacements = {}
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") and part.Name == "Wall" then
            table.insert(replacements, part)
        end
    end
    for _, part in replacements do
        -- Mesh wall panels retain the existing collision/layout contract.
        local width = math.max(part.Size.X, part.Size.Z)
        local yaw = part.Size.Z > part.Size.X and math.pi / 2 or 0
        local count = math.max(1, math.ceil(width / 8))
        for index = 1, count do
            local offset = (index - .5) * width / count - width / 2
            local cframe = CFrame.new(part.Position) * CFrame.Angles(0, yaw, 0) * CFrame.new(offset, 0, 0)
            local mesh = Environment.Mesh(art, "wall", cframe, Vector3.new(width / count, part.Size.Y, .8))
            mesh.CanCollide = false
            mesh.Color = Color3.fromRGB(150, 164, 158)
        end
        part.Transparency = 1
    end
    local props = {
        {"bed-single", -23, 2, -8}, {"bed-single", -23, 2, 5},
        {"computer-wide", 28, 3, 10}, {"computer-system", 19, 3, -28},
        {"container-tall", -29, 3.6, 24}, {"container", 29, 2.4, 27},
    }
    for _, entry in props do
        Environment.Mesh(art, entry[1], origin * CFrame.new(entry[2], entry[3], entry[4]))
    end
    -- Abandoned clinic dressing: overturned gurneys, a toppled IV stand, a dark
    -- nurses' station and peeling paint bands so the ward reads as left behind.
    local grime = Color3.fromRGB(96, 104, 92)
    for index, z in {-16, 14} do
        local gurney = Environment.Part(art, "GurneyFrame", Vector3.new(2.2, .4, 6.2), origin * CFrame.new(-14 + index * 3, 1.1, z) * CFrame.Angles(0, 0, math.rad(index == 1 and 78 or -64)), Color3.fromRGB(120, 128, 126), Enum.Material.Metal)
        gurney.CanCollide = false
    end
    local stand = Environment.Part(art, "IVStand", Vector3.new(.3, 6, .3), origin * CFrame.new(-6, 3, 14) * CFrame.Angles(0, 0, math.rad(82)), Color3.fromRGB(190, 190, 186), Enum.Material.Metal)
    stand.CanCollide = false
    Environment.Part(art, "NursesStation", Vector3.new(10, 3, 3), origin * CFrame.new(24, 1.5, -14), Color3.fromRGB(70, 58, 50), Enum.Material.Wood)
    for _, z in {-30, -10, 10, 30} do
        local band = Environment.Part(art, "PeelingPaint", Vector3.new(.2, 2.4, 6), origin * CFrame.new(-17.8, 6.2, z), grime, Enum.Material.Concrete)
        band.CanCollide = false
        band.Transparency = .35
    end
    for _, x in {-29, -19} do
        Environment.Mesh(art, "container", origin * CFrame.new(x, 1.2, -1), Vector3.new(3, 2.4, 2.4))
    end
    for z = -29, 27, 8 do
        local mesh = Environment.Mesh(art, "floor-panel", origin * CFrame.new(0, -.55, z), Vector3.new(12, 1, 8))
        mesh.CanCollide = false
    end
    Environment.Sign(art, "SAINT ORIN   /   CONTAINMENT WARD", origin:PointToWorldSpace(Vector3.new(0, 9, -35)), Vector3.new(13, 1.4, .1))
    Environment.Sign(art, "CLOSED  -  NO ADMISSIONS", origin:PointToWorldSpace(Vector3.new(-25, 7, 33)), Vector3.new(9, 1.2, .1), Color3.fromRGB(182, 74, 64))
    for _, x in {-5.5, 5.5} do
        local strip = Environment.Part(art, "DischargeBoundary", Vector3.new(.15, .1, 24), origin * CFrame.new(x, .15, -12), amber, Enum.Material.Neon)
        strip.CanCollide = false
        strip:SetAttribute("HazardIndicator", true)
    end
    Environment.Sign(art, "DISCHARGE ZONE  /  USE SIDE WARDS DURING ALARM", origin:PointToWorldSpace(Vector3.new(0, 8, -4)), Vector3.new(12, 1.2, .1), amber)
    return model
end

-- Abandoned subway: a long platform hall flanking a single track. A stopped
-- train sits in the tunnel to the north and periodically rolls through the
-- track bed, so the central rail is a lethal lane during its pass.
function Environment.BuildSubway()
    local model = Instance.new("Model")
    model.Name = "AbandonedSubway"
    local origin = Environment.Part(model, "Origin", Vector3.one * .1, CFrame.new(), dark)
    origin.Transparency, origin.CanCollide, origin.CanQuery = 1, false, false
    model.PrimaryPart = origin
    local architecture = Instance.new("Folder")
    architecture.Name, architecture.Parent = "ImportedArchitecture", model
    local tile = Color3.fromRGB(84, 92, 86)
    local grime = Color3.fromRGB(42, 46, 44)
    -- Track bed in the centre, platforms on either side, raised 4 studs.
    Environment.Part(model, "TrackBed", Vector3.new(12, 1, 110), CFrame.new(0, -3.5, 0), Color3.fromRGB(28, 30, 30), Enum.Material.Concrete)
    for _, x in {-22, 22} do
        Environment.Part(model, "Platform", Vector3.new(16, 1, 110), CFrame.new(x, -.5, 0), tile, Enum.Material.Concrete)
        Environment.Part(model, "PlatformEdge", Vector3.new(.8, 1.2, 110), CFrame.new(x + (x > 0 and -7.6 or 7.6), .1, 0), Color3.fromRGB(214, 176, 62), Enum.Material.Metal)
    end
    Environment.Part(model, "Floor", Vector3.new(60, 1, 120), CFrame.new(0, -4.5, 0), grime, Enum.Material.Concrete)
    -- Tunnel walls and a vaulted ceiling line.
    for _, x in {-30, 30} do
        Environment.Part(model, "TunnelWall", Vector3.new(2, 18, 120), CFrame.new(x, 4, 0), grime, Enum.Material.Concrete)
    end
    Environment.Part(model, "Ceiling", Vector3.new(60, 1, 120), CFrame.new(0, 13, 0), grime, Enum.Material.Concrete)
    for z = -54, 54, 18 do
        for _, x in {-16, 16} do
            Environment.Mesh(architecture, "container-tall", CFrame.new(x, 5, z), Vector3.new(4, 12, 4))
        end
    end
    -- Ticket hall and stair north/south. Stairs are walkable ramps for the stalker.
    Environment.Part(model, "EntranceStairs", Vector3.new(14, 1, 12), CFrame.new(0, -2, -58), tile, Enum.Material.Concrete)
    Environment.Sign(architecture, "LAST TRAIN   /   NORTHBOUND  -  NOT IN SERVICE", Vector3.new(0, 10, -55), Vector3.new(20, 2, .15), amber)
    Environment.Sign(architecture, "SIGNAL RELAY  /  AUTHORIZED STAFF ONLY", Vector3.new(0, 10, 55), Vector3.new(18, 2, .15), cyan)
    for z = -48, 48, 16 do
        Environment.Light(model, Vector3.new(-22, 11, z), Color3.fromRGB(230, 214, 176), 24)
        Environment.Light(model, Vector3.new(22, 11, z), Color3.fromRGB(230, 214, 176), 24)
    end
    -- Stopped train car in the north tunnel. Its doors are solid, so the hazard
    -- is the rolling pass, not the geometry.
    local car = Environment.Part(model, "TrainCar", Vector3.new(11, 8, 40), CFrame.new(0, 1.5, -86), Color3.fromRGB(70, 96, 74), Enum.Material.Metal)
    car.MaterialVariant = "PaintedSteel"
    car.CanCollide = false
    car:SetAttribute("HazardIndicator", true)
    local markers = Instance.new("Folder")
    markers.Name, markers.Parent = "Markers", model
    local function marker(name, position, size)
        local part = Environment.Part(markers, name, size or Vector3.one, CFrame.new(position))
        part.Transparency, part.CanCollide, part.CanQuery = 1, false, false
        return part
    end
    marker("EntranceSpawn", Vector3.new(0, 4, 46))
    marker("ElevatorSocket", Vector3.new(0, 0, 62))
    marker("ElevatorReturnZone", Vector3.new(0, 5, 62), Vector3.new(18, 10, 16))
    marker("EnemySpawn", Vector3.new(-22, 4, -40))
    marker("RoomBounds", Vector3.new(0, 5, 0), Vector3.new(60, 20, 130))
    local paths = Instance.new("Folder")
    paths.Name, paths.Parent = "PatrolPaths", markers
    for index, position in {Vector3.new(-22, 4, -20), Vector3.new(22, 4, 0), Vector3.new(-22, 4, 20), Vector3.new(22, 4, 40)} do
        local point = Environment.Part(paths, tostring(index), Vector3.one, CFrame.new(position))
        point.Transparency, point.CanCollide, point.CanQuery = 1, false, false
    end
    -- Return bridge from the platform edge to the elevator socket.
    Environment.Part(model, "ElevatorBridge", Vector3.new(18, 1, 16), CFrame.new(0, -.5, 56), dark)
    return model
end

function Environment.BuildLaboratory()
    local model = Instance.new("Model")
    model.Name = "FloodedLaboratory"
    local origin = Environment.Part(model, "Origin", Vector3.one * .1, CFrame.new(), dark)
    origin.Transparency, origin.CanCollide, origin.CanQuery = 1, false, false
    model.PrimaryPart = origin
    local architecture = Instance.new("Folder")
    architecture.Name, architecture.Parent = "ImportedArchitecture", model
    Environment.Part(model, "Basin", Vector3.new(94, 1, 110), CFrame.new(0, -4, 0), dark, Enum.Material.Concrete)
    local water = Environment.Part(model, "FloodWater", Vector3.new(90, .16, 106), CFrame.new(0, -1.1, 0), Color3.fromRGB(32, 87, 95), Enum.Material.Glass)
    water.Transparency, water.Reflectance, water.CanCollide = .38, .2, false
    water:SetAttribute("WaterSurface", true)
    -- The cross and perimeter are continuous, wide enough for two players to pass.
    local walkways = {
        {0, 0, 12, 106}, {0, 0, 90, 12}, {-39, 0, 12, 106}, {39, 0, 12, 106},
        {0, -47, 90, 12}, {0, 47, 90, 12},
    }
    for _, entry in walkways do
        local x, z, width, length = table.unpack(entry)
        Environment.Part(model, "CatwalkCollision", Vector3.new(width, 1, length), CFrame.new(x, -.5, z), Color3.fromRGB(120, 140, 146))
        for dx = -width / 2 + 6, width / 2 - 1, 12 do
            for dz = -length / 2 + 6, length / 2 - 1, 12 do
                Environment.Mesh(architecture, "floor-panel", CFrame.new(x + dx, -.4, z + dz), Vector3.new(12, .8, 12))
            end
        end
    end
    for x = -40, 40, 8 do
        for _, z in {-55, 55} do
            if z == -55 or math.abs(x) > 8 then
                Environment.Mesh(architecture, "wall-window", CFrame.new(x, 7, z), Vector3.new(8, 14, 2.4))
            end
        end
    end
    for z = -47, 49, 8 do
        for _, x in {-47, 47} do
            Environment.Mesh(architecture, "wall", CFrame.new(x, 7, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(8, 14, 2.4))
        end
    end
    for _, x in {-25, 25} do
        for _, z in {-27, 27} do
            local plinth = Environment.Part(model, "ContainmentPlinth", Vector3.new(13, 1.5, 13), CFrame.new(x, -2, z), dark)
            Environment.Mesh(architecture, "container-tall", CFrame.new(x, 2, z), Vector3.new(6, 9, 6))
            local glass = Environment.Part(model, "ContainmentCylinder", Vector3.new(11, 7.5, 7.5), CFrame.new(x, 3.5, z), cyan, Enum.Material.Glass)
            glass.Shape, glass.Transparency, glass.CanCollide = Enum.PartType.Cylinder, .78, false
            glass.CFrame *= CFrame.Angles(0, 0, math.pi / 2)
            Environment.Light(model, Vector3.new(x, 11, z), cyan, 23)
        end
    end
    for _, x in {-38, 38} do
        for z = -40, 40, 16 do
            Environment.Mesh(architecture, "rail", CFrame.new(x > 0 and 32 or -32, 1.6, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(12, 3.2, .5))
            Environment.Light(model, Vector3.new(x, 12, z), Color3.fromRGB(153, 199, 204))
        end
    end
    for _, x in {-44, 44} do
        for z = -36, 36, 12 do
            Environment.Mesh(architecture, "pipe", CFrame.new(x, 10, z), Vector3.new(2, 12, 2))
        end
    end
    Environment.Mesh(architecture, "computer-system", CFrame.new(-37, 2.4, -44))
    Environment.Mesh(architecture, "computer-system", CFrame.new(37, 2.4, -44))
    Environment.Mesh(architecture, "computer-wide", CFrame.new(0, 2, -45))
    for _, x in {-37, 37} do
        Environment.Mesh(architecture, "computer-system", CFrame.new(x, 2.4, 34))
        Environment.Mesh(architecture, "pipe-bend", CFrame.new(x > 0 and 43 or -43, 3, 38), Vector3.new(5, 5, 3))
        Environment.Mesh(architecture, "wall-detail", CFrame.new(x, 7, 52), Vector3.new(5, 7, 1.4))
        leak(model, Vector3.new(x, 11, -24), cyan)
    end
    Environment.Sign(model, "PELAGIC   /   SUBLEVEL 06", Vector3.new(0, 10, -53), Vector3.new(26, 2.5, .15))
    Environment.Sign(model, "PUMP A     ←     RAISED ROUTE     →     PUMP B", Vector3.new(0, 7, 12), Vector3.new(22, 1.5, .15), amber)
    Environment.Part(model, "Ceiling", Vector3.new(96, 1, 112), CFrame.new(0, 16, 0), Color3.fromRGB(67, 85, 94))
    for z = -48, 48, 16 do
        Environment.Part(model, "StructuralBeam", Vector3.new(94, .7, .8), CFrame.new(0, 14, z), Color3.fromRGB(86, 106, 116))
        Environment.Light(model, Vector3.new(0, 13, z), Color3.fromRGB(161, 206, 213), 30)
    end
    for _, x in {-6.2, 6.2} do
        local strip = Environment.Part(model, "CatwalkEdgeLight", Vector3.new(.12, .12, 100), CFrame.new(x, .12, 0), cyan, Enum.Material.Neon)
        strip.CanCollide = false
        strip:SetAttribute("HazardIndicator", true)
    end
    local markers = Instance.new("Folder")
    markers.Name, markers.Parent = "Markers", model
    local function marker(name, position, size)
        local part = Environment.Part(markers, name, size or Vector3.one, CFrame.new(position))
        part.Transparency, part.CanCollide, part.CanQuery = 1, false, false
        return part
    end
    marker("EntranceSpawn", Vector3.new(0, 4, 43))
    marker("ElevatorSocket", Vector3.new(0, 0, 63))
    marker("ElevatorReturnZone", Vector3.new(0, 5, 63), Vector3.new(18, 10, 16))
    marker("EnemySpawn", Vector3.new(0, 5, -40))
    marker("RoomBounds", Vector3.new(0, 5, 0), Vector3.new(96, 20, 130))
    local paths = Instance.new("Folder")
    paths.Name, paths.Parent = "PatrolPaths", markers
    for index, position in {Vector3.new(0, 4, -40), Vector3.new(-38, 4, 0), Vector3.new(0, 4, 40), Vector3.new(38, 4, 0)} do
        local point = Environment.Part(paths, tostring(index), Vector3.one, CFrame.new(position))
        point.Transparency, point.CanCollide, point.CanQuery = 1, false, false
    end
    -- Bridge through the opening to the return elevator.
    Environment.Part(model, "ElevatorBridge", Vector3.new(18, 1, 16), CFrame.new(0, -.5, 56), dark)
    return model
end

return Environment
