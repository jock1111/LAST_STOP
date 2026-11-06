local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local result = {
    -- Camera state
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
    cameraFocus = tostring(camera.Focus),
    cameraSubject = tostring(camera.CameraSubject),
    cameraViewportSize = tostring(camera.ViewportSize),
    cameraFieldOfView = camera.FieldOfView,

    -- Player state
    playerExists = player ~= nil,
    playerPosition = "none",
    playerCharacterExists = false,
    playerHumanoidRootPart = "none",
    playerHumanoidHealth = "none",

    -- Workspace state
    isClient = RunService:IsClient(),
    isServer = RunService:IsServer(),
    isStudio = RunService:IsStudio(),
    streamingEnabled = Workspace.StreamingEnabled,

    -- Active expedition
    activeExpedition = "none",
    floorModels = {},
}

-- Player character details
if player and player.Character then
    result.playerCharacterExists = true
    local root = player.Character:FindFirstChild("HumanoidRootPart")
    if root then
        result.playerPosition = tostring(root.Position)
        result.playerHumanoidRootPart = tostring(root.CFrame)
    end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        result.playerHumanoidHealth = tostring(humanoid.Health) .. "/" .. tostring(humanoid.MaxHealth)
    end
end

-- Active expedition details
local world = Workspace:FindFirstChild("LastStopWorld")
if world then
    local runtime = world:FindFirstChild("Runtime")
    if runtime then
        local active = runtime:FindFirstChild("ActiveExpedition")
        if active then
            result.activeExpedition = active:GetFullName()
            for _, child in ipairs(active:GetChildren()) do
                if child:IsA("Model") then
                    local cf, size = child:GetBoundingBox()
                    table.insert(result.floorModels, {
                        name = child.Name,
                        theme = child:GetAttribute("FloorTheme"),
                        pivot = tostring(child:GetPivot().Position),
                        boundingBoxCF = tostring(cf),
                        boundingBoxSize = tostring(size),
                        boundingBoxMin = tostring(cf.Position - size/2),
                        boundingBoxMax = tostring(cf.Position + size/2),
                        descendants = #child:GetDescendants(),
                        baseParts = (function()
                            local count = 0
                            for _, d in ipairs(child:GetDescendants()) do
                                if d:IsA("BasePart") then count = count + 1 end
                            end
                            return count
                        end)(),
                        meshParts = (function()
                            local count = 0
                            for _, d in ipairs(child:GetDescendants()) do
                                if d:IsA("MeshPart") then count = count + 1 end
                            end
                            return count
                        end)(),
                    })
                end
            end
        end
    end
end

return result
