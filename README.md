# Tiny Trouble · Toast Express

A solo 3D puzzle adventure on a tiny breakfast table. The original Toast Express demo and Crumb Crossing, Blueberry Ballast and Milk Harbor are playable. Choose **Visit the Matchbox Workshop** from the title screen.

The working Mac package is **0.2.6**, with stable **0.2.2** separately preserved. It fixes Workshop text-size preferences and navigation while portrait guidance is active. This remains a three-stage chapter preview; human audiovisual acceptance, sustained performance, physical-device/Windows validation and actual Figma execution remain open. See [the acceptance record](evidence/PLATFORM_026_ACCEPTANCE.md) for checks, package hashes and history.

## Run from source

On macOS, double-click `run.command`, or run these commands in the project folder:

```sh
./scripts/setup.sh
./run.command
```

Setup downloads the pinned official Godot **4.5.1** editor if needed and imports the project. It requires an internet connection for the initial download; gameplay runs locally. The launcher resolves its own directory, so its absolute path also works from any current directory. Open `project.godot` in Godot to edit the source scene, procedural models and game code.

For isolated manual Workshop review:

```sh
./playtest.command --playtest-scene=workshop
./playtest.command --playtest-scene=workshop --touch-ui
```

These open the current local app with disposable progress/settings. The touch option is a Mac viewport preview; no automatic gameplay, recording or human result is created. See [the player protocol](docs/PLAYER_VALIDATION.md).

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

These are the default bindings. Pause settings provide separate music and effects levels, reduced motion, text size and keyboard remapping. The footer, prompts and hints follow changed bindings; 1/2/3 remain fixed size shortcuts. Keyboard/mouse and injected touch input have source tests. To preview the adaptive controls on a Mac, run `./run.command -- --touch-ui`. Use the movement pad with Use/Hop/Target/Hint/Pause and Small/Normal/Large; keyboard/controller input changes the prompts, and touch restores virtual controls. Physical touch, controller/accessory-keyboard hardware and human control-feel review remain unverified.

Progress uses Godot's `user://` storage under the application name. On macOS this is `~/Library/Application Support/Godot/app_userdata/Tiny Trouble · Toast Express/`. `toast_express_v1.json` holds demo progress; `breakfast_chapter_v1.json` separately holds chapter snapshots and earned completions; `settings.cfg` holds shared preferences. Atomic chapter completion saves the earned clear and completed snapshot together. Backups recover valid saves, and local reset preserves earned completion. Sequential profile unlocks never make an unbuilt stage playable.

## Build a standalone Mac app

```sh
./scripts/build_macos.sh
```

The script requires Python 3 for its resource audit. It downloads official Godot 4.5.1 export templates when needed (the initial archive is approximately 1.35 GB), checks the pinned SHA-512 checksum, imports and parses the project, audits selected runtime resources, and exports:

- `builds/Tiny Trouble.app`
- `builds/Tiny-Trouble-macOS.zip`

The current working app is the local **0.2.6 candidate**, with universal Apple Silicon/Intel binaries, identifier `games.tinytrouble.toast`, and an 85-resource PCK/digest/prearchive-signature audit. The working ZIP SHA-256 is `81b893a02c3bb786576f23fb05520469ef11e9416e6680011611e448abd02697`. Stable **0.2.2** remains separately preserved as `builds/W01S03-verified-macOS.zip`; rejected `builds/platform-0.2.3-candidate-macOS.zip` and `builds/platform-0.2.4-candidate-macOS.zip` retain their own evidence. `builds/platform-0.2.5-candidate-macOS.zip` and source checkpoint `436967e` preserve the prior 0.2.5 evidence. Earlier W01S02/W01S01/VS01 ZIPs are retained. These are local artifacts without Apple notarization or public distribution.

A Windows x64 candidate is also exported at `builds/windows-0.2.6/Tiny-Trouble-0.2.6-Windows-x64.zip`, with PE32+ x64 and 85-resource digest checks. It has not run on Windows. [Export instructions](docs/EXPORTING.md) cover Windows and the iOS preflight dependency. No iOS project/IPA or physical mobile-device execution is claimed.

The bundle signature is verified before ZIP creation in a clean local temporary directory. This machine's Desktop FileProvider adds Finder metadata to `.app` folders placed on Desktop, which can affect a later strict signature check there. The ZIP preserves the verified bundle; use a folder outside the synced Desktop when independently checking its signature.

The workflow follows Godot's [macOS export documentation](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_macos.html) and [command-line documentation](https://docs.godotengine.org/en/4.5/tutorials/editor/command_line_tutorial.html). It performs structural build checks; an exported app is not proof of a completed gameplay or visual gate.

## Source and verification

`scripts/art.gd` builds editable toy geometry. `python3 scripts/generate_audio.py` reproduces the original WAVs and technical report; `./scripts/transcode_music.sh` derives the runtime music.ogg. Nunito's OFL license is preserved in `assets/fonts/OFL.txt`. Concept art in `assets/reference/` is a target, not an engine screenshot.

The new platform source checks are separate from the preserved chapter totals:

```sh
./run.command --script res://tests/platform/test_adaptive_ui.gd -- --touch-ui
./run.command --headless --script res://tests/platform/test_lifecycle.gd -- --touch-ui
```

The latest complete fifteen-suite run passes **10,371 regular assertions +15,262 swept checks**, before the final persistent-card adjustment. That subsequent HUD change passes source/package UI 1,293, route 14, actual package settings 91 and lifecycle 134; the full runner was not repeated after every later HUD edit. Counts below retain historical scope. Run the regression suites from the project directory:

```sh
./scripts/check.sh
```

The retained M1 suites pass **2,452 regular assertions** and 15,262 conservative flight-clearance checks; the 91 settings checks were rerun after the footer change. Current Crumb Crossing/profile/scene coverage is **1,505 assertions** (917 + 365 + 223). Blueberry Ballast adds **3,201 pure-state checks and 82 actual scene checks**. The scene contact test measures zero maximum foot penetration against an actual 0.02-scene-unit limit; this is bounded contact evidence. The preserved eleven-suite W01S02 checkpoint totals **7,240 regular assertions plus 15,262 swept checks**. `check.sh` saves logs under `evidence/` and requires `rg` (ripgrep).

Milk Harbor pure rules pass **2,791 checks**; the final source scene suite passes **147 checks** with clean logs, covering actual mesh contacts, both boarding directions, cargo/mooring states, rim/jump recovery, checkpoints, interrupted saves and atomic completion retry. The current 1280×720 source route passes **11 ordinary-input checks**. The regenerated final-geometry 1920 route also passes 11 checks; it supersedes earlier 1920 views. The [Harbor workshop](evidence/workshop_harbor/README.md) passes **307 native checks and six reviewed captures**, including actual fresh/saved stage → hub → demo → hub → stage button navigation with isolated settings and snapshots. The retained Crumb scene suite still passes 223 checks. The full thirteen-suite run passes 10,178 regular assertions (7,240 + 2,791 + 147) plus 15,262 swept checks; Harbor now also passes the 81-resource 0.2.2 audit and actual package route 11/scene 147/workshop 307 gates. All six packaged workshop views were reviewed with no observed clipping or drawer/Pip overlap. All ten source 1280 views, ten regenerated source 1920 views, ten actual package 1920 views and five actual encoded samples are reviewed. Dock/ring/wafer/rim, water and copy findings are resolved; no new concrete art defect remains in that scope. Full uninterrupted motion quality and subjective audio remain unclaimed.

The actual Harbor movie route passes 11 checks and the [Milk Harbor MP4](evidence/Milk-Harbor-playthrough.mp4) fully decodes without errors: **14.5 seconds, 870 H.264 frames at 60 FPS, 1280×720, 48 kHz stereo AAC**. Its [verification](evidence/harbor_recording/verification.json) records the digest; five actual encoded samples are reviewed. Reproduce with `./scripts/record_harbor.sh`. Automated duration is not first-play timing, and movie cadence is not real-time performance.

The capture-free packaged 1920×1080 Harbor run passes 11 checks: 697 frame intervals measure p50/p95/p99 **16.664/18.148/18.621ms**, with peaks of 378 draws/622 objects. Default cap 60/VSync and FPS-monitor p50/p95/max 60 are recorded; all 12 focus samples are unfocused. This native M4 Pro/macOS 26.6.2 run makes no PNG requests and is outside movie mode; ordinary save/report I/O remains. It started without competing Godot/ffmpeg processes. These conditions do not establish every-frame 16.67ms, foreground hands-on feel or another-hardware performance. `evidence/harbor_performance/replay_report.json`.

The 0.2.2 package is preserved as `builds/W01S03-verified-macOS.zip`, SHA-256 `a1411379fdacbdf8d89b6897f2fb3768e484b5b241ef164c5cb7597cb50bee89`. Source checkpoint: commit `9da8d5a`, tag `w01s03-technical-1`. Prior W01S02/W01S01/VS01 ZIPs remain preserved. `evidence/W01S03_ACCEPTANCE.md` records the current gate scope.

The [main Blueberry Ballast source route](evidence/ballast_1920/replay_report.json) and [alternate far-berry solution](evidence/ballast_alternate/replay_report.json) each pass 10 ordinary-input checks. The alternate captures precede the final foot-pose correction and must not be used as evidence for that fix. Native mechanism art passes 28 checks. The [preserved W01S02 workshop](evidence/workshop_ballast/README.md) passes 247 native checks with six reviewed captures, including maximum text size and actual stage → hub → demo → hub → stage button navigation. Reproduce source routes or workshop captures with:

```sh
./run.command --script res://tests/chapter/replay_crumb.gd
./run.command --script res://tests/chapter/replay_ballast.gd
./run.command --script res://tests/chapter/replay_harbor.gd
./run.command --script res://tests/chapter/test_workshop_capture.gd
```

The corrected [packaged Blueberry Ballast route](evidence/ballast_export/replay_report.json) passes 10 checks with nine captures, including ramp entry. Its [actual packaged scene suite](evidence/ballast_export/scene_checks.log) passes 82 checks with zero measured foot penetration, and its [packaged workshop run](evidence/workshop_ballast_export/capture_report.json) passes 247 checks with six native frames. All nine final packaged route views and four encoded MP4 samples are reviewed; entry-foot, ramp-lip and copy findings are closed. [W01S02 acceptance](evidence/W01S02_ACCEPTANCE.md) records the bounded technical gate. Milk Harbor has now passed its source and package functional/recovery/navigation gates; available technical presentation gates pass and M2 stays incomplete.

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

Human enjoyment, satisfaction and demand remain **UNVERIFIED**. The audience question is pending. [Player validation](docs/PLAYER_VALIDATION.md) separates owner requirements, observed bugs and agent hypotheses, and requires recurring representative feedback plus human judgment of Pip/props/environment/UI at normal display size without zoom. No automatic beauty score or test count closes that gate. The preserved 0.2.5 source/package adaptive evidence is 1,293/28 each; current 0.2.6 Workshop checks are separately scoped above.
