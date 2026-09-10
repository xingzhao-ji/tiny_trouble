# Tiny Trouble · Toast Express

A solo 3D puzzle adventure on a tiny breakfast table. The original Toast Express demo and two campaign stages, Crumb Crossing and Blueberry Ballast, are playable from source. Choose **Visit the Matchbox Workshop** on the title screen to enter the chapter preview.

**M2 Breakfast Chapter is active: two of sixty campaign stages are implemented in source, plus a minimal 3D Matchbox Workshop.** Crumb Crossing opens a sugar passage and turns a small carried spoon into a bridge. Blueberry Ballast rolls two enlarged berries onto a cereal flap, then lets the player shrink either berry to align a counterbalanced ramp. Its corrected final package passes the available technical gates, including reviewed route and encoded frames. Blueberry Ballast unlocks after Crumb Crossing; Milk Harbor, The Jam Detour and Toast Express remain unavailable. The other 58 campaign stages remain planned in `campaign_manifest.json`.

The original VS01 demo retains its three connected puzzles, optional picnic and recorded toast finale. Its [M1 technical acceptance](evidence/M1_ACCEPTANCE.md) is preserved at commit `fd5a1cc`, tag `vs01-technical-1`, and `builds/VS01-verified-macOS.zip`. This is a chapter preview, not a completed campaign.

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

Progress uses Godot's `user://` storage under the application name. On macOS this is `~/Library/Application Support/Godot/app_userdata/Tiny Trouble · Toast Express/`. `toast_express_v1.json` holds demo progress; `breakfast_chapter_v1.json` separately holds chapter snapshots and earned completions; `settings.cfg` holds shared preferences. Atomic chapter completion saves the earned clear and completed snapshot together. Backups recover valid saves, and local reset preserves earned completion. Sequential profile unlocks never make an unbuilt stage playable.

## Build a standalone Mac app

```sh
./scripts/build_macos.sh
```

The script requires Python 3 for its resource audit. It downloads official Godot 4.5.1 export templates when needed (the initial archive is approximately 1.35 GB), checks the pinned SHA-512 checksum, imports and parses the project, audits selected runtime resources, and exports:

- `builds/Tiny Trouble.app`
- `builds/Tiny-Trouble-macOS.zip`

The local **0.2.1** app contains universal Apple Silicon/Intel binaries and uses the identifier `games.tinytrouble.toast`. Its [package audit](builds/package-audit.json) verifies 73 PCK resources and digests, including both campaign stages, the original demo and workshop; universal architecture and ad hoc signature checks pass. It is for local testing, without Apple notarization or public distribution. Development tools, concepts, evidence, tests and generation sources stay in the editable project. The accepted VS01/W01S01 ZIPs remain separate; the current package is preserved as `builds/W01S02-verified-macOS.zip`.

The bundle signature is verified before ZIP creation in a clean local temporary directory. This machine's Desktop FileProvider adds Finder metadata to `.app` folders placed on Desktop, which can affect a later strict signature check there. The ZIP preserves the verified bundle; use a folder outside the synced Desktop when independently checking its signature.

The workflow follows Godot's [macOS export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_macos.html) and [command-line documentation](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html). It performs structural build checks; an exported app is not proof of a completed gameplay or visual gate.

## Source and verification

`scripts/art.gd` builds editable toy geometry. `python3 scripts/generate_audio.py` reproduces the original WAVs and technical report; `./scripts/transcode_music.sh` derives the runtime music.ogg. Nunito's OFL license is preserved in `assets/fonts/OFL.txt`. Concept art in `assets/reference/` is a target, not an engine screenshot.

Run all eleven headless regression suites from the project directory:

```sh
./scripts/check.sh
```

The retained M1 suites pass **2,452 regular assertions** and 15,262 conservative flight-clearance checks; the 91 settings checks were rerun after the footer change. Current Crumb Crossing/profile/scene coverage is **1,505 assertions** (917 + 365 + 223). Blueberry Ballast adds **3,201 pure-state checks and 82 actual scene checks**. The scene contact test measures zero maximum foot penetration against an actual 0.02-scene-unit limit; this is bounded contact evidence. All eleven suites total **7,240 regular assertions plus 15,262 swept checks**. `check.sh` saves logs under `evidence/` and requires `rg` (ripgrep).

The [main Blueberry Ballast source route](evidence/ballast_1920/replay_report.json) and [alternate far-berry solution](evidence/ballast_alternate/replay_report.json) each pass 10 ordinary-input checks. The alternate captures precede the final foot-pose correction and must not be used as evidence for that fix. Native mechanism art passes 28 checks. The [updated workshop](evidence/workshop_ballast/README.md) passes 247 native checks with six reviewed captures, including maximum text size and actual stage → hub → demo → hub → stage button navigation. Reproduce source routes or workshop captures with:

```sh
./run.command --script res://tests/chapter/replay_crumb.gd
./run.command --script res://tests/chapter/replay_ballast.gd
./run.command --script res://tests/chapter/test_workshop_capture.gd
```

The corrected [packaged Blueberry Ballast route](evidence/ballast_export/replay_report.json) passes 10 checks with nine captures, including ramp entry. Its [actual packaged scene suite](evidence/ballast_export/scene_checks.log) passes 82 checks with zero measured foot penetration, and its [packaged workshop run](evidence/workshop_ballast_export/capture_report.json) passes 247 checks with six native frames. All nine final packaged route views and four encoded MP4 samples are reviewed; entry-foot, ramp-lip and copy findings are closed. [W01S02 acceptance](evidence/W01S02_ACCEPTANCE.md) records the bounded technical gate. W01S03 Milk Harbor is next; M2 stays incomplete.

The [capture-free packaged 1920×1080 run](evidence/ballast_performance/replay_report.json) passes 10 route checks on Apple M4 Pro: 972 frame intervals measure p50/p95/p99 **16.651/18.327/18.671ms**, with peaks of 336 draws and 585 objects. The default cap is 60 with VSync, and the FPS monitor's p50/p95/max are 60. All 17 focus samples are false. PNG stalls are excluded, ordinary I/O remains, and these conditions establish no every-frame 16.67ms or other-hardware guarantee.

The [Blueberry Ballast MP4](evidence/Blueberry-Ballast-playthrough.mp4) passes the actual packaged movie route's 10 checks and fully decodes without errors: **19.083333 seconds, 1,145 H.264 frames at 60 FPS, 1280×720, 48 kHz stereo AAC**. [Verification](evidence/ballast_recording/verification.json) records its digest. Reproduce with `./scripts/record_ballast.sh`. This fast automated solution is not first-play duration, and movie cadence is not real-time performance.

The preserved [W01S01 package route](evidence/crumb_export/replay_report.json) passes 10 checks and its [packaged scene suite](evidence/crumb_export/scene_checks.log) passes 223. Commit `4568ced`, tag `w01s01-technical-1`, and `builds/W01S01-verified-macOS.zip` retain its historical 881-rule / 1,469-assertion chapter checkpoint. Patch `b118d82` subsequently fixes malformed stage-field types, bringing Crumb rules to 917; historical results are not rewritten as new tests.

For the preserved VS01 checkpoint, both the [final native replay](evidence/final_1280/replay_report.json) and [60 FPS capped replay](evidence/capped_1280/replay_report.json) pass all 15 route checks. Its [visual review](evidence/VISUAL_REVIEW.md) closes the occupied-marker, focused-text and cinematic-prompt defects. To replay the original demo in the exported package with isolated test progress and settings:

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
