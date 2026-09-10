# Tiny Trouble · Toast Express

A solo 3D puzzle adventure on a tiny breakfast table. Help Pip shrink a spoon into a portable tool, grow it into a bridge, latch a cereal ramp, and prepare a toast flight to a soft napkin landing.

This is the **playable VS01 native demo, accepted through its available M1 technical gates**. Three connected puzzles, an optional picnic, the toast finale, replay and recovery are implemented and recorded. [M1 acceptance](evidence/M1_ACCEPTANCE.md) records the evidence and remaining human/device reviews. The next frontier is M2, beginning with W01S01 Crumb Crossing. All sixty main campaign stages and the Matchbox Workshop remain unimplemented plans in `campaign_manifest.json`.

## Run from source

On macOS, double-click `run.command`, or run these commands in the project folder:

```sh
./scripts/setup.sh
./run.command
```

Setup downloads the pinned official Godot **4.5.1** editor if needed and imports the project. It requires an internet connection for the initial download; gameplay runs locally. The launcher resolves its own directory, so its absolute path also works from any current directory. Open `project.godot` in Godot to edit the source scene, procedural models and game code.

## Controls

| Input | Action |
| --- | --- |
| WASD or arrow keys | Move |
| Space | Jump |
| E | Carry / place / interact |
| Tab | Cycle target |
| 1 / 2 / 3 | Small / normal / large |
| Q / F | Shrink / enlarge one state |
| H | Next hint |
| R | Restore local checkpoint |
| Esc | Pause / settings |

These are the default bindings. Pause settings provide separate music and effects levels, reduced motion, text size and keyboard remapping. The footer, prompts and hints follow changed bindings; 1/2/3 remain fixed size shortcuts. Keyboard/mouse is the tested input path. Gamepad controls are mapped, but physical controller hardware and human control-feel review remain unverified.

Progress uses Godot's `user://` storage under the application name. On macOS this is `~/Library/Application Support/Godot/app_userdata/Tiny Trouble · Toast Express/`. `toast_express_v1.json` holds progress and `settings.cfg` holds preferences. Save state belongs to the user data directory, separate from the source and exported application. Local reset restores the current puzzle checkpoint.

## Build a standalone Mac app

```sh
./scripts/build_macos.sh
```

The script requires Python 3 for its resource audit. It downloads official Godot 4.5.1 export templates when needed (the initial archive is approximately 1.35 GB), checks the pinned SHA-512 checksum, imports and parses the project, audits selected runtime resources, and exports:

- `builds/Tiny Trouble.app`
- `builds/Tiny-Trouble-macOS.zip`

The local app contains universal Apple Silicon/Intel binaries and uses the identifier `games.tinytrouble.toast`. It is signed ad hoc for local testing, without Apple notarization or public distribution. Build logs and the resource audit stay in `builds/`. Exported packages include the runtime scene, scripts, audio and Nunito font; development tools, concept references, evidence, tests and generation sources remain in the editable project. The script retains the previous `.app` after a successful replacement.

The bundle signature is verified before ZIP creation in a clean local temporary directory. This machine's Desktop FileProvider adds Finder metadata to `.app` folders placed on Desktop, which can affect a later strict signature check there. The ZIP preserves the verified bundle; use a folder outside the synced Desktop when independently checking its signature.

The workflow follows Godot's [macOS export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_macos.html) and [command-line documentation](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html). It performs structural build checks; an exported app is not proof of a completed gameplay or visual gate.

## Source and verification

`scripts/art.gd` builds editable toy geometry. `python3 scripts/generate_audio.py` reproduces the original WAVs and technical report; `./scripts/transcode_music.sh` derives the runtime music.ogg. Nunito's OFL license is preserved in `assets/fonts/OFL.txt`. Concept art in `assets/reference/` is a target, not an engine screenshot.

Run all headless regression suites from the project directory:

```sh
./scripts/check.sh
```

The complete regression run passes **2,452 regular assertions** with clean logs: 2,091 rules, 38 persistence, 62 scene safety, 170 scene recovery and 91 settings checks. A separate conservative flight-clearance suite passes 15,262 checks. `check.sh` saves logs under `evidence/` and requires `rg` (ripgrep).

Both the [final native replay](evidence/final_1280/replay_report.json) and [60 FPS capped replay](evidence/capped_1280/replay_report.json) pass all 15 route checks. The [visual review](evidence/VISUAL_REVIEW.md) closes the occupied-marker, focused-text and cinematic-prompt defects in the nine final frames. To replay the exported package with isolated test progress and settings:

```sh
"./builds/Tiny Trouble.app/Contents/MacOS/Tiny Trouble · Toast Express" \
  --path . --resolution 1280x720 \
  --script "$PWD/tests/replay_export.gd" -- \
  --evidence-dir="$PWD/evidence/export_1280"
```

Record the route and encode an MP4 with:

```sh
./scripts/record_route.sh
```

The [recorded playthrough](evidence/Toast-Express-playthrough.mp4) passes all 15 route checks and fully decodes without errors: 36.9 seconds, 2,214 H.264 frames at 60 FPS, 1280×720, with 48 kHz stereo AAC. [Recording verification](evidence/recording/verification.json) preserves the inspection and digest. This fast automated solution does not measure first-play duration. Recording and music transcoding require ffmpeg; movie-mode timings measure capture throughput. Replays use ordinary input without teleporting Pip or writing puzzle state. Their harnesses are excluded from the packaged app.

The [capture-free 1920×1080 native run](evidence/performance_1080/replay_report.json) on Apple M4 Pro passes all 15 route checks. Its 2,025 frame samples measure p50/p95/p99 **16.675/17.577/19.908ms**; all 34 once-per-second FPS samples report 60. The default cap is 60 FPS with VSync enabled; peaks are 524 draw calls and 766 objects. The window remained unfocused despite requesting activation, so foreground hands-on feel remains unverified. Earlier capped 1280×720 timings include PNG capture stalls; the uncapped run used different pacing. These conditions limit comparisons and support no every-frame 16.67ms or other-hardware guarantee.

See `PROJECT_STATE.md` for current launch/build status and next tasks, `QUALITY_REPORT.md` for actual checks and limitations, and `BACKLOG.md` for requirement mapping. Human enjoyment, first-play duration, untested devices and unmeasured performance remain unverified until recorded evidence supports them.
