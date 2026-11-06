local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local camera = Workspace.CurrentCamera

camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(0, 6, 700), Vector3.new(-25, 4, 673))

local startTime = os.clock()
local connection
connection = RunService.RenderStepped:Connect(function()
    if os.clock() - startTime < 4 then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(Vector3.new(0, 6, 700), Vector3.new(-25, 4, 673))
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
