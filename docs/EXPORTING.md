# Local platform exports

The candidate export metadata is **0.2.3**. These scripts package the current working source; they do not publish, install, sign with a developer certificate, or download tools. Finish source QA before creating a candidate. The preserved 0.2.2 macOS application and its hardware baseline are separate artifacts.

| Target | Entry point | Current validation |
| --- | --- | --- |
| macOS universal | `./scripts/build_macos.sh` | Candidate 0.2.3: universal app/ZIP, 85 runtime resources, all PCK digests and prearchive signature verified; native gates tracked separately |
| Windows x64 | `./scripts/build_windows.sh` | Candidate 0.2.3 exported: PE32+ x64, 85 runtime resources and all PCK digests verified; Windows execution unverified |
| iPhone/iPad arm64 | `./scripts/export_ios.sh --check` | Local Xcode/SDK found; project export blocked by missing real Team ID |

Both new scripts require Python 3, the local Godot **4.5.1 stable** editor, and `tools/godot-export-templates-4.5.1.tpz`. They verify that archive against the pinned SHA-512 before extracting the required templates into a temporary project. `TINY_TROUBLE_GODOT` can select an existing editor executable. They never fetch missing dependencies.

Each export freezes `project.godot`, presets, assets, scenes and scripts into a temporary directory with a private import cache. The output directory must not exist, protecting previous candidates. Failed attempts retain diagnostic logs there; choose a new output directory for a retry. Source manifests identify the exact copied files. The resource selection explicitly includes `scripts/platform/touch_controls.gd` and all four playable scenes. Actual PCK entry digests, required resources and excluded development files are checked before reporting success.

## Windows x64

After the source candidate is ready:

```sh
./scripts/build_windows.sh
# Or preserve multiple candidates in distinct directories:
./scripts/build_windows.sh builds/windows-0.2.3-candidate2
```

The default output is `builds/windows-0.2.3/`, containing:

- `Tiny-Trouble-0.2.3-Windows-x64.zip` and an extracted `TinyTrouble-Windows-x64/` folder.
- `TinyTrouble.exe` beside its separate `TinyTrouble.pck` inside that folder.
- Import/export logs, `package-audit.json`, `source-manifest.json` and `SHA256SUMS.txt`.

The script verifies an x86-64 PE32+ executable and compares the actual PCK with the independently exported resource list. It creates an unsigned package. Keeping the PCK separate is the documented Windows export layout. [Godot Windows export guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_windows.html)

Extract the entire ZIP before launching the executable on Windows. Archive/header/resource inspection is **not Windows execution evidence**. No accessible Windows guest or native Windows test host has been established in this workspace. Startup, audio, input, saves, controller behavior and sustained performance still require an actual Windows run.

## Unsigned iOS project

```sh
./scripts/export_ios.sh --check
```

This bounded check currently reports Xcode 26.6 (17F113) and the iPhoneOS 26.5 SDK, then exits **2** because no actual Team ID is configured. It does not inspect developer accounts, certificates or connected devices. No Xcode project or IPA has been produced.

Godot 4.5 requires both a bundle identifier and a real App Store Team ID. The pinned 4.5.1 exporter rejects an empty Team ID in `_export_project_helper` even when `application/export_project_only=true`. Project-only mode returns before the archive/build step, but does not bypass that earlier validation. [Godot iOS guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html), [Godot 4.5.1 exporter source](https://github.com/godotengine/godot/blob/4.5.1-stable/editor/export/editor_export_platform_apple_embedded.cpp)

Once the project owner explicitly supplies their real 10-character Team ID in the environment:

```sh
# Set TINY_TROUBLE_IOS_TEAM_ID to the owner's actual ID outside this repository.
./scripts/export_ios.sh --check
./scripts/export_ios.sh
```

Do not substitute an invented ID to bypass the check. The script validates the supplied format, not Apple account membership. It inserts that ID into a temporary preset only; tracked Team ID, identity and provisioning fields stay blank. Generated Xcode metadata contains the supplied ID and Godot's default signing configuration, but no signing operation is performed.

The default destination is `builds/ios-0.2.3/XcodeProject/TinyTrouble.xcodeproj`. The `.ipa` basename passed internally to Godot names the output project; project-only mode must create neither an IPA nor an XCArchive. The script audits that condition and the project's actual PCK. A later Xcode build, signing setup, device installation or distribution requires a separate authorized step. [Project-only export option](https://docs.godotengine.org/en/4.5/classes/class_editorexportplatformios.html#class-editorexportplatformios-property-application-export-project-only)

The preset targets arm64 iPhone and iPad with minimum iOS 14.0. It retains the project's Compatibility renderer and sensor orientation with a landscape-play/portrait-guidance policy; Godot 4.5.1 includes an iOS OpenGL ES rendering path, so export preparation does not require silently changing to Mobile/Metal. Actual device rendering and performance remain unverified. [Pinned Apple embedded display-server source](https://github.com/godotengine/godot/blob/4.5.1-stable/drivers/apple_embedded/display_server_apple_embedded.mm)

**Godot 4.5 does not support iOS Simulator export.** An installed simulator SDK therefore does not establish a runnable test target for this exporter. Local simulator inventory also remains unresolved after bounded queries timed out. Physical touch, controller, thermal, battery and device-memory tests have not run. [Godot iOS export limitations](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html)

## Preparation checks

On 2026-09-09, `bash -n` passed for both new scripts; all six embedded Python blocks compiled; preset sections parsed without duplicates; both new presets selected the touch-controls dependency; and the pre-existing macOS preset initially remained unchanged; integration subsequently bumped its version to 0.2.3 and added the shared token dependency. The iOS prerequisite command produced its expected missing-Team-ID exit 2. These checks establish script preparation only. Actual candidate package audits now exist in `evidence/platform_export/`; Windows execution and iOS project generation remain unverified.
