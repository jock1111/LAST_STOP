const fs = require('node:fs');
const xml = fs.readFileSync('assets/prefabs/Lobby.rbxmx', 'utf8');
const re = /<\/?Item class="([^"]+)" referent="([^"]+)">/g;
let m, n = 0;
while ((m = re.exec(xml)) !== null && n < 10) {
  const isClose = m[0].startsWith('</');
  const cls = m[1], id = m[2];
  if (isClose) { console.log(n, 'CLOSE', id); n++; continue; }
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
  const cfM = inner.match(/<CoordinateFrame name="CFrame">([\s\S]*?)<\/CoordinateFrame>/);
  console.log(n, 'OPEN', cls, id, nameM && nameM[1], 'cfFound=', !!cfM, 'innerLen=', inner.length, 'endIdx=', i);
  if (cfM) {
    const r = cfM[1].match(/<X>([\d.eE+\-]+)<\/X><Y>([\d.eE+\-]+)<\/Y><Z>([\d.eE+\-]+)<\/Z>/);
    console.log('   pos=', r && r.slice(1));
  }
  n++;
}