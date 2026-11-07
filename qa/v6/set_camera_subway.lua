local Workspace = game:GetService("Workspace")
local camera = Workspace.CurrentCamera

-- Set camera to look at the Subway platform from above
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(0, 15, 750), Vector3.new(0, 2, 700))

-- Wait a frame for the camera to update
task.wait(0.1)

return {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
}
