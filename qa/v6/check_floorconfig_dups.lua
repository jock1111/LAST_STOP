local config = game:GetService("ReplicatedStorage").Shared.Config
local out = {children = {}}
for _, c in ipairs(config:GetChildren()) do
    table.insert(out.children, c.Name .. " (" .. c.ClassName .. ")")
end
local fc = config:FindFirstChild("FloorConfig")
out.resolved = fc and fc:GetFullName() or "nil"
-- also check for duplicates anywhere
local dups = {}
for _, d in ipairs(game:GetDescendants()) do
    if d.Name == "FloorConfig" then table.insert(dups, d:GetFullName() .. " (" .. d.ClassName .. ")") end
end
out.allFloorConfigs = dups
return out
