local ServerStorage = game:GetService("ServerStorage")
local lib = ServerStorage:WaitForChild("LastStopAssets"):WaitForChild("Environment", 5)
local out = {libClass = lib and lib.ClassName, children = {}}
if lib then
    for _, c in ipairs(lib:GetChildren()) do
        table.insert(out.children, c.Name .. " (" .. c.ClassName .. ")")
    end
    local m = lib:FindFirstChild("containment-vessel", true)
    out.found = m and (m:GetFullName() .. " " .. m.ClassName) or "nil"
end
return out
