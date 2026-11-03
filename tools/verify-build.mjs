// Offline checks for the Rojo source of truth. Engine tests live in Tests/.
import fs from 'node:fs';
import assert from 'node:assert/strict';
import crypto from 'node:crypto';
const project=JSON.parse(fs.readFileSync('default.project.json','utf8'));
const place=fs.readFileSync('LAST_STOP.rbxlx','utf8');
const theme=fs.readFileSync('src/ReplicatedStorage/Shared/ArtTheme.lua','utf8');
const requirements={Lobby:['EntranceSpawn','ElevatorSocket','RoomBounds','LobbySpawnPoint','QueueConsole'],Elevator:['EntranceSpawn','ElevatorReturnZone','DoorLeft','DoorRight','FloorDisplay'],Hospital:['EntranceSpawn','ElevatorSocket','ElevatorReturnZone','RoomBounds','EnemySpawn','PatrolPaths','ObjectiveSockets','Ward_Record','Imaging_Record','Archive_Record'],Stalker:['HumanoidRootPart','Humanoid','Neck','Left Hip','Right Hip']};
const inventory={};
for(const [name,required] of Object.entries(requirements)){
  const xml=fs.readFileSync(`assets/prefabs/${name}.rbxmx`,'utf8');
  assert(!/<Item class="(?:Script|LocalScript|ModuleScript)"/.test(xml),`${name} contains executable code`);
  for(const marker of required) assert(xml.includes(`name="Name">${marker}<`),`${name}: missing ${marker}`);
  inventory[name]=(xml.match(/<Item class=/g)||[]).length;
  assert(place.includes(`name="Name">${name}<`),`Build missing ${name}`);
}
for(const [name,node] of Object.entries(project.tree.MaterialService)){
  if(name.startsWith('$')) continue;
  assert(node.$className==='MaterialVariant');
  const definition=theme.split(`${name} = {`)[1]?.split('}')[0];
  assert(definition,`ArtTheme missing ${name}`);
  for(const map of ['ColorMap','NormalMap','RoughnessMap','MetalnessMap']){
    const id=node.$properties[map];
    assert(/^rbxassetid:\/\/\d+$/.test(id),`${name}.${map} missing real ID`);
    assert(definition.includes(`${map} = "${id}"`),`${name}.${map} differs from ArtTheme`);
    assert(place.includes(id),`Built place missing ${id}`);
  }
}
assert(project.tree.ServerStorage.LastStopAssets.Floors.Hospital.$path==='assets/prefabs/Hospital.rbxmx');
assert(place.includes('RECOVERY V3 / AUTHORED HOSPITAL'));
console.log(JSON.stringify({pass:true,inventory,totalPrefabInstances:Object.values(inventory).reduce((a,b)=>a+b,0),bytes:Buffer.byteLength(place),sha256:crypto.createHash('sha256').update(place).digest('hex')},null,2));
