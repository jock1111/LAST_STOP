local ServerStorage = game:GetService("ServerStorage")
local lib = ServerStorage:WaitForChild("LastStopAssets"):WaitForChild("Environment")
local names = {"specimen-canister","containment-vessel","pump-machine","research-console","subway-train-car","station-bench","signal-post","subway-track-section"}
local out = {}
for _, name in ipairs(names) do
    local model = lib:FindFirstChild(name)
    if not model then
        table.insert(out, name .. ":MISSING")
    else
        local mesh = model:FindFirstChildWhichIsA("MeshPart", true)
        if mesh then
            mesh.Name = name
            mesh.Anchored = true
            mesh.CanTouch = false
            mesh.CFrame = CFrame.new(0, -500, 0)
            table.insert(out, name .. ":OK meshId=" .. tostring(mesh.MeshId) .. " size=" .. tostring(mesh.Size))
        else
            table.insert(out, name .. ":NOMESH " .. model.ClassName)
        end
    end
end
return out
