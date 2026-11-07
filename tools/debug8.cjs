const fs = require('node:fs');
const xml = fs.readFileSync('assets/prefabs/Lobby.rbxmx', 'utf8');
const nodes = [];
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
  nodes.push({ cls, id, start: m.index, end: i });
  re.lastIndex = i;
}
nodes.sort((a, b) => a.start - b.start);
const stack = [];
for (const n of nodes) {
  while (stack.length && stack[stack.length - 1].end < n.end) stack.pop();
  n.parent = stack.length ? stack[stack.length - 1].id : null;
  stack.push(n);
}
for (const n of nodes.slice(0, 12)) console.log(n.cls, n.id, 'start=' + n.start, 'end=' + n.end, 'parent=' + n.parent, 'stackDepth=' + (stack.indexOf(n) >= 0 ? 'in' : 'out'));