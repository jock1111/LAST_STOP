// One-shot patcher for tools/build-prefabs.mjs. Reads the pristine backup,
// applies the --dump instrumentation by exact line, and writes the working copy.
const fs = require('node:fs');
const lines = fs.readFileSync('qa/v6/backup-pre-v6-runtime-20261104-1934/tools/build-prefabs.mjs', 'utf8').split('\n');

function at(i, text) {
  if (lines[i - 1] !== text) throw new Error(`Line ${i} mismatch:\n  want: ${text}\n  got:  ${lines[i - 1]}`);
}

// 1. Header: add the --dump flag after `let sequence=0;`.
at(7, 'let sequence=0;');
lines.splice(7, 0, 'const DUMP = process.argv.includes(\'--dump\');', 'const dumpLines=[];');

// 2. World-space AABB helper before `function item(...`.
let itemIdx = lines.findIndex(l => l.startsWith('function item(cls,name'));
if (itemIdx < 0) throw new Error('item() not found');
const worldBox = [
  '// World-space AABB for QA. Prefab CFrames are authored axis-aligned (yaw in',
  '// multiples of 90 deg), so the local half-extents map straight onto world axes.',
  'function worldBox(size, pos, yaw) {',
  '  const s = size.map(v => v / 2);',
  '  const swap = (Math.round((yaw % 360) / 90) % 2) === 1;',
  '  const ex = swap ? s[2] : s[0], ez = swap ? s[0] : s[2];',
  '  return [pos[0] - ex, pos[1] - s[1], pos[2] - ez, pos[0] + ex, pos[1] + s[1], pos[2] + ez];',
  '}',
];
lines.splice(itemIdx, 0, ...worldBox);

// 3. Record every authored BasePart inside part(). Replace the
//    `parent.children.push(n);return n;` line inside part() (line 25) with a
//    block that also records the world AABB when --dump is set.
let pushIdx = lines.findIndex(l => l === ' parent.children.push(n);return n;');
if (pushIdx < 0) throw new Error('parent.children.push(n);return n; not found');
const partInsert = [
  ' parent.children.push(n);',
  ' if (DUMP && (o.cls || \'Part\') !== \'StringValue\' && !name.endsWith(\'PbrMaterial\')) {',
  '   const b = worldBox(size, pos, o.yaw || 0);',
  '   dumpLines.push(JSON.stringify({cls:o.cls||\'Part\',name,size,box:b,material:mat,pbr:o.pbr||null,detail:!!o.detail,marker:!!o.marker}));',
  ' }',
  ' return n;',
];
lines.splice(pushIdx, 1, ...partInsert);

// 4. Emit the dump after each write().
let writeIdx = lines.findIndex(l => l.startsWith('function write(name'));
if (writeIdx < 0) throw new Error('write() not found');
const writeLine = lines[writeIdx];
const expectedWrite =
  'function write(name,n){fs.writeFileSync(path.join(out,name+\'.rbxmx\'),`<roblox version="4"><External>null</External><External>nil</External>${xml(n)}</roblox>\\n`);return n;}';
if (writeLine !== expectedWrite) throw new Error('write() mismatch:\n' + writeLine);
lines[writeIdx] =
  'function write(name,n){fs.writeFileSync(path.join(out,name+\'.rbxmx\'),`<roblox version="4"><External>null</External><External>nil</External>${xml(n)}</roblox>\\n`);if(DUMP){process.stdout.write(JSON.stringify({model:name,count:dumpLines.length,parts:dumpLines})+\'\\n\');dumpLines.length=0;}return n;}';

// 5. Keep the summary on stderr so the dump stays clean on stdout.
let logIdx = lines.findIndex(l => l.startsWith('console.log(JSON.stringify({models:'));
if (logIdx < 0) throw new Error('final console.log not found');
lines.splice(logIdx, 1, 'if (DUMP) process.stderr.write(\'dump complete\\n\');', 'process.stderr.write(JSON.stringify({models:[\'Lobby\',\'Elevator\',\'Hospital\',\'Stalker\'],instances:sequence,output:out})+\'\\n\');');

const out = lines.join('\n');
const checks = ['const DUMP = process.argv', 'function worldBox(', 'dumpLines.push(JSON.stringify', 'process.stdout.write(JSON.stringify({model:name', "process.stderr.write('dump complete'"];
for (const c of checks) {
  if (!out.includes(c)) { console.error('CHECK FAILED for pattern:', c); process.exit(1); }
}
fs.writeFileSync('tools/build-prefabs.mjs', out);
console.log('patched build-prefabs.mjs,', out.length, 'bytes');