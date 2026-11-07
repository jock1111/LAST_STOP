local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- Position camera inside the Subway room, above floor, below ceiling
-- Room bounds: X -31 to 31, Y -5 to 15.5, Z 479.6 to 770.55
-- Player at (-26.5, 2.94, 743) on west platform
-- Put camera at center-south, looking north at platforms and track
camera.CameraType = Enum.CameraType.Scriptable
camera.CFrame = CFrame.new(Vector3.new(0, 8, 750), Vector3.new(0, 2, 650))

-- Lock camera for 3 seconds
local startTime = os.clock()
local connection
connection = RunService.RenderStepped:Connect(function()
    if os.clock() - startTime < 3 then
        camera.CameraType = Enum.CameraType.Scriptable
        camera.CFrame = CFrame.new(Vector3.new(0, 8, 750), Vector3.new(0, 2, 650))
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
