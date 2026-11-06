local Workspace = game:GetService("Workspace")

local world = Workspace:FindFirstChild("LastStopWorld")
local runtime = world and world:FindFirstChild("Runtime")
local active = runtime and runtime:FindFirstChild("ActiveExpedition")
local floor = active and active:FindFirstChildWhichIsA("Model")

local result = {
    floorName = floor and floor.Name or "none",
    floorTheme = floor and floor:GetAttribute("FloorTheme") or "none",
    parts = {},
}

if not floor then return result end

local patterns = {
    "contain", "cylinder", "catwalk", "computer", "pump", "door", "sign", "light",
    "rail", "pipe", "tank", "console", "terminal", "stairs", "bridge", "elevator",
    "platform", "track", "train", "signal", "bench", "poster", "crate", "container",
    "specimen", "relay", "panel", "grate", "vent", "machine", "screen", "monitor",
}

local count = 0
for _, d in ipairs(floor:GetDescendants()) do
    if d:IsA("BasePart") then
        local name = d.Name:lower()
        local match = false
        for _, p in ipairs(patterns) do
            if name:find(p, 1, true) then match = true break end
        end
        if match then
            count = count + 1
            if count <= 220 then
                table.insert(result.parts, {
                    name = d.Name,
                    class = d.ClassName,
                    pos = tostring(d.Position),
                    size = tostring(d.Size),
                    material = tostring(d.Material),
                })
            end
        end
    end
end
result.matched = count
return result
