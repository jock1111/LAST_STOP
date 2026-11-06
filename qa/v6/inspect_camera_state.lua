local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local result = {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
    cameraLookVector = tostring(camera.CFrame.LookVector),
    playerPosition = player and player.Character and player.Character:FindFirstChild("HumanoidRootPart") and tostring(player.Character.HumanoidRootPart.Position) or "no character",
    isStudio = RunService:IsStudio(),
    isClient = RunService:IsClient(),
    isServer = RunService:IsServer(),
}

return result
