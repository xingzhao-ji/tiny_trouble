#!/bin/bash
# Cross-export an unsigned x64 package; this does not execute Windows code.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
python3 "$TASK_ROOT/scripts/sync_design_tokens.py" --check
python3 "$TASK_ROOT/scripts/audio_provenance.py" check > /dev/null
TASK_ENGINE="${TINY_TROUBLE_GODOT:-$TASK_ROOT/tools/Godot.app/Contents/MacOS/Godot}"
TASK_OUTPUT="${1:-$TASK_ROOT/builds/windows-0.2.5}"
TASK_ARCHIVE="$TASK_ROOT/tools/godot-export-templates-4.5.1.tpz"
TASK_SHA="8a65c73541184fbcf1a7afedb37c9c15ed0f3babdaafe36ff47ccc515548ac84bc7563ba5b94c253e6085b121ac608b7e03d35dfc0b2c8c690a646a8755b57e5"
if [ "$#" -gt 1 ]; then printf '%s\n' 'Usage: build_windows.sh [new-output-directory]'; exit 2; fi
if [ ! -x "$TASK_ENGINE" ] || [ ! -f "$TASK_ARCHIVE" ]; then
  printf '%s\n' 'The local Godot 4.5.1 editor and verified template archive are required. Nothing was downloaded.'; exit 2
fi
case "$("$TASK_ENGINE" --version)" in 4.5.1.stable*) ;; *) printf '%s\n' 'Godot 4.5.1 stable is required.'; exit 2 ;; esac
if [ -e "$TASK_OUTPUT" ]; then printf '%s\n' 'Output already exists; choose a new directory to preserve prior builds.'; exit 2; fi
printf '%s  %s\n' "$TASK_SHA" "$TASK_ARCHIVE" | shasum -a 512 -c -
mkdir -p "$TASK_OUTPUT"
TASK_OUTPUT="$(cd -- "$TASK_OUTPUT" && pwd)"
TASK_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/tiny-trouble-windows.XXXXXX")"
trap 'rm -rf "$TASK_STAGE"' EXIT

# Freeze only the runtime source and create a private import cache. The working
# project's preset, templates, .godot cache and preserved macOS app are untouched.
python3 - "$TASK_ROOT" "$TASK_STAGE" "$TASK_ARCHIVE" <<'PY'
from pathlib import Path
import json, shutil, sys, zipfile, hashlib
root, stage, archive = map(Path, sys.argv[1:])
project = stage / 'project'
project.mkdir()
for name in ('project.godot', 'export_presets.cfg'):
    shutil.copy2(root / name, project / name)
for name in ('assets', 'scenes', 'scripts'):
    shutil.copytree(root / name, project / name,
        ignore=shutil.ignore_patterns('reference', '__pycache__', '*.py', '*.sh', '*.md'))
templates = project / 'tools/export-templates/4.5.1.stable'
templates.mkdir(parents=True)
with zipfile.ZipFile(archive) as source:
    for name in ('windows_debug_x86_64.exe', 'windows_release_x86_64.exe'):
        (templates / name).write_bytes(source.read('templates/' + name))
source_files = {str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest()
    for p in project.rglob('*') if p.is_file() and 'tools' not in p.relative_to(project).parts}
(stage / 'source-manifest.json').write_text(json.dumps(source_files, indent=2) + '\n')
PY

run_checked() {
  local task_log="$1"; shift
  if ! "$@" > "$task_log" 2>&1; then cat "$task_log"; return 1; fi
  python3 - "$task_log" <<'PY'
from pathlib import Path
import re, sys
errors = [line for line in Path(sys.argv[1]).read_text(errors='replace').splitlines()
    if re.search(r'SCRIPT ERROR|Parse Error|^ERROR:', line)]
if errors:
    print('\n'.join(errors)); raise SystemExit(1)
PY
}
TASK_PROJECT="$TASK_STAGE/project"
mkdir -p "$TASK_STAGE/package"
run_checked "$TASK_OUTPUT/import.log" "$TASK_ENGINE" --headless --path "$TASK_PROJECT" --import
run_checked "$TASK_OUTPUT/resource-export.log" "$TASK_ENGINE" --headless --path "$TASK_PROJECT" \
  --export-pack 'Windows x64' "$TASK_STAGE/resources.zip"
run_checked "$TASK_OUTPUT/export.log" "$TASK_ENGINE" --headless --path "$TASK_PROJECT" \
  --export-release 'Windows x64' "$TASK_STAGE/package/TinyTrouble.exe"

# Inspect the actual PE header and every PCK entry, rather than treating a
# successful editor exit as proof that the selected runtime resources shipped.
python3 - "$TASK_STAGE" "$TASK_OUTPUT" <<'PY'
from pathlib import Path
import hashlib, json, re, shutil, struct, sys, zipfile
stage, out = map(Path, sys.argv[1:])
exe = (stage / 'package/TinyTrouble.exe').read_bytes()
assert exe[:2] == b'MZ', 'Missing PE DOS header'
pe = struct.unpack_from('<I', exe, 0x3c)[0]
assert exe[pe:pe+4] == b'PE\0\0', 'Missing PE signature'
assert struct.unpack_from('<H', exe, pe + 4)[0] == 0x8664, 'Expected x86-64 PE'
assert struct.unpack_from('<H', exe, pe + 24)[0] == 0x20b, 'Expected PE32+'
config = (stage / 'project/export_presets.cfg').read_text()
selection = config.split('[preset.1]')[1].split('[preset.1.options]')[0]
required = re.findall(r'"res://([^"\n]+)"', re.search(r'^export_files=.*$', selection, re.M)[0])
assert 'scripts/platform/touch_controls.gd' in required
with zipfile.ZipFile(stage / 'resources.zip') as archive:
    expected = sorted(archive.namelist())
for name in expected:
    assert not name.startswith(('design/', 'development/', 'tools/', 'tests/', 'evidence/', 'references/', 'assets/reference/', 'builds/')), name
    assert not name.endswith(('.py', '.sh', '.md')), name
    assert name != 'campaign_manifest.json', name
for name in required:
    assert any(p in expected for p in (name, name + '.remap', name + '.import')), name
assert 'assets/fonts/OFL.txt' in expected
pack = (stage / 'package/TinyTrouble.pck').read_bytes()
assert pack[:4] == b'GDPC' and struct.unpack_from('<I', pack, 4)[0] == 3
base, cursor = struct.unpack_from('<QQ', pack, 24)
count = struct.unpack_from('<I', pack, cursor)[0]
cursor += 4
actual = []
for _ in range(count):
    length = struct.unpack_from('<I', pack, cursor)[0]; cursor += 4
    name = pack[cursor:cursor+length].rstrip(b'\0').decode(); cursor += length
    offset, size = struct.unpack_from('<QQ', pack, cursor); cursor += 16
    digest = pack[cursor:cursor+16]; cursor += 16
    flags = struct.unpack_from('<I', pack, cursor)[0]; cursor += 4
    assert flags == 0 and base + offset + size <= len(pack), name
    assert hashlib.md5(pack[base+offset:base+offset+size]).digest() == digest, name
    actual.append(name.removeprefix('res://'))
assert sorted(actual) == expected, 'Actual executable PCK differs from audited selection'
package = out / 'TinyTrouble-Windows-x64'
shutil.copytree(stage / 'package', package)
(package / 'READ-ME.txt').write_text('Tiny Trouble 0.2.5 — Windows x64 candidate\n'
    'Extract the whole folder and keep TinyTrouble.exe beside TinyTrouble.pck.\n'
    'Unsigned local build. Windows execution and physical controller testing remain unverified.\n')
archive_path = out / 'Tiny-Trouble-0.2.5-Windows-x64.zip'
with zipfile.ZipFile(archive_path, 'w', zipfile.ZIP_DEFLATED) as archive:
    for item in sorted(package.rglob('*')):
        if item.is_file(): archive.write(item, item.relative_to(out))
hashes = {str(p.relative_to(out)): hashlib.sha256(p.read_bytes()).hexdigest()
    for p in sorted(package.rglob('*')) if p.is_file()}
hashes[archive_path.name] = hashlib.sha256(archive_path.read_bytes()).hexdigest()
(out / 'SHA256SUMS.txt').write_text(''.join(f'{digest}  {name}\n' for name, digest in hashes.items()))
shutil.copy2(stage / 'source-manifest.json', out / 'source-manifest.json')
(out / 'package-audit.json').write_text(json.dumps({
    'status': 'passed', 'version': '0.2.5', 'preset': 'Windows x64',
    'pe_architecture': 'x86_64 / PE32+', 'pck_version': 3, 'pck_file_count': count,
    'all_payload_md5_verified': True, 'required_resources': required,
    'actual_pck_files': sorted(actual), 'windows_execution': 'unverified',
    'signed': False, 'sha256': hashes}, indent=2) + '\n')
print(f'Windows package audit passed: PE32+ x64 and {count} verified PCK resources.')
PY
printf 'Exported %s\n' "$TASK_OUTPUT/Tiny-Trouble-0.2.5-Windows-x64.zip"
printf '%s\n' 'Windows execution remains a separate, unverified gate.'
