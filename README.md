# Tiny Trouble · Toast Express

A solo 3D puzzle adventure on a tiny breakfast table. The original Toast Express demo and the first campaign stage, Crumb Crossing, are playable. Choose **Visit Matchbox Workshop** on the title screen to enter the chapter preview.

**M2 Breakfast Chapter is active: one of sixty campaign stages is implemented, plus a minimal 3D Matchbox Workshop.** Crumb Crossing asks Pip to shrink a blocking sugar cube, carry a small spoon through a cup handle, then enlarge it into a bridge. Local checkpoints, optional crumb greetings, pinwheel reactions, chapter saves and replay are implemented. Blueberry Ballast, Milk Harbor, The Jam Detour and Toast Express remain disabled in the hub until their distinct stages are built; all 59 remaining campaign stages are planned in `campaign_manifest.json`.

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

The local **0.2.0** app contains universal Apple Silicon/Intel binaries and uses the identifier `games.tinytrouble.toast`. It is signed ad hoc for local testing, without Apple notarization or public distribution. Its [package audit](builds/package-audit.json) verifies 63 PCK resources and their digests, including the original demo, Crumb Crossing and workshop. Development tools, concept references, evidence, tests and generation sources remain in the editable project. The script retains the previous `.app` after a successful replacement; the accepted VS01 ZIP is preserved separately.

The bundle signature is verified before ZIP creation in a clean local temporary directory. This machine's Desktop FileProvider adds Finder metadata to `.app` folders placed on Desktop, which can affect a later strict signature check there. The ZIP preserves the verified bundle; use a folder outside the synced Desktop when independently checking its signature.

The workflow follows Godot's [macOS export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_macos.html) and [command-line documentation](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html). It performs structural build checks; an exported app is not proof of a completed gameplay or visual gate.

## Source and verification

`scripts/art.gd` builds editable toy geometry. `python3 scripts/generate_audio.py` reproduces the original WAVs and technical report; `./scripts/transcode_music.sh` derives the runtime music.ogg. Nunito's OFL license is preserved in `assets/fonts/OFL.txt`. Concept art in `assets/reference/` is a target, not an engine screenshot.

Run all nine headless regression suites from the project directory:

```sh
./scripts/check.sh
```

The retained M1 suites pass **2,452 regular assertions** and 15,262 conservative flight-clearance checks. The chapter adds **1,469 assertions**: 881 Crumb Crossing rules, 365 chapter-profile checks and 223 scene recovery/navigation checks. The native art studio passes 21 checks; [workshop review](evidence/workshop/README.md) passes 201 checks and reviews six captures at 1280×720 and 1920×1080, including maximum text size. `check.sh` runs the six M1 and three chapter suites, saves their logs under `evidence/`, and requires `rg` (ripgrep).

The [Crumb Crossing source route](evidence/crumb_crossing/replay_report.json) passes all 10 ordinary-input checks without teleports or puzzle-state writes. Reproduce its route or the workshop captures with:

```sh
./run.command --script res://tests/chapter/replay_crumb.gd
./run.command --script res://tests/chapter/test_workshop_capture.gd
```

The [packaged Crumb Crossing route](evidence/crumb_export/replay_report.json) also passes all 10 checks with a clean exit. The actual packaged app passes all [223 scene recovery/navigation checks](evidence/crumb_export/scene_checks.log), including the demo/hub/stage button flow and isolated save/settings paths. The [first-stage visual review](evidence/crumb_crossing/VISUAL_REVIEW.md) records eight source views and their limits; final packaged title/completion frames close both stale-caption issues. W01S01’s available bounded gates are verified; M2 remains active, with W01S02 Blueberry Ballast next.

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
