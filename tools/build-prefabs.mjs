// Original LAST STOP modular art. Emits actual editable Studio Models; no
// gameplay scripts are embedded in models. Run `node tools/build-prefabs.mjs`.
import fs from 'node:fs';
import path from 'node:path';
const out = path.resolve('assets/prefabs');
fs.mkdirSync(out, {recursive:true});
let sequence=0;
const C={navy:[17,24,32],steel:[95,111,119],dark:[32,44,52],concrete:[120,128,128],white:[210,219,208],cyan:[99,216,213],amber:[233,166,77],red:[208,62,67],green:[92,127,116],rubber:[27,32,35]};
const esc=s=>String(s).replaceAll('&','&amp;').replaceAll('<','&lt;').replaceAll('>','&gt;').replaceAll('"','&quot;');
const scalar=(type,name,value)=>`<${type} name="${esc(name)}">${esc(value)}</${type}>`;
const vec=(name,v)=>`<Vector3 name="${name}"><X>${v[0]}</X><Y>${v[1]}</Y><Z>${v[2]}</Z></Vector3>`;
const col=(name,v)=>`<Color3 name="${name}"><R>${v[0]/255}</R><G>${v[1]/255}</G><B>${v[2]/255}</B></Color3>`;
function cf(name,p=[0,0,0],yaw=0,rz=0){
 const y=yaw*Math.PI/180,z=rz*Math.PI/180,cy=Math.cos(y),sy=Math.sin(y),cz=Math.cos(z),sz=Math.sin(z);
 const r=[cy*cz,-cy*sz,sy,sz,cz,0,-sy*cz,sy*sz,cy];
 return `<CoordinateFrame name="${name}"><X>${p[0]}</X><Y>${p[1]}</Y><Z>${p[2]}</Z>${r.map((n,i)=>`<R${Math.floor(i/3)}${i%3}>${Math.abs(n)<1e-10?0:n}</R${Math.floor(i/3)}${i%3}>`).join('')}</CoordinateFrame>`;
}
function item(cls,name,props='',children=[]){return {cls,name,id:`RBX${++sequence}`,props,children};}
function xml(n){return `<Item class="${n.cls}" referent="${n.id}"><Properties>${scalar('string','Name',n.name)}${n.props}</Properties>${n.children.map(xml).join('')}</Item>`;}
function folder(parent,name){const n=item('Folder',name);parent.children.push(n);return n;}
function model(name){const n=item('Model',name);const origin=part(n,'Origin',[.1,.1,.1],[0,0,0],C.dark,256,{marker:true});n.props=scalar('Ref','PrimaryPart',origin.id);return n;}
function part(parent,name,size,pos,color=C.dark,mat=1088,o={}){
 const n=item(o.cls||'Part',name,vec('size',size)+cf('CFrame',pos,o.yaw||0,o.roll||0)+col('Color',color)+scalar('token','Material',mat)+scalar('bool','Anchored',o.dynamic?false:true)+scalar('bool','CanCollide',o.marker||o.detail||o.dynamic?false:true)+scalar('bool','CanTouch',false)+scalar('bool','CanQuery',!o.marker)+scalar('float','Transparency',o.marker?1:o.alpha||0)+scalar('bool','Massless',!!o.dynamic)+scalar('token','TopSurface',0)+scalar('token','BottomSurface',0)+(o.shape!==undefined?scalar('token','shape',o.shape):''));
if(o.pbr){const material=o.pbr==='MetalPlate'&&!['Floor','Threshold','ServicePipe'].includes(name)?'PaintedSteel':o.pbr;n.children.push(item('StringValue','PbrMaterial',scalar('string','Value',material)));}
 parent.children.push(n);return n;
}
function marker(parent,name,pos,size=[1,1,1],yaw=0){return part(parent,name,size,pos,C.cyan,256,{marker:true,yaw});}
function sign(parent,name,text,size,pos,color=C.white,yaw=0,bg=C.navy,face=5){
 const board=part(parent,name,size,pos,bg,1088,{yaw,detail:true});
 const gui=item('SurfaceGui','PrintedSign',scalar('token','Face',face)+scalar('bool','AlwaysOnTop',false)+scalar('float','LightInfluence',.3)+`<Vector2 name="CanvasSize"><X>1024</X><Y>256</Y></Vector2>`);
 gui.children.push(item('TextLabel','Text',`<UDim2 name="Size"><XS>1</XS><XO>0</XO><YS>1</YS><YO>0</YO></UDim2>`+scalar('float','BackgroundTransparency',1)+scalar('string','Text',text)+col('TextColor3',color)+scalar('bool','TextScaled',true)+scalar('bool','TextWrapped',true)+scalar('token','Font',4)));
 board.children.push(gui);
 const reverse=structuredClone(gui);reverse.id=`RBX${++sequence}`;reverse.props=reverse.props.replace(`<token name="Face">${face}</token>`,`<token name="Face">${face===5?2:5}</token>`);reverse.children[0].id=`RBX${++sequence}`;board.children.push(reverse);return board;
}
function lamp(parent,pos,color=C.white,range=22,brightness=2){
 const n=part(parent,'FluorescentHousing',[4.7,.35,1.3],pos,C.dark);
 const tube=part(parent,'Diffuser',[4.1,.12,.75],[pos[0],pos[1]-.23,pos[2]],color,288,{detail:true});
 tube.children.push(item('PointLight','PracticalLight',col('Color',color)+scalar('float','Range',range)+scalar('float','Brightness',brightness)+scalar('bool','Shadows',false)));
 return n;
}
function pipe(parent,pos,length,axis='Z',color=C.steel){
 // Roblox cylinders run along local X.
 part(parent,'ServicePipe',[length,.38,.38],pos,color,1088,{shape:2,yaw:axis==='Z'?90:0,detail:true,pbr:'MetalPlate'});
 for(let a=-length/2+2;a<length/2;a+=6){let p=[...pos];p[axis==='Z'?2:0]+=a;part(parent,'PipeCollar',[.25,.65,.65],p,C.dark,1088,{shape:2,yaw:axis==='Z'?90:0,detail:true});}
}
function panel(parent,pos,size=[5,7,.3],yaw=0){
 part(parent,'InsetPanelFrame',size,pos,C.steel,1088,{yaw,pbr:'MetalPlate'});
 part(parent,'InsetPanel',[size[0]-.25,size[1]-.25,.16],[pos[0],pos[1],pos[2]+.22],C.dark,1088,{yaw,pbr:'MetalPlate'});
}
function floor(parent,pos,size,kind='ChippedConcrete',color=C.concrete){return part(parent,'Floor',size,pos,color,kind==='MetalPlate'?1088:816,{pbr:kind});}
function wall(parent,pos,size,color=C.concrete,o={}){
 const w=part(parent,'Wall',size,pos,color,816,{pbr:'ChippedConcrete'});
 const alongX=size[0]>=size[2];
 part(parent,'WallSkirting',alongX?[size[0],.28,size[2]+.08]:[size[0]+.08,.28,size[2]],[pos[0],.65,pos[2]],C.dark);
 if(o.clinical){
  // Clinical trim follows the wall's long axis. A single trim block centred on
  // a thin wall protrudes from both faces, so wainscot, cap and accent read as
  // continuous bands instead of crossing doorways or the corridor.
  part(parent,'WardWainscot',alongX?[size[0]-.5,2.5,size[2]+.14]:[size[0]+.14,2.5,size[2]-.5],[pos[0],2.05,pos[2]],[150,158,150],816,{detail:true});
  part(parent,'WardCap',alongX?[size[0]-.4,.28,size[2]+.22]:[size[0]+.22,.28,size[2]-.4],[pos[0],3.45,pos[2]],[130,138,132],816,{detail:true});
  part(parent,'WallAccent',alongX?[size[0]-.6,.1,size[2]+.16]:[size[0]+.16,.1,size[2]-.6],[pos[0],4.0,pos[2]],C.green,272,{detail:true});
 } else {
  part(parent,'WallBand',[size[0]+.02,.7,size[2]+.02],[pos[0],3.5,pos[2]],C.green);
 }
 return w;
}
function bench(parent,x,z,yaw=0){
 const m=folder(parent,'PlatformBench');
 const trans=(dx,y,dz)=>[x+dx*Math.cos(yaw*Math.PI/180)+dz*Math.sin(yaw*Math.PI/180),y,z-dx*Math.sin(yaw*Math.PI/180)+dz*Math.cos(yaw*Math.PI/180)];
 for(let a=-1;a<=1;a++){
  part(m,'MoldedSeat',[2.15,.4,2],trans(a*2.3,2,0),C.green,272,{yaw});
  part(m,'SeatBack',[2.15,2.1,.3],trans(a*2.3,3,1),C.green,272,{yaw});
 }
 for(const a of [-3.2,3.2]){part(m,'Leg',[.35,1.7,1.7],trans(a,1,0),C.steel,1088,{yaw,pbr:'MetalPlate'});part(m,'Armrest',[.2,.3,2],trans(a,2.8,0),C.steel,1088,{yaw});}
}
function monitor(parent,x,y,z){
 part(parent,'MonitorHousing',[2.3,1.7,.35],[x,y,z],C.dark);
 sign(parent,'MonitorGlass','ECG  /  072\n_∧__∧__∧__',[1.95,1.35,.05],[x,y,z+.22],C.cyan,0,C.navy);
 part(parent,'MonitorStand',[.3,1,.4],[x,y-1.1,z],C.steel);
}
function vent(parent,x,y,z){
 part(parent,'VentFrame',[4.2,2.4,.3],[x,y,z],C.steel);
 for(let n=-.8;n<=.8;n+=.32)part(parent,'VentLouvre',[3.7,.12,.3],[x,y+n,z+.2],C.dark,1088,{detail:true});
}
function bed(parent,x,z){
 const m=folder(parent,'PatientBed');
 part(m,'Undercarriage',[3.8,.45,7.2],[x,1.1,z],C.steel,1088,{pbr:'MetalPlate'});
 part(m,'Mattress',[3.45,.8,6.8],[x,2,z],C.white,272);
 part(m,'FoldedBlanket',[3.5,.16,3.3],[x,2.49,z+1.6],C.green,1312);
 part(m,'Pillow',[2.6,.3,1.3],[x,2.5,z-2.3],C.white,1312);
 for(const dz of [-3.6,3.6]){
  part(m,'EndBoard',[4,1.6,.3],[x,2.4,z+dz],C.white);
  for(const dx of [-1.6,1.6])part(m,'Caster',[.55,.65,.65],[x+dx,.55,z+dz*.8],C.rubber,272,{shape:2});
 }
 for(const dx of [-2,2]){part(m,'SafetyRail',[.18,.18,5.6],[x+dx,2.9,z],C.steel);for(const dz of [-2.6,0,2.6])part(m,'RailPost',[.15,.8,.15],[x+dx,2.5,z+dz],C.steel);}
 part(m,'IVPole',[.12,6,.12],[x-2.9,3.5,z-1.4],C.steel);
 part(m,'IVBag',[.8,1.3,.35],[x-2.5,5.5,z-1.4],C.white,1568,{alpha:.3,detail:true});
 part(m,'BedsideCabinet',[2,2.8,2],[x+3.5,1.8,z-2],C.white);
 monitor(m,x+3.5,4.2,z-2);
}
function records(parent,name,pos){
 const m=folder(parent,`${name}Desk`);
 part(m,'Desk',[6,.3,3],[pos[0],2.9,pos[2]],C.steel);
 for(const dx of [-2.5,2.5])part(m,'Pedestal',[.5,2.7,2.5],[pos[0]+dx,1.5,pos[2]],C.dark);
 const r=part(m,name,[1.7,.28,1.2],[pos[0],3.23,pos[2]],C.amber,272);
 part(m,'RecordPaper',[1.45,.04,1],[pos[0],3.4,pos[2]],C.white,272,{detail:true});
 r.children.push(item('StringValue','ObjectiveCaption',scalar('string','Value',name.replaceAll('_',' '))));
 return r;
}
function write(name,n){fs.writeFileSync(path.join(out,name+'.rbxmx'),`<roblox version="4"><External>null</External><External>nil</External>${xml(n)}</roblox>\n`);return n;}

const lobby=model('Lobby');
const shell=folder(lobby,'StationArchitecture');
const concFloor=floor(shell,[5,-.5,0],[70,1,72]);
const serviceFloor=floor(shell,[-34,-1.5,0],[14,1,72],'ChippedConcrete',C.navy);
// Structural columns at concourse quarters with plinths, webs, flanges and capitals.
for(const x of [-24,28])for(const z of [-25,-1,23]){
 part(shell,'ColumnPlinth',[3.7,.65,3.7],[x,.4,z],C.steel);
 part(shell,'ColumnWeb',[1.1,16,1.1],[x,8.5,z],C.steel,1088,{pbr:'MetalPlate'});
 for(const side of [-1,1])part(shell,'ColumnFlange',[2.7,16,.32],[x,8.5,z+side*.65],C.steel,1088,{pbr:'MetalPlate'});
 part(shell,'ColumnCapital',[4,1,4],[x,16.2,z],C.steel);
 sign(shell,'ColumnNumber',z===23?'01':'07',[1.2,2,.08],[x,6,z+.85],C.white);
}
// Painted plaster wall bands and a recessed wainscot band replace raw steel.
for(const side of [-1,1]){
 part(shell,'WallPlaster',[1.2,12,72],[side*40,6,0],[200,206,198],816);
 part(shell,'WallWainscot',[1.2,2.2,72],[side*40,1.7,0],[150,158,150],816,{detail:true});
 part(shell,'WallCap',[1.2,.4,72],[side*40,3.1,0],[130,138,132],816,{detail:true});
}
part(shell,'WallPlaster',[82,12,1.4],[0,6,-36.5],[200,206,198],816);
part(shell,'WallPlaster',[82,12,1.4],[0,6,36.5],[200,206,198],816);
part(shell,'WallWainscot',[82,2.2,1.4],[0,1.7,-36.5],[150,158,150],816,{detail:true});
part(shell,'WallWainscot',[82,2.2,1.4],[0,1.7,36.5],[150,158,150],816,{detail:true});
part(shell,'WallCap',[82,.4,1.4],[0,3.1,-36.5],[130,138,132],816,{detail:true});
part(shell,'WallCap',[82,.4,1.4],[0,3.1,36.5],[130,138,132],816,{detail:true});
part(shell,'CofferedCeiling',[84,.6,72],[0,18.5,0],C.dark);
for(const z of [-30,-18,-6,6,18,30]){
 part(shell,'RivetedCeilingBeam',[82,1.1,.7],[0,17.5,z],C.steel);
 for(const x of [-20,4,28])lamp(shell,[x,16.7,z],C.white,23,1.65);
}
// Amplified rear service wall with practical lighting, pipes and cable trays.
for(const x of [-31,-37])part(shell,'Rail',[.25,.55,70],[x,-.3,0],C.steel,1088,{pbr:'MetalPlate'});
for(let z=-32;z<=32;z+=4){part(shell,'RailSleeper',[11,.3,1.2],[-34,-.65,z],[62,49,40],512);}
for(const z of [-24,-8,8,24]){
 panel(shell,[39,7,z],[.5,9,10]);
 vent(shell,-41,10,z);
 // Rear service pipes alternate above the service wall.
 pipe(shell,[36,10,z],26,'Z');
}
for(const z of [-22,-6,10]){
 wall(shell,[34,7,z],[.8,14,7],C.dark);
 part(shell,'GalleryLintel',[8,1,1],[36,14,z+4],C.steel);
 part(shell,'GalleryRail',[.15,.15,10],[31,3,z],C.steel);
 for(const dz of [-4,0,4])part(shell,'RailPost',[.18,3,.18],[31,1.5,z+dz],C.steel);
}
for(const x of [-20,0,20]){pipe(shell,[x,16.8,0],65,'Z');}
for(let z=-30;z<=30;z+=8){part(shell,'CableTray',[7,.25,1],[21,16.4,z],C.dark);for(const x of [18,20,22,24])part(shell,'Cable',[.14,.14,7],[x,16.65,z],C.rubber,272,{detail:true});}
// Tactile warning strip along the platform edge for navigation clarity.
for(let z=-32;z<34;z+=3){part(shell,'TactilePaver',[1.5,.09,2.8],[-26,.06,z],C.amber,272);for(const dx of [-.4,0,.4])part(shell,'TactileRidge',[.08,.11,2.3],[-26+dx,.13,z],C.dark,272,{detail:true});}
// Benches flank the central queue path.
for(const z of [-20,0,20]){bench(lobby,-18,z,90);}
bench(lobby,20,23,180);
// Ticket/check-in barriers with readers and status LEDs.
for(const x of [-18,-10,10,18]){
 const g=folder(lobby,'TicketBarrier');
 part(g,'SteelPedestal',[1.8,3.3,4],[x,1.7,14],C.steel,1088,{pbr:'MetalPlate'});
 part(g,'Reader',[1.3,.25,1.4],[x,3.5,13.1],C.dark);
 part(g,'StatusLED',[.55,.06,.6],[x,3.66,13],C.cyan,288,{detail:true});
 part(g,'TurnstileArm',[3.2,.18,.18],[x+1.6,2.4,14],C.steel,1088,{detail:true});
}
// Signage hierarchy: station identifier, wayfinding, posters.
sign(lobby,'MainStationSign','SAINT ORIN\nRESEARCH TRANSIT  /  TERMINUS',[26,4,.35],[0,13.2,-14],C.white);
sign(lobby,'BoardingWayfinding','↓  DEEP ACCESS  /  ELEVATOR  ↓',[20,1.6,.25],[0,9.7,-14],C.cyan);
sign(lobby,'PlatformSign','01  /  NORTHBOUND\nSERVICE SUSPENDED',[12,4,.35],[-39.2,7,-8],C.amber,-90);
sign(lobby,'OriginalPoster','DO NOT WAIT\nFOR THE LAST TRAIN\nTRANSIT AUTHORITY  1986',[5,7,.1],[38.9,7,24],C.white,-90,[40,79,85]);
sign(lobby,'SafetyPoster','IF THE LIGHTS FAIL\nFOLLOW THE AMBER LINE',[5,7,.1],[38.9,7,9],C.amber,-90,C.navy);
// Queue console (preserved boarding anchor) with illuminated screen and keys.
const consolePart=part(lobby,'QueueConsole',[3.5,3.7,2],[14,1.9,-10],C.dark,1088,{pbr:'MetalPlate'});
sign(lobby,'QueueScreen','EXPEDITION\nPRESS E TO BOARD',[3,1.5,.1],[14,3,-8.94],C.cyan);
for(const x of [13.2,14,14.8])part(lobby,'ConsoleKey',[.45,.15,.45],[x,3.85,-9.6],C.amber,272,{detail:true});
const lobbyMarkers=folder(lobby,'Markers');
marker(lobbyMarkers,'EntranceSpawn',[0,4,27]);marker(lobbyMarkers,'ElevatorSocket',[0,0,-25]);
marker(lobbyMarkers,'RoomBounds',[0,8,0],[84,18,72]);
const spawnPoint=part(lobby,'LobbySpawnPoint',[5,.2,5],[0,.2,27],C.dark,272,{cls:'SpawnLocation',marker:true});
spawnPoint.props+=scalar('bool','Enabled',true)+scalar('bool','Neutral',true)+scalar('float','Duration',0);
write('Lobby',lobby);

const lift=model('Elevator');
floor(lift,[0,.1,0],[20,.5,17],'MetalPlate',C.steel);
part(lift,'RubberFloorInset',[17,.12,13],[0,.42,0],C.rubber,272);
// Cabin shell: side walls, rear wall and ceiling.
for(const x of [-9.8,9.8])part(lift,'CabinWall',[.5,13.5,17],[x,7,0],C.dark,1088,{pbr:'MetalPlate'});
part(lift,'BackWall',[20,13.5,.5],[0,7,-8.3],C.dark,1088,{pbr:'MetalPlate'});
for(const x of [-7.5,-3.75,0,3.75,7.5]){
 part(lift,'BackPanel',[3.5,10,.16],[x,6.6,-7.95],C.steel,1088,{pbr:'MetalPlate'});
 for(const y of [2,11])part(lift,'PanelBolt',[.13,.13,.08],[x-1.4,y,-7.8],C.dark,1088,{shape:0,detail:true});
}
part(lift,'CabinCeiling',[20,.5,17],[0,14,0],C.navy);
// Ceiling practicals: two long fluorescents plus louvre array.
lamp(lift,[-4,13.5,0],C.white,20,2);lamp(lift,[4,13.5,0],C.white,20,2);
for(let z=-5;z<=5;z+=1)part(lift,'CeilingLouvre',[5,.15,.1],[0,13.5,z],C.steel,1088,{detail:true});
// Handrails and kickplates inside the cabin.
for(const x of [-9.35,9.35]){
 part(lift,'Handrail',[.2,.22,12],[x,4,0],C.steel);
 part(lift,'WallKickplate',[.12,1.3,15],[x,.95,0],C.steel,1088,{pbr:'MetalPlate'});
}
// Door framing: outer jambs, header, seals and threshold.
for(const x of [-10.5,10.5]){
 part(lift,'OuterJamb',[1.2,14.8,1.5],[x,7.4,8.4],C.steel,1088,{pbr:'MetalPlate'});
 part(lift,'DoorSeal',[.18,12.8,.3],[x*.91,6.8,8.7],C.rubber,272);
}
part(lift,'MechanicalHeader',[23,2,2],[0,14.5,8.4],C.dark);
part(lift,'Threshold',[22,.3,2.2],[0,.4,8.6],C.steel,1088,{pbr:'MetalPlate'});
for(const z of [8,8.5,9])part(lift,'ThresholdGroove',[19,.04,.06],[0,.57,z],C.rubber,272,{detail:true});
// Moving doors: each leaf carries an inset panel and a door jamb side-stripe.
// Children are welded by FloorService before door tweening; markers on the
// door leaves are preserved for the boarding/exit logic.
for(const side of [-1,1]){
 const d=part(lift,side===-1?'DoorLeft':'DoorRight',[9.5,12.8,.45],[side*4.78,6.95,8.55],C.steel,1088,{pbr:'MetalPlate'});
 part(d,'DoorInset',[8.7,10.5,.08],[side*4.78,6.9,8.82],C.dark,1088,{pbr:'MetalPlate',detail:true});
 // Meeting seals sit on the inner leaf edges, not mid-door. Bottom seals and
 // portholes finish the leaf without interfering with the welded tween.
 part(d,'DoorMeetingSeal',[.08,12.8,.35],[side*.06,6.9,8.55],C.rubber,272,{detail:true});
 part(d,'DoorBottomSeal',[9.2,.3,.4],[side*4.78,.72,8.55],C.rubber,272,{detail:true});
 part(d,'DoorViewportFrame',[2.5,3,.1],[side*4.78,8.7,8.84],C.steel,1088,{detail:true});
 part(d,'DoorViewportGlass',[2.1,2.6,.06],[side*4.78,8.7,8.9],C.cyan,1568,{alpha:.55,detail:true});
 for(let y=1.5;y<13;y+=1.4)part(lift,'JambHazardStripe',[.55,.7,.12],[side*10,y,9.21],C.amber,272,{roll:25,detail:true});
}
// Cabin instruction and control panel.
sign(lift,'CabinInstruction','MAX 12\nBANK TO SURVIVE',[5,1.8,.1],[0,10.9,-7.79],C.white);
part(lift,'ControlPanel',[1.5,4,.25],[8,5.5,-7.8],C.dark);
for(let i=0;i<4;i++){part(lift,'TactileButton',[.5,.5,.15],[8,4.2+i*.75,-7.57],i===3?C.red:C.amber,272,{shape:2,detail:true});}
sign(lift,'EtchedPanelLabel','01\n02\n03\nSOS',[.5,3,.03],[8.55,5.3,-7.6],C.white);
// Animated floor indicator above the door. The three named dots sit proud of
// the bezel so FloorService can paint and chase them without z-fighting.
sign(lift,'FloorDisplay','B0  /  CONCOURSE',[6.8,.75,.1],[0,14.85,9.56],C.cyan);
part(lift,'IndicatorBezel',[7.4,1.75,.16],[0,14.42,9.48],C.dark,1088,{detail:true});
for(let i=0;i<3;i++){
 part(lift,`IndicatorRing${i+1}`,[.42,.42,.03],[i-1,14.02,9.575],C.dark,288,{detail:true});
 part(lift,`IndicatorDot${i+1}`,[.3,.3,.02],[i-1,14.02,9.605],i===0?C.amber:C.dark,288,{detail:true});
}
const liftMarkers=folder(lift,'Markers');marker(liftMarkers,'EntranceSpawn',[0,4,0]);marker(liftMarkers,'ElevatorReturnZone',[0,5,0],[18,10,14]);
write('Elevator',lift);

const hospital=model('Hospital');const rooms=folder(hospital,'Rooms');
const roomSpecs=[['CentralCorridor',0,-4,14,66],['ArrivalFoyer',0,28,30,12],['PatientWard',-21,-2,28,30],['Treatment',21,9,28,28],['Archive',21,-26,28,22],['EastLoop',21,-10,28,10],['NorthCrossing',10,-35,34,8]];
for(const [name,x,z,w,d] of roomSpecs){
 const r=folder(rooms,name);floor(r,[x,-.5,z],[w,1,d],'ChippedConcrete',[165,175,164]);
 part(r,'CeilingTiles',[w,.4,d],[x,12.5,z],C.dark);
 for(let tz=z-d/2+2;tz<z+d/2;tz+=6){for(let tx=x-w/2+2;tx<x+w/2;tx+=6){part(r,'TerrazzoTile',[5.8,.035,5.8],[tx,.025,tz],((Math.round(tx+tz)/2)%3===0)?[148,161,153]:[184,192,177],816,{detail:true,pbr:'ChippedConcrete'});}}
 for(let tz=z-d/2+4;tz<z+d/2;tz+=10)lamp(r,[x,11.8,tz],name==='Archive'?[180,202,186]:C.white,19,2);
}
// Corridor walls have authored door openings; there is no enclosing box fallback.
// Clinical trim follows each wall's long axis so wainscot and caps never bridge
// a doorway or run across the corridor.
const corridorWalls=[[-7,-28,14],[-7,-10,6],[-7,17,14],[7,-30,10],[7,-8,12],[7,23,8]];
for(const [x,z,len] of corridorWalls)wall(rooms,[x,6,z],[.65,12,len],[167,183,171],{clinical:true});
for(const [x,z,len] of corridorWalls){
 const railX=x+(x<0?.45:-.45);
 part(rooms,'WallProtectionRail',[.2,.25,len-1.6],[railX,3,z],C.green,1088,{detail:true});
 for(const dz of [-(len-1.6)/2,(len-1.6)/2])part(rooms,'RailBracket',[.3,.3,.3],[railX,3,z+dz],C.steel,1088,{detail:true});
}
for(const x of [-35,35])wall(rooms,[x,6,-3],[.8,12,66],[173,186,174],{clinical:true});
for(const [x,z,w] of [[-21,-17,28],[-21,13,28],[21,23,28],[21,-37,28],[-13,34,4],[13,34,4]])wall(rooms,[x,6,z],[w,12,.8],[173,186,174],{clinical:true});
// Foyer side walls close the arrival room around the elevator opening.
for(const x of [-15,15])wall(rooms,[x,6,28],[.8,12,12],[173,186,174],{clinical:true});
// Open east-loop doorway between treatment and archive.
for(const z of [-5,-15]){wall(rooms,[11,6,z],[8,12,.6],[173,186,174],{clinical:true});wall(rooms,[31,6,z],[8,12,.6],[173,186,174],{clinical:true});}
for(const [x,z] of [[-7,3],[7,9],[7,-19],[21,-5]]){
 part(rooms,'DoorLintel',[.9,2,9],[x,11,z],C.green);
 for(const dz of [-4.5,4.5])part(rooms,'DoorJamb',[.9,10,.35],[x,5,z+dz],C.green);
}
for(const z of [-29,-13,4,20]){
 sign(rooms,'OverheadWayfinding',z<0?'ARCHIVE  →  /  WARD  ←':'←  PATIENT WARD\nELEVATOR  ↓',[10,1.4,.2],[0,9.5,z],C.white);
}
sign(rooms,'HospitalIdentifier','SAINT ORIN\nCLINICAL RESEARCH / WARD 07',[11,2.4,.2],[-14.45,7.8,28],C.white,-90,C.green);
for(const z of [-9,5]){bed(rooms,-25,z);bed(rooms,-13,z);}
// Privacy curtains are per bed, not one ward-wide track crossing both beds.
for(const [x,z] of [[-25,-9],[-13,-9],[-25,5],[-13,5]]){
 part(rooms,'CurtainTrack',[8.6,.15,.15],[x,10,z+3.9],C.steel);
 for(let dx=-3.6;dx<=3.6;dx+=1.2)part(rooms,'FadedCurtainFold',[.5,6,.3],[x+dx,7,z+3.9],C.green,1312,{detail:true});
}
bed(rooms,26,10);
part(rooms,'ScannerTable',[4,1,7],[17,2.4,10],C.white);
for(const x of [14.5,19.5])part(rooms,'ScannerSupport',[1,7,1],[x,4,7],C.white);
part(rooms,'ScannerArch',[6,1.2,3],[17,7.5,7],C.white);
sign(rooms,'ScannerLabel','ORIN // IMAGING\nDO NOT ENTER WHEN LIT',[4,.9,.1],[17,7.5,8.6],C.cyan);
monitor(rooms,15,4,19);
// Nurses' station in the arrival foyer: a supported counter, monitor, chart
// tray and spill, clear of the delivery receiver and elevator approach.
const ns=folder(rooms,'NursesStation');
part(ns,'NursesBody',[5.8,2.6,2.2],[-10,1.45,30.5],C.white,1088,{pbr:'ChippedConcrete'});
part(ns,'NursesCounter',[6,.3,2.4],[-10,2.9,30.5],C.white,1088,{pbr:'ChippedConcrete'});
part(ns,'NursesTop',[6.2,.1,2.6],[-10,3.1,30.5],C.white,1088,{detail:true});
part(ns,'StationMonitor',[2.3,1.7,.35],[-8.5,4,30.5],C.dark);
part(ns,'MonitorStand',[.3,1,.4],[-8.5,3.5,30.5],C.steel);
part(ns,'ChartTray',[1.2,.2,1.6],[-11.5,3.2,30.5],C.white,272,{detail:true});
part(ns,'SpillPuddle',[1.4,.08,1.4],[-8,0.1,29.2],C.rubber,1312,{alpha:.4,detail:true});
part(ns,'StationChair',[1.5,1.8,1.5],[-11.5,1,32],C.rubber,272);
// Abandoned personal effects around the authored beds, without duplicate beds
// or room-wide curtains.
for(const [x,z] of [[-21,-12],[-9,-4],[-21,8],[-9,11]]){
 part(rooms,'DroppedClipboard',[.4,.3,.2],[x,0.15,z],C.white,272,{detail:true});
 part(rooms,'SpilledPills',[.6,.15,.6],[x+1.2,0.14,z+.4],C.rubber,1312,{detail:true});
}
// Treatment room carts: crash cart and a treatment trolley with supplies.
const tc=folder(rooms,'TreatmentCarts');
part(tc,'CrashCart',[2.2,3,1.4],[24,1.5,3],C.rubber,1088,{pbr:'MetalPlate'});
part(tc,'CrashCartDrawer',[1.9,.5,1.2],[24,3.1,2.6],C.rubber,272,{detail:true});
part(tc,'TreatmentTrolley',[1.8,.9,1.2],[26,1.5,10],C.steel,1088,{pbr:'MetalPlate'});
part(tc,'Tray',[1.4,.08,1],[26,2.4,11.2],C.white,272,{detail:true});
part(tc,'Tray',[1.4,.08,1],[26,2.4,11.6],C.white,272,{detail:true});
part(tc,'Tray',[1.4,.08,1],[26,2.4,12],C.white,272,{detail:true});
// Deterioration: containment-breach tape and peeling paint bands so damage
// tells a story of hurried evacuation rather than generic decay.
const tape=C.amber;
for(const z of [-29,-19,-9,1]){
 part(rooms,'BreachTape',[.12,.1,12],[30,4,z],tape);
 part(rooms,'BreachTape',[.12,.1,12],[30,5.6,z],tape);
}
for(const [x,z] of [[-34.35,-10],[-34.35,4],[34.35,6],[34.35,18]]){
 part(rooms,'PeelingPaint',[.18,2.4,6],[x,6.2,z],[96,104,92],816,{alpha:.35,detail:true});
}
for(const x of [13,21,29]){
 part(rooms,'ArchiveShelf',[5,8,2],[x,4,-33],C.steel);
 for(const y of [1.4,3.4,5.4,7.4]){part(rooms,'ShelfBoard',[5.2,.15,2.2],[x,y,-32.8],C.dark);for(let dx=-1.8;dx<=1.8;dx+=.6)part(rooms,'RecordBinder',[.48,1.5,1.5],[x+dx,y+.85,-32.8],dx>0?C.green:C.rubber,272,{detail:true});}
}
const objectives=folder(hospital,'ObjectiveSockets');
for(const [name,p] of [['Ward_Record',[-18,0,-12]],['Imaging_Record',[27,0,17]],['Archive_Record',[25,0,-23]]]){
 const r=records(objectives,name,p);const a=part(r,'LocatorLamp',[.22,.09,.22],[p[0]+.55,3.43,p[2]],C.amber,288,{detail:true});
}
for(const [x,z] of [[-34,0],[34,12],[34,-23]]){vent(rooms,x,8,z);pipe(rooms,[x,10.7,z],13,'Z');}
sign(rooms,'ArchiveDoorSign','RECORD ARCHIVE\nAUTHORIZED STAFF',[.15,1.8,6],[7.6,7,-19],C.white,90,C.green);
sign(rooms,'WardSign','PATIENT WARD\nBEDS 01 — 04',[.15,1.8,6],[-7.6,7,3],C.white,-90,C.green);
// Ward control A is a wall station on the outer ward wall, clear of the beds.
part(rooms,'WardControlCabinet',[.4,2.4,1.8],[-34.4,3.4,9],C.steel,1088,{pbr:'MetalPlate'});
part(rooms,'WardControlFace',[.12,1.8,1.3],[-34.2,3.4,9],C.dark,1088,{detail:true});
part(rooms,'WardControlLamp',[.1,.18,.18],[-34.12,4.35,9],C.amber,288,{detail:true});
for(const y of [2.5,4.3])part(rooms,'ControlConduit',[.1,.1,2.6],[-34.35,y,9],C.steel,1088,{detail:true});
const hm=folder(hospital,'Markers');
marker(hm,'EntranceSpawn',[0,4,28]);marker(hm,'ElevatorSocket',[0,0,43],[1,1,1],180);marker(hm,'ElevatorReturnZone',[0,5,43],[18,10,14]);
marker(hm,'EnemySpawn',[0,5,-25]);marker(hm,'RoomBounds',[0,7,3],[74,16,100]);
const patrol=folder(hm,'PatrolPaths');for(const [i,p] of [[0,[0,1,-25]],[1,[0,1,12]],[2,[21,1,9]],[3,[21,1,-24]],[4,[0,1,-31]]])marker(patrol,String(i+1),p);
// Medical equipment detail for the treatment and ward rooms (additive world props).
function medCab(x,z,yaw){
 const y=1.3;
 part(rooms,'MedCabinet',[1.4,2.6,.9],[x,y,z],C.white,272,{yaw});
 part(rooms,'MedTop',[1.6,.25,1.1],[x,y+1.3,z+0.06],C.white,1088,{yaw});
 part(rooms,'MedTray',[1.2,.15,.7],[x,y+1.45,z+0.32],C.white,288,{detail:true});
 part(rooms,'MedBin',[.35,.35,.35],[x+0.55,y+1.45,z+0.42],C.red,272,{detail:true});
}
for(const p of [[10,8,0],[32,8,180],[10,20,0],[32,20,180],[-32,4,90],[-6,11,-90],[-32,-10,90],[-6,-10,-90]])medCab(p[0],p[1],p[2]);
write('Hospital',hospital);

// An original articulated containment subject. Art details are welded onto
// named R6 body segments; Motor6Ds drive the gait in EnemyService.
const stalker=model('Stalker');const root=part(stalker,'HumanoidRootPart',[2,2,1],[0,5,0],C.dark,272,{dynamic:true,alpha:1});stalker.props=scalar('Ref','PrimaryPart',root.id);
const torso=part(stalker,'Torso',[2,3,1.1],[0,5,0],C.rubber,1312,{dynamic:true});
torso.props+=scalar('bool','CanCollide',true);
const head=part(stalker,'Head',[1.1,1.8,.9],[0,7.25,0],C.steel,1088,{dynamic:true});
const limbs=[['Left Arm',[-1.75,4.6,0],[.65,4.6,.7]],['Right Arm',[1.75,4.6,0],[.7,4.6,.7]],['Left Leg',[-.6,2,0],[.65,4,.8]],['Right Leg', [.6,2,0],[.65,4,.8]]].map(([n,p,s])=>part(stalker,n,s,p,C.rubber,1312,{dynamic:true}));
function joint(name,p0,p1,c0,c1){p0.children.push(item('Motor6D',name,scalar('Ref','Part0',p0.id)+scalar('Ref','Part1',p1.id)+cf('C0',c0)+cf('C1',c1)));}
joint('RootJoint',root,torso,[0,0,0],[0,0,0]);joint('Neck',torso,head,[0,1.5,0],[0,-.75,0]);
joint('Left Shoulder',torso,limbs[0],[-1.3,1.1,0],[.45,1.5,0]);joint('Right Shoulder',torso,limbs[1],[1.3,1.1,0],[-.45,1.5,0]);
joint('Left Hip',torso,limbs[2],[-.6,-1,0],[0,2,0]);joint('Right Hip',torso,limbs[3],[.6,-1,0],[0,2,0]);
function attached(owner,name,size,pos,color,mat=1088,o={}){const n=part(stalker,name,size,pos,color,mat,{...o,dynamic:true});n.children.push(item('WeldConstraint','ArtWeld',scalar('Ref','Part0',owner.id)+scalar('Ref','Part1',n.id)));return n;}
for(const x of [-.25,.25])attached(head,'DimEye',[.15,.1,.08],[x,7.45,-.5],C.amber,288);
attached(head,'ContainmentMask',[1.25,.5,.15],[0,6.95,-.54],C.dark);
for(const y of [4.3,5.4,6.2])attached(torso,'RestraintStrap',[2.25,.25,1.3],[0,y,0],[92,76,55],1312);
attached(torso,'ContainmentSpine',[.45,3.5,.5],[0,5.2,.8],C.steel);
attached(limbs[1],'AsymmetricPauldron',[1.8,1.1,1.8],[1.7,6.3,0],C.steel);
for(let i=0;i<4;i++)attached(limbs[0],'LongFinger',[.12,1.1,.15],[-1.5+i*.16,1.9,-.3],C.steel,1088);
stalker.children.push(item('Humanoid','Humanoid',scalar('float','WalkSpeed',9)+scalar('float','MaxHealth',100)+scalar('float','Health',100)+scalar('float','HipHeight',0)+scalar('token','DisplayDistanceType',2)+scalar('bool','RequiresNeck',true)));
write('Stalker',stalker);
console.log(JSON.stringify({models:['Lobby','Elevator','Hospital','Stalker'],instances:sequence,output:out}));
