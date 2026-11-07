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
    -- Generated assets are inserted as "<name>" Models wrapping a MeshPart;
    -- FindFirstChild would return the Model, so scan descendants for the part.
    local source
    for _, d in meshLibrary:GetDescendants() do
        if d:IsA("MeshPart") and d.Name == name then source = d break end
    end
    assert(source, "Missing imported mesh " .. name)
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
    art.Name, art.Parent = "ConcourseDressing", model

    -- The elevator leaves slide to x=+/-14.58. A pocket wall on the lobby side
    -- of the opening hides them without changing the door tween or blocking the
    -- walkable centre. The header ties the pockets together.
    for _, side in {-1, 1} do
        local pocket = Environment.Part(art, "ElevatorPocket", Vector3.new(10, 14, .4),
            CFrame.new(side * 14.5, 7, -16), dark, Enum.Material.Metal)
        pocket.MaterialVariant = "MetalPlate"
        local trim = Environment.Part(art, "PocketTrim", Vector3.new(.3, 14, .55),
            CFrame.new(side * 9.55, 7, -15.95), Color3.fromRGB(145, 165, 171), Enum.Material.Metal)
        trim.CanCollide, trim.CanQuery = false, false
    end
    local header = Environment.Part(art, "ElevatorHeader", Vector3.new(21, .8, .5),
        CFrame.new(0, 14.1, -16), dark, Enum.Material.Metal)
    header.MaterialVariant = "MetalPlate"
    -- The floor display and travel dots occupy the header face now. The old
    -- "DEEP ACCESS / B0 CONCOURSE" plaque sat behind them and was clipped by the
    -- bezel, so the boarding wayfinding below the doors is the single label.

    -- Hazard band in front of the threshold.
    for index = 0, 9 do
        local stripe = Environment.Part(art, "ThresholdHazard", Vector3.new(2, .04, 1.1),
            CFrame.new(-9 + index * 2, .03, -15.3), index % 2 == 0 and amber or dark,
            Enum.Material.SmoothPlastic)
        stripe.CanCollide, stripe.CanQuery = false, false
    end

    -- The boarding terminal stays exactly where the prefab authored it. The
    -- kiosk, canopy, pendant and queue lane are additive so the console screen,
    -- keys and proximity prompt remain aligned and usable.
    local kiosk = Instance.new("Folder")
    kiosk.Name, kiosk.Parent = "QueueKiosk", art
    for _, x in {11.9, 16.1} do
        local pylon = Environment.Part(kiosk, "KioskPylon", Vector3.new(.35, 4.6, 2.6),
            CFrame.new(x, 2.3, -10), dark, Enum.Material.Metal)
        pylon.MaterialVariant = "MetalPlate"
    end
    local canopy = Environment.Part(kiosk, "KioskCanopy", Vector3.new(4.8, .3, 2.8),
        CFrame.new(14, 4.55, -10), dark, Enum.Material.Metal)
    canopy.MaterialVariant = "MetalPlate"
    local back = Environment.Part(kiosk, "KioskBack", Vector3.new(4.4, 4.4, .25),
        CFrame.new(14, 2.3, -11.15), dark, Enum.Material.Metal)
    back.MaterialVariant = "MetalPlate"
    local mat = Environment.Part(kiosk, "KioskMat", Vector3.new(4.6, .05, 2.2),
        CFrame.new(14, .03, -8.1), Color3.fromRGB(50, 60, 64), Enum.Material.Fabric)
    mat.CanCollide, mat.CanQuery = false, false
    Environment.Part(kiosk, "PendantCable", Vector3.new(.08, 3.2, .08),
        CFrame.new(14, 16.6, -10), dark)
    Environment.Light(kiosk, Vector3.new(14, 15.1, -10), amber, 18)

    local lane = Instance.new("Folder")
    lane.Name, lane.Parent = "QueueLane", art
    local stripe = Environment.Part(lane, "QueueFloorStripe", Vector3.new(8.6, .03, 15),
        CFrame.new(14, .035, 2.5), amber, Enum.Material.Neon)
    stripe.Transparency, stripe.CanCollide, stripe.CanQuery = .45, false, false
    for _, x in {9.5, 18.5} do
        for index, z in {-5, 0, 5, 10} do
            local post = Environment.Part(lane, "QueueStanchion", Vector3.new(.18, 3.2, .18),
                CFrame.new(x, 1.6, z), Color3.fromRGB(145, 165, 171), Enum.Material.Metal)
            post.CanCollide, post.CanQuery = false, false
            local base = Environment.Part(lane, "StanchionBase", Vector3.new(.7, .12, .7),
                CFrame.new(x, .08, z), dark, Enum.Material.Metal)
            base.CanCollide, base.CanQuery = false, false
            if index < 4 then
                local belt = Environment.Part(lane, "QueueBelt", Vector3.new(.06, .12, 5),
                    CFrame.new(x, 3.05, z + 2.5), Color3.fromRGB(120, 40, 38), Enum.Material.Fabric)
                belt.CanCollide, belt.CanQuery = false, false
            end
        end
    end

    -- Service-track freight and the east-gallery maintenance bay give the
    -- concourse a working transit-hub history beyond the boarding kiosk.
    local service = Instance.new("Folder")
    service.Name, service.Parent = "ServiceFreight", art
    local flatbed = Environment.Part(service, "FreightFlatbed", Vector3.new(7, .5, 4.5),
        CFrame.new(-34, .35, 10), Color3.fromRGB(95, 111, 119), Enum.Material.Metal)
    flatbed.MaterialVariant = "MetalPlate"
    for _, dx in {-2.5, 0, 2.5} do
        for _, dz in {-1.6, 1.6} do
            local wheel = Environment.Part(service, "FreightWheel", Vector3.new(.55, .55, .35),
                CFrame.new(-34 + dx, .1, 10 + dz), Color3.fromRGB(27, 32, 35), Enum.Material.Rubber)
            wheel.CanCollide, wheel.CanQuery = false, false
        end
    end
    for _, entry in {{-35.2, 1.8, 9, 2.4}, {-32.6, 1.5, 10.5, 2.1}, {-34.2, 3.9, 9.6, 1.8}} do
        local crate = Environment.Part(service, "FreightCrate", Vector3.one * entry[4],
            CFrame.new(entry[1], entry[2], entry[3]), Color3.fromRGB(96, 78, 52), Enum.Material.Wood)
        crate.CanCollide, crate.CanQuery = false, false
        local strap = Environment.Part(service, "CrateStrap", Vector3.new(entry[4] + .04, .12, .18),
            CFrame.new(entry[1], entry[2], entry[3]), Color3.fromRGB(40, 44, 46), Enum.Material.Metal)
        strap.CanCollide, strap.CanQuery = false, false
    end
    local puddle = Environment.Part(service, "ServicePuddle", Vector3.new(3, .03, 2),
        CFrame.new(-30, .03, 16), Color3.fromRGB(40, 70, 74), Enum.Material.Glass)
    puddle.Transparency, puddle.CanCollide, puddle.CanQuery = .35, false, false

    local gallery = Instance.new("Folder")
    gallery.Name, gallery.Parent = "GalleryMaintenance", art
    local bench = Environment.Part(gallery, "WorkbenchTop", Vector3.new(2.4, .3, 6),
        CFrame.new(36.5, 3, 0), Color3.fromRGB(120, 128, 126), Enum.Material.Wood)
    bench.CanCollide, bench.CanQuery = false, false
    for _, dx in {-1, 1} do
        for _, dz in {-2.6, 2.6} do
            local leg = Environment.Part(gallery, "WorkbenchLeg", Vector3.new(.22, 3, .22),
                CFrame.new(36.5 + dx, 1.5, dz), Color3.fromRGB(95, 111, 119), Enum.Material.Metal)
            leg.CanCollide, leg.CanQuery = false, false
        end
    end
    local pegboard = Environment.Part(gallery, "Pegboard", Vector3.new(.12, 5, 6),
        CFrame.new(39.35, 5, 0), Color3.fromRGB(70, 58, 50), Enum.Material.Wood)
    pegboard.CanCollide, pegboard.CanQuery = false, false
    for _, y in {4.2, 5.2, 6.2} do
        local tool = Environment.Part(gallery, "HangingTool", Vector3.new(.12, .9, .18),
            CFrame.new(39.2, y, -1.2), Color3.fromRGB(145, 165, 171), Enum.Material.Metal)
        tool.CanCollide, tool.CanQuery = false, false
    end
    local locker = Environment.Part(gallery, "ToolLocker", Vector3.new(1.6, 6, 2),
        CFrame.new(36.5, 3, 4.8), Color3.fromRGB(70, 88, 94), Enum.Material.Metal)
    locker.MaterialVariant = "MetalPlate"
    locker.CanCollide, locker.CanQuery = false, false
    Environment.Part(gallery, "LampCable", Vector3.new(.08, 8, .08),
        CFrame.new(36.5, 14, 0), dark)
    Environment.Light(gallery, Vector3.new(36.5, 10, 0), amber, 14)
    Environment.Sign(gallery, "MAINTENANCE  /  AUTHORIZED CREW", Vector3.new(33.5, 7, -6),
        Vector3.new(5, 1.6, .14), amber, 90)
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
    local art = Instance.new("Folder")
    art.Name, art.Parent = "ClinicalDressing", model

    -- The authored V6 clinical architecture, trim, beds, curtains, nurses'
    -- station and wall control stay untouched. Runtime only adds story props in
    -- clear floor space so no objective or corridor is obstructed.
    local gurney = Environment.Part(art, "GurneyFrame", Vector3.new(2.2, .4, 6.2),
        origin * CFrame.new(-18, 1.1, -15) * CFrame.Angles(0, math.rad(90), math.rad(8)),
        Color3.fromRGB(120, 128, 126), Enum.Material.Metal)
    gurney.CanCollide, gurney.CanQuery = false, false
    for _, dx in {-2.6, 2.6} do
        local wheel = Environment.Part(art, "GurneyWheel", Vector3.new(.5, .5, .5),
            origin * CFrame.new(-18 + dx, .35, -15), Color3.fromRGB(27, 32, 35), Enum.Material.Rubber)
        wheel.CanCollide, wheel.CanQuery = false, false
    end
    local stand = Environment.Part(art, "IVStand", Vector3.new(.3, 6, .3),
        origin * CFrame.new(-31.5, 3, 7), Color3.fromRGB(190, 190, 186), Enum.Material.Metal)
    stand.CanCollide, stand.CanQuery = false, false
    local bag = Environment.Part(art, "IVBag", Vector3.new(.8, 1.3, .35),
        origin * CFrame.new(-31.5, 5.5, 7), Color3.fromRGB(210, 219, 208), Enum.Material.Glass)
    bag.Transparency, bag.CanCollide, bag.CanQuery = .3, false, false

    local linen = Environment.Part(art, "LinenCart", Vector3.new(2.4, 2.2, 1.6),
        origin * CFrame.new(-32, 1.1, -14), Color3.fromRGB(120, 128, 126), Enum.Material.Metal)
    linen.CanCollide, linen.CanQuery = false, false
    local linenTop = Environment.Part(art, "LinenBundle", Vector3.new(2.2, .7, 1.4),
        origin * CFrame.new(-32, 2.55, -14), Color3.fromRGB(210, 219, 208), Enum.Material.Fabric)
    linenTop.CanCollide, linenTop.CanQuery = false, false

    -- Discharge boundary is readable from outside the damage lane.
    for _, x in {-5.5, 5.5} do
        local strip = Environment.Part(art, "DischargeBoundary", Vector3.new(.15, .1, 24),
            origin * CFrame.new(x, .15, -12), amber, Enum.Material.Neon)
        strip.CanCollide, strip.CanQuery = false, false
        strip:SetAttribute("HazardIndicator", true)
    end
    for _, z in {-.5, -23.5} do
        local strip = Environment.Part(art, "DischargeThreshold", Vector3.new(10, .1, .3),
            origin * CFrame.new(0, .15, z), amber, Enum.Material.Neon)
        strip.CanCollide, strip.CanQuery = false, false
        strip:SetAttribute("HazardIndicator", true)
    end
    -- Mount the warning on the east corridor wall so it never overlaps the
    -- overhead wayfinding or the room-height signage in the central corridor.
    Environment.Sign(art, "DISCHARGE ZONE  /  USE SIDE WARDS DURING ALARM",
        origin:PointToWorldSpace(Vector3.new(6.55, 5.5, -8)), Vector3.new(8, 1.2, .1), amber, 90)

    -- Existing ceiling diffusers become the flicker source, so no duplicate
    -- fittings are layered over the authored room lighting.
    local tagged = 0
    for _, part in model:GetDescendants() do
        if tagged >= 10 then break end
        if part:IsA("BasePart") and part.Name == "Diffuser" then
            part:SetAttribute("FlickerLight", true)
            tagged += 1
        end
    end

    -- Foyer mobility prop, clear of the delivery receiver and elevator approach.
    local wheelchair = Environment.Part(art, "WheelchairSeat", Vector3.new(1.6, .3, 1.8),
        origin * CFrame.new(10, 1.4, 25), Color3.fromRGB(70, 88, 94), Enum.Material.Fabric)
    wheelchair.CanCollide, wheelchair.CanQuery = false, false
    local backrest = Environment.Part(art, "WheelchairBack", Vector3.new(1.6, 1.6, .2),
        origin * CFrame.new(10, 2.3, 25.8), Color3.fromRGB(70, 88, 94), Enum.Material.Fabric)
    backrest.CanCollide, backrest.CanQuery = false, false
    for _, dx in {-1, 1} do
        local wheel = Environment.Part(art, "WheelchairWheel", Vector3.new(.2, 1.4, 1.4),
            origin * CFrame.new(10 + dx, .8, 25), Color3.fromRGB(27, 32, 35), Enum.Material.Rubber)
        wheel.CanCollide, wheel.CanQuery = false, false
    end

    -- Thin decorative geometry must not intercept objective line-of-sight rays.
    for _, part in model:GetDescendants() do
        if part:IsA("BasePart") and not part.CanCollide then part.CanQuery = false end
    end
    return model
end

-- Flooded laboratory: a deep-sea research facility at sublevel 06, partially
-- flooded with electrified water. Raised catwalks cross a central basin, four
-- containment cylinders hold specimens, pump rooms sit west and east, and a
-- central control room synchronises the recovery. All marker positions,
-- hazard timing, and objective coordinates are preserved from the original
-- procedural layout; only the visual representation is upgraded.
function Environment.BuildLaboratory()
    local model = Instance.new("Model")
    model.Name = "FloodedLaboratory"
    local origin = Environment.Part(model, "Origin", Vector3.one * .1, CFrame.new(), dark)
    origin.Transparency, origin.CanCollide, origin.CanQuery = 1, false, false
    model.PrimaryPart = origin
    local architecture = Instance.new("Folder")
    architecture.Name, architecture.Parent = "ImportedArchitecture", model

    -- Basin floor: flooded concrete PBR, darker and wetter than the dry walkways.
    local basin = Environment.Part(model, "Basin", Vector3.new(94, 1, 110), CFrame.new(0, -4, 0), dark, Enum.Material.Concrete)
    basin:SetAttribute("PbrMaterial", "FloodedConcrete")
    local basinCost = Instance.new("PathfindingModifier")
    basinCost.Label, basinCost.Parent = "FloodBasin", basin

    -- Flood water surface: glass with subtle cyan tint, reflective, non-colliding.
    local water = Environment.Part(model, "FloodWater", Vector3.new(90, .16, 106), CFrame.new(0, -1.1, 0), Color3.fromRGB(20, 60, 70), Enum.Material.Glass)
    water.Transparency, water.Reflectance, water.CanCollide = .42, .25, false
    water:SetAttribute("WaterSurface", true)

    -- Submerged caustic light: surface light on the water for godray effect.
    local caustic = Instance.new("SurfaceLight")
    caustic.Color, caustic.Brightness, caustic.Range, caustic.Parent = Color3.fromRGB(99, 216, 213), .35, 60, water

    -- The cross and perimeter are continuous, wide enough for two players to pass.
    local walkways = {
        {0, 0, 12, 106}, {0, 0, 90, 12}, {-39, 0, 12, 106}, {39, 0, 12, 106},
        {0, -47, 90, 12}, {0, 47, 90, 12},
    }
    for _, entry in walkways do
        local x, z, width, length = table.unpack(entry)
        -- Invisible collision hull for the walkway surface.
        Environment.Part(model, "CatwalkCollision", Vector3.new(width, 1, length), CFrame.new(x, -.5, z), Color3.fromRGB(120, 140, 146))
        -- Grating deck: floor-panel MeshParts with FloodedConcrete PBR.
        for dx = -width / 2 + 6, width / 2 - 1, 12 do
            for dz = -length / 2 + 6, length / 2 - 1, 12 do
                local panel = Environment.Mesh(architecture, "floor-panel", CFrame.new(x + dx, -.4, z + dz), Vector3.new(12, .8, 12))
                panel:SetAttribute("PbrMaterial", "FloodedConcrete")
            end
        end
    end

    -- Perimeter walls: corroded steel PBR with window panels at the ends.
    for x = -40, 40, 8 do
        for _, z in {-55, 55} do
            if z == -55 or math.abs(x) > 8 then
                local wall = Environment.Mesh(architecture, "wall-window", CFrame.new(x, 7, z), Vector3.new(8, 14, 2.4))
                wall:SetAttribute("PbrMaterial", "CorrodedSteel")
            end
        end
    end
    for z = -47, 49, 8 do
        for _, x in {-47, 47} do
            local wall = Environment.Mesh(architecture, "wall", CFrame.new(x, 7, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(8, 14, 2.4))
            wall:SetAttribute("PbrMaterial", "CorrodedSteel")
        end
    end

    -- Corner bulkheads at the four corners of the room for structural detail.
    for _, x in {-44, 44} do
        for _, z in {-51, 51} do
            local corner = Environment.Mesh(architecture, "wall-corner", CFrame.new(x, 7, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(8, 14, 2.4))
            corner:SetAttribute("PbrMaterial", "CorrodedSteel")
        end
    end

    -- Containment cells: plinth plus the generated containment-vessel mesh —
    -- a corroded pressure chamber with a glowing specimen core inside.
    for _, x in {-25, 25} do
        for _, z in {-27, 27} do
            local plinth = Environment.Part(model, "ContainmentPlinth", Vector3.new(13, 1.5, 13), CFrame.new(x, -2, z), dark)
            plinth:SetAttribute("PbrMaterial", "CorrodedSteel")
            local vessel = Environment.Mesh(model, "containment-vessel",
                CFrame.new(x, 5.4, z), Vector3.new(7, 13.2, 6.6))
            vessel.CanCollide = true
            local core = Environment.Light(model, Vector3.new(x, 11, z), cyan, 23)
            -- Specimen ID tag on each containment cylinder.
            local idBoard = Environment.Sign(model, string.format("SPEC-73%d-PELAGIC", x < 0 and 4 or 5),
                Vector3.new(x, 6.5, z), Vector3.new(4, 1, .1), cyan, 0)
            -- Small canister cluster at the plinth corner.
            local canister = Environment.Mesh(model, "specimen-canister",
                CFrame.new(x + 4.5, .7, z + 4.5) * CFrame.Angles(0, .6, 0), Vector3.new(1.4, 3.8, 1.4))
            canister.CanCollide = false
        end
    end

    -- Catwalk railings: corroded steel PBR along both sides of the cross.
    for _, x in {-38, 38} do
        for z = -40, 40, 16 do
            local rail = Environment.Mesh(architecture, "rail", CFrame.new(x > 0 and 32 or -32, 1.6, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(12, 3.2, .5))
            rail:SetAttribute("PbrMaterial", "CorrodedSteel")
            Environment.Light(model, Vector3.new(x, 12, z), Color3.fromRGB(153, 199, 204))
        end
    end

    -- Perimeter pipes: corroded steel PBR vertical runs.
    for _, x in {-44, 44} do
        for z = -36, 36, 12 do
            local pipe = Environment.Mesh(architecture, "pipe", CFrame.new(x, 10, z), Vector3.new(2, 12, 2))
            pipe:SetAttribute("PbrMaterial", "CorrodedSteel")
            -- Steam vent particle emitter on each pipe junction.
            local vent = Environment.Part(model, "SteamVent", Vector3.one * .2, CFrame.new(x, 16.5, z), dark)
            vent.Transparency, vent.CanCollide, vent.CanQuery = 1, false, false
            local steam = Instance.new("ParticleEmitter")
            steam.Texture = "rbxasset://textures/particles/smoke_main.dds"
            steam.Color = ColorSequence.new(Color3.fromRGB(200, 210, 215))
            steam.Lifetime = NumberRange.new(1.5, 2.5)
            steam.Rate = 3
            steam.Size = NumberSequence.new(.4)
            steam.Speed = NumberRange.new(2, 4)
            steam.SpreadAngle = Vector2.new(4, 4)
            steam.Parent = vent
            leak(model, Vector3.new(x, 11, -24), cyan)
        end
    end

    -- Recovery ramps: stairs-ramp MeshPart for basin access at the four corners.
    for _, x in {-30, 30} do
        for _, z in {-32, 32} do
            local slope = math.atan(3.5 / 12) * (x > 0 and 1 or -1)
            local ramp = Environment.Mesh(architecture, "stairs-ramp",
                CFrame.new(x, -2.25, z) * CFrame.Angles(0, 0, slope), Vector3.new(12.5, 1, 4))
            ramp:SetAttribute("PbrMaterial", "CorrodedSteel")
        end
    end

    -- Control consoles: generated research-console meshes with glowing screens.
    local consoleA = Environment.Mesh(model, "research-console", CFrame.new(-37, 1.6, -44) * CFrame.Angles(0, math.pi, 0), Vector3.new(6.5, 3, 4.5))
    consoleA.CanCollide = false
    local consoleB = Environment.Mesh(model, "research-console", CFrame.new(37, 1.6, -44), Vector3.new(6.5, 3, 4.5))
    consoleB.CanCollide = false
    local consoleMain = Environment.Mesh(model, "research-console", CFrame.new(0, 1.6, -45), Vector3.new(7.5, 3.2, 5))
    consoleMain.CanCollide = false
    for _, x in {-37, 37} do
        Environment.Mesh(architecture, "computer-system", CFrame.new(x, 2.4, 34)):SetAttribute("PbrMaterial", "PaintedSteel")
        Environment.Mesh(architecture, "pipe-bend", CFrame.new(x > 0 and 43 or -43, 3, 38), Vector3.new(5, 5, 3)):SetAttribute("PbrMaterial", "CorrodedSteel")
        Environment.Mesh(architecture, "wall-detail", CFrame.new(x, 7, 52), Vector3.new(5, 7, 1.4)):SetAttribute("PbrMaterial", "CorrodedSteel")
    end

    -- Pump machines: generated industrial pumps flanking the south walkway,
    -- next to the PumpA/PumpB objective prompts at (+/-37, 3, 38).
    for _, x in {-37, 37} do
        local pump = Environment.Mesh(model, "pump-machine",
            CFrame.new(x + (x > 0 and -4 or 4), 4.2, 30) * CFrame.Angles(0, x > 0 and -math.pi / 2 or math.pi / 2, 0),
            Vector3.new(5.5, 10.5, 4.2))
        pump.CanCollide = true
        -- Pipe run from pump up to the ceiling.
        local riser = Environment.Mesh(architecture, "pipe", CFrame.new(x + (x > 0 and -6.5 or 6.5), 9, 30), Vector3.new(1.6, 12, 1.6))
        riser:SetAttribute("PbrMaterial", "CorrodedSteel")
        -- Status lamp on each pump: amber until restarted.
        local lamp = Environment.Part(model, "PumpStatusLamp", Vector3.new(.7, .7, .3),
            CFrame.new(x + (x > 0 and -1.8 or 1.8), 8.6, 30) * CFrame.Angles(0, x > 0 and -math.pi / 2 or math.pi / 2, 0), amber, Enum.Material.Neon)
        lamp.CanCollide, lamp.CanQuery = false, false
        lamp:SetAttribute("PumpStatus", x < 0 and "A" or "B")
    end

    -- Pressure doors at the west and east pump room entrances.
    for _, x in {-34, 34} do
        local door = Environment.Mesh(architecture, "door-double", CFrame.new(x, 1, 52) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(8, 14, .4))
        door:SetAttribute("PbrMaterial", "CorrodedSteel")
        door:SetAttribute("PressureDoor", true)
    end

    -- Depth gauges on perimeter walls: storytelling markers at 12-stud intervals.
    for _, x in {-36, -24, -12, 0, 12, 24, 36} do
        local gauge = Environment.Sign(model, string.format("−%dm", 600 + math.abs(x) * 2),
            Vector3.new(x, 3, -52), Vector3.new(2.5, 1.2, .1), amber, 0)
    end

    -- Equipment crates: container MeshParts scattered near pump rooms.
    for _, pos in {{-30, 1, 30}, {30, 1, 30}, {-34, 1, -30}, {34, 1, -30}} do
        local crate = Environment.Mesh(architecture, "container", CFrame.new(unpack(pos)), Vector3.new(4, 4, 4))
        crate:SetAttribute("PbrMaterial", "CorrodedSteel")
    end

    Environment.Sign(model, "PELAGIC   /   SUBLEVEL 06", Vector3.new(0, 10, -53), Vector3.new(26, 2.5, .15))
    Environment.Sign(model, "PUMP A     ←     RAISED ROUTE     →     PUMP B", Vector3.new(0, 7, 12), Vector3.new(22, 1.5, .15), amber)

    -- Ceiling: dark structural surface above the catwalks.
    Environment.Part(model, "Ceiling", Vector3.new(96, 1, 112), CFrame.new(0, 16, 0), Color3.fromRGB(67, 85, 94))
    for z = -48, 48, 16 do
        local beam = Environment.Part(model, "StructuralBeam", Vector3.new(94, .7, .8), CFrame.new(0, 14, z), Color3.fromRGB(86, 106, 116))
        beam:SetAttribute("PbrMaterial", "CorrodedSteel")
        Environment.Light(model, Vector3.new(0, 13, z), Color3.fromRGB(161, 206, 213), 30)
    end

    -- Catwalk edge lights: cyan neon strips marking the walkway boundaries.
    for _, x in {-6.2, 6.2} do
        local strip = Environment.Part(model, "CatwalkEdgeLight", Vector3.new(.12, .12, 100), CFrame.new(x, .12, 0), cyan, Enum.Material.Neon)
        strip.Transparency = .15
        strip.CanCollide = false
        strip:SetAttribute("HazardIndicator", true)
    end

    -- Handrails on the central catwalk so the drop into the flood reads as
    -- dangerous rather than an invisible cliff.
    for _, x in {-6, 6} do
        for z = -48, 48, 12 do
            local post = Environment.Part(model, "HandrailPost", Vector3.new(.35, 3.4, .35), CFrame.new(x, 1.7, z), dark)
            post.CanCollide, post.CanQuery = false, false
            post:SetAttribute("PbrMaterial", "CorrodedSteel")
        end
        for z = -42, 42, 12 do
            local rail = Environment.Mesh(architecture, "rail",
                CFrame.new(x, 3.4, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(12, .5, .5))
            rail.CanCollide, rail.CanQuery = false, false
            rail:SetAttribute("PbrMaterial", "CorrodedSteel")
        end
    end

    -- Flood depth: a darker under-layer gives the water volume real depth
    -- instead of a single glass sheet over the basin floor.
    local deepWater = Environment.Part(model, "FloodWaterDeep", Vector3.new(88, .1, 104), CFrame.new(0, -2.7, 0), Color3.fromRGB(8, 26, 34), Enum.Material.Glass)
    deepWater.Transparency, deepWater.CanCollide, deepWater.CanQuery, deepWater.CastShadow = .55, false, false, false
    -- Faint light shafts falling through the water onto the basin floor.
    for _, pos in {{-22, -1.5, -22}, {18, -1.5, -18}, {-14, -1.5, 22}, {24, -1.5, 26}, {0, -1.5, -34}, {0, -1.5, 34}} do
        local shaft = Environment.Part(model, "LightShaft", Vector3.new(5, 12, 5), CFrame.new(unpack(pos)), Color3.fromRGB(60, 160, 170), Enum.Material.Glass)
        shaft.Transparency, shaft.CanCollide, shaft.CanQuery, shaft.CastShadow = .9, false, false, false
    end

    -- Specimen canisters staged along the catwalks: the lab is a collection
    -- facility, so samples should be everywhere. All spots sit on walkways
    -- (deck top is y=0, canister is ~3.6 tall).
    local canisterSpots = {
        {-5, -40}, {5, -28}, {-5, -16}, {5, -4}, {-5, 8}, {5, 20}, {-5, 32}, {5, 44},
        {-34, 44}, {34, 44}, {-20, 44}, {20, 44}, {-34, -44}, {34, -44},
        {-34, 0}, {34, 0}, {-40, -10}, {40, -10}, {-40, 30}, {40, 30},
    }
    for index, spot in canisterSpots do
        local x, z = spot[1], spot[2]
        local canister = Environment.Mesh(model, "specimen-canister",
            CFrame.new(x, 1.8, z) * CFrame.Angles(0, (index * 1.7) % 6.28, 0),
            Vector3.new(1.3, 3.6, 1.3) * (1 + (index % 3) * .12))
        canister.CanCollide = false
        canister.CanQuery = false
    end

    -- Catwalk support columns rising from the basin floor into the water.
    for _, pos in {{-20, -30}, {20, -30}, {-20, 30}, {20, 30}, {-36, -20}, {36, -20}, {-36, 20}, {36, 20}} do
        local column = Environment.Part(model, "CatwalkColumn", Vector3.new(1.6, 7, 1.6), CFrame.new(pos[1], -4.6, pos[2]), dark)
        column.CanCollide, column.CanQuery = false, false
        column:SetAttribute("PbrMaterial", "CorrodedSteel")
        local collar = Environment.Mesh(architecture, "pipe-bend", CFrame.new(pos[1], -2.4, pos[2]), Vector3.new(2.4, 2.4, 2.4))
        collar:SetAttribute("PbrMaterial", "CorrodedSteel")
    end

    -- Bioluminescent mote particles in the water volume.
    for _, pos in {{-20, -1, -30}, {20, -1, -30}, {-20, -1, 30}, {20, -1, 30}} do
        local mote = Environment.Part(model, "BioMote", Vector3.one * .1, CFrame.new(unpack(pos)), dark)
        mote.Transparency, mote.CanCollide, mote.CanQuery = 1, false, false
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Color = ColorSequence.new(Color3.fromRGB(99, 216, 213))
        emitter.Lifetime = NumberRange.new(2, 4)
        emitter.Rate = 6
        emitter.Size = NumberSequence.new(.15)
        emitter.Speed = NumberRange.new(.5, 1.5)
        emitter.SpreadAngle = Vector2.new(10, 10)
        emitter.VelocityInheritance = 0
        emitter.Parent = mote
    end

    -- Water drip particle emitters from ceiling beams.
    for z = -48, 48, 32 do
        local drip = Environment.Part(model, "WaterDrip", Vector3.one * .1, CFrame.new(0, 16, z), dark)
        drip.Transparency, drip.CanCollide, drip.CanQuery = 1, false, false
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
        emitter.Color = ColorSequence.new(Color3.fromRGB(120, 160, 170))
        emitter.Lifetime = NumberRange.new(.8, 1.2)
        emitter.Rate = 2
        emitter.Size = NumberSequence.new(.08)
        emitter.Speed = NumberRange.new(6, 10)
        emitter.SpreadAngle = Vector2.new(1, 1)
        emitter.EmissionDirection = Enum.NormalId.Top
        emitter.Parent = drip
    end

    local markers = Instance.new("Folder")
    markers.Name, markers.Parent = "Markers", model
    local function marker(name, position, size)
        local part = Environment.Part(markers, name, size or Vector3.one, CFrame.new(position))
        part.Transparency, part.CanCollide, part.CanQuery = 1, false, false
        return part
    end
    marker("EntranceSpawn", Vector3.new(0, 4, 43))
    local elevatorSocket = marker("ElevatorSocket", Vector3.new(0, 0, 63))
    elevatorSocket.CFrame *= CFrame.Angles(0, math.pi, 0)
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

-- Abandoned subway: a long platform hall flanking a single track. A stopped
-- train sits in the tunnel to the north and periodically rolls through the
-- track bed, so the central rail is a lethal lane during its pass.
-- All marker positions, hazard timing, and objective coordinates are preserved
-- from the original procedural layout; only the visual representation is upgraded.
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

    -- Track bed: concrete with PBR, PathfindingModifier preserved.
    local trackBed = Environment.Part(model, "TrackBed", Vector3.new(12, 1, 110), CFrame.new(0, -3.5, 0), Color3.fromRGB(28, 30, 30), Enum.Material.Concrete)
    trackBed:SetAttribute("PbrMaterial", "FloodedConcrete")
    local trackCost = Instance.new("PathfindingModifier")
    trackCost.Label, trackCost.Parent = "TrainTrack", trackBed

    -- Real trackwork on the bed: gravel ballast strip, two running rails and
    -- concrete sleepers. The train hazard lane stays |x| < ~5.
    local ballast = Environment.Part(model, "Ballast", Vector3.new(10, .7, 108), CFrame.new(0, -2.85, 0), Color3.fromRGB(52, 50, 46), Enum.Material.Slate)
    ballast.CanCollide = false
    for _, x in {-1.7, 1.7} do
        local rail = Environment.Part(model, "RunningRail", Vector3.new(.45, .55, 108), CFrame.new(x, -2.35, 0), Color3.fromRGB(120, 124, 128), Enum.Material.Metal)
        rail.CanCollide = false
        rail.MaterialVariant = "MetalPlate"
    end
    for z = -52, 52, 4 do
        local sleeper = Environment.Part(model, "Sleeper", Vector3.new(4.6, .3, 1.1), CFrame.new(0, -2.55, z), Color3.fromRGB(38, 34, 30), Enum.Material.Wood)
        sleeper.CanCollide = false
    end

    -- Platforms: concrete with amber edge strips.
    for _, x in {-22, 22} do
        local platform = Environment.Part(model, "Platform", Vector3.new(16, 1, 110), CFrame.new(x, -.5, 0), tile, Enum.Material.Concrete)
        platform:SetAttribute("PbrMaterial", "FloodedConcrete")
        local edge = Environment.Part(model, "PlatformEdge", Vector3.new(.8, 1.2, 110), CFrame.new(x + (x > 0 and -7.6 or 7.6), .1, 0), Color3.fromRGB(214, 176, 62), Enum.Material.Metal)
        edge:SetAttribute("PbrMaterial", "MetalPlate")
        edge:SetAttribute("HazardIndicator", true)
    end

    -- Floor: grime concrete.
    local floor = Environment.Part(model, "Floor", Vector3.new(60, 1, 120), CFrame.new(0, -4.5, 0), grime, Enum.Material.Concrete)
    floor:SetAttribute("PbrMaterial", "FloodedConcrete")

    -- Tunnel walls: corroded concrete.
    for _, x in {-30, 30} do
        local wall = Environment.Part(model, "TunnelWall", Vector3.new(2, 18, 120), CFrame.new(x, 4, 0), grime, Enum.Material.Concrete)
        wall:SetAttribute("PbrMaterial", "FloodedConcrete")
    end

    -- Vaulted ceiling: dark concrete.
    local ceiling = Environment.Part(model, "Ceiling", Vector3.new(60, 1, 120), CFrame.new(0, 13, 0), grime, Enum.Material.Concrete)
    ceiling:SetAttribute("PbrMaterial", "FloodedConcrete")

    -- Container-tall props hugging the tunnel walls, clear of the platform
    -- walking lanes and the level crossing.
    for z = -54, 54, 18 do
        for _, x in {-27, 27} do
            local container = Environment.Mesh(architecture, "container-tall", CFrame.new(x, 5, z), Vector3.new(4, 12, 4))
            container:SetAttribute("PbrMaterial", "CorrodedSteel")
        end
    end

    -- Level crossing: tactile pavers connecting platforms.
    local crossing = Environment.Part(model, "NorthCrossing", Vector3.new(60, 1, 8), CFrame.new(0, -.5, -46), tile, Enum.Material.Concrete)
    crossing:SetAttribute("PbrMaterial", "FloodedConcrete")
    Environment.Sign(architecture, "USE MARKED CROSSINGS / CLEAR TRACK ON WARNING", Vector3.new(0, 9, -46), Vector3.new(26, 2, .15), amber)
    Environment.Sign(architecture, "LAST TRAIN   /   NORTHBOUND  -  NOT IN SERVICE", Vector3.new(0, 10, -55), Vector3.new(20, 2, .15), amber)
    Environment.Sign(architecture, "SIGNAL RELAY  /  AUTHORIZED STAFF ONLY", Vector3.new(0, 10, 55), Vector3.new(18, 2, .15), cyan)

    -- Platform lighting: warm amber point lights along both platforms.
    for z = -48, 48, 16 do
        Environment.Light(model, Vector3.new(-22, 11, z), Color3.fromRGB(230, 214, 176), 24)
        Environment.Light(model, Vector3.new(22, 11, z), Color3.fromRGB(230, 214, 176), 24)
    end

    -- Signal lamps at the south signal box: cyan/green/red indicator lights.
    local signalBox = Environment.Part(model, "SignalBox", Vector3.new(6, 8, 4), CFrame.new(24, 2, 40), Color3.fromRGB(70, 88, 94), Enum.Material.Metal)
    signalBox:SetAttribute("PbrMaterial", "CorrodedSteel")
    signalBox:SetAttribute("SignalBox", true)
    -- Three distinct signal lamps spaced across the signal-box face
    -- (red / amber / green, left to right when facing the box).
    local signalColors = {Color3.fromRGB(220, 60, 60), Color3.fromRGB(233, 166, 77), Color3.fromRGB(80, 220, 80)}
    for index, color in signalColors do
        local lamp = Environment.Part(model, "SignalLamp" .. index, Vector3.new(.8, .8, .4),
            CFrame.new(22.6 + (index - 1) * 1.4, 5.6, 37.9), color, Enum.Material.Neon)
        lamp.CanCollide = false
        lamp:SetAttribute("SignalLamp", true)
    end

    -- Generated signal posts at the platform ends and the north crossing.
    for _, pos in {{-14, -52}, {14, -52}, {-14, 44}, {14, 44}, {26, 48}, {-26, 48}} do
        local post = Environment.Mesh(model, "signal-post", CFrame.new(pos[1], 3.4, pos[2]), Vector3.new(1.6, 8, 1.6))
        post.CanCollide = false
        post.CanQuery = false
    end

    -- Platform screen walls: tiled panel sections along the tunnel walls so
    -- the platforms read as a station rather than a bare box.
    for z = -48, 48, 12 do
        for _, x in {-29.2, 29.2} do
            local panel = Environment.Mesh(architecture, "wall", CFrame.new(x, 6, z) * CFrame.Angles(0, math.pi / 2, 0), Vector3.new(12, 12, 1))
            panel.CanCollide = false
            panel:SetAttribute("PbrMaterial", "ChippedConcrete")
        end
    end
    -- Ceiling beams spanning the vault every 16 studs.
    for z = -48, 48, 16 do
        local beam = Environment.Part(model, "CeilingBeam", Vector3.new(58, 1.4, 2), CFrame.new(0, 11.5, z), Color3.fromRGB(56, 60, 58), Enum.Material.Metal)
        beam.CanCollide, beam.CanQuery = false, false
        beam.MaterialVariant = "MetalPlate"
        -- Hanging lamp cages under every second beam.
        if z % 32 == 0 then
            for _, x in {-22, 22} do
                local cage = Environment.Part(model, "LampCage", Vector3.new(3, .4, 1), CFrame.new(x, 10.4, z), Color3.fromRGB(60, 64, 62), Enum.Material.Metal)
                cage.CanCollide, cage.CanQuery = false, false
                local bulb = Environment.Part(model, "LampBulb", Vector3.new(2.4, .15, .7), CFrame.new(x, 10.1, z), Color3.fromRGB(255, 226, 170), Enum.Material.Neon)
                bulb.CanCollide, bulb.CanQuery = false, false
            end
        end
    end
    -- Coloured tunnel light strips along the wall base for depth readability.
    for z = -40, 40, 20 do
        for _, x in {-28.6, 28.6} do
            local strip = Environment.Part(model, "WallWash", Vector3.new(.15, .5, 14), CFrame.new(x, 1.6, z), Color3.fromRGB(70, 140, 150), Enum.Material.Neon)
            strip.CanCollide, strip.CanQuery = false, false
            strip.Transparency = .3
        end
    end

    -- Benches on both platforms: generated station-bench meshes facing the
    -- track, set back from the platform edge so they don't block the lane.
    for _, x in {-22, 22} do
        for _, z in {-20, 0, 20} do
            local bench = Environment.Mesh(model, "station-bench",
                CFrame.new(x + (x > 0 and 3 or -3), 1.1, z) * CFrame.Angles(0, x > 0 and -math.pi / 2 or math.pi / 2, 0),
                Vector3.new(4.2, 2.4, 1.9))
            bench.CanCollide = false
            bench.CanQuery = false
        end
    end

    -- Poster frames on platform walls: "SERVICE SUSPENDED", timetable.
    for _, x in {-29, 29} do
        for _, z in {-30, 30} do
            local frame = Environment.Part(model, "PosterFrame", Vector3.new(3, 4, .2), CFrame.new(x, 4, z) * CFrame.Angles(0, math.pi / 2, 0), Color3.fromRGB(200, 200, 195), Enum.Material.Metal)
            frame.CanCollide, frame.CanQuery = false, false
            frame:SetAttribute("PbrMaterial", "MetalPlate")
            local poster = Environment.Sign(model, "SERVICE\nSUSPENDED", Vector3.new(x, 4, z), Vector3.new(2.5, 3.5, .1), amber, 90)
            poster.CanCollide, poster.CanQuery = false, false
        end
    end

    -- Lockers in service areas: door banks with vents.
    for _, x in {-28, 28} do
        for _, z in {-44, -26, 26, 44} do
            local locker = Environment.Part(model, "Locker", Vector3.new(2, 6, 1), CFrame.new(x, 1, z), Color3.fromRGB(70, 88, 94), Enum.Material.Metal)
            locker.CanCollide, locker.CanQuery = false, false
            locker:SetAttribute("PbrMaterial", "CorrodedSteel")
        end
    end

    -- Trackside valves: pressure gauges and valve wheels on tunnel walls.
    for _, x in {-28, 28} do
        for _, z in {-30, 0, 30} do
            local valve = Environment.Part(model, "TrackValve", Vector3.new(.5, .5, .2), CFrame.new(x, 2, z), Color3.fromRGB(145, 165, 171), Enum.Material.Metal)
            valve.CanCollide, valve.CanQuery = false, false
            valve:SetAttribute("PbrMaterial", "CorrodedSteel")
        end
    end

    -- Cable trays along tunnel ceiling: conduit runs with junction boxes.
    for _, x in {-26, 26} do
        for z = -50, 50, 20 do
            local tray = Environment.Part(model, "CableTray", Vector3.new(1, .5, 10), CFrame.new(x, 10, z), Color3.fromRGB(80, 90, 95), Enum.Material.Metal)
            tray.CanCollide, tray.CanQuery = false, false
            tray:SetAttribute("PbrMaterial", "CorrodedSteel")
        end
    end

    -- The visual train: generated subway-train-car mesh with weathered panel
    -- texture, plug doors and window strip. Non-uniform Z stretch gives the
    -- ~44-stud consist the hazard lane needs.
    local train = Instance.new("Model")
    train.Name, train.Parent = "Train", model
    local car = Environment.Mesh(train, "subway-train-car", CFrame.new(0, 1.6, -86), Vector3.new(11, 8.4, 44))
    car.CanCollide = false
    car.CanQuery = false
    car:SetAttribute("HazardIndicator", true)
    -- Roof gear: AC pods and a pantograph silhouette for skyline interest.
    for _, z in {-96, -76} do
        local pod = Environment.Part(train, "RoofPod", Vector3.new(4, 1.2, 5), CFrame.new(0, 6.2, z), Color3.fromRGB(52, 58, 60), Enum.Material.Metal)
        pod.CanCollide, pod.CanQuery = false, false
        pod.MaterialVariant = "MetalPlate"
    end
    -- End fascias: the generated mesh can have open/notched end faces, so both
    -- ends get a proud cab face panel, windshield band and marker housing.
    -- The train travels toward +Z, so the cab face is the -64 end.
    local function fascia(z, isFront)
        local face = Environment.Part(train, isFront and "FrontFascia" or "RearFascia",
            Vector3.new(10.6, 7, .5), CFrame.new(0, 1.6, z), Color3.fromRGB(52, 74, 70), Enum.Material.Metal)
        face.CanCollide, face.CanQuery = false, false
        face.MaterialVariant = "MetalPlate"
        local glass = Environment.Part(train, isFront and "FrontWindshield" or "RearWindow",
            Vector3.new(8, 1.9, .3), CFrame.new(0, 3.7, z + (isFront and .35 or -.35)), Color3.fromRGB(24, 34, 38), Enum.Material.Glass)
        glass.Transparency, glass.CanCollide, glass.CanQuery = .25, false, false
        local blind = Environment.Part(train, isFront and "FrontBlind" or "RearBlind", Vector3.new(3.4, 1, .25),
            CFrame.new(0, 4.9, z + (isFront and .4 or -.4)), Color3.fromRGB(30, 36, 34), Enum.Material.Metal)
        blind.CanCollide, blind.CanQuery = false, false
    end
    fascia(-63.7, true)
    fascia(-108.3, false)
    -- Headlight: bright spot on the leading (+Z) end, aimed down the track.
    local headlight = Environment.Part(train, "Headlight", Vector3.new(2, 2, .4),
        CFrame.lookAt(Vector3.new(0, 3, -63.4), Vector3.new(0, 1.5, -20)), Color3.fromRGB(255, 244, 210), Enum.Material.Neon)
    headlight.CanCollide = false
    local headlightLight = Instance.new("SpotLight")
    headlightLight.Color, headlightLight.Brightness, headlightLight.Range, headlightLight.Angle = Color3.fromRGB(255, 244, 210), 3, 60, 25
    headlightLight.Face = Enum.NormalId.Front
    headlightLight.Parent = headlight
    -- Marker lights: red rear, white front.
    local rearLight = Environment.Part(train, "RearLight", Vector3.new(1, 1, .3), CFrame.new(0, 2, -108.6), Color3.fromRGB(220, 60, 60), Enum.Material.Neon)
    rearLight.CanCollide = false
    local frontLight = Environment.Part(train, "FrontLight", Vector3.new(1, 1, .3), CFrame.new(0, 2, -63.6), Color3.fromRGB(255, 255, 255), Enum.Material.Neon)
    frontLight.CanCollide = false
    train.PrimaryPart = car

    -- Dust motes in the tunnel air.
    for _, pos in {{-15, 8, -30}, {15, 8, -30}, {-15, 8, 30}, {15, 8, 30}} do
        local mote = Environment.Part(model, "DustMote", Vector3.one * .1, CFrame.new(unpack(pos)), dark)
        mote.Transparency, mote.CanCollide, mote.CanQuery = 1, false, false
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
        emitter.Color = ColorSequence.new(Color3.fromRGB(200, 190, 170))
        emitter.Lifetime = NumberRange.new(3, 6)
        emitter.Rate = 4
        emitter.Size = NumberSequence.new(.1)
        emitter.Speed = NumberRange.new(.3, .8)
        emitter.SpreadAngle = Vector2.new(15, 15)
        emitter.Parent = mote
    end

    -- Rail dust particles near the track bed.
    for _, pos in {{-3, 1, -40}, {3, 1, -40}, {-3, 1, 0}, {3, 1, 0}, {-3, 1, 40}, {3, 1, 40}} do
        local dust = Environment.Part(model, "RailDust", Vector3.one * .1, CFrame.new(unpack(pos)), dark)
        dust.Transparency, dust.CanCollide, dust.CanQuery = 1, false, false
        local emitter = Instance.new("ParticleEmitter")
        emitter.Texture = "rbxasset://textures/particles/smoke_main.dds"
        emitter.Color = ColorSequence.new(Color3.fromRGB(150, 140, 120))
        emitter.Lifetime = NumberRange.new(1, 2)
        emitter.Rate = 2
        emitter.Size = NumberSequence.new(.2)
        emitter.Speed = NumberRange.new(.5, 1)
        emitter.SpreadAngle = Vector2.new(20, 20)
        emitter.Parent = dust
    end

    local markers = Instance.new("Folder")
    markers.Name, markers.Parent = "Markers", model
    local function marker(name, position, size)
        local part = Environment.Part(markers, name, size or Vector3.one, CFrame.new(position))
        part.Transparency, part.CanCollide, part.CanQuery = 1, false, false
        return part
    end
    marker("EntranceSpawn", Vector3.new(-22, 4, 46))
    local elevatorSocket = marker("ElevatorSocket", Vector3.new(0, 0, 62))
    elevatorSocket.CFrame *= CFrame.Angles(0, math.pi, 0)
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
    Environment.Part(model, "ElevatorBridge", Vector3.new(60, 1, 16), CFrame.new(0, -.5, 56), dark)
    return model
end

-- Legacy pre-V6 laboratory is intentionally not assigned to BuildLaboratory;
-- the upgraded definition above is the authoritative runtime builder.
function Environment.BuildLaboratoryLegacy()
    local model = Instance.new("Model")
    model.Name = "FloodedLaboratory"
    local origin = Environment.Part(model, "Origin", Vector3.one * .1, CFrame.new(), dark)
    origin.Transparency, origin.CanCollide, origin.CanQuery = 1, false, false
    model.PrimaryPart = origin
    local architecture = Instance.new("Folder")
    architecture.Name, architecture.Parent = "ImportedArchitecture", model
    local basin = Environment.Part(model, "Basin", Vector3.new(94, 1, 110), CFrame.new(0, -4, 0), dark, Enum.Material.Concrete)
    local basinCost = Instance.new("PathfindingModifier")
    basinCost.Label, basinCost.Parent = "FloodBasin", basin
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
    -- Recovery ramps cross the gaps between rail segments, so falling into
    -- the basin never leaves a player trapped below the raised catwalk.
    for _, x in {-30, 30} do
        for _, z in {-32, 32} do
            local slope = math.atan(3.5 / 12) * (x > 0 and 1 or -1)
            Environment.Part(model, "BasinAccessRamp", Vector3.new(12.5, 1, 4),
                CFrame.new(x, -2.25, z) * CFrame.Angles(0, 0, slope), amber)
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
    local elevatorSocket = marker("ElevatorSocket", Vector3.new(0, 0, 63))
    elevatorSocket.CFrame *= CFrame.Angles(0, math.pi, 0)
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
