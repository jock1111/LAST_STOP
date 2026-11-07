local RunService = game:GetService("RunService")

local okSet, setErr = pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
local quality = okSet and "Level01" or ("default (set failed: " .. tostring(setErr) .. ")")
task.wait(1) -- let the renderer settle at the new level

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

pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)

table.sort(samples)
local total = 0
for _, dt in ipairs(samples) do total += dt end
local avg = total / math.max(1, #samples)
return {
    quality = quality,
    frames = #samples,
    avgFps = math.floor(1 / avg + 0.5),
    avgFrameMs = math.floor(avg * 1000 + 0.5),
    p95FrameMs = math.floor((samples[math.floor(#samples * 0.95)] or 0) * 1000 + 0.5),
    p99FrameMs = math.floor((samples[math.floor(#samples * 0.99)] or 0) * 1000 + 0.5),
}
