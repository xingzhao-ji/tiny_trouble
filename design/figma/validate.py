"""Offline schema, provenance and rectangle checks. Not a Figma renderer test."""
from pathlib import Path
import hashlib,json,math,re,struct
from image_info import dimensions
HERE=Path(__file__).resolve().parent
T=json.loads((HERE/'tokens.json').read_text());S=json.loads((HERE/'asset_snapshot.json').read_text())
checks=[]
def check(ok,what):
 checks.append({'check':what,'passed':bool(ok)})
 if not ok:raise AssertionError(what)
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
check(T['schema_version']==1,'Token contract version1')
for key,value in T['colors'].items():check(bool(re.fullmatch(r'#[0-9a-fA-F]{6}',value)),f'RGB token {key}')
for group in ['typography','radii','layout']:
 for key,value in T[group].items():
  if isinstance(value,(int,float)):check(math.isfinite(value) and value>0,f'Positive finite token {group}.{key}')
check(T['typography']['weight']==600 and T['typography']['family']=='Nunito','Unchanged Nunito600 identity')
check(T['typography']['touch_body_min']>=24,'Touch body minimum24 logical units')
check(T['layout']['touch_min_target']>=88,'Touch target minimum88 logical units')
check(sha(HERE/'tokens.json')==S['tokens_sha256'],'Bundled token hash matches contract')
for asset in S['assets']:
 p=HERE/asset['path'];b=p.read_bytes();check(sha(p)==asset['sha256'],'Unchanged asset bytes: '+asset['key']);check(list(struct.unpack('>II',b[16:24]))==asset['dimensions'],'PNG dimensions: '+asset['key'])
check(len(S['assets'])==4,'Two concept and two actual-engine references bundled')
check(all('concept' in a['label'].lower() for a in S['assets'][:2]),'Concepts explicitly separated from engine captures')
study=json.loads((HERE/'reference_study.json').read_text())
study_snapshot=json.loads((HERE/'reference_study_snapshot.json').read_text())
check(sha(HERE/'tokens.json')==study['tokens_sha256'],'Study references the current shared token contract')
check(sha(HERE/'asset_snapshot.json')==study['frozen_asset_snapshot_sha256'],'Study binds the intentional project reference snapshot')
check(T['layout']['touch_toast_width']==480 and T['layout']['touch_toast_min_height']==90,'Touch toast dimensions retain the verified runtime values')
check(study_snapshot['reference_study_sha256']==sha(HERE/'reference_study.json'),'Study annotations match their bundled snapshot')
check(study['stills_only'] and not study['reference_audio_auditioned'],'Study does not imply motion review or audio audition')
check(len(study['entries'])==7==len(study_snapshot['assets']),'Seven approved official study stills bundled')
for entry,asset in zip(study['entries'],study_snapshot['assets']):
 p=HERE/asset['path'];source=HERE.parents[1]/entry['source']
 check(entry['key']==asset['key'],'Study identity: '+entry['key'])
 check(sha(p)==entry['sha256']==sha(source),'Official still unchanged from study source: '+entry['key'])
 check(dimensions(p.read_bytes())==entry['dimensions'],'Official still dimensions: '+entry['key'])
 check(entry['source_page'].startswith('https://') and entry['asset_url'].startswith('https://'),'Exact primary links: '+entry['key'])
 check(all(entry.get(k) for k in ['copyright_owner','observed','transfer','limit']),'Distinct provenance, observation, transfer and limit: '+entry['key'])
L=T['layout'];layouts=[]
for v in T['reference_viewports']:
 w,h=v['width'],v['height'];s=min(w/L['base_width'],h/L['base_height']);lw,lh=w/s,h/s
 ins=[n/s for n in v['safe_insets']];x,y,sw,sh=ins[0],ins[1],lw-ins[0]-ins[2],lh-ins[1]-ins[3]
 check(sw>0 and sh>0,'Positive simulated safe rectangle: '+v['id'])
 if v['mode']!='touch':continue
 ex,ey,mid=x+sw,y+sh,x+sw/2
 boxes={'pause':[ex-164,y+16,140,88],'hint':[ex-328,y+16,140,88],'target':[ex-164,y+116,140,88],'use':[ex-212,ey-208,188,88],'hop':[ex-212,ey-108,188,88],'small':[mid-207,ey-112,130,88],'normal':[mid-65,ey-112,130,88],'large':[mid+77,ey-112,130,88],'joystick':[x+34,ey-208,176,176]}
 for name,(bx,by,bw,bh) in boxes.items():check(bx>=x and by>=y and bx+bw<=ex and by+bh<=ey,v['id']+' safe target: '+name)
 items=list(boxes.items())
 for i,(an,a) in enumerate(items):
  for bn,b in items[i+1:]:
   overlap=min(a[0]+a[2],b[0]+b[2])>max(a[0],b[0]) and min(a[1]+a[3],b[1]+b[3])>max(a[1],b[1])
   check(not overlap,v['id']+' controls separate: '+an+'/'+bn)
 layouts.append({'viewport':v['id'],'canvas_scale':s,'logical_extent':[lw,lh],'simulated_safe_rect':[x,y,sw,sh],'rendered_min_target_pixels':88*s,'target_rectangles':boxes})
manifest=json.loads((HERE/'manifest.template.json').read_text())
check(manifest['documentAccess']=='dynamic-page','Dynamic-page API manifest')
check(manifest['networkAccess']['allowedDomains']==['none'],'Runtime plugin performs no network access')
check(manifest['id']=='FIGMA_ASSIGNED_ID_REQUIRED','No invented Figma plugin identity')
check((HERE/manifest['main']).is_file(),'Compiled plugin exists')
report={'result':'PASS','checks':len(checks),'assertions':checks,'layouts':layouts,'tokens_sha256':S['tokens_sha256'],'compiled_sha256':sha(HERE/'code.js'),'study_sha256':sha(HERE/'reference_study.json'),'frozen_asset_snapshot_sha256':sha(HERE/'asset_snapshot.json'),'figma_execution':'UNVERIFIED — connection request interrupted; no file or assigned plugin ID confirmed','limits':'TypeScript/API-shape, syntax, JSON constraints, bundled unchanged PNG/JPEG bytes and control rectangle arithmetic only. No Figma import, text metrics, Auto Layout rendering, prototype clicks, iOS points, device support, motion review, audio audition or subjective visual quality claimed.'}
(HERE/'validation/local_report.json').write_text(json.dumps(report,indent=2)+'\n')
print('PASS',len(checks),'local checks; Figma execution remains UNVERIFIED')
