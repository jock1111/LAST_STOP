local ServerStorage = game:GetService("ServerStorage")
local lib = ServerStorage.LastStopAssets.Environment
local mesh
for _, d in ipairs(lib:GetDescendants()) do
    if d:IsA("MeshPart") and d.Name == "subway-train-car" then mesh = d break end
end
if not mesh then return "mesh not found" end
local clone = mesh:Clone()
clone.Name = "TrainMeshInspect"
clone.Anchored = true
clone.CFrame = CFrame.new(0, 10, 0)
clone.Parent = workspace
local bounds = clone.Size
return {size = tostring(bounds), meshId = tostring(mesh.MeshId)}
