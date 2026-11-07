// Offline checks for the canonical Rojo build. Engine tests live in Tests/.
import fs from 'node:fs';
import path from 'node:path';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';

const project = JSON.parse(fs.readFileSync('default.project.json', 'utf8'));
const place = fs.readFileSync('LAST_STOP.rbxlx', 'utf8');
const theme = fs.readFileSync('src/ReplicatedStorage/Shared/ArtTheme.lua', 'utf8');
const requirements = {
  Lobby: ['EntranceSpawn', 'ElevatorSocket', 'RoomBounds', 'LobbySpawnPoint', 'QueueConsole'],
  Elevator: ['EntranceSpawn', 'ElevatorReturnZone', 'DoorLeft', 'DoorRight', 'FloorDisplay'],
  Hospital: ['EntranceSpawn', 'ElevatorSocket', 'ElevatorReturnZone', 'RoomBounds', 'EnemySpawn', 'PatrolPaths', 'ObjectiveSockets'],
  Stalker: ['HumanoidRootPart', 'Humanoid', 'Neck', 'Left Hip', 'Right Hip'],
  Environment: ['wall', 'floor-panel', 'bed-single', 'computer-wide', 'pipe'],
  StalkerSkin: [],
};
const inventory = {};
for (const [name, markers] of Object.entries(requirements)) {
  const xml = fs.readFileSync(`assets/prefabs/${name}.rbxmx`, 'utf8');
  assert(!/<Item class="(?:Script|LocalScript|ModuleScript)"/.test(xml), `${name} contains executable code`);
  for (const marker of markers) {
    assert(xml.includes(`name="Name">${marker}<`), `${name} missing ${marker}`);
  }
  inventory[name] = (xml.match(/<Item class=/g) || []).length;
  assert(place.includes(`name="Name">${name}<`), `Build missing ${name}`);
}

const skin = fs.readFileSync('assets/prefabs/StalkerSkin.rbxmx', 'utf8');
const environment = fs.readFileSync('assets/prefabs/Environment.rbxmx', 'utf8');
const bones = (skin.match(/<Item class="Bone"/g) || []).length;
assert(bones >= 50, 'Skinned Stalker skeleton missing');
assert(environment.match(/<Item class="MeshPart"/g).length >= 18, 'Imported environment mesh library incomplete');
assert(skin.includes('<Item class="SurfaceAppearance"'), 'Stalker PBR appearance missing');
for (const id of ['79662703056041', '139290702449907', '96470019773943', '129007056108561']) {
  assert(skin.includes(id) && place.includes(id), `Stalker asset ${id} missing`);
}

for (const [name, node] of Object.entries(project.tree.MaterialService)) {
  if (name.startsWith('$')) continue;
  assert.equal(node.$className, 'MaterialVariant');
  const definition = theme.split(`${name} = {`)[1]?.split('}')[0];
  assert(definition, `ArtTheme missing ${name}`);
  for (const map of ['ColorMap', 'NormalMap', 'RoughnessMap', 'MetalnessMap']) {
    const id = node.$properties[map];
    assert(/^rbxassetid:\/\/\d+$/.test(id), `${name}.${map} ID`);
    assert(definition.includes(`${map} = "${id}"`), `${name}.${map} differs from ArtTheme`);
    assert(place.includes(id), `Built material missing ${id}`);
  }
}

let scripts = 0;
function verifySources(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    const filename = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      verifySources(filename);
    } else if (entry.name.endsWith('.lua')) {
      const source = fs.readFileSync(filename, 'utf8').replace(/\r\n/g, '\n');
      assert(Buffer.byteLength(source) <= 200000, `Studio Source limit exceeded by ${filename}`);
      assert(place.includes(`<![CDATA[${source}]]>`), `Build has stale source for ${filename}`);
      scripts++;
    }
  }
}
verifySources('src');
assert(place.includes('V5 DEVELOPMENT'));
assert.equal(project.tree.ServerStorage.LastStopAssets.Environment.$path, 'assets/prefabs/Environment.rbxmx');
assert.equal(project.tree.ServerStorage.LastStopAssets.StalkerSkin.$path, 'assets/prefabs/StalkerSkin.rbxmx');
assert(/FloorTimeLimitSeconds\s*=\s*240\s*,/.test(fs.readFileSync('src/ReplicatedStorage/Shared/Config/GameConfig.lua', 'utf8')), 'Release floor timing must be 240 seconds');
console.log(JSON.stringify({
  pass: true, scripts, bones, inventory,
  totalPrefabInstances: Object.values(inventory).reduce((sum, count) => sum + count, 0),
  bytes: Buffer.byteLength(place),
  sha256: crypto.createHash('sha256').update(place).digest('hex'),
}, null, 2));
