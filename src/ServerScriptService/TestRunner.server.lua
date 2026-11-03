-- Runs pure deterministic smoke tests in Studio Play mode. It is deliberately
-- skipped in published servers so it cannot affect live performance.
local RunService = game:GetService("RunService")
if not RunService:IsStudio() then
	return
end

local spec = require(script.Parent.Tests.VerticalSliceSpec)
local ok, err = pcall(spec)
if not ok then
	error("[LAST STOP] Vertical-slice tests failed: " .. tostring(err))
end
print("[LAST STOP] Vertical-slice pure logic tests passed.")
