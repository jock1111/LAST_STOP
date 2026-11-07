local Workspace = game:GetService("Workspace")
local assetId = "71213574399953"
local result = {matches = {}, recent = {}}
for _, d in ipairs(Workspace:GetDescendants()) do
    if d:IsA("MeshPart") then
        local meshId = tostring(d.MeshId)
        if meshId:find(assetId, 1, true) then
            table.insert(result.matches, {
                name = d.Name,
                fullName = d:GetFullName(),
                meshId = meshId,
                textureId = tostring(d.TextureID),
                size = tostring(d.Size),
                cframe = tostring(d.CFrame),
            })
        end
    end
    if d:IsA("Model") and (d.Name:lower():find("canister") or d.Name:lower():find("specimen")) then
        table.insert(result.recent, d:GetFullName())
    end
end
return result
