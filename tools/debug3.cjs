const fs = require('node:fs');
const xml = fs.readFileSync('assets/prefabs/Lobby.rbxmx', 'utf8');
const re = /<Item class="([^"]+)" referent="([^"]+)">/g;
let m = re.exec(xml);
console.log('first item:', m[1], m[2], 'at', m.index);
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
console.log('inner length:', inner.length);
console.log('inner head:', inner.slice(0, 200));
console.log('has size:', /<Vector3 name="size">/.test(inner));
const sizeM = inner.match(/<Vector3 name="size">([\d.eE+\-]+)<\/X><\/Y><\/Z><\/Vector3>/);
console.log('size match:', sizeM && sizeM[1]);