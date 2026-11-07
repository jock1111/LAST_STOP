local counts = {Script = 0, LocalScript = 0, ModuleScript = 0}
local names = {}
for _, d in ipairs(game:GetDescendants()) do
    if counts[d.ClassName] ~= nil then
        counts[d.ClassName] += 1
        table.insert(names, d.ClassName .. ":" .. d:GetFullName())
    end
end
return {counts = counts, total = counts.Script + counts.LocalScript + counts.ModuleScript}
