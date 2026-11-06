local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Set camera inside the Subway room, below ceiling (Y=13), looking at platform
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(0, 8, 750), Vector3.new(0, 2, 700))

-- Keep resetting the camera every frame for 3 seconds
local startTime = os.clock()
local connection
connection = RunService.RenderStepped:Connect(function()
    if os.clock() - startTime < 3 then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(Vector3.new(0, 8, 750), Vector3.new(0, 2, 700))
    else
        connection:Disconnect()
    end
end)

return {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
}
