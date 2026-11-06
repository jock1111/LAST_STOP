local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Position: West pump room looking at pump A
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(-37, 4, 730), Vector3.new(-37, 2, 738))

local startTime = os.clock()
local connection
connection = RunService.RenderStepped:Connect(function()
    if os.clock() - startTime < 2 then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(Vector3.new(-37, 4, 730), Vector3.new(-37, 2, 738))
    else
        connection:Disconnect()
    end
end)

return {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
}
