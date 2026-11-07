local Workspace = game:GetService("Workspace")
local target
for _, child in ipairs(Workspace:GetChildren()) do
    if child:IsA("Model") and child.Name:lower():find("small sealed") then
        target = child
        break
    end
end
local result = {model = target and target:GetFullName() or "none", descendants = {}}
if target then
    for _, d in ipairs(target:GetDescendants()) do
        if d:IsA("MeshPart") or d:IsA("Part") or d:IsA("Model") or d:IsA("Folder") then
            table.insert(result.descendants, {
                class = d.ClassName,
                name = d.Name,
                meshId = d:IsA("MeshPart") and tostring(d.MeshId) or nil,
                textureId = d:IsA("MeshPart") and tostring(d.TextureID) or nil,
                size = d:IsA("BasePart") and tostring(d.Size) or nil,
                cframe = d:IsA("BasePart") and tostring(d.CFrame) or nil,
                material = d:IsA("BasePart") and tostring(d.Material) or nil,
                color = d:IsA("BasePart") and tostring(d.Color) or nil,
                transparency = d:IsA("BasePart") and d.Transparency or nil,
            })
        end
    end
end
return result
