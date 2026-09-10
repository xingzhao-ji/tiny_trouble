# Tiny Trouble · Toast Express

A solo 3D puzzle adventure on a tiny breakfast table. Help Pip shrink a spoon into a portable tool, grow it into a bridge, latch a cereal ramp, and prepare a toast flight to a soft napkin landing.

This is the **VS01 development slice, part of M1**. Milestone acceptance is still being verified. The planned twelve-world, sixty-stage campaign and Matchbox Workshop are not implemented; `campaign_manifest.json` records their planned status.

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

Pause settings provide separate music and effects levels, reduced motion and text size. Keyboard/mouse is the primary input. Gamepad controls are mapped, but actual controller hardware and human control-feel review remain unverified.

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

`scripts/art.gd` builds editable toy geometry. `python3 scripts/generate_audio.py` reproduces the original audio and technical report. Nunito's OFL license is preserved in `assets/fonts/OFL.txt`. Concept art in `assets/reference/` is a target, not an engine screenshot.

Run source verification from the project directory:

```sh
./run.command --headless --script res://tests/test_puzzle_state.gd
./run.command --headless --script res://tests/test_scene_persistence.gd
./run.command -- --replay
```

The first integration checkpoint passed 2,091 state checks, 38 persistence checks and 15 checks in the native scene replay using real input events. The replay opens a game window and uses a separate test save. These tests stay in the source project and are excluded from the standalone app. Check `QUALITY_REPORT.md` for later results and remaining visual, audio and recovery gates.

See `PROJECT_STATE.md` for current launch/build status and next tasks, `QUALITY_REPORT.md` for actual checks and limitations, and `BACKLOG.md` for requirement mapping. Human enjoyment, first-play duration, untested devices and unmeasured performance remain unverified until recorded evidence supports them.
