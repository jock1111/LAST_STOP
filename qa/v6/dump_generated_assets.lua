local Workspace = game:GetService("Workspace")
local keys = {
    ["small sealed"] = "specimen-canister",
    ["tall cylindrical"] = "containment-vessel",
    ["industrial water pump"] = "pump-machine",
    ["laboratory research console"] = "research-console",
    ["old abandoned subway train car"] = "subway-train-car",
    ["subway platform bench"] = "station-bench",
    ["railway signal post"] = "signal-post",
    ["straight subway track"] = "subway-track-section",
}
local result = {}
for _, child in ipairs(Workspace:GetChildren()) do
    if child:IsA("Model") then
        local lower = child.Name:lower()
        local key
        for prefix, name in pairs(keys) do
            if lower:find(prefix, 1, true) then key = name break end
        end
        if key then
            local entry = {key = key, model = child.Name, parts = {}}
            for _, d in ipairs(child:GetDescendants()) do
                if d:IsA("MeshPart") then
                    table.insert(entry.parts, {
                        name = d.Name,
                        meshId = tostring(d.MeshId),
                        textureId = tostring(d.TextureID),
                        size = tostring(d.Size),
                        cframe = tostring(d.CFrame),
                        material = tostring(d.Material),
                        color = tostring(d.Color),
                    })
                elseif d:IsA("BasePart") then
                    table.insert(entry.parts, {
                        name = d.Name,
                        class = d.ClassName,
                        size = tostring(d.Size),
                        cframe = tostring(d.CFrame),
                        material = tostring(d.Material),
                        color = tostring(d.Color),
                    })
                end
            end
            table.insert(result, entry)
        end
    end
end
return result
