local s = game:GetService("ServerScriptService"):FindFirstChild("QA_V6_LabHarness")
if not s then return "missing" end
local src = s.Source
-- print lines containing Weight or weight-force context
local lines = {}
for line in string.gmatch(src, "[^\n]+") do
    if line:find("Weight", 1, true) or line:find("FloorConfig", 1, true) or line:find("while", 1, true) and line:find("do", 1, true) then
        table.insert(lines, line)
    end
end
return {len = #src, matches = lines, head = src:sub(1, 400)}
