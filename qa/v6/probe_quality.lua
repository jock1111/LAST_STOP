local out = {typeofSettings = typeof(settings), tostringSettings = tostring(settings)}
local ok1, r1 = pcall(function() return UserSettings() end)
out.userSettings = ok1 and tostring(r1) or ("err " .. tostring(r1))
local ok2, r2 = pcall(function() return UserSettings().GameSettings end)
out.gameSettings = ok2 and tostring(r2) or ("err " .. tostring(r2))
local ok3, r3 = pcall(function() return settings().Rendering.QualityLevel end)
out.qualityLevel = ok3 and tostring(r3) or ("err " .. tostring(r3))
return out
