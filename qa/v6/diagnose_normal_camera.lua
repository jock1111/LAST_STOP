local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local character = player and player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local root = character and character:FindFirstChild("HumanoidRootPart")
local head = character and character:FindFirstChild("Head")

local function cf(cf)
    if not cf then return "nil" end
    return string.format("%.2f, %.2f, %.2f | look %.2f, %.2f, %.2f", cf.Position.X, cf.Position.Y, cf.Position.Z, cf.LookVector.X, cf.LookVector.Y, cf.LookVector.Z)
end

local subject = camera.CameraSubject
local result = {
    cameraType = tostring(camera.CameraType),
    cameraCFrame = cf(camera.CFrame),
    cameraFocus = cf(camera.Focus),
    cameraSubject = subject and (subject:GetFullName() .. " (" .. subject.ClassName .. ")") or "nil",
    cameraHeadLocked = camera.HeadLocked,
    cameraFieldOfView = camera.FieldOfView,
    playerCameraMode = tostring(player.CameraMode),
    playerDevComputer = tostring(player.DevComputerMovementMode),
    playerDevTouch = tostring(player.DevTouchMovementMode),
    characterPosition = root and tostring(root.Position) or "none",
    headPosition = head and tostring(head.Position) or "none",
    humanoidCameraOffset = humanoid and tostring(humanoid.CameraOffset) or "none",
    playerMinZoom = player.CameraMinZoomDistance,
    playerMaxZoom = player.CameraMaxZoomDistance,
    humanoidState = humanoid and tostring(humanoid:GetState()) or "none",
    humanoidHipHeight = humanoid and humanoid.HipHeight or "none",
    isClient = RunService:IsClient(),
    isStudio = RunService:IsStudio(),
}

-- Raycast from head toward camera to see if geometry blocks the view.
if head and camera then
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    local hit = Workspace:Raycast(head.Position, camera.CFrame.Position - head.Position, params)
    result.headToCameraHit = hit and (hit.Instance:GetFullName() .. " @ " .. tostring(hit.Position) .. " dist " .. tostring(hit.Distance)) or "none"
end
return result
