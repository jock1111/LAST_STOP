// World-AABB inventory of the generated V6 prefabs.
// Uses a real stack-based XML parser (no regex区间 hacks) so the parent
// chain is exact. Prefab parts are authored with identity parent transforms,
// so each part's CFrame is already world-space.
const fs = require('node:fs');

function parseItems(xml) {
  const items = [];
  const stack = [];
  let i = 0;
  const openTag = /<Item\s+class="([^"]+)"\s+referent="([^"]+)">/;
  while (i < xml.length) {
    const open = xml.indexOf('<Item ', i);
    if (open === -1) break;
    const om = openTag.exec(xml.slice(open, open + 200));
    if (!om) break;
    const cls = om[1], id = om[2];
    const innerStart = open + om[0].length;
    // Find matching </Item> by counting nested <Item ...> opens.
    let depth = 1, j = innerStart;
    while (j < xml.length && depth > 0) {
      const o = xml.indexOf('<Item ', j);
      const c = xml.indexOf('</Item>', j);
      if (c === -1) break;
      if (o !== -1 && o < c) { depth++; j = o + 6; }
      else { depth--; j = c + 8; }
    }
    const inner = xml.slice(innerStart, j - 8);
    const nameM = inner.match(/<string name="Name">([^<]*)<\/string>/);
    const sizeM = inner.match(/<Vector3 name="size"><X>([\d.eE+\-]+)<\/X><Y>([\d.eE+\-]+)<\/Y><Z>([\d.eE+\-]+)<\/Z><\/Vector3>/);
    const cfM = inner.match(/<CoordinateFrame name="CFrame">([\s\S]*?)<\/CoordinateFrame>/);
    let pos = [0, 0, 0], yaw = 0;
    if (cfM) {
      const r = cfM[1].match(/<X>([\d.eE+\-]+)<\/X><Y>([\d.eE+\-]+)<\/Y><Z>([\d.eE+\-]+)<\/Z>/);
      if (r) pos = [+r[1], +r[2], +r[3]];
    }
    const node = { cls, id, name: nameM ? nameM[1] : '', size: sizeM ? [+sizeM[1], +sizeM[2], +sizeM[3]] : null, pos, yaw, parent: stack.length ? stack[stack.length - 1].id : null };
    items.push(node);
    stack.push(node);
    i = j;
    // Pop this node and any siblings whose close tag we passed.
    const closeEnd = xml.indexOf('</Item>', j);
    if (closeEnd !== -1) {
      let k = closeEnd + 8;
      while (stack.length && xml.indexOf('<Item ', stack[stack.length - 1].start) === -1) stack.pop();
      // Pop all stack entries that end at or before k.
      const endBy = {};
      for (const n of items) endBy[n.id] = xml.indexOf('</Item>', n.start);
      while (stack.length && endBy[stack[stack.length - 1].id] <= k) stack.pop();
    }
  }
  return items;
}

function parse(name) {
  return parseItems(fs.readFileSync(`assets/prefabs/${name}.rbxmx`, 'utf8'));
}

function aabb(it) {
  const s = it.size.map(v => v / 2);
  return [it.pos[0] - s[0], it.pos[1] - s[1], it.pos[2] - s[2],
          it.pos[0] + s[0], it.pos[1] + s[1], it.pos[2] + s[2]];
}

function overlap(a, b) {
  return a[0] < b[3] && b[0] < a[3] && a[1] < b[4] && b[1] < a[4] && a[2] < b[5] && b[2] < a[5];
}

const target = process.argv[2] || 'Lobby';
const items = parse(target);
const parts = items.filter(i => (i.cls === 'Part' || i.cls === 'MeshPart') && i.size);
console.log(`${target}: ${items.length} items, ${parts.length} base parts`);

if (process.argv[3] === 'list') {
  for (const p of parts) {
    const b = aabb(p);
    console.log(`  ${p.name.padEnd(26)} ${p.cls.padEnd(8)} pos=${p.pos.map(v => v.toFixed(1)).join(',')} size=${p.size.map(v => v.toFixed(1)).join('x')} box=[${b.map(v => v.toFixed(1)).join(',')}]`);
  }
} else {
  const suspects = [];
  for (let i = 0; i < parts.length; i++) {
    for (let j = i + 1; j < parts.length; j++) {
      const a = aabb(parts[i]), b = aabb(parts[j]);
      if (overlap(a, b)) {
        const ox = Math.min(a[3], b[3]) - Math.max(a[0], b[0]);
        const oy = Math.min(a[4], b[4]) - Math.max(a[1], b[1]);
        const oz = Math.min(a[5], b[5]) - Math.max(a[2], b[2]);
        if (ox > 0.5 && oy > 0.5 && oz > 0.5) suspects.push({ a: parts[i].name, b: parts[j].name, ox, oy, oz });
      }
    }
  }
  console.log(`  AABB overlaps > 0.5 stud: ${suspects.length}`);
  for (const s of suspects.slice(0, 80)) console.log(`    ${s.a} x ${s.b}  (${s.ox.toFixed(2)} x ${s.oy.toFixed(2)} x ${s.oz.toFixed(2)})`);
}