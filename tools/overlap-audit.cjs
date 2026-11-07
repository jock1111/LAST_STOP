// Overlap audit between V6 authored prefabs and the runtime-inserted art in
// EnvironmentService.UpgradeLobby / UpgradeHospital. Prefab parts are cloned
// at identity transform (FloorService clones then optionally PivotTo), so their
// authored world AABB is the runtime box. Runtime art is authored relative to
// the model origin, which is identity for both lobby and hospital.
const fs = require('node:fs');
const { parseItems } = (() => {
  const src = fs.readFileSync('tools/inspect-prefabs.cjs', 'utf8');
  const m = src.match(/function parseItems[\s\S]*?\n^}/m);
  return { parseItems: new Function(m[0].replace('function parseItems', 'return function parseItems') + '\nreturn parseItems;')() };
})();

function aabb(it) {
  const s = it.size.map(v => v / 2);
  return [it.pos[0] - s[0], it.pos[1] - s[1], it.pos[2] - s[2],
          it.pos[0] + s[0], it.pos[1] + s[1], it.pos[2] + s[2]];
}
function overlap(a, b) {
  return a[0] < b[3] && b[0] < a[3] && a[1] < b[4] && b[1] < a[4] && a[2] < b[5] && b[2] < a[5];
}

function runtimeLobby() {
  // Environment.UpgradeLobby(model) inserts meshes relative to the model
  // origin (identity). Sizes are as authored in EnvironmentService.Mesh calls.
  const art = [];
  const add = (name, x, y, z, size, yaw) => art.push({ name, pos: [x, y, z], size, yaw: yaw || 0 });
  for (const x of [-38, 38]) {
    for (let z = -24; z <= 24; z += 8) add('wall-window', x, 8, z, [8, 16, 2.4], 90);
  }
  for (const x of [-25, 25]) {
    add('display-wall-wide', x, 6, -32, [12, 8, 3]);
    for (let z = -12; z <= 12; z += 12) add('container-tall', x > 0 ? 34 : -34, 3.6, z, [4, 12, 4]);
  }
  add('computer-system', 14, 2.4, -11, [3, 2, 2]);
  for (let z = -8; z <= 24; z += 8) add('floor-panel', 0, -0.4, z, [14, 0.8, 8]);
  return art;
}
function runtimeHospital() {
  // Environment.UpgradeHospital(model) inserts meshes relative to model origin.
  const art = [];
  const add = (name, x, y, z, size, yaw) => art.push({ name, pos: [x, y, z], size, yaw: yaw || 0 });
  for (const part of [
    ['bed-single', -23, 2, -8, [4, 1.2, 7]], ['bed-single', -23, 2, 5, [4, 1.2, 7]],
    ['computer-wide', 28, 3, 10, [6, 2.5, 3]], ['computer-system', 19, 3, -28, [3, 2, 2]],
    ['container-tall', -29, 3.6, 24, [4, 12, 4]], ['container', 29, 2.4, 27, [3, 2.4, 2.4]],
  ]) add(...part);
  for (const x of [-29, -19]) add('container', x, 1.2, -1, [3, 2.4, 2.4]);
  for (let z = -29; z <= 27; z += 8) add('floor-panel', 0, -0.55, z, [12, 1, 8]);
  return art;
}

function run(prefab, runtime, label) {
  const items = parseItems(fs.readFileSync(`assets/prefabs/${prefab}.rbxmx`, 'utf8'));
  const parts = items.filter(i => (i.cls === 'Part' || i.cls === 'MeshPart') && i.size);
  let hits = 0;
  const report = [];
  for (const r of runtime) {
    const yaw = (Math.round(((r.yaw || 0) % 360) / 90) % 2) === 1;
    const s = r.size;
    const ex = yaw ? s[2] / 2 : s[0] / 2, ez = yaw ? s[0] / 2 : s[2] / 2;
    const b = [r.pos[0] - ex, r.pos[1] - s[1] / 2, r.pos[2] - ez, r.pos[0] + ex, r.pos[1] + s[1] / 2, r.pos[2] + ez];
    for (const p of parts) {
      const a = aabb(p);
      if (overlap(a, b)) {
        const ox = Math.min(a[3], b[3]) - Math.max(a[0], b[0]);
        const oy = Math.min(a[4], b[4]) - Math.max(a[1], b[1]);
        const oz = Math.min(a[5], b[5]) - Math.max(a[2], b[2]);
        if (ox > 0.3 && oy > 0.3 && oz > 0.3) {
          hits++;
          report.push(`${r.name} @ ${r.pos.map(v => v.toFixed(1))} overlaps ${p.name} ${p.cls} box=[${a.map(v => v.toFixed(1)).join(',')}] by (${ox.toFixed(2)}, ${oy.toFixed(2)}, ${oz.toFixed(2)})`);
        }
      }
    }
  }
  console.log(`${label}: ${hits} runtime/prefab overlaps`);
  for (const r of report.slice(0, 40)) console.log('  ' + r);
}

run('Lobby', runtimeLobby(), 'Lobby');
run('Hospital', runtimeHospital(), 'Hospital');