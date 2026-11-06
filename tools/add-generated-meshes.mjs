// Inserts Studio-generated MeshParts into assets/prefabs/Environment.rbxmx.
// Each asset is wrapped in a "<name>_Node" Model containing one MeshPart,
// matching the existing Kenney import layout so Environment.Mesh() can find
// them by name. Idempotent: skips names already present.
import fs from 'node:fs';
import crypto from 'node:crypto';

const FILE = 'assets/prefabs/Environment.rbxmx';
let xml = fs.readFileSync(FILE, 'utf8');

const MESHES = [
  { name: 'specimen-canister',    meshId: 'rbxassetid://95792177258500', textureId: 'rbxassetid://120915859445902', size: [1.08338869, 3, 1.09786355] },
  { name: 'containment-vessel',   meshId: 'rbxassetid://71376769722129', textureId: 'rbxassetid://78261601254527', size: [6.14523125, 12, 5.68912268] },
  { name: 'pump-machine',         meshId: 'rbxassetid://87119713783145', textureId: 'rbxassetid://112175610566765', size: [3.70586348, 8, 2.90696478] },
  { name: 'research-console',     meshId: 'rbxassetid://76438650829671', textureId: 'rbxassetid://92729882681763', size: [5.92827797, 2.75467777, 4] },
  { name: 'subway-train-car',     meshId: 'rbxassetid://75278130929878', textureId: 'rbxassetid://81495936608992', size: [6.73513699, 8, 15.68163967] },
  { name: 'station-bench',        meshId: 'rbxassetid://113924694873821', textureId: 'rbxassetid://124826055360128', size: [3.42565823, 2, 1.29859173] },
  { name: 'signal-post',          meshId: 'rbxassetid://71593920777017', textureId: 'rbxassetid://117247863089433', size: [1.06332707, 6, 0.95463395] },
  { name: 'subway-track-section', meshId: 'rbxassetid://134933032983834', textureId: 'rbxassetid://72808269414642', size: [1.83820772, 2, 1.14464617] },
];

// Locate the first "<name>_Node" Model wrapper and its MeshPart child.
const nodeNameIdx = xml.indexOf('_Node</string>');
if (nodeNameIdx < 0) throw new Error('Node template not found');
const modelOpen = xml.lastIndexOf('<Item class="Model"', nodeNameIdx);
const meshOpen = xml.indexOf('<Item class="MeshPart"', nodeNameIdx);
const meshClose = xml.indexOf('</Item>', meshOpen) + '</Item>'.length;
// Node wrapper = everything from modelOpen up to its MeshPart child, plus the
// node's own closing </Item> (the last </Item> before the next sibling Model).
const nodeHead = xml.slice(modelOpen, meshOpen);           // Model open + Properties
const nodeTail = '\t\t\t\t</Item>\n\t\t\t</Item>';          // mesh close handled separately; node close only
const meshTemplate = xml.slice(meshOpen, meshClose);

const referent = () => 'RBX' + crypto.randomBytes(16).toString('hex').toUpperCase();
const uniqueId = () => {
  const b = crypto.randomBytes(16);
  b[0] &= 0x7f; // UniqueId parses as signed 128-bit; keep the top bit clear.
  return b.toString('hex');
};
const fmt = n => Number(n.toFixed(8)).toString();

function vec3(name, v) {
  return `<Vector3 name="${name}">\n\t\t\t\t\t\t\t<X>${fmt(v[0])}</X>\n\t\t\t\t\t\t\t<Y>${fmt(v[1])}</Y>\n\t\t\t\t\t\t\t<Z>${fmt(v[2])}</Z>\n\t\t\t\t\t\t</Vector3>`;
}

function patchMesh(block, def) {
  let b = block;
  b = b.replace(/referent="RBX[0-9A-F]+"/, `referent="${referent()}"`);
  b = b.replace(/<Content name="MeshId"><url>[^<]+<\/url><\/Content>/, `<Content name="MeshId"><url>${def.meshId}</url></Content>`);
  b = b.replace(/<Content name="TextureID"><url>[^<]+<\/url><\/Content>/, `<Content name="TextureID"><url>${def.textureId}</url></Content>`);
  for (const prop of ['InitialSize', 'size']) {
    b = b.replace(new RegExp(`<Vector3 name="${prop}">[\\s\\S]*?<\\/Vector3>`), vec3(prop, def.size));
  }
  b = b.replace(/<string name="Name">[^<]+<\/string>/, `<string name="Name">${def.name}</string>`);
  b = b.replace(/<UniqueId name="UniqueId">[0-9a-f]+<\/UniqueId>/, `<UniqueId name="UniqueId">${uniqueId()}</UniqueId>`);
  b = b.replace(/<CoordinateFrame name="CFrame">[\s\S]*?<\/CoordinateFrame>/,
    '<CoordinateFrame name="CFrame"><X>0</X><Y>0</Y><Z>0</Z><R00>1</R00><R01>0</R01><R02>0</R02><R10>0</R10><R11>1</R11><R12>0</R12><R20>0</R20><R21>0</R21><R22>1</R22></CoordinateFrame>');
  return b;
}

function patchNodeHead(head, def) {
  let b = head;
  b = b.replace(/referent="RBX[0-9A-F]+"/, `referent="${referent()}"`);
  b = b.replace(/<string name="Name">[^<]*_Node<\/string>/, `<string name="Name">${def.name}_Node</string>`);
  b = b.replace(/<UniqueId name="UniqueId">[0-9a-f]+<\/UniqueId>/, `<UniqueId name="UniqueId">${uniqueId()}</UniqueId>`);
  return b;
}

const missing = MESHES.filter(m => !xml.includes(`<string name="Name">${m.name}</string>`));
if (!missing.length) {
  console.log('All generated meshes already present.');
  process.exit(0);
}

let insert = '';
for (const def of missing) {
  const block = patchNodeHead(nodeHead, def) + patchMesh(meshTemplate, def) + '\n\t\t\t</Item>';
  insert += '\n' + block;
}

const tail = '\t\t</Item>\n\t</roblox>';
const idx = xml.lastIndexOf(tail);
if (idx < 0) throw new Error('Root model close not found');
xml = xml.slice(0, idx) + insert + '\n' + xml.slice(idx);
fs.writeFileSync(FILE, xml);
console.log(`Inserted ${missing.length} generated meshes: ${missing.map(m => m.name).join(', ')}`);
