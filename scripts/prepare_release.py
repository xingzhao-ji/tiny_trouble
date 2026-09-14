#!/usr/bin/env python3
"""Produce versioned desktop previews and bind them to a clean runtime revision."""
from pathlib import Path
import argparse, hashlib, json, plistlib, re, shutil, subprocess, tempfile, zipfile
ROOT=Path(__file__).resolve().parent.parent
RUNTIME=['project.godot','export_presets.cfg','scripts','assets','scenes']

def digest(path):
    with path.open('rb') as stream: return hashlib.file_digest(stream,'sha256').hexdigest()

def inventory(folder):
    return {str(p.relative_to(folder)):digest(p) for p in sorted(folder.rglob('*')) if p.is_file() and p.name!='.DS_Store'}

def source():
    result={}
    for entry in RUNTIME:
        base=ROOT/entry
        for path in ([base] if base.is_file() else sorted(base.rglob('*'))):
            if not path.is_file() or '__pycache__' in path.parts or 'reference' in path.parts or path.name=='.DS_Store': continue
            result[str(path.relative_to(ROOT))]=digest(path)
    return dict(sorted(result.items()))

def run(command,log):
    with log.open('w') as stream:
        result=subprocess.run(command,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=600)
    content=log.read_text(errors='replace')
    if result.returncode or re.search(r'SCRIPT ERROR|Parse Error|^ERROR:',content,re.M): raise RuntimeError(f'Failed: {log}')

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--output',required=True,type=Path);args=parser.parse_args()
    output=args.output.resolve(); output.mkdir(parents=True,exist_ok=False)
    version=re.search(r'^config/version="([0-9.]+)"',(ROOT/'project.godot').read_text(),re.M).group(1)
    status=subprocess.check_output(['git','status','--porcelain','--',*RUNTIME],cwd=ROOT,text=True)
    if status: raise RuntimeError('Commit or preserve the runtime changes before exporting:\n'+status)
    before=source();sha=hashlib.sha256(json.dumps(before,sort_keys=True,separators=(',',':')).encode()).hexdigest()
    report={'version':version,'revision':subprocess.check_output(['git','rev-parse','HEAD'],cwd=ROOT,text=True).strip(),'source':before,'source_sha256':sha,'complete':False,'human_tests':0,'release_ready':False,'windows_execution':'unverified','macos_notarized':False}
    manifest=output/'manifest.json';manifest.write_text(json.dumps(report,indent=2)+'\n')
    run(['./scripts/build_macos.sh'],output/'build-macos.log')
    mac=output/f'Tiny-Trouble-{version}-macOS.zip';shutil.copy2(ROOT/'builds/Tiny-Trouble-macOS.zip',mac)
    shutil.copy2(ROOT/'builds/package-audit.json',output/'mac-package-audit.json')
    run(['./scripts/build_windows.sh',str(output/'windows')],output/'build-windows.log')
    win=output/'windows'/f'Tiny-Trouble-{version}-Windows-x64.zip'
    notice=json.loads((ROOT/'notices/manifest.json').read_text())['files']
    with tempfile.TemporaryDirectory(prefix='tiny-trouble-release-verify-') as tmp:
        tmp=Path(tmp);subprocess.run(['/usr/bin/ditto','-x','-k',str(mac),str(tmp)],check=True)
        app=tmp/'Tiny Trouble.app';subprocess.run(['/usr/bin/codesign','--verify','--deep','--strict',str(app)],check=True)
        info=plistlib.loads((app/'Contents/Info.plist').read_bytes());assert info['CFBundleShortVersionString']==version
        exe=app/'Contents/MacOS'/info['CFBundleExecutable'];subprocess.run(['/usr/bin/lipo',str(exe),'-verify_arch','arm64','x86_64'],check=True)
        for name,expected in notice.items(): assert digest(tmp/'Notices'/name)==expected,name
        report['macos']={'archive':mac.name,'sha256':digest(mac),'bytes':mac.stat().st_size,'app':'Tiny Trouble.app','executable':str(exe.relative_to(app)),'bundle_files':inventory(app),'signature':'verified ad-hoc; unnotarized','notices':notice}
    with zipfile.ZipFile(win) as archive:
        assert archive.testzip() is None
        for name,expected in notice.items(): assert hashlib.sha256(archive.read('TinyTrouble-Windows-x64/Notices/'+name)).hexdigest()==expected,name
    report['windows']={'archive':str(win.relative_to(output)),'sha256':digest(win),'bytes':win.stat().st_size,'files':inventory(output/'windows/TinyTrouble-Windows-x64'),'notices':notice}
    after=source();report['source_unchanged']=before==after
    if before!=after: raise RuntimeError('Source changed during export; candidate is not complete')
    report['complete']=True
    manifest.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps({'output':str(output),'version':version,'source':sha,'complete':True,'windows_execution':'unverified'}))

if __name__=='__main__': main()
