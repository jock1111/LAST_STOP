local SoundService = game:GetService("SoundService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")
local assets = require(game:GetService("ReplicatedStorage").Shared.SoundAssets)
local Soundscape = {}
Soundscape.__index = Soundscape

local function sound(parent, name, volume, looped)
    local audio = Instance.new("Sound")
    audio.Name, audio.SoundId, audio.Volume, audio.Looped = name, assets[name], volume, looped or false
    audio.RollOffMinDistance, audio.RollOffMaxDistance = 7, 65
    audio.Parent = parent
    return audio
end

function Soundscape.new()
    local self = setmetatable({state = "Lobby", progress = 0, creatures = {}}, Soundscape)
    self.drone = sound(SoundService, "TransitDrone", .14, true)
    self.water = sound(SoundService, "FloodAmbience", 0, true)
    self.travel = sound(SoundService, "ElevatorTravel", .38)
    self.chime = sound(SoundService, "ObjectiveChime", .3)
    self.warn = sound(SoundService, "ObjectiveChime", .5)
    self.drone:Play()
    self.water:Play()
    task.spawn(function()
        ContentProvider:PreloadAsync({self.drone, self.water, self.travel, self.chime})
        print("[LAST STOP V4] Audio loaded", self.drone.IsLoaded, self.water.IsLoaded, self.travel.IsLoaded, self.chime.IsLoaded)
    end)
    local elapsed = 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        if elapsed < .15 then return end
        elapsed = 0
        local world = workspace:FindFirstChild("LastStopWorld")
        local runtime = world and world:FindFirstChild("Runtime")
        local folder = runtime and runtime:FindFirstChild("ActiveExpedition")
        local floor = folder and folder:FindFirstChildOfClass("Model")
        self.water.Volume = floor and floor:GetAttribute("FloorTheme") == "Laboratory" and .23 or 0
        if floor then
            if self.floor ~= floor then
                self.floor, self.indicators, self.lights = floor, {}, {}
                for _, part in floor:GetDescendants() do
                    if part:IsA("BasePart") and part:GetAttribute("HazardIndicator") then table.insert(self.indicators, part) end
                    if part:IsA("BasePart") and part:GetAttribute("FlickerLight") then table.insert(self.lights, part) end
                end
            end
            local monster = floor:FindFirstChild("Stalker")
            if monster and not self.creatures[monster] then
                local root = monster:FindFirstChild("HumanoidRootPart")
                if root then
                    local breath = sound(root, "StalkerBreath", .5, true)
                    local threat = sound(root, "StalkerThreat", .7)
                    local alert = sound(root, "StalkerThreat", .45)
                    breath:Play()
                    self.creatures[monster] = {breath = breath, threat = threat, alert = alert}
                end
            end
            local phase = floor:GetAttribute("HazardPhase")
            local warning = phase == "Warning" or phase == "Active"
            -- Synchronized train warning: one sting when the warning phase begins.
            if phase == "Warning" and self.lastPhase ~= "Warning" and floor:GetAttribute("FloorTheme") == "Subway" then
                self.warn:Play()
            end
            self.lastPhase = phase
            -- Random power flicker: the warning lights pulse brightly for one beat.
            local flicker = floor:GetAttribute("PowerFlicker") == true
            for _, part in self.lights do
                if part.Parent then part.Transparency = flicker and .85 or 0 end
            end
            for _, part in self.indicators do
                if part.Parent then
                    part.Color = warning and Color3.fromRGB(245, 118, 62) or Color3.fromRGB(66, 153, 156)
                    part.Transparency = warning and (.1 + .2 * math.sin(os.clock() * 9) ^ 2) or .7
                    if flicker then
                        part.Color = Color3.fromRGB(255, 236, 190)
                        part.Transparency = .05
                    end
                end
            end
        end
        for model, record in self.creatures do
            if not model.Parent then self.creatures[model] = nil; continue end
            local state = model:GetAttribute("AIState")
            if state == "Windup" and record.state ~= state then record.threat:Play() end
            -- Alert: the stalker has spotted a player and is turning. One sting, so the
            -- player knows to break line of sight. Lurk: a quiet hold with a breath cue.
            if state == "Alert" and record.state ~= state then record.alert:Play() end
            if state == "Lurk" and record.state ~= state then record.breath.Volume = .9 end
            if state ~= "Lurk" and record.state == "Lurk" then record.breath.Volume = .5 end
            record.breath.PlaybackSpeed = state == "Chase" and 1.2 or .9
            record.state = state
        end
    end)
    return self
end
function Soundscape:ApplyState(data)
    if data.state == "Travel" and self.state ~= "Travel" then self.travel:Play() end
    if data.progress and data.progress > self.progress then self.chime:Play() end
    self.progress = data.progress or 0
    self.state = data.state or self.state
end
return Soundscape
