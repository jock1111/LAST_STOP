local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Position: Center of room looking north at both platforms and track
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(0, 8, 720), Vector3.new(0, 2, 650))

local startTime = os.clock()
local connection
connection = RunService.RenderStepped:Connect(function()
    if os.clock() - startTime < 3 then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(Vector3.new(0, 8, 720), Vector3.new(0, 2, 650))
    else
        connection:Disconnect()
    end
end)

return {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
}
