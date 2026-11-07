local Workspace = game:GetService("Workspace")
local camera = Workspace.CurrentCamera
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.lookAt(Vector3.new(-8, 8, 712), Vector3.new(-24, 4, 697))
camera.FieldOfView = 80
return { position = tostring(camera.CFrame.Position), fov = camera.FieldOfView }
