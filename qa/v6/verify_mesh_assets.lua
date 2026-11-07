local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local lib = ServerStorage.LastStopAssets.Environment
local names = {"specimen-canister","containment-vessel","pump-machine","research-console","subway-train-car","station-bench","signal-post","subway-track-section"}
local out = {}
for _, name in ipairs(names) do
    local mesh
    for _, d in ipairs(lib:GetDescendants()) do
        if d:IsA("MeshPart") and d.Name == name then mesh = d break end
    end
    local entry = {found = mesh ~= nil}
    if mesh then
        entry.meshId = tostring(mesh.MeshId)
        entry.textureId = tostring(mesh.TextureID)
        entry.size = tostring(mesh.Size)
        entry.hasMeshContent = mesh.MeshId ~= "" and mesh.MeshId ~= "rbxassetid://0"
    end
    -- count live usages in the active expedition
    local uses = 0
    local world = Workspace:FindFirstChild("LastStopWorld")
    local active = world and world:FindFirstChild("Runtime") and world.Runtime:FindFirstChild("ActiveExpedition")
    if active then
        for _, d in ipairs(active:GetDescendants()) do
            if d:IsA("MeshPart") and d.Name == name then uses += 1 end
        end
    end
    entry.liveUses = uses
    table.insert(out, entry)
end
return out
