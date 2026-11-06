import fs from 'node:fs';
const s = fs.readFileSync('assets/prefabs/Environment.rbxmx', 'utf8');
const i = s.indexOf('<Item class="MeshPart"');
const j = s.indexOf('</Item>', i);
console.log('block length', j + 8 - i);
console.log(s.slice(i, i + 7000));
