-- QA/dev sync: inserts the Studio-generated meshes into the open place's
-- ServerStorage.LastStopAssets.Environment library (Edit mode only).
local ServerStorage = game:GetService("ServerStorage")
local lib = ServerStorage:WaitForChild("LastStopAssets"):WaitForChild("Environment")

local MESHES = {
    { name = "specimen-canister",    meshId = "rbxassetid://95792177258500", textureId = "rbxassetid://120915859445902", size = Vector3.new(1.08338869, 3, 1.09786355) },
    { name = "containment-vessel",   meshId = "rbxassetid://71376769722129", textureId = "rbxassetid://78261601254527", size = Vector3.new(6.14523125, 12, 5.68912268) },
    { name = "pump-machine",         meshId = "rbxassetid://87119713783145", textureId = "rbxassetid://112175610566765", size = Vector3.new(3.70586348, 8, 2.90696478) },
    { name = "research-console",     meshId = "rbxassetid://76438650829671", textureId = "rbxassetid://92729882681763", size = Vector3.new(5.92827797, 2.75467777, 4) },
    { name = "subway-train-car",     meshId = "rbxassetid://75278130929878", textureId = "rbxassetid://81495936608992", size = Vector3.new(6.73513699, 8, 15.68163967) },
    { name = "station-bench",        meshId = "rbxassetid://113924694873821", textureId = "rbxassetid://124826055360128", size = Vector3.new(3.42565823, 2, 1.29859173) },
    { name = "signal-post",          meshId = "rbxassetid://71593920777017", textureId = "rbxassetid://117247863089433", size = Vector3.new(1.06332707, 6, 0.95463395) },
    { name = "subway-track-section", meshId = "rbxassetid://134933032983834", textureId = "rbxassetid://72808269414642", size = Vector3.new(1.83820772, 2, 1.14464617) },
}

-- Parent new nodes beside the existing "*_Node" models.
local parent = lib
for _, child in ipairs(lib:GetChildren()) do
    if child:IsA("Model") then parent = child.Parent break end
end

local results = {}
for _, def in ipairs(MESHES) do
    if lib:FindFirstChild(def.name, true) then
        table.insert(results, "SKIP " .. def.name)
    else
        local node = Instance.new("Model")
        node.Name = def.name .. "_Node"
        local mesh = Instance.new("MeshPart")
        mesh.Name = def.name
        mesh.MeshId = def.meshId
        mesh.TextureID = def.textureId
        mesh.Size = def.size
        mesh.Anchored = true
        mesh.CanCollide = true
        mesh.CanTouch = false
        mesh.CastShadow = true
        mesh.CFrame = CFrame.new(0, -500, 0)
        mesh.Parent = node
        node.Parent = parent
        table.insert(results, "OK " .. def.name)
    end
end
return results
