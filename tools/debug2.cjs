const fs = require('node:fs');
function parseItems(xml) {
  const out = [];
  const re = /<Item class="([^"]+)" referent="([^"]+)">/g;
  let m;
  while ((m = re.exec(xml)) !== null) {
    const cls = m[1], id = m[2];
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
    const nameM = inner.match(/<string name="Name">([^<]*)<\/string>/);
    const sizeM = inner.match(/<Vector3 name="size">([\d.eE+\-]+)<\/X><\/Y><\/Z><\/Vector3>/);
    const cfM = inner.match(/<CoordinateFrame name="CFrame">([\s\S]*?)<\/CoordinateFrame>/);
    let pos = [0, 0, 0], rot = '';
    if (cfM) {
      const r = cfM[1].match(/<X>([\d.eE+\-]+)<\/X><Y>([\d.eE+\-]+)<\/Y><Z>([\d.eE+\-]+)<\/Z>([\s\S]*?)<\/CoordinateFrame>/);
      if (r) { pos = [+r[1], +r[2], +r[3]]; rot = r[4]; }
    }
    out.push({ cls, id, name: nameM ? nameM[1] : '', size: sizeM ? [+sizeM[1], +sizeM[2], +sizeM[3]] : null, pos, rot });
    re.lastIndex = i;
  }
  return out;
}
const xml = fs.readFileSync('assets/prefabs/Lobby.rbxmx', 'utf8');
const items = parseItems(xml);
console.log('parsed:', items.length);
const parts = items.filter(i => (i.cls === 'Part' || i.cls === 'MeshPart') && i.size);
console.log('parts with size:', parts.length);
for (const p of parts.slice(0, 8)) console.log(' ', p.cls, p.name, p.size, p.pos);