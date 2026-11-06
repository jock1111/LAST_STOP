local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local result = {
    playerPosition = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and tostring(player.Character.HumanoidRootPart.Position) or "no character",
    playerAttributes = {},
    activeExpeditionChildren = {},
    runtimeChildren = {},
}

if player then
    for key, value in pairs(player:GetAttributes()) do
        result.playerAttributes[key] = tostring(value)
    end
end

local world = Workspace:FindFirstChild("LastStopWorld")
if world then
    local runtime = world:FindFirstChild("Runtime")
    if runtime then
        for _, child in ipairs(runtime:GetChildren()) do
            table.insert(result.runtimeChildren, child.Name .. " (" .. child.ClassName .. ")")
            if child.Name == "ActiveExpedition" then
                for _, expChild in ipairs(child:GetChildren()) do
                    table.insert(result.activeExpeditionChildren, expChild.Name .. " (" .. expChild.ClassName .. ")")
                end
            end
        end
    end
end

return result
