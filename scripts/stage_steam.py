#!/usr/bin/env python3
"""Prepare verified local SteamPipe content and preview-only VDFs; never upload."""
from pathlib import Path
import argparse, hashlib, json, shutil, subprocess
ROOT=Path(__file__).resolve().parent.parent

def digest(path):
    with path.open('rb') as f: return hashlib.file_digest(f,'sha256').hexdigest()

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest',type=Path,required=True);parser.add_argument('--output',type=Path,required=True);parser.add_argument('--ids',type=Path)
    args=parser.parse_args();manifest=args.manifest.resolve();m=json.loads(manifest.read_text());assert m['complete'] and m['source_unchanged']
    ids=json.loads(args.ids.read_text()) if args.ids else {'app':None,'windows':None,'macos':None}
    if args.ids:
        assert all(type(ids.get(k)) is int and 0<ids[k]<2**32 for k in ['app','windows','macos'])
        assert len(set(ids.values()))==3
    out=args.output.resolve();out.mkdir(parents=True,exist_ok=False)
    win=out/'content/windows';mac=out/'content/macos';mac.mkdir(parents=True)
    for platform in ['windows','macos']:
        data=m[platform];assert digest(manifest.parent/data['archive'])==data['sha256']
    shutil.copytree(manifest.parent/'windows/TinyTrouble-Windows-x64',win)
    subprocess.run(['/usr/bin/ditto','-x','-k',str(manifest.parent/m['macos']['archive']),str(mac)],check=True)
    for name,expected in m['windows']['files'].items(): assert digest(win/name)==expected,name
    app=mac/m['macos']['app']
    for name,expected in m['macos']['bundle_files'].items(): assert digest(app/name)==expected,name
    for name,expected in m['macos']['notices'].items(): assert digest(mac/'Notices'/name)==expected,name
    subprocess.run(['/usr/bin/codesign','--verify','--deep','--strict',str(app)],check=True)
    # Restrict VDF values to strings with safely quoted paths; credentials never enter files.
    def q(value): return '"'+str(value).replace('\\','\\\\').replace('"','\\"')+'"'
    ext='.vdf' if args.ids else '.vdf.in'
    def number(key): return ids[key] or '<'+key.upper()+'_ID>'
    for platform in ['windows','macos']:
        text='"DepotBuildConfig"\n{\n  "DepotID" '+q(number(platform))+'\n  "ContentRoot" '+q(out/'content'/platform)+'\n  "FileMapping" { "LocalPath" "*" "DepotPath" "." "recursive" "1" }\n}\n'
        (out/f'depot_{platform}{ext}').write_text(text)
    text='"AppBuild"\n{\n  "AppID" '+q(number('app'))+'\n  "Desc" '+q('Tiny Trouble '+m['version']+' private preview')+'\n  "BuildOutput" '+q(out/'logs')+'\n  "Preview" "1"\n  "SetLive" ""\n  "Depots"\n  {\n'
    for platform in ['windows','macos']: text+='    '+q(number(platform))+' '+q(out/f'depot_{platform}{ext}')+'\n'
    (out/f'app_build{ext}').write_text(text+'  }\n}\n')
    (out/'steam-ids.example.json').write_text(json.dumps({'app':None,'windows':None,'macos':None},indent=2)+'\n')
    (out/'README.md').write_text('''# Offline SteamPipe staging

Verified content only. No upload, login, payment or store operation occurred. Preview is1 and SetLive is empty. Files ending `.in` contain placeholders; provide the real application and two depot IDs to generate preview VDFs in a new directory. Use a local volume outside Desktop to avoid FileProvider metadata on Mac app bundles.

Configure Windows launch as TinyTrouble.exe and macOS launch as Tiny Trouble.app in Steamworks, with their respective OS restrictions. The two depots supply those paths at the installation root. Keep accompanying Notices files. Minimum device requirements await physical testing. Mac is ad-hoc signed and unnotarized; Windows has not been executed on Windows. Human/store/build approval and account setup remain separate.

SteamPipe documentation: https://partner.steamgames.com/doc/sdk/uploading
Release review: https://partner.steamgames.com/doc/store/releasing
''')
    files={str(p.relative_to(out)):digest(p) for p in sorted(out.rglob('*')) if p.is_file() and p.name!='.DS_Store'}
    (out/'staging-manifest.json').write_text(json.dumps({'source_manifest':str(manifest),'source_manifest_sha256':digest(manifest),'source':m['source_sha256'],'version':m['version'],'files':files,'preview':True,'ids_configured':bool(args.ids),'uploaded':False},indent=2)+'\n')
    print(json.dumps({'output':str(out),'files':len(files),'verified':True,'ids_configured':bool(args.ids),'uploaded':False}))

if __name__=='__main__': main()
