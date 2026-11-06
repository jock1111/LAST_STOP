local s = game:GetService("ServerScriptService"):FindFirstChild("QA_V6_LabHarness")
if not s then return "missing" end
local src = s.Source
local target = ... -- not supported; detect current
if src:find('floor.Template == "AbandonedSubway"', 1, true) then
    src = src:gsub('floor%.Template == "AbandonedSubway"', 'floor.Template == "FloodedLaboratory"')
    s.Source = src
    return "reverted to Laboratory"
else
    src = src:gsub('floor%.Template == "FloodedLaboratory"', 'floor.Template == "AbandonedSubway"')
    s.Source = src
    return "switched to AbandonedSubway"
end
