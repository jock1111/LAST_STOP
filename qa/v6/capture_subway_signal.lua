local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Position: Signal box area looking at the south end
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(24, 5, 45), Vector3.new(24, 2, 40))

local startTime = os.clock()
local connection
connection = RunService.RenderStepped:Connect(function()
    if os.clock() - startTime < 2 then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(Vector3.new(24, 5, 45), Vector3.new(24, 2, 40))
    else
        connection:Disconnect()
    end
end)

return {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
}
