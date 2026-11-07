local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local data = require(game:GetService("ReplicatedStorage").Shared.StalkerMotion)
local Controller = {}

function Controller.Start()
    local clips = {}
    for name, clip in data do
        clips[name] = {fps = clip.fps, frames = {}}
        for _, frame in clip.frames do
            local poses = {}
            for bone, matrix in frame do
                poses[bone] = CFrame.new(table.unpack(matrix))
            end
            table.insert(clips[name].frames, poses)
        end
    end
    local creatures = {}
    local function register(model)
        if not model:IsA("Model") or creatures[model] then return end
        if not model:GetAttribute("V4Stalker") then
            if model.Name == "Stalker" then
                model:GetAttributeChangedSignal("V4Stalker"):Once(function() register(model) end)
            end
            return
        end
        local bones = {}
        local function bindBone(bone)
            if bone:IsA("Bone") then bones[bone.Name] = bone end
        end
        for _, bone in model:GetDescendants() do bindBone(bone) end
        creatures[model] = {bones = bones, time = 0, connection = model.DescendantAdded:Connect(bindBone)}
    end
    for _, item in workspace:GetDescendants() do register(item) end
    workspace.DescendantAdded:Connect(function(item)
        if item:IsA("Model") then task.defer(register, item) end
    end)
    local elapsed = 0
    RunService.RenderStepped:Connect(function(dt)
        elapsed += dt
        if elapsed < 1 / 30 then return end
        local step = elapsed
        elapsed = 0
        for model, record in creatures do
            if not model.Parent then record.connection:Disconnect(); creatures[model] = nil; continue end
            local root = model:FindFirstChild("HumanoidRootPart")
            local camera = workspace.CurrentCamera
            if not root or not camera or (root.Position - camera.CFrame.Position).Magnitude > 130 then continue end
            local state = model:GetAttribute("AIState")
            local clipName = state == "Chase" and "Run" or (state == "Patrol" or state == "Search" or state == "Investigate") and "Walk" or "Idle"
            local clip = clips[clipName]
            record.time += step
            local frame = record.time * clip.fps
            local index = math.floor(frame) % #clip.frames + 1
            local nextIndex = index % #clip.frames + 1
            for name, bone in record.bones do
                local first, second = clip.frames[index][name], clip.frames[nextIndex][name]
                if first and second then
                    local target = first:Lerp(second, frame % 1)
                    -- A readable forward lunge during the attack's visible windup.
                    if state == "Windup" and name == "joint3" then target *= CFrame.Angles(0, 0, -.3) end
                    bone.Transform = bone.Transform:Lerp(target, math.min(step * 12, 1))
                end
            end
        end
    end)
end
return Controller
