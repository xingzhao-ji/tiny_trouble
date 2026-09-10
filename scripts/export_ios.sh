#!/bin/bash
# Generate an unsigned Xcode project only. Never archive, sign or install it.
set -euo pipefail
TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
python3 "$TASK_ROOT/scripts/sync_design_tokens.py" --check
python3 "$TASK_ROOT/scripts/audio_provenance.py" check > /dev/null
TASK_ENGINE="${TINY_TROUBLE_GODOT:-$TASK_ROOT/tools/Godot.app/Contents/MacOS/Godot}"
TASK_ARCHIVE="$TASK_ROOT/tools/godot-export-templates-4.5.1.tpz"
TASK_SHA="8a65c73541184fbcf1a7afedb37c9c15ed0f3babdaafe36ff47ccc515548ac84bc7563ba5b94c253e6085b121ac608b7e03d35dfc0b2c8c690a646a8755b57e5"
TASK_CHECK=false
if [ "${1:-}" = '--check' ]; then TASK_CHECK=true; shift; fi
if [ "$#" -gt 1 ]; then printf '%s\n' 'Usage: export_ios.sh [--check] [new-output-directory]'; exit 2; fi
TASK_OUTPUT="${1:-$TASK_ROOT/builds/ios-0.2.6}"
if [ "$(uname -s)" != Darwin ]; then printf '%s\n' 'iOS project export requires macOS and Xcode.'; exit 2; fi
if [ ! -x "$TASK_ENGINE" ] || [ ! -f "$TASK_ARCHIVE" ]; then
  printf '%s\n' 'The local Godot 4.5.1 editor and verified template archive are required. Nothing was downloaded.'; exit 2
fi
case "$("$TASK_ENGINE" --version)" in 4.5.1.stable*) ;; *) printf '%s\n' 'Godot 4.5.1 stable is required.'; exit 2 ;; esac
xcodebuild -version
xcrun --sdk iphoneos --show-sdk-version
if [ -z "${TINY_TROUBLE_IOS_TEAM_ID:-}" ]; then
  printf '%s\n' 'Blocked: Godot 4.5.1 requires a real App Store Team ID even with application/export_project_only=true.' \
    'No Team ID is configured. Supply your actual 10-character ID as TINY_TROUBLE_IOS_TEAM_ID to generate an unsigned Xcode project.' \
    'No signing identity was queried, invented or configured. See docs/EXPORTING.md.'
  exit 2
fi
if ! [[ "$TINY_TROUBLE_IOS_TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
  printf '%s\n' 'TINY_TROUBLE_IOS_TEAM_ID must be your actual 10-character uppercase alphanumeric Team ID.'; exit 2
fi
if "$TASK_CHECK"; then
  printf '%s\n' 'Local prerequisites found and a Team ID was explicitly supplied (account membership not verified).' \
    'Project export, signing, installation and device execution have not run.'
  exit 0
fi
if [ -e "$TASK_OUTPUT" ]; then printf '%s\n' 'Output already exists; choose a new directory to preserve prior exports.'; exit 2; fi
printf '%s  %s\n' "$TASK_SHA" "$TASK_ARCHIVE" | shasum -a 512 -c -
mkdir -p "$TASK_OUTPUT"
TASK_OUTPUT="$(cd -- "$TASK_OUTPUT" && pwd)"
TASK_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/tiny-trouble-ios.XXXXXX")"
trap 'rm -rf "$TASK_STAGE"' EXIT
python3 - "$TASK_ROOT" "$TASK_STAGE" "$TASK_ARCHIVE" <<'PY'
from pathlib import Path
import hashlib, json, os, shutil, sys, zipfile
root, stage, archive = map(Path, sys.argv[1:])
project = stage / 'project'
project.mkdir()
shutil.copy2(root / 'project.godot', project / 'project.godot')
config = (root / 'export_presets.cfg').read_text()
prefix, options = config.split('[preset.2.options]', 1)
assert 'application/export_project_only=true' in options
assert 'application/app_store_team_id=""' in options
options = options.replace('application/app_store_team_id=""',
    'application/app_store_team_id="' + os.environ['TINY_TROUBLE_IOS_TEAM_ID'] + '"', 1)
(project / 'export_presets.cfg').write_text(prefix + '[preset.2.options]' + options)
for name in ('assets', 'scenes', 'scripts'):
    shutil.copytree(root / name, project / name,
        ignore=shutil.ignore_patterns('reference', '__pycache__', '*.py', '*.sh', '*.md'))
templates = project / 'tools/export-templates/4.5.1.stable'
templates.mkdir(parents=True)
with zipfile.ZipFile(archive) as source:
    (templates / 'ios.zip').write_bytes(source.read('templates/ios.zip'))
with zipfile.ZipFile(templates / 'ios.zip') as template:
    assert template.testzip() is None, 'iOS template ZIP is corrupt'
files = {str(p.relative_to(project)): hashlib.sha256(p.read_bytes()).hexdigest()
    for p in project.rglob('*') if p.is_file() and 'tools' not in p.relative_to(project).parts}
(stage / 'source-manifest.json').write_text(json.dumps(files, indent=2) + '\n')
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
mkdir -p "$TASK_STAGE/xcode"
run_checked "$TASK_OUTPUT/import.log" "$TASK_ENGINE" --headless --path "$TASK_STAGE/project" --import
# Godot uses the .ipa basename to name the project. Project-only returns before
# xcodebuild, so this command must create neither an IPA nor an XCArchive.
run_checked "$TASK_OUTPUT/export.log" "$TASK_ENGINE" --headless --path "$TASK_STAGE/project" \
  --export-release 'iOS Project' "$TASK_STAGE/xcode/TinyTrouble.ipa"
python3 - "$TASK_STAGE" "$TASK_OUTPUT" <<'PY'
from pathlib import Path
import hashlib, json, re, shutil, struct, sys
stage, out = map(Path, sys.argv[1:])
xcode = stage / 'xcode'
assert (xcode / 'TinyTrouble.xcodeproj/project.pbxproj').is_file(), 'Missing Xcode project'
assert not list(xcode.rglob('*.ipa')) and not list(xcode.rglob('*.xcarchive')), 'Project-only contract violated'
packs = list(xcode.rglob('*.pck'))
assert len(packs) == 1, 'Expected one runtime PCK'
data = packs[0].read_bytes()
assert data[:4] == b'GDPC' and struct.unpack_from('<I', data, 4)[0] == 3
base, cursor = struct.unpack_from('<QQ', data, 24)
count = struct.unpack_from('<I', data, cursor)[0]; cursor += 4
files = []
for _ in range(count):
    length = struct.unpack_from('<I', data, cursor)[0]; cursor += 4
    name = data[cursor:cursor+length].rstrip(b'\0').decode(); cursor += length
    offset, size = struct.unpack_from('<QQ', data, cursor); cursor += 16
    digest = data[cursor:cursor+16]; cursor += 16
    flags = struct.unpack_from('<I', data, cursor)[0]; cursor += 4
    assert flags == 0 and base + offset + size <= len(data), name
    assert hashlib.md5(data[base+offset:base+offset+size]).digest() == digest, name
    files.append(name.removeprefix('res://'))
selection = (stage / 'project/export_presets.cfg').read_text().split('[preset.2]')[1].split('[preset.2.options]')[0]
required = re.findall(r'"res://([^"\n]+)"', re.search(r'^export_files=.*$', selection, re.M)[0])
assert 'scripts/platform/touch_controls.gd' in required
for name in required:
    assert any(p in files for p in (name, name + '.remap', name + '.import')), name
assert 'assets/fonts/OFL.txt' in files
for name in files:
    assert not name.startswith(('design/', 'development/', 'tools/', 'tests/', 'evidence/', 'references/', 'assets/reference/', 'builds/')), name
    assert not name.endswith(('.py', '.sh', '.md')) and name != 'campaign_manifest.json', name
shutil.copytree(xcode, out / 'XcodeProject')
shutil.copy2(stage / 'source-manifest.json', out / 'source-manifest.json')
(out / 'package-audit.json').write_text(json.dumps({
    'status': 'passed', 'version': '0.2.6', 'preset': 'iOS Project',
    'project_only': True, 'signed_or_archived': False, 'team_id_source': 'explicit environment variable',
    'account_membership_verified': False, 'ios_execution': 'unverified',
    'pck_file_count': count, 'all_payload_md5_verified': True,
    'actual_pck_files': sorted(files), 'required_resources': required,
    'pck_sha256': hashlib.sha256(data).hexdigest()}, indent=2) + '\n')
print(f'Unsigned Xcode project audit passed: {count} verified PCK resources.')
PY
printf 'Generated %s\n' "$TASK_OUTPUT/XcodeProject/TinyTrouble.xcodeproj"
printf '%s\n' 'No archive, IPA, code signing, installation or device execution was performed.'
