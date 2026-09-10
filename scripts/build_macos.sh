#!/bin/bash
# Build an inspectable local macOS application from official Godot templates.
set -euo pipefail

TASK_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$TASK_ROOT"
python3 scripts/sync_design_tokens.py --check
python3 scripts/audio_provenance.py check > /dev/null

if [ "$(uname -s)" != Darwin ]; then
  printf '%s\n' 'This packaging script requires macOS (ditto and codesign).'
  exit 1
fi
if [ ! -f scripts/main.gd ]; then
  printf '%s\n' 'scripts/main.gd is not present yet; no build was produced.'
  exit 1
fi

TASK_ENGINE="${TINY_TROUBLE_GODOT:-$TASK_ROOT/tools/Godot.app/Contents/MacOS/Godot}"
if [ ! -x "$TASK_ENGINE" ]; then
  printf '%s\n' 'Install the pinned editor first: ./scripts/setup.sh'
  exit 1
fi
case "$("$TASK_ENGINE" --version)" in
  4.5.1.stable*) ;;
  *) printf '%s\n' 'Godot 4.5.1 stable is required for this export preset.'; exit 1 ;;
esac

TASK_TEMPLATE_DIR="$TASK_ROOT/tools/export-templates/4.5.1.stable"
TASK_ARCHIVE="$TASK_ROOT/tools/godot-export-templates-4.5.1.tpz"
TASK_TEMPLATE_SHA="8a65c73541184fbcf1a7afedb37c9c15ed0f3babdaafe36ff47ccc515548ac84bc7563ba5b94c253e6085b121ac608b7e03d35dfc0b2c8c690a646a8755b57e5"
if [ ! -f "$TASK_TEMPLATE_DIR/macos.zip" ]; then
  mkdir -p "$TASK_TEMPLATE_DIR"
  if [ ! -f "$TASK_ARCHIVE" ]; then
    curl --fail --location --retry 2 --output "$TASK_ARCHIVE.part" \
      'https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_export_templates.tpz'
    mv "$TASK_ARCHIVE.part" "$TASK_ARCHIVE"
  fi
  printf '%s  %s\n' "$TASK_TEMPLATE_SHA" "$TASK_ARCHIVE" | shasum -a 512 -c -
  unzip -p "$TASK_ARCHIVE" templates/macos.zip > "$TASK_TEMPLATE_DIR/macos.zip.part"
  unzip -tq "$TASK_TEMPLATE_DIR/macos.zip.part"
  mv "$TASK_TEMPLATE_DIR/macos.zip.part" "$TASK_TEMPLATE_DIR/macos.zip"
fi

mkdir -p "$TASK_ROOT/builds"
# Desktop may be managed by a FileProvider that immediately attaches Finder
# metadata to .app directories. Stage and verify on the local temporary volume.
TASK_STAGE="$(mktemp -d "${TMPDIR:-/tmp}/tiny-trouble-macos.XXXXXX")"
trap 'rm -rf "$TASK_STAGE"' EXIT

# Godot can log script errors while returning zero, so inspect output as well.
run_checked() {
  local task_log="$1"
  shift
  if ! "$@" > "$task_log" 2>&1; then
    cat "$task_log"
    return 1
  fi
  python3 - "$task_log" <<'PY'
from pathlib import Path
import re, sys
text = Path(sys.argv[1]).read_text(errors="replace")
errors = [line for line in text.splitlines() if re.search(r"SCRIPT ERROR|Parse Error|^ERROR:", line)]
if errors:
    print("\n".join(errors))
    raise SystemExit(1)
PY
}

run_checked "$TASK_ROOT/builds/import.log" "$TASK_ENGINE" --headless --path "$TASK_ROOT" --import
run_checked "$TASK_ROOT/builds/parse.log" "$TASK_ENGINE" --headless --path "$TASK_ROOT" --check-only --script res://scripts/main.gd
run_checked "$TASK_ROOT/builds/resource-export.log" "$TASK_ENGINE" --headless --path "$TASK_ROOT" \
  --export-pack macOS "$TASK_STAGE/resources.zip"

# Audit the same preset before retaining an application. Dynamic audio loads
# are explicit resources; development references and generators never ship.
python3 - "$TASK_STAGE/resources.zip" "$TASK_ROOT/builds/package-audit.json" <<'PY'
import json, sys, zipfile
from pathlib import Path
with zipfile.ZipFile(sys.argv[1]) as package:
    files = sorted(package.namelist())
for path in files:
    assert not path.startswith(("design/", "development/", "tools/", "tests/", "evidence/", "references/", "assets/reference/", "builds/")), path
    assert not path.endswith((".py", ".sh", ".md")), path
    assert path != "campaign_manifest.json", path
required = ["scenes/main.tscn", "scripts/main.gd", "scripts/art.gd", "scripts/hud.gd", "scripts/platform/touch_controls.gd", "scripts/platform/design_tokens.gd", "scripts/puzzle_state.gd", "assets/fonts/Nunito.ttf"]
required += ['scenes/chapter/milk_harbor.tscn', 'scripts/chapter/milk_harbor.gd', 'scripts/chapter/harbor_state.gd', 'scripts/chapter/harbor_art.gd']
required += ['scenes/chapter/blueberry_ballast.tscn', 'scripts/chapter/blueberry_ballast.gd', 'scripts/chapter/ballast_state.gd', 'scripts/chapter/ballast_art.gd', 'scripts/chapter/chapter_stage.gd']
required += ['scenes/chapter/crumb_crossing.tscn', 'scenes/chapter/workshop.tscn', 'scripts/chapter/crumb_crossing.gd', 'scripts/chapter/crumb_state.gd', 'scripts/chapter/chapter_art.gd', 'scripts/chapter/chapter_progress.gd', 'scripts/chapter/chapter_navigation.gd', 'scripts/chapter/workshop.gd']
required += [f"assets/audio/{name}.wav" for name in ("resize_up", "resize_down", "pickup", "place", "reject", "checkpoint", "jump", "land", "launch", "complete", "discovery", "music")]
for resource in required:
    assert any(path in (resource, resource + ".remap", resource + ".import") for path in files), resource
assert "assets/fonts/OFL.txt" in files
assert any(path in ("assets/audio/music.ogg", "assets/audio/music.ogg.remap", "assets/audio/music.ogg.import") for path in files), "music.ogg"
Path(sys.argv[2]).write_text(json.dumps({"status": "passed", "preset": "macOS", "required_resources": required,
    "excluded": ["tools", "references", "evidence", "docs", "tests", "generation scripts"], "files": files}, indent=2) + "\n")
print(f"Package audit passed: {len(files)} runtime files, all required resources present.")
PY

run_checked "$TASK_ROOT/builds/export.log" "$TASK_ENGINE" --headless --path "$TASK_ROOT" \
  --export-release macOS "$TASK_STAGE/Tiny Trouble.app"

TASK_APP="$TASK_STAGE/Tiny Trouble.app"
python3 - "$TASK_APP" "$TASK_ROOT/builds/package-audit.json" <<'PY'
from pathlib import Path
import hashlib, json, struct, sys
pack = next((Path(sys.argv[1]) / "Contents/Resources").glob("*.pck"))
data = pack.read_bytes()
assert data[:4] == b"GDPC" and struct.unpack_from("<I", data, 4)[0] == 3
base = struct.unpack_from("<Q", data, 24)[0]
position = struct.unpack_from("<Q", data, 32)[0]
count = struct.unpack_from("<I", data, position)[0]
position += 4
files = []
for _ in range(count):
    length = struct.unpack_from("<I", data, position)[0]
    position += 4
    name = data[position:position + length].rstrip(b"\0").decode()
    position += length
    offset, size = struct.unpack_from("<QQ", data, position)
    position += 16
    digest = data[position:position + 16]
    position += 16
    flags = struct.unpack_from("<I", data, position)[0]
    position += 4
    assert flags == 0, name
    assert hashlib.md5(data[base + offset:base + offset + size]).digest() == digest, name
    files.append(name.removeprefix("res://"))
audit_path = Path(sys.argv[2])
audit = json.loads(audit_path.read_text())
assert sorted(files) == sorted(audit["files"])
audit["actual_pck_status"] = "passed: native application payload matches audited resource list; every payload MD5 verifies"
audit["actual_pck_file_count"] = count
audit_path.write_text(json.dumps(audit, indent=2) + "\n")
print(f"Native PCK audit passed: {count} files and payload digests verified.")
PY
# Strip incidental metadata from this newly generated application only. This
# bundle is our local export; no downloaded app or existing user file is altered.
/usr/bin/xattr -cr "$TASK_APP"
codesign --verify --deep --strict "$TASK_APP"
TASK_EXECUTABLE="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$TASK_APP/Contents/Info.plist")"
test -x "$TASK_APP/Contents/MacOS/$TASK_EXECUTABLE"
test "$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$TASK_APP/Contents/Info.plist")" = games.tinytrouble.toast
lipo "$TASK_APP/Contents/MacOS/$TASK_EXECUTABLE" -verify_arch arm64 x86_64
ditto -c -k --sequesterRsrc --keepParent "$TASK_APP" "$TASK_STAGE/Tiny-Trouble-macOS.zip"

# Keep the previous local build until a new export has passed structural checks.
if [ -d "$TASK_ROOT/builds/Tiny Trouble.app" ]; then
  rm -rf "$TASK_ROOT/builds/Tiny Trouble.previous.app"
  mv "$TASK_ROOT/builds/Tiny Trouble.app" "$TASK_ROOT/builds/Tiny Trouble.previous.app"
fi
mv "$TASK_APP" "$TASK_ROOT/builds/Tiny Trouble.app"
mv "$TASK_STAGE/Tiny-Trouble-macOS.zip" "$TASK_ROOT/builds/Tiny-Trouble-macOS.zip"
shasum -a 256 "$TASK_ROOT/builds/Tiny-Trouble-macOS.zip" > "$TASK_ROOT/builds/SHA256SUMS.txt"
printf '%s\n' 'Exported builds/Tiny Trouble.app and builds/Tiny-Trouble-macOS.zip.' \
  'Parse, resource selection, universal architecture and pre-archive signature checks passed.' \
  'An interactive playthrough remains a separate quality gate. No public publishing was performed.'
