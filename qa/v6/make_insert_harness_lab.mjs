import fs from 'node:fs';
const src = fs.readFileSync('qa/v6/runtime_harness_lab.server.lua', 'utf8');
const quoted = JSON.stringify(src);
const code = `local existing=game.ServerScriptService:FindFirstChild("QA_V6_LabHarness")
if existing then existing:Destroy() end
local s=Instance.new("Script")
s.Name="QA_V6_LabHarness"
s.Source=${quoted}
s.Parent=game.ServerScriptService
return {inserted=true,bytes=#s.Source}
`;
fs.writeFileSync('qa/v6/insert_harness_lab.lua', code);
console.log('generated', code.length);
