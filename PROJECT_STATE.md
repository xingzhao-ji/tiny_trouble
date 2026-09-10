# Tiny Trouble checkpoint

Active integration milestone: **M1 — VS01 Toast Express Demo**. Native Godot 4.5.1, offline, solo, authored 3D toy diorama. The 12-world / 60-stage campaign remains planned; VS01 is not an extra campaign stage.

The scene is playable from source. An initial native replay completed all three puzzles and the optional discovery through the real input handlers, without teleporting Pip or writing puzzle state. Subsequent contact, safety, lighting and UI changes are under regression review. A universal local macOS export is being validated. See QUALITY_REPORT.md for evidence and limits; source presence does not mark a milestone complete.

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

1. Finish the updated native replay and geometric/safety checks, including the toast/window and spoon contact fixes; retain the six fixed views and a route recording.
2. Verify the standalone app, settings, recovery and clean shutdown; update quality evidence and preserve a versioned working checkpoint.
3. Resolve remaining M1 gates, then begin W01S01 Crumb Crossing under M2. Do not broaden the campaign before the slice gates pass.

Human enjoyment, first-time completion time, and physical controller hardware remain unverified. Work proceeds during active authorized execution only; this file does not indicate a background development service.
