local RunService = game:GetService("RunService")
local Stats = game:GetService("Stats")

-- Try to drop render quality for the reduced-graphics pass (Studio only).
local qualityNote = "default"
local ok, err = pcall(function()
    local settings = settings()
    settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
    qualityNote = "Level01"
end)
if not ok then
    qualityNote = "default (quality override unavailable: " .. tostring(err) .. ")"
end

local samples = {}
local start = os.clock()
local conn
conn = RunService.Heartbeat:Connect(function(dt)
    if os.clock() - start < 6 then
        table.insert(samples, dt)
    else
        conn:Disconnect()
    end
end)
task.wait(6.5)

table.sort(samples)
local total = 0
for _, dt in ipairs(samples) do total += dt end
local avg = total / math.max(1, #samples)
local p95 = samples[math.floor(#samples * 0.95)] or 0
local p99 = samples[math.floor(#samples * 0.99)] or 0

return {
    quality = qualityNote,
    frames = #samples,
    avgFps = math.floor(1 / avg + 0.5),
    avgFrameMs = math.floor(avg * 1000 + 0.5),
    p95FrameMs = math.floor(p95 * 1000 + 0.5),
    p99FrameMs = math.floor(p99 * 1000 + 0.5),
}
