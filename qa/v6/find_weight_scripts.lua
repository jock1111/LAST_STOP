local out = {}
for _, d in ipairs(game:GetDescendants()) do
    if d:IsA("LuaSourceContainer") then
        local src = d.Source or ""
        if src:find("Weight", 1, true) and (src:find("FloorConfig", 1, true) or src:find("Floors", 1, true)) then
            table.insert(out, d:GetFullName() .. " (" .. d.ClassName .. ")")
        end
    end
end
return out
