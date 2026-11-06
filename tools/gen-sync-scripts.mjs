// Generates a Luau script that pushes local source files into the open Studio
// place (Edit mode). Use when the rbxlx on disk is newer than the open place.
import fs from 'node:fs';
import path from 'node:path';

const FILES = [
  ['src/ServerScriptService/Services/EnvironmentService.lua', 'ServerScriptService.Services.EnvironmentService'],
  ['src/ServerScriptService/Services/ExpeditionService.lua', 'ServerScriptService.Services.ExpeditionService'],
  ['src/StarterPlayer/StarterPlayerScripts/Controllers/HUDController.lua', 'StarterPlayer.StarterPlayerScripts.Controllers.HUDController'],
];

let out = 'local results = {}\nlocal function setSource(rootPath, source)\n\tlocal node = game\n\tfor part in string.gmatch(rootPath, "[^%.]+") do\n\t\tnode = node and node:FindFirstChild(part)\n\tend\n\tif not node then\n\t\ttable.insert(results, "MISSING " .. rootPath)\n\t\treturn\n\tend\n\tnode.Source = source\n\ttable.insert(results, "OK " .. rootPath)\nend\n';

for (const [file, instPath] of FILES) {
  let src = fs.readFileSync(file, 'utf8').replace(/\r\n/g, '\n');
  if (src.includes(']==]')) throw new Error('long-bracket collision in ' + file);
  out += `setSource("${instPath}", [==[\n${src}]==]\n)\n`;
}
out += 'return results\n';
fs.writeFileSync('qa/v6/sync_changed_scripts.lua', out);
console.log('wrote qa/v6/sync_changed_scripts.lua', out.length, 'bytes');
