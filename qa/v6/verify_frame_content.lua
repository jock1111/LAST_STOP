local Workspace = game:GetService("Workspace")
local camera = Workspace.CurrentCamera

-- Check what's visible from the camera
local result = {
    cameraCFrame = tostring(camera.CFrame),
    cameraPosition = tostring(camera.CFrame.Position),
    lookVector = tostring(camera.CFrame.LookVector),
    viewportSize = tostring(camera.ViewportSize),
}

-- Check if there are any parts in front of the camera
local rayOrigin = camera.CFrame.Position
local rayDirection = camera.CFrame.LookVector * 200
local raycastParams = RaycastParams.new()
raycastParams.FilterType = Enum.RaycastFilterType.Exclude
raycastParams.FilterDescendantsInstances = {Workspace:FindFirstChild("Camera")}

local hit = Workspace:Raycast(rayOrigin, rayDirection, raycastParams)
if hit then
    result.hitPart = hit.Instance.Name
    result.hitPosition = tostring(hit.Position)
    result.hitDistance = hit.Distance
    result.hitMaterial = tostring(hit.Instance.Material)
else
    result.hitPart = "none"
end

-- Count visible parts in the active expedition
local world = Workspace:FindFirstChild("LastStopWorld")
if world then
    local runtime = world:FindFirstChild("Runtime")
    if runtime then
        local active = runtime:FindFirstChild("ActiveExpedition")
        if active then
            for _, child in ipairs(active:GetChildren()) do
                if child:IsA("Model") then
                    result.floorName = child.Name
                    result.floorTheme = child:GetAttribute("FloorTheme")
                    result.floorPivot = tostring(child:GetPivot().Position)
                    local count = 0
                    for _, descendant in ipairs(child:GetDescendants()) do
                        if descendant:IsA("BasePart") then
                            count = count + 1
                        end
                    end
                    result.floorPartCount = count
                end
            end
        end
    end
end

return result
