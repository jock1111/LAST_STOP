local Workspace = game:GetService("Workspace")
local result = {models = {}, parts = {}}
for _, child in ipairs(Workspace:GetChildren()) do
    table.insert(result.models, child.Name .. " (" .. child.ClassName .. ")")
end
for _, d in ipairs(Workspace:GetDescendants()) do
    if d:IsA("MeshPart") or d:IsA("Part") then
        local name = d.Name:lower()
        if name:find("canister") or name:find("specimen") or name:find("sealed") or (d.Parent and d.Parent.Name:lower():find("sealed")) then
            table.insert(result.parts, {
                class = d.ClassName,
                name = d.Name,
                fullName = d:GetFullName(),
                meshId = d:IsA("MeshPart") and tostring(d.MeshId) or nil,
                textureId = d:IsA("MeshPart") and tostring(d.TextureID) or nil,
                size = tostring(d.Size),
                cframe = tostring(d.CFrame),
                material = tostring(d.Material),
                color = tostring(d.Color),
            })
        end
    end
end
return result
