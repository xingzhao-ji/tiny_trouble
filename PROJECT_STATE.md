# Tiny Trouble checkpoint

Verified technical checkpoint: **M0 foundation / M1 — VS01 Toast Express Demo**. Next integration frontier: **M2 — Breakfast Chapter**. Native Godot 4.5.1, offline, solo, authored 3D toy diorama. The 12-world / 60-stage campaign remains planned; VS01 is not an extra campaign stage.

The scene is playable from source and as a standalone universal Mac app. Source and packaged input replays complete all three puzzles, the optional discovery and the toast finale. Rules, persistence, safety, recovery, settings and swept flight clearance have executed passing checks. See QUALITY_REPORT.md for measured conditions and limits. The larger campaign remains planned; this is a verified demo checkpoint, not a full-game completion claim. The recorded route is `evidence/Toast-Express-playthrough.mp4`; bounded acceptance and external limitations are in `evidence/M1_ACCEPTANCE.md`.

## Launch and build

From this directory:

```sh
./run.command
./scripts/build_macos.sh
```

`run.command` starts the installed project-local Godot runtime. On a fresh Mac checkout, first run `./scripts/setup.sh`. The app export is `builds/Tiny Trouble.app`; its ZIP is `builds/Tiny-Trouble-macOS.zip`. These are local artifacts, not public releases.

```sh
./tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_puzzle_state.gd
./tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/test_scene_persistence.gd
./tools/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 -- --replay
```

Replay uses a separate save. It injects ordinary key/axis actions and navigates the physical scene. Screenshots and the report are written to `evidence/`.

## Decisions and durable state

- Compatibility renderer and a gently tracking orthographic camera; broad warm key and restrained fill.
- Six puzzle prop families; toaster platform is a subassembly. Small, normal and large are authored states. Cereal/toaster large transitions are visibly refused where the tray has no room.
- Pip carries small props, passes the spoon through the handle, places it as a bridge, uses blueberry ballast and butter latch, prepares the napkin, and reuses the berry at the toaster.
- The permanent return bridge is unlocked with the butter latch. All puzzle boundaries have canonical reset snapshots.
- Save profile version 1 contains PuzzleState schema 1 and persistent earned-completion history. Legacy bare puzzle saves remain readable. Valid backups survive corruption, and interrupted flights reload at the launch checkpoint.
- Original procedural geometry and audio sources are included. Generated images are labeled concept references; runtime views are separate.

## Next three tasks

1. Build W01S01 Crumb Crossing: a blocking sugar cube, small spoon carried through the narrow cup handle, and visible spoon enlargement across the saucer gap. Keep the verified VS01 demo available.
2. Connect the first stage to minimal Matchbox Workshop navigation and separate chapter progress; verify fresh saves, local recovery, completion and replay without affecting demo progress.
3. Complete the distinct W01S02–W01S05 stages in approved order after each prior stage meets its functional/recovery/visual gates; then accept M2 before starting World 2.

Latest available suites pass 2,452 regular assertions plus 15,262 conservative flight-clearance checks. The final recording passes all 15 route checks. The default 60 FPS cap is verified on the recorded Mac; native performance windows remained unfocused despite requesting foreground activation. Movie-mode timings are excluded from real-time performance. See QUALITY_REPORT.md for exact percentiles and conditions.

Human enjoyment, first-time completion time, subjective audio balance and physical controller hardware remain unverified. Work proceeds during active authorized execution only; this file does not indicate a background development service.
