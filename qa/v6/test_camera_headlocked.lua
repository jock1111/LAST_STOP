local Workspace = game:GetService("Workspace")
local camera = Workspace.CurrentCamera
task.wait(0.2)
local before = tostring(camera.CFrame)
camera.HeadLocked = false
camera.CameraType = Enum.CameraType.Custom
task.wait(0.5)
return {
    headLocked = camera.HeadLocked,
    cameraType = tostring(camera.CameraType),
    before = before,
    after = tostring(camera.CFrame),
    focus = tostring(camera.Focus),
}
