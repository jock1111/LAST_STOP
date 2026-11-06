local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local result = {
    playerPosition = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and tostring(player.Character.HumanoidRootPart.Position) or "no character",
    workspaceChildren = {},
    lastStopWorld = nil,
    activeExpedition = nil,
    floorModels = {},
}

for _, child in ipairs(Workspace:GetChildren()) do
    table.insert(result.workspaceChildren, child.Name .. " (" .. child.ClassName .. ")")
end

local world = Workspace:FindFirstChild("LastStopWorld")
if world then
    result.lastStopWorld = world:GetFullName()
    local runtime = world:FindFirstChild("Runtime")
    if runtime then
        local active = runtime:FindFirstChild("ActiveExpedition")
        if active then
            result.activeExpedition = active:GetFullName()
            for _, child in ipairs(active:GetChildren()) do
                if child:IsA("Model") then
                    table.insert(result.floorModels, {
                        name = child.Name,
                        theme = child:GetAttribute("FloorTheme"),
                        pivot = tostring(child:GetPivot().Position),
                        children = #child:GetChildren(),
                        descendants = #child:GetDescendants(),
                    })
                end
            end
        end
    end
end

return result
