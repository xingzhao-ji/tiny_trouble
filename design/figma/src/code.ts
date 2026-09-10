/* Original Tiny Trouble Figma development plugin. No network or existing-page edits.
 * Locally type-checked against official Figma typings; editor execution unverified.
 */
type Parent = PageNode | FrameNode | ComponentNode;
type View = typeof TT_TOKENS.reference_viewports[number];
const C = TT_TOKENS.colors, L = TT_TOKENS.layout, T = TT_TOKENS.typography;
let FONT: FontName = { family: T.family, style: "SemiBold" };
const buttonMasters: Record<string, ComponentNode> = {};
const cardMasters: Record<string, ComponentNode> = {};
const links: Array<{from: string; to: string; label: string}> = [];
function rgb(hex: string): RGB { return {r:parseInt(hex.slice(1,3),16)/255,g:parseInt(hex.slice(3,5),16)/255,b:parseInt(hex.slice(5,7),16)/255}; }
function paint(hex: string): SolidPaint { return {type:"SOLID",color:rgb(hex)}; }
function rect(parent: Parent, name: string, x: number, y: number, w: number, h: number, color: string, radius=0): RectangleNode {
 const n=figma.createRectangle();parent.appendChild(n);n.name=name;n.x=x;n.y=y;n.resize(w,h);n.fills=[paint(color)];n.cornerRadius=radius;return n;
}
function text(parent: Parent, value: string, x: number,y: number,w: number,size: number,color=C.ink): TextNode {
 const n=figma.createText();parent.appendChild(n);n.name=value.slice(0,55);n.fontName=FONT;n.fontSize=size;n.lineHeight={unit:"PERCENT",value:140};n.characters=value;n.fills=[paint(color)];n.resize(w,Math.ceil(size*1.4));n.textAutoResize="HEIGHT";n.x=x;n.y=y;return n;
}
function frame(parent: Parent,name:string,x:number,y:number,w:number,h:number,color=C.cream):FrameNode {
 const f=figma.createFrame();parent.appendChild(f);f.name=name;f.x=x;f.y=y;f.resize(w,h);f.fills=[paint(color)];f.clipsContent=true;return f;
}
function decode64(value:string):Uint8Array {
 const chars="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/",out:number[]=[];let bits=0,buffer=0;
 for(const ch of value){if(ch==="=")break;const v=chars.indexOf(ch);if(v<0)continue;buffer=(buffer<<6)|v;bits+=6;if(bits>=8){bits-=8;out.push((buffer>>bits)&255);}}
 return new Uint8Array(out);
}
function image(parent:Parent,key:string,x:number,y:number,w:number,h:number):void {
 const a=TT_ASSETS.find(v=>v.key===key);if(!a)throw new Error("Missing asset "+key);
 const n=rect(parent,a.label,x,y,w,h,C.cream);n.fills=[{type:"IMAGE",imageHash:figma.createImage(decode64(a.data)).hash,scaleMode:"FIT"}];n.setPluginData("tt.source",JSON.stringify({path:a.source,sha256:a.sha256,kind:a.label}));
}
function baseButton(mode:string,state:string):ComponentNode {
 const mobile=mode==="Touch",w=mobile?L.touch_action_width:240,h=mobile?L.touch_min_target:48;
 const b=figma.createComponent();b.name=`Mode=${mode}, State=${state}`;b.resize(w,h);
 b.layoutMode="HORIZONTAL";b.primaryAxisSizingMode="FIXED";b.counterAxisSizingMode="FIXED";b.primaryAxisAlignItems="CENTER";b.counterAxisAlignItems="CENTER";b.paddingLeft=12;b.paddingRight=12;
 b.cornerRadius=mobile?TT_TOKENS.radii.touch_button:TT_TOKENS.radii.button;
 const fill=state==="Hover"?C.teal:state==="Pressed"?C.button_pressed:state==="Selected"?C.selected:state==="Disabled"?C.disabled:mobile?C.cream:C.button_normal;
 b.fills=[paint(fill)];b.strokes=[paint(state==="Focus"?C.focus:C.teal)];b.strokeWeight=state==="Focus"?2:state==="Selected"?3:1;
 b.strokeAlign="INSIDE";if(state==="Normal"&& !mobile)b.strokes=[];
 const t=text(b,"Button",0,0,w-24,mobile?T.touch_body_min:T.desktop_body,["Hover","Pressed"].includes(state)?C.cream:C.ink);t.textAutoResize="WIDTH_AND_HEIGHT";t.name="Label";
 const prop=b.addComponentProperty("Label","TEXT","Button");t.componentPropertyReferences={characters:prop};
 b.setPluginData("tt.token_hash",TT_TOKEN_HASH);return b;
}
function instanceButton(parent:Parent,label:string,x:number,y:number,w:number,h:number,mobile:boolean,state="Normal",scale=1):InstanceNode {
 const n=buttonMasters[(mobile?"Touch":"Desktop")+state].createInstance();parent.appendChild(n);n.name=label;n.resize(w,h);n.x=x;n.y=y;
 const t=n.findOne(v=>v.type==="TEXT") as TextNode;t.characters=label;t.fontSize=(mobile?T.touch_body_min:T.desktop_body)*scale;return n;
}
function card(parent:Parent,kind:string,title:string,body:string,x:number,y:number,w:number,mobile:boolean,fontScale=1):InstanceNode {
 const n=cardMasters[kind].createInstance();parent.appendChild(n);n.name=kind+" / "+title;n.resize(w,n.height);n.x=x;n.y=y;
 for(const child of n.children){if(child.type!=="TEXT")continue;child.resize(w-40,child.height);child.fontSize=(mobile? (child.name==="Title"?(kind==="Objective"?T.touch_objective:T.touch_target_title):T.touch_body_min):(child.name==="Title"?(kind==="Objective"?T.desktop_objective:T.desktop_target_title):T.desktop_target_help))*fontScale;child.characters=child.name==="Title"?title:body;}
 return n;
}
async function link(from:InstanceNode,to:FrameNode,label:string):Promise<void>{
 await from.setReactionsAsync([{trigger:{type:"ON_CLICK"},actions:[{type:"NODE",destinationId:to.id,navigation:"NAVIGATE",transition:null}]}]);links.push({from:from.id,to:to.id,label});
}
function sceneProxy(parent:Parent,w:number,h:number):void {
 // Editable framing proxy. Native photographs are on the evidence board, not repainted as UI.
 rect(parent,"Table — schematic proxy",0,0,w,h,"#e9bf81");
 rect(parent,"Milk dish — schematic proxy",w*.27,h*.22,w*.49,h*.55,"#dbeae5",24);
 rect(parent,"Milk",w*.28,h*.24,w*.47,h*.51,"#edfbf7",16);
 const ring=figma.createEllipse();parent.appendChild(ring);ring.name="Cereal raft proxy";ring.resize(w*.16,h*.20);ring.x=w*.48;ring.y=h*.39;ring.fills=[paint("#cc964b")];
 rect(parent,"Wafer proxy",w*.5,h*.405,w*.12,h*.13,"#f0dfbf",6);
 const pip=figma.createEllipse();parent.appendChild(pip);pip.name="Pip framing proxy";pip.resize(h*.065,h*.10);pip.x=w*.515;pip.y=h*.34;pip.fills=[paint(C.cream)];
 rect(parent,"Parcel proxy",w*.575,h*.41,h*.055,h*.065,C.cream,4);rect(parent,"Flag proxy",w*.79,h*.44,5,h*.18,C.teal);rect(parent,"Flag",w*.79,h*.44,w*.035,h*.05,C.teal);
}
function studySource(parent:Parent,label:string,url:string,y:number,w:number):number {
 const source=text(parent,label,24,y,w,16,C.teal);
 source.setRangeHyperlink(0,source.characters.length,{type:"URL",value:url});
 return source.y+source.height+16;
}
function studyBoard(page:PageNode):void {
 const b=frame(page,"03 Official reference study / still-only observations",4300,0,1740,5400);
 b.setPluginData("tt.study",JSON.stringify(TT_STUDY));
 text(b,"Study qualities · preserve Tiny Trouble",32,28,1670,36);
 text(b,"OFFICIAL THIRD-PARTY STILLS · local reference study only. No reference art enters the game. Figma execution remains unverified; motion and audio were not assessed.",32,88,1660,24);
 let rowY=200,rowHeight=0;
 TT_STUDY.entries.forEach((entry,index)=>{
  const col=index%2;
  if(col===0&&index>0){rowY+=rowHeight+24;rowHeight=0;}
  const c=frame(b,entry.title,32+col*852,rowY,824,1000,"#f4ead6");c.cornerRadius=18;
  text(c,entry.title,24,20,776,25);
  image(c,entry.key,24,80,776,370);
  let yy=470;
  for(const value of ["Observed in this still: "+entry.observed,"Transfer: "+entry.transfer,"Limit: "+entry.limit]){
   const t=text(c,value,24,yy,776,21);yy=t.y+t.height+16;
  }
  yy=studySource(c,"Official source · "+entry.copyright_owner,entry.source_page,yy,776);
  text(c,"Unchanged image · SHA-256 "+entry.sha256.slice(0,16)+"…\nFull asset URL and hash are stored on this card.",24,yy,776,15);
  c.setPluginData("tt.provenance",JSON.stringify(entry));c.resize(824,yy+68);rowHeight=Math.max(rowHeight,c.height);
 });
 const note=TT_STUDY.catalog_note;
 const c=frame(b,"Stardew Valley / metadata, no audition",884,rowY,824,650,"#f4ead6");c.cornerRadius=18;
 text(c,note.title,24,20,776,25);
 rect(c,"No audio claim",24,80,776,175,C.selected,12);
 text(c,"CATALOG METADATA ONLY\nReference audio has not been auditioned.",48,114,728,29);
 let yy=286;for(const value of [note.observation,note.transfer,note.limit]){const t=text(c,value,24,yy,776,21);yy=t.y+t.height+20;}
 yy=studySource(c,"Composer catalog · ConcernedApe",note.source_page,yy,776);
 text(c,"Companion study: "+note.companion_doc,24,yy,776,16);c.resize(824,yy+64);rowHeight=Math.max(rowHeight,c.height);
 const comparisonY=rowY+rowHeight+42;
 text(b,"Tiny Trouble · actual frozen engine references",32,comparisonY,1660,32);
 image(b,"runtime_desktop",32,comparisonY+66,824,464);image(b,"runtime_phone",884,comparisonY+66,824,381);
 text(b,"DESKTOP 0.2.2 / Milk Harbor\nAmber raft and teal goal read. Pale deck, parcel, rim and milk need stronger grouping. Keep accepted contacts while testing material/value changes.",32,comparisonY+550,824,22);
 text(b,"SOURCE CANDIDATE 0.2.5 / Milk Harbor phone viewport · text1.25\nThe persistent target card shifts left, exposing Pip’s full body and feet at the far flag. This is a macOS simulation. Human motion comfort, proportions and cohesion remain pending.",884,comparisonY+475,824,22);
 const lastY=comparisonY+750;
 text(b,"Next gate: matching native views and complete action playback. The candidate phone still shows improved message placement; it cannot approve movement timing, audio warmth or emotional response. Keep the existing palette and Nunito identity.",32,lastY,1660,24);
 b.resize(1740,lastY+160);
}
function workshopBoard(page:PageNode):void {
 const b=frame(page,"04 Workshop / native package evidence",6200,0,1720,1550);
 b.setPluginData("tt.workshop_evidence",JSON.stringify(TT_WORKSHOP));
 text(b,"Matchbox Workshop · package 0.2.6",32,28,1656,36);
 text(b,"NATIVE MACOS VIEWPORT SIMULATION · text1.25 · unchanged PNGs. Exact executable/PCK provenance accompanies these engine stills; no Figma rendering or physical-device claim.",32,88,1656,24);
 image(b,"workshop_tablet_top",32,174,800,600);
 image(b,"workshop_phone_top",888,174,800,370);
 text(b,"TABLET 1024 × 768 · top scroll",32,792,800,22,C.teal);
 text(b,"PHONE 844 × 390 · top scroll",888,566,800,22,C.teal);
 text(b,"Both native top/bottom pairs are reviewed in the linked audit record. These two selected stills show the max-text hierarchy and Pip/menu separation.",888,624,800,24);
 text(b,"One scale application: body/actions24→30; authored heading base30→37. Top and bottom views expose the complete menu through scrolling. Pip remains outside the menu; the right drawer/workbench is partly covered.",32,846,1656,24);
 let y=1004;
 for(const value of TT_WORKSHOP.annotations){const n=text(b,value,32,y,1656,24);y=n.y+n.height+20;}
 const source=text(b,"Recorded Workshop source-file SHA-256: "+TT_WORKSHOP.captured_workshop_sha256+"\nCapture report: "+TT_WORKSHOP.capture_report.path,32,y,1656,18);
 y=source.y+source.height+24;
 text(b,"Figma execution remains unverified. Human normal-size proportions, cohesion, motion comfort and device use are pending. Existing Harbor, concept and official study references remain unchanged.",32,y,1656,24);
 b.resize(1720,y+160);
}
async function buildFlow(page:PageNode,v:View,y:number,fontScale=1):Promise<FrameNode>{
 const mobile=v.mode==="touch",s=mobile?Math.min(v.width/L.base_width,v.height/L.base_height):1;
 const w=v.width/s,h=v.height/s,ins=v.safe_insets.map(n=>n/s),safe={x:ins[0],y:ins[1],w:w-ins[0]-ins[2],h:h-ins[1]-ins[3]};
 const suffix=fontScale>1?" / text125":"";
 const menu=frame(page,v.id+suffix+" / Menu",0,y,w,h),play=frame(page,v.id+suffix+" / Play",v.width+80,y,w,h),pause=frame(page,v.id+suffix+" / Pause",2*(v.width+80),y,w,h);
 for(const f of [menu,play,pause]){sceneProxy(f,w,h);f.setPluginData("tt.viewport",JSON.stringify({view:v,scale:s,logical:[w,h],text_scale:fontScale,scope:"editable Figma framing mock; not engine capture"}));}
 const title=card(play,"Objective","Milk Harbor","Sail through the shallows.",safe.x+(mobile?24:28),safe.y+(mobile?16:24),mobile?L.touch_objective_width:330,mobile,fontScale);title.name="Objective";
 const targetCard=card(play,"Target","Cargo parcel","A smaller parcel lets the raft float higher.",mobile?safe.x+safe.w/2-250:28,mobile?safe.y+safe.h-260:h-210,mobile?500:380,mobile,fontScale);
 if(mobile)targetCard.y=safe.y+safe.h-120-targetCard.height;
 let pauseButton:InstanceNode;
 if(mobile){
  const endX=safe.x+safe.w,endY=safe.y+safe.h,mid=safe.x+safe.w/2;
  pauseButton=instanceButton(play,"Pause",endX-164,safe.y+16,140,88,true,"Normal",fontScale);
  instanceButton(play,"Hint",endX-328,safe.y+16,140,88,true,"Normal",fontScale);instanceButton(play,"Target",endX-164,safe.y+116,140,88,true,"Normal",fontScale);
  instanceButton(play,"Use",endX-212,endY-208,188,88,true,"Normal",fontScale);instanceButton(play,"Hop",endX-212,endY-108,188,88,true,"Normal",fontScale);
  ["Small","Normal","Large"].forEach((label,i)=>instanceButton(play,label,mid-207+i*142,endY-112,130,88,true,i===1?"Selected":"Normal",fontScale));
  const pad=figma.createEllipse();play.appendChild(pad);pad.name="Movement pad / radius88";pad.resize(176,176);pad.x=safe.x+34;pad.y=endY-208;pad.fills=[paint(C.cream)];pad.strokes=[paint(C.teal)];pad.strokeWeight=3;
  const knob=figma.createEllipse();play.appendChild(knob);knob.resize(68,68);knob.x=pad.x+54;knob.y=pad.y+54;knob.fills=[paint(C.teal)];
 }else{
  pauseButton=instanceButton(play,"Pause",w-148,26,120,44,false);
  ["1 Small","2 Normal","3 Large"].forEach((label,i)=>instanceButton(play,label,45+i*113,h-102,106,34,false,i===1?"Selected":"Normal"));
  text(play,"W/A/S/D Move     Space Hop     E Board / Sail     Tab Target     Q/F Resize     H Hint",200,h-30,w-400,T.desktop_footer);
 }
 const menuW=mobile?Math.min(L.touch_menu_max_width,safe.w-64):L.desktop_menu_width;
 const bx=safe.x+(safe.w-menuW)/2,by=safe.y+20;
 function menuPanel(target:FrameNode,heading:string):{panel:FrameNode;top:number;bw:number}{
  const dim=rect(target,"Pause scrim",0,0,w,h,"#213133");dim.opacity=.36;
  const scroll=frame(target,"Safe menu scroll region",safe.x+20,safe.y+20,safe.w-40,safe.h-40);scroll.fills=[];scroll.overflowDirection="VERTICAL";
  const panelHeight=mobile?620:440;
  const panel=frame(scroll,"Menu panel",bx-(safe.x+20),Math.max(0,(safe.h-40-panelHeight)/2),menuW,panelHeight);panel.cornerRadius=25;
  text(panel,"TINY TROUBLE",32,24,menuW-64,mobile?24:13,C.teal);
  const t=text(panel,heading,32,68,menuW-64,mobile?40*fontScale:42);return{panel,top:t.y+t.height+24,bw:menuW-64};
 }
 const m=menuPanel(menu,"Milk Harbor"),p=menuPanel(pause,"A little breather");
 const btnH=mobile?88:48,gap=12;
 const start=instanceButton(m.panel,"Take a little step →",32,m.top,m.bw,btnH,mobile,"Focus",fontScale);
 text(m.panel,"A cereal loop. A precious little parcel.",32,m.top+btnH+20,m.bw,mobile?24*fontScale:18);
 const resume=instanceButton(p.panel,"Back to Pip",32,p.top,p.bw,btnH,mobile,"Focus",fontScale);
 const returnTitle=instanceButton(p.panel,"Save & return to title",32,p.top+btnH+gap,p.bw,btnH,mobile,"Normal",fontScale);
 text(p.panel,"Reduced motion\nMusic   ━━━━━   Effects   ━━━━━\nText size   100% — 125%",32,p.top+2*(btnH+gap),p.bw,mobile?24*fontScale:18);
 await link(start,play,"Menu → Play");await link(pauseButton,pause,"Play → Pause");await link(resume,play,"Pause → Play");await link(returnTitle,menu,"Pause → Menu");
 for(const f of [menu,play,pause])f.rescale(s);
 text(page,`${v.id}${suffix}: ${v.width} × ${v.height}; ${mobile?"simulated safe insets "+v.safe_insets.join("/"):"desktop baseline"}. Editable framing mock, engine reference kept separately.`,0,y-40,3*(v.width+80),18);
 return menu;
}
async function main():Promise<void>{
 const available=await figma.listAvailableFontsAsync();const match=available.find(f=>f.fontName.family===T.family&&/semi.?bold|600/i.test(f.fontName.style));
 if(match)FONT=match.fontName;else{FONT={family:"Inter",style:"Medium"};}
 await figma.loadFontAsync(FONT);
 const page=figma.createPage();page.name="Tiny Trouble / TT-027 / "+TT_TOKEN_HASH.slice(0,8);await figma.setCurrentPageAsync(page);
 page.setPluginData("tt.tokens",JSON.stringify(TT_TOKENS));page.setPluginData("tt.token_hash",TT_TOKEN_HASH);
 page.setPluginData("tt.font_status",FONT.family===T.family?"Nunito semibold available":"Fallback Inter; font parity NOT verified");
 for (const key of ["desktop_body","desktop_objective","desktop_target_title","desktop_target_help","touch_body_min","touch_objective"] as const) { const style=figma.createTextStyle();style.name="Tiny Trouble/"+key;style.fontName=FONT;style.fontSize=T[key];style.lineHeight={unit:"PERCENT",value:140}; }
 const board=frame(page,"01 Art direction / concepts versus engine",0,0,1720,1510);
 text(board,"Tiny Trouble · a breakfast world you can touch",40,32,1600,40);
 text(board,"Warm cream, amber crumbs, coral thread and teal actions. Rounded toy shapes; quiet rough surfaces; readable silhouettes.",40,100,1600,24);
 let x=40;for(const[name,value]of Object.entries(C)){rect(board,name,x,162,156,65,value,10);text(board,name+"\n"+value,x,234,160,16);const style=figma.createPaintStyle();style.name="Tiny Trouble/"+name;style.paints=[paint(value)];x+=180;}
 text(board,`Type: ${T.family} ${T.weight}. Actual Figma font: ${FONT.family} / ${FONT.style}.`,40,314,1600,24);
 image(board,"concept_sheet",40,370,790,430);image(board,"concept_target",890,370,790,430);
 text(board,"GENERATED CONCEPT · aspirational art sheet",40,815,790,20,C.teal);text(board,"GENERATED CONCEPT · aspirational target",890,815,790,20,C.teal);
 image(board,"runtime_desktop",40,884,790,444);image(board,"runtime_phone",890,884,790,365);
 text(board,"ENGINE CAPTURE · packaged desktop 0.2.2",40,1340,790,20,C.teal);text(board,"ENGINE CAPTURE · source 0.2.5 phone simulation · text1.25",890,1270,790,20,C.teal);
 text(board,"Concepts describe direction; engine captures establish actual output. Physical iOS layout, Figma font rendering and full responsive parity require separate verification.",40,1410,1600,22);
 const compBoard=frame(page,"02 Reusable components",1800,0,1640,1510);text(compBoard,"Native UI vocabulary",32,24,1400,36);
 const all:ComponentNode[]=[];let row=0;
 for(const mode of ["Desktop","Touch"]){let col=0;for(const state of ["Normal","Hover","Pressed","Focus","Selected","Disabled"]){const b=baseButton(mode,state);compBoard.appendChild(b);b.x=32+col*262;b.y=100+row*180;buttonMasters[mode+state]=b;all.push(b);col++;}row++;}
 const set=figma.combineAsVariants(all,compBoard);set.name="Button";
 const cards:ComponentNode[]=[];
 for(const[kind,index]of ["Objective","Target","Toast"].map((v,i)=>[v,i] as const)){
  const width=kind==="Toast"?L.touch_toast_width:500;
  const c=figma.createComponent();compBoard.appendChild(c);c.name="Kind="+kind;c.x=32+index*530;c.y=550;c.resize(width,150);c.layoutMode="VERTICAL";c.primaryAxisSizingMode="AUTO";c.counterAxisSizingMode="FIXED";c.paddingTop=20;c.paddingBottom=20;c.paddingLeft=20;c.paddingRight=20;c.itemSpacing=6;c.fills=[paint(C.cream)];c.cornerRadius=18;
  if(kind==="Toast")c.minHeight=L.touch_toast_min_height;
  else{const title=text(c,kind,0,0,width-40,24);title.name="Title";}
  const body=text(c,"One clear next step for Pip.",0,0,width-40,24);body.name="Body";cardMasters[kind]=c;cards.push(c);
 }
 const cardSet=figma.combineAsVariants(cards,compBoard);cardSet.name="Card";
 text(compBoard,"Components use editable text and Auto Layout. Focus retains ink text; teal hover/pressed states use cream text. Selected is distinct from focused. Touch controls: ≥88 logical units; text24–30 at scale1–1.25. Toast: width480, minimum height90. Runtime places toasts around actor/action obstacles, shifts the persistent target card horizontally around Pip/controls, and refits shorter copy. Prototype frames do not simulate this movement; human motion review is pending.",32,830,1520,24);
 text(compBoard,"Prototype frames are logical-canvas reconstructions with an editable scene proxy, not claimed Figma exports or gameplay. Navigation links: Menu → Play → Pause → Resume / Title. Safe insets are design inputs, not measured device values.",32,1030,1520,24);
 studyBoard(page);
 workshopBoard(page);
 const starts:FrameNode[]=[];let y=1700;
 for(const v of TT_TOKENS.reference_viewports){starts.push(await buildFlow(page,v,y));y+=v.height+140;}
 const compact=TT_TOKENS.reference_viewports.find(v=>v.id==="phone_compact")!;starts.push(await buildFlow(page,compact,y,1.25));
 page.flowStartingPoints=starts.map(node=>({nodeId:node.id,name:node.name}));page.setPluginData("tt.prototype_links",JSON.stringify(links));
 figma.viewport.scrollAndZoomIntoView([board]);figma.currentPage.selection=[board];
 figma.closePlugin(`Created Tiny Trouble boards, 2 component sets and ${starts.length} navigation flows. ${FONT.family===T.family?"Nunito loaded.":"Inter fallback: verify Nunito before approval."}`);
}
main().catch(error=>{figma.closePlugin("Tiny Trouble import incomplete: "+String(error));});
