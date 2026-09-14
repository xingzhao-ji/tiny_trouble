#!/usr/bin/env python3
"""Include the pinned engine and font notices beside desktop runtime files."""
from pathlib import Path
import argparse, hashlib, json, shutil, zipfile
ROOT=Path(__file__).resolve().parent.parent

def main():
    parser=argparse.ArgumentParser(description=__doc__)
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--zip',type=Path); group.add_argument('--directory',type=Path)
    args=parser.parse_args()
    manifest=json.loads((ROOT/'notices/manifest.json').read_text())
    payload={}
    for name,expected in manifest['files'].items():
        data=(ROOT/'notices'/name).read_bytes()
        if hashlib.sha256(data).hexdigest()!=expected: raise SystemExit('Notice hash mismatch: '+name)
        payload['Notices/'+name]=data
    if args.zip:
        with zipfile.ZipFile(args.zip,'a',zipfile.ZIP_DEFLATED) as archive:
            if any(name in archive.namelist() for name in payload): raise SystemExit('Notices already included')
            for name,data in payload.items(): archive.writestr(name,data)
        with zipfile.ZipFile(args.zip) as archive:
            assert archive.testzip() is None
            assert all(archive.read(name)==data for name,data in payload.items())
    else:
        for name,data in payload.items():
            path=args.directory/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
    print(f'Included and verified {len(payload)} notice files.')

if __name__=='__main__': main()
