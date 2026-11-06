local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Position camera to look at containment area
-- Containment cylinders at local (±25, ±27), world (±25, y, 673) and (±25, y, 727)
-- Put camera at center-south, looking north at containment ring
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(0, 6, 720), Vector3.new(0, 3, 673))

-- Lock camera for 3 seconds
local startTime = os.clock()
local connection
connection = RunService.RenderStepped:Connect(function()
    if os.clock() - startTime < 3 then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(Vector3.new(0, 6, 720), Vector3.new(0, 3, 673))
    else
        connection:Disconnect()
    end
end)

return {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
    lookVector = tostring(camera.CFrame.LookVector),
}
