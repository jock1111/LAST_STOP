local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
local before = tostring(camera.CFrame)

-- Kick the camera module by cycling subject and type.
camera.CameraSubject = nil
task.wait(0.1)
camera.CameraType = Enum.CameraType.Scriptable
task.wait(0.1)
camera.CameraType = Enum.CameraType.Custom
camera.CameraSubject = humanoid
task.wait(0.5)
return {
    before = before,
    after = tostring(camera.CFrame),
    focus = tostring(camera.Focus),
    subject = tostring(camera.CameraSubject),
    type = tostring(camera.CameraType),
}
