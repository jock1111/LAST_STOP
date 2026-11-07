const fs = require('node:fs');
const xml = fs.readFileSync('assets/prefabs/Lobby.rbxmx', 'utf8');
const re = /<Item class="([^"]+)" referent="([^"]+)">/g;
let m = re.exec(xml); // model
m = re.exec(xml); // first child = StationArchitecture Folder
const openIdx = m.index + m[0].length;
let depth = 1, i = openIdx;
while (i < xml.length && depth > 0) {
  const open = xml.indexOf('<Item ', i);
  const close = xml.indexOf('</Item>', i);
  if (close === -1) break;
  if (open !== -1 && open < close) { depth++; i = open + 6; }
  else { depth--; i = close + 8; }
}
const inner = xml.slice(openIdx, i - 8);
console.log('inner len:', inner.length);
console.log('inner head:', JSON.stringify(inner.slice(0, 400)));
console.log('inner tail:', JSON.stringify(inner.slice(-200)));