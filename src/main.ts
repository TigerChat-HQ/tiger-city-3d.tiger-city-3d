import * as THREE from 'three';
import { OrbitControls } from 'three/examples/jsm/controls/OrbitControls.js';
import './style.css';

type BuildType = 'house' | 'shop' | 'office' | 'barracks';
type Mode = 'select' | BuildType | 'army';
type SaveData = { coins:number; population:number; buildings:{type:BuildType;x:number;z:number}[]; conquered:boolean };

const root = document.querySelector<HTMLDivElement>('#game')!;
const coinsEl = document.querySelector<HTMLElement>('#coins')!;
const populationEl = document.querySelector<HTMLElement>('#population')!;
const armyEl = document.querySelector<HTMLElement>('#army')!;
const toastEl = document.querySelector<HTMLElement>('#toast')!;
const statusEl = document.querySelector<HTMLElement>('#status')!;
const battlePanel = document.querySelector<HTMLElement>('#battle-panel')!;
const battleStatus = document.querySelector<HTMLElement>('#battle-status')!;
let coins = 12000, population = 850, army = 120, mode:Mode = 'select', conquered = false;
const buildings: {type:BuildType;x:number;z:number;mesh:THREE.Group}[] = [];
const scene = new THREE.Scene();
scene.background = new THREE.Color('#9bc7d7');
scene.fog = new THREE.Fog('#9bc7d7', 55, 145);
const camera = new THREE.PerspectiveCamera(48, innerWidth/innerHeight, .1, 300);
camera.position.set(27, 27, 30);
const renderer = new THREE.WebGLRenderer({antialias:true, powerPreference:'high-performance'});
renderer.setPixelRatio(Math.min(devicePixelRatio, 1.65));
renderer.setSize(innerWidth, innerHeight);
renderer.shadowMap.enabled = true;
renderer.shadowMap.type = THREE.PCFSoftShadowMap;
renderer.outputColorSpace = THREE.SRGBColorSpace;
root.appendChild(renderer.domElement);
const controls = new OrbitControls(camera, renderer.domElement);
controls.enableDamping = true; controls.maxPolarAngle = Math.PI * .47; controls.minDistance = 12; controls.maxDistance = 72; controls.target.set(0,0,0);
scene.add(new THREE.HemisphereLight(0xd9efff, 0x52634b, 2.05));
const sun = new THREE.DirectionalLight(0xffedcf, 2.4); sun.position.set(-25,40,18); sun.castShadow = true; sun.shadow.mapSize.set(2048,2048); scene.add(sun);
const ground = new THREE.Mesh(new THREE.PlaneGeometry(120,120), new THREE.MeshStandardMaterial({color:0x789b68,roughness:1})); ground.rotation.x=-Math.PI/2; ground.receiveShadow=true; scene.add(ground);
const grid = new THREE.GridHelper(100,50,0x9eb28a,0x829a78); grid.position.y=.015; scene.add(grid);
const roadMat = new THREE.MeshStandardMaterial({color:0x303942,roughness:.92});
function road(x:number,z:number,w:number,d:number){const m=new THREE.Mesh(new THREE.BoxGeometry(w,.12,d),roadMat);m.position.set(x,.07,z);m.receiveShadow=true;scene.add(m);for(let i=-Math.floor((w>d?w:d)/4);i<=Math.floor((w>d?w:d)/4);i++){const dash=new THREE.Mesh(new THREE.BoxGeometry(w>d?1.1:.1,.13,w>d?.12:1.1),new THREE.MeshBasicMaterial({color:0xe7dcae}));dash.position.set(x+(w>d?i*4:0),.145,z+(d>=w?i*4:0));scene.add(dash);}}
for(let i=-40;i<=40;i+=16){road(i,0,7,100);road(0,i,100,7);}
function tree(x:number,z:number){const g=new THREE.Group();const trunk=new THREE.Mesh(new THREE.CylinderGeometry(.16,.22,1.2,7),new THREE.MeshStandardMaterial({color:0x79543a}));trunk.position.y=.6;const crown=new THREE.Mesh(new THREE.IcosahedronGeometry(.85,1),new THREE.MeshStandardMaterial({color:0x326b43,roughness:1}));crown.position.y=1.55;g.add(trunk,crown);g.position.set(x,0,z);scene.add(g);}
for(let i=0;i<34;i++){const x=(Math.random()-.5)*94,z=(Math.random()-.5)*94;if(Math.abs(x%16)>5&&Math.abs(z%16)>5)tree(x,z);}
function building(type:BuildType,x:number,z:number){
 const group=new THREE.Group(); const palette:Record<BuildType,number>={house:0xd8c5a2,shop:0x72a8ad,office:0x8198b5,barracks:0x78836b};
 const h=type==='house'?3.4:type==='shop'?4.2:type==='office'?9:5.2, w=type==='office'?4.2:3.6;
 const body=new THREE.Mesh(new THREE.BoxGeometry(w,h,3.6),new THREE.MeshStandardMaterial({color:palette[type],roughness:.78}));body.position.y=h/2;body.castShadow=true;body.receiveShadow=true;group.add(body);
 const roof=new THREE.Mesh(new THREE.BoxGeometry(w+.18,.35,3.8),new THREE.MeshStandardMaterial({color:type==='barracks'?0x414d3d:0x454b54}));roof.position.y=h+.16;roof.castShadow=true;group.add(roof);
 const floors=Math.max(2,Math.floor(h/1.65));for(let f=0;f<floors;f++)for(let side=-1;side<=1;side++){const win=new THREE.Mesh(new THREE.BoxGeometry(.55,.65,.055),new THREE.MeshStandardMaterial({color:0x9fd5e0,metalness:.25,roughness:.25,emissive:0x17333c}));win.position.set(side*1.08,.9+f*1.45,1.83);group.add(win);}
 if(type==='house'){const peak=new THREE.Mesh(new THREE.ConeGeometry(2.7,.95,4),new THREE.MeshStandardMaterial({color:0x8a5140}));peak.rotation.y=Math.PI/4;peak.position.y=h+.55;group.add(peak);}
 if(type==='barracks'){const flag=new THREE.Mesh(new THREE.BoxGeometry(.08,2,.08),new THREE.MeshStandardMaterial({color:0xddd9ca}));flag.position.set(1.4,h+1,0);group.add(flag);const banner=new THREE.Mesh(new THREE.BoxGeometry(.9,.5,.06),new THREE.MeshStandardMaterial({color:0xb63e32}));banner.position.set(1.82,h+1.65,0);group.add(banner);}
 group.position.set(x,0,z);scene.add(group);return group;
}
function refresh(){coinsEl.textContent=coins.toLocaleString();populationEl.textContent=population.toLocaleString();armyEl.textContent=army.toLocaleString();}
function toast(s:string){toastEl.textContent=s;toastEl.classList.add('show');window.setTimeout(()=>toastEl.classList.remove('show'),2300);}
function save(){const data:SaveData={coins,population,buildings:buildings.map(b=>({type:b.type,x:b.x,z:b.z})),conquered};localStorage.setItem('tiger-city-save-v1',JSON.stringify(data));toast('Maendeleo yamehifadhiwa kwenye simu yako');}
function load(){try{const raw=localStorage.getItem('tiger-city-save-v1');if(!raw)return;const d=JSON.parse(raw) as SaveData;coins=d.coins;population=d.population;conquered=d.conquered;for(const b of d.buildings??[]){const mesh=building(b.type,b.x,b.z);buildings.push({...b,mesh});}refresh();}catch{toast('Save haikusomeka; mchezo umeanza upya');}}
load();
function place(x:number,z:number){const type=mode as BuildType;const cost:Record<BuildType,number>={house:500,shop:850,office:1400,barracks:1800};if(coins<cost[type]){toast('Fedha hazitoshi');return;}const gx=Math.round(x/4)*4,gz=Math.round(z/4)*4;if(buildings.some(b=>Math.hypot(b.x-gx,b.z-gz)<5)){toast('Eneo hili tayari lina jengo');return;}const mesh=building(type,gx,gz);buildings.push({type,x:gx,z:gz,mesh});coins-=cost[type];if(type==='house')population+=24;if(type==='barracks')army+=35;refresh();toast(type==='barracks'?'Kambi imejengwa: wanajeshi +35':'Jengo limejengwa');save();}
const raycaster=new THREE.Raycaster(), pointer=new THREE.Vector2();
renderer.domElement.addEventListener('pointerup',e=>{if((e.target as HTMLElement).closest?.('button'))return;const rect=renderer.domElement.getBoundingClientRect();pointer.x=((e.clientX-rect.left)/rect.width)*2-1;pointer.y=-((e.clientY-rect.top)/rect.height)*2+1;raycaster.setFromCamera(pointer,camera);const hits=raycaster.intersectObject(ground);if(hits.length&&mode!=='select'&&mode!=='army')place(hits[0].point.x,hits[0].point.z);});
document.querySelectorAll<HTMLButtonElement>('.tool').forEach(btn=>btn.addEventListener('click',()=>{document.querySelector('.tool.active')?.classList.remove('active');btn.classList.add('active');mode=btn.dataset.mode as Mode;if(mode==='army'){battlePanel.hidden=false;toast('Jeshi tayari. Jenga kambi kuongeza wanajeshi.');}else if(mode==='select'){battlePanel.hidden=true;}else toast('Gusa sehemu ya wazi kuweka jengo');}));
document.querySelector('#save')!.addEventListener('click',save);
document.querySelector('#rotate')!.addEventListener('click',()=>{const p=camera.position.clone().sub(controls.target);p.applyAxisAngle(new THREE.Vector3(0,1,0),Math.PI/4);camera.position.copy(controls.target.clone().add(p));});
document.querySelector('#zoom-in')!.addEventListener('click',()=>{camera.position.sub(controls.target).multiplyScalar(.82).add(controls.target);});
document.querySelector('#zoom-out')!.addEventListener('click',()=>{camera.position.sub(controls.target).multiplyScalar(1.2).add(controls.target);});
document.querySelector('#attack')!.addEventListener('click',()=>{if(army<60){toast('Unahitaji angalau wanajeshi 60');return;}const attackBtn=document.querySelector<HTMLButtonElement>('#attack')!;attackBtn.disabled=true;battleStatus.textContent='Vikosi vyako vinaingia vitani…';statusEl.textContent='Vita vinaendelea mpakani';const enemy=new THREE.Group();for(let i=0;i<18;i++){const soldier=new THREE.Mesh(new THREE.CapsuleGeometry(.22,.7,3,6),new THREE.MeshStandardMaterial({color:0x9c4638}));soldier.position.set(28+(i%6)*1.2,.65,24+Math.floor(i/6)*1.3);enemy.add(soldier);}scene.add(enemy);let tick=0;const timer=window.setInterval(()=>{tick++;enemy.position.x-=.75;enemy.position.z-=.45;if(tick>=12){window.clearInterval(timer);scene.remove(enemy);const loss=Math.min(army,18+Math.floor(Math.random()*20));army-=loss;coins+=2600;conquered=true;refresh();battleStatus.textContent='USHINDI! Eneo la jirani limetwaliwa';statusEl.textContent='Eneo jipya limeongezwa kwenye himaya';document.querySelector('#mission')!.textContent='Linda eneo jipya na endeleza uchumi';attackBtn.disabled=false;save();toast(`Ushindi! Umepora sarafu 2,600; wanajeshi ${loss} wamepotea`);}},450);});
window.addEventListener('resize',()=>{camera.aspect=innerWidth/innerHeight;camera.updateProjectionMatrix();renderer.setSize(innerWidth,innerHeight);});
function animate(){requestAnimationFrame(animate);controls.update();renderer.render(scene,camera);}animate();
if(!navigator.onLine)toast('Unacheza OFFLINE — maendeleo yanahifadhiwa kwenye simu');
window.addEventListener('offline',()=>toast('Intaneti imekatika — mchezo unaendelea OFFLINE'));
window.addEventListener('online',()=>toast('Intaneti imerudi'));
