from pathlib import Path
import subprocess,json,hashlib
root=Path('/Users/xingzhaoji/Desktop/mine/tiny_trouble')
app=Path.home()/'Library/Application Support/TinyTrouble/SteamStaging/0.2.7-20260914/content/macos/Tiny Trouble.app'
engine=app/'Contents/MacOS/Tiny Trouble · Toast Express'
base=root/'evidence/platform_export/candidate_027';base.mkdir(exist_ok=False)
manifest=root/'builds/release-0.2.7-20260914/manifest.json';build=json.loads(manifest.read_text())
files={str(p.relative_to(app)):hashlib.sha256(p.read_bytes()).hexdigest() for p in app.rglob('*') if p.is_file() and p.name!='.DS_Store'}
assert files==build['macos']['bundle_files'];report={'manifest_sha256':hashlib.sha256(manifest.read_bytes()).hexdigest(),'source':build['source_sha256'],'executable':str(engine),'before':files,'tests':[],'ok':False}
runs=[('startup_desktop','tests/platform/test_workshop_startup.gd',[]),('startup_mobile','tests/platform/test_workshop_startup.gd',['--touch-ui']),('workshop_desktop','tests/chapter/test_workshop_capture.gd',[]),('workshop_mobile','tests/platform/test_workshop_mobile.gd',['--touch-ui']),('orientation','tests/platform/test_workshop_orientation.gd',['--touch-ui']),('adaptive','tests/platform/test_adaptive_ui.gd',['--touch-ui']),('settings','tests/test_settings.gd',[]),('lifecycle','tests/platform/test_lifecycle.gd',['--touch-ui']),('crumb_route','tests/chapter/replay_crumb.gd',[]),('ballast_route','tests/chapter/replay_ballast.gd',[]),('harbor_route','tests/chapter/replay_harbor.gd',[]),('demo_route','tests/replay_route.gd',[])]
for name,script,flags in runs:
    folder=base/name;folder.mkdir()
    with (folder/'engine.log').open('w') as log:
        try:
            result=subprocess.run([str(engine),'--path',str(root),'--resolution','1920x1080','--script',str(root/script),'--',f'--evidence-dir={folder}',*flags],cwd=root,stdout=log,stderr=subprocess.STDOUT,timeout=240)
            code=result.returncode
        except subprocess.TimeoutExpired: code=124
    content=(folder/'engine.log').read_text();ok=code==0 and 'ERROR:' not in content and 'FAIL' not in content
    report['tests'].append({'name':name,'ok':ok,'exit':code});print(json.dumps(report['tests'][-1]),flush=True)
    (base/'report.json').write_text(json.dumps(report,indent=2)+'\n')
    if not ok: raise SystemExit(1)
report['after']={str(p.relative_to(app)):hashlib.sha256(p.read_bytes()).hexdigest() for p in app.rglob('*') if p.is_file() and p.name!='.DS_Store'}
report['ok']=report['before']==report['after']
(base/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'ok':report['ok'],'runs':len(runs)}));raise SystemExit(0 if report['ok'] else 1)
