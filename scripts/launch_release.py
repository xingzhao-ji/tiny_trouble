#!/usr/bin/env python3
"""Verify and open the explicitly selected local Mac preview."""
from pathlib import Path
import argparse, hashlib, json, subprocess, sys
ROOT=Path(__file__).resolve().parent.parent

def digest(path):
    with path.open('rb') as stream: return hashlib.file_digest(stream,'sha256').hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--verify-only',action='store_true');args=parser.parse_args()
    if sys.platform!='darwin': raise SystemExit('Use the complete Windows ZIP on Windows.')
    selected=json.loads((ROOT/'builds/current-release.json').read_text())
    manifest_path=(ROOT/selected['manifest']).resolve();assert manifest_path.is_relative_to(ROOT/'builds')
    manifest=json.loads(manifest_path.read_text());assert manifest['complete'] and manifest['source_unchanged'] and manifest['source_sha256']==selected['source']
    mac=manifest['macos'];archive=manifest_path.parent/mac['archive'];assert digest(archive)==mac['sha256']
    cache=Path.home()/'Library/Application Support/TinyTrouble/Builds'/mac['sha256'];cache.mkdir(parents=True,exist_ok=True)
    app=cache/mac['app']
    if not app.exists(): subprocess.run(['/usr/bin/ditto','-x','-k',str(archive),str(cache)],check=True)
    for name,expected in mac['bundle_files'].items(): assert digest(app/name)==expected,name
    for name,expected in mac['notices'].items(): assert digest(cache/'Notices'/name)==expected,name
    subprocess.run(['/usr/bin/codesign','--verify','--deep','--strict',str(app)],check=True)
    if args.verify_only: print(json.dumps({'verified':True,'version':manifest['version'],'app':str(app),'source':manifest['source_sha256']}))
    else: subprocess.run(['/usr/bin/open',str(app)],check=True)

if __name__=='__main__': main()
