local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Disable HUDController camera control by setting a flag
player:SetAttribute("QA_CameraLock", true)

-- Set camera to Scriptable and position it above the Subway platform
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(0, 15, 750), Vector3.new(0, 2, 700))

-- Keep resetting the camera every frame for 2 seconds
local startTime = os.clock()
local connection
connection = RunService.RenderStepped:Connect(function()
    if os.clock() - startTime < 2 then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(Vector3.new(0, 15, 750), Vector3.new(0, 2, 700))
    else
        connection:Disconnect()
        player:SetAttribute("QA_CameraLock", false)
    end
end)

return {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
}
