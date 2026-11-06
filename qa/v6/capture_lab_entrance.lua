local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Position: Entrance looking down main corridor
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(0, 6, 745), Vector3.new(0, 3, 700))

local startTime = os.clock()
local connection
connection = RunService.RenderStepped:Connect(function()
    if os.clock() - startTime < 2 then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(Vector3.new(0, 6, 745), Vector3.new(0, 3, 700))
    else
        connection:Disconnect()
    end
end)

return {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
}
