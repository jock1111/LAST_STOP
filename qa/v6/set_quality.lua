local out = {}
local ok1, e1 = pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
out.setLevel01 = ok1 and "ok" or tostring(e1)
local ok2, e2 = pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level05 end)
out.setLevel05 = ok2 and "ok" or tostring(e2)
task.wait(0.5)
out.now = tostring(settings().Rendering.QualityLevel)
-- restore automatic
local ok3, e3 = pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic end)
out.restore = ok3 and "ok" or tostring(e3)
return out
