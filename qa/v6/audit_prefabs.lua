-- Read-only V6 prefab audit. Run in Studio Edit mode via tools/studio-mcp.mjs.
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local assets = ServerStorage:WaitForChild("LastStopAssets")

local function round(n) return math.floor(n * 100 + 0.5) / 100 end
local function v3(v) return {round(v.X), round(v.Y), round(v.Z)} end
local function box(model)
    local ok, cf, size = pcall(function() return model:GetBoundingBox() end)
    if not ok then return nil end
    return {center = v3(cf.Position), size = v3(size)}
end
local function summarize(model, names)
    local counts, rows = {}, {}
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then
            counts[d.Name] = (counts[d.Name] or 0) + 1
            if names[d.Name] then
                table.insert(rows, {
                    name = d.Name,
                    pos = v3(d.Position),
                    size = v3(d.Size),
                    color = {d.Color.R * 255, d.Color.G * 255, d.Color.B * 255},
                    material = d.Material.Name,
                    transparency = round(d.Transparency),
                    canCollide = d.CanCollide,
                    canQuery = d.CanQuery,
                })
            end
        end
    end
    return {parts = #model:GetDescendants(), bounds = box(model), counts = counts, rows = rows}
end

local lobbyNames = {}
for _, n in ipairs({"WallPlaster", "WallWainscot", "WallCap", "ColumnPlinth", "ColumnWeb", "ColumnFlange",
    "ColumnCapital", "CofferedCeiling", "RivetedCeilingBeam", "QueueConsole", "QueueScreen", "ConsoleKey",
    "MainStationSign", "BoardingWayfinding", "PlatformSign", "OriginalPoster", "SafetyPoster", "LobbySpawnPoint",
    "Floor", "ServicePipe", "CableTray", "TactilePaver", "GalleryLintel", "GalleryRail"}) do lobbyNames[n] = true end

local hospitalNames = {}
for _, n in ipairs({"Wall", "WardWainscot", "WardCap", "WardBed", "BedBlanket", "BedPillow", "BedsideCabinet",
    "CurtainTrack", "FadedCurtainFold", "ScannerTable", "ScannerSupport", "ScannerArch", "ScannerLabel",
    "NursesCounter", "NursesTop", "StationMonitor", "ChartTray", "CrashCart", "TreatmentTrolley", "Tray",
    "ArchiveShelf", "ShelfBoard", "MedCabinet", "MedTop", "MedTray", "MedBin", "DoorLintel", "DoorJamb",
    "CeilingTiles", "TerrazzoTile", "BreachTape", "PeelingPaint", "WallProtectionRail", "OverheadWayfinding",
    "HospitalIdentifier", "SpillPuddle", "DroppedClipboard", "SpilledPills"}) do hospitalNames[n] = true end

local envMeshes = {}
for _, d in ipairs(assets.Environment:GetDescendants()) do
    if d:IsA("MeshPart") then
        table.insert(envMeshes, {name = d.Name, size = v3(d.Size), pos = v3(d.Position), texture = d.TextureID ~= ""})
    end
end

local elevator = summarize(assets.Elevator, {["IndicatorDot1"] = true, ["IndicatorDot2"] = true, ["IndicatorDot3"] = true,
    ["FloorDisplay"] = true, ["DoorLeft"] = true, ["DoorRight"] = true, ["OuterJamb"] = true, ["EntranceSpawn"] = true,
    ["ElevatorReturnZone"] = true, ["ControlPanel"] = true, ["TactileButton"] = true, ["Threshold"] = true})

local result = {
    lobby = summarize(assets.Lobby, lobbyNames),
    hospital = summarize(assets.Floors.Hospital, hospitalNames),
    elevator = elevator,
    environmentMeshes = envMeshes,
}
return HttpService:JSONEncode(result)
