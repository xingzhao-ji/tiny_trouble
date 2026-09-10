# Platform foundation · TT-027

**Working 0.2.6: actual Mac app targeted checks and all 26 Workshop package-frame reviews pass; UI-027-04/05 close in that bounded scope.** Stable 0.2.2 remains preserved; M2/TT-027/TT-028 stay open and TT-026 is paused. Three of sixty stages retain bounded technical checkpoints. Human/device/Figma execution and broader audiovisual acceptance remain unverified.

The app passes **1,392 checks**: mobile Workshop 825/20, desktop 319/6, orientation 23, settings 91, lifecycle 134, plus manual startup/isolation smoke. The initial source 825/20 preceded two timing-race reproductions 20/2; corrected source 23/0 and final package tests cover the final guards and cancellation recovery. Both races had reached a guarded Crumb title, without gameplay. See [0.2.6 acceptance](../evidence/PLATFORM_026_ACCEPTANCE.md) and [the decision record](WORKSHOP_026_REFINEMENT.md).

| Task field | Record |
| --- | --- |
| Parent / requirements | M2; PLAY-01, ART-02, QUALITY-01, FOCUS-01 and the new user platform/Figma requirement |
| Missing deliverable | Demonstrated platform-appropriate design, input, lifecycle and sustained performance across the requested targets |
| Player benefit | Readable, usable controls on desktop/tablet/phone layouts and safe recovery when play is interrupted |
| Scope | Existing VS01, HUB01 and W01S01–W01S03; shared UI/input/lifecycle, export support and evidence |
| Available source gates | Initial Workshop 825/20; orientation 20/2 failing baseline then 23/0 fixed. Source snapshot/harness hashes preserved. Final app 1,392 checks separately cover completed code |
| Remaining gates | Ten-minute attempt failed on focus loss; sustained gate and human audiovisual acceptance, actual Windows/mobile/Figma execution. Observed still aliasing and menu/backdrop composition require later contextual review |

## Capability and execution matrix

[`platform_inventory.json`](../evidence/platform_inventory.json) is a sanitized read-only inventory. It distinguishes installed software from an operational runtime or physical device. It contains no device serials, UDIDs, personal device/VM names, account details or private paths. No VM boot, device pairing/installation, account inspection or signing configuration was performed by the inventory.

| Target or capability | Confirmed | Limit |
| --- | --- | --- |
| Physical Mac | Apple M4 Pro, 48 GiB, macOS 26.6.2, Godot 4.5.1; native gameplay, new adaptive captures and a focused 60-second stable-package baseline | Apple Silicon host only; universal Intel architecture inspection is not Intel hardware execution; twenty-minute workload failed; repaired collector requires a valid sustained rerun |
| Apple tooling | Xcode 26.6/17F113; iPhoneOS and Simulator 26.5 SDKs | iOS preflight actually exits 2 because a real Team ID is absent; no Xcode project, IPA, signing, installation or iOS execution |
| iOS Simulator | Local simctl queries timed out; no local device definitions observed | Godot 4.5 officially does not support iOS Simulator export; desktop viewport fixtures must not be called Simulator tests |
| Physical iPhone/iPad | USB family scan empty; xcdevice failed and devicectl timed out | No reachable mobile device established; wireless availability remains unresolved, rather than a claim that no device exists |
| Windows | Parallels/VirtualBox/UTM/QEMU tools are installed; 0.2.6 Windows x64 candidate exports and passes PE32+/85-resource digest audit | No accessible Windows guest or native Windows host established; one listed VirtualBox VM is inaccessible. Export is not execution |
| Figma | Local development plugin and shared tokens prepared, compiled and statically checked | Actual Figma connection was not confirmed when the request ended. Local app search found no desktop app; web/account access and actual import/rendering remain unverified |

Godot's [4.5 iOS export guide](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_ios.html) requires a Team ID and documents the Simulator limitation. The actual preflight is retained in `evidence/platform_ios_preflight.log`; `docs/EXPORTING.md` records the exact dependency and local commands. A real Team ID must be supplied by the owner; none was invented, queried from an account or committed.

## Design workflow and adaptive UI

`design/figma/tokens.json` supplies shared palette/type/spacing values; the runtime consumes generated `scripts/platform/design_tokens.gd`. The local development plugin under `design/figma/` creates editable component/frame variants and navigation flows when run in a real Figma file. Its TypeScript/API-shape, syntax, provenance and rectangle checks are local checks. It is an **unexecuted development plugin**, not a `.fig`, published library, confirmed prototype, or actual Figma file. No file/node URL or assigned plugin ID is fabricated. Follow `design/figma/README.md` when a real connection with edit access is available, then review all imported flows and compare them with native captures.

Desktop and tablet use adaptive landscape gameplay. Phone gameplay initially uses landscape with a portrait rotate-to-play guard. The guard pauses active play, suppresses input, blocks start/resume while portrait, and leaves play paused after rotating back until explicit resume. Physical-device safe areas and both device landscape orientations remain untested.

The production HUD now has scrollable menus, safe-area layout, text scale 1.0–1.25, minimum 88-logical-unit touch targets, a movement pad, Use/Hop/Target/Hint/Pause and three named size actions. Layout stays shared with the existing game rather than introducing a second gameplay engine. At the smallest requested desktop window 667×375, macOS captures 666×374; an 88-logical-unit target renders 45.71 pixels high. Requested and actual dimensions are both retained, with no equivalence to physical iOS points.

`tests/platform/test_adaptive_ui.gd` passes **1,293 assertions and 28 reviewed native source captures** at 1280×720, 1024×768, 844×390, requested 667×375 and 390×844 portrait. Landscape gameplay is tested at both default and 1.25 text; menus are checked at 1.25. The asymmetric logical safe-inset fixture is L48 / T16 / R32 / B24. These are **Mac desktop viewport simulations**, not Simulator or physical iOS tests. `evidence/platform_refinement/ui_025a/` records current source bounds; actual package results are in `evidence/platform_export/candidate_025/ui/`. Historical 1,289/1,265 sets retain their original evidence.

## Open package presentation findings

All 26 actual 0.2.3 package frames have been reviewed. **UI-027-01 remains OPEN:** the Harbor phone toast hides Pip and cargo during boarding and the shallow-water resize response, and obscures other key interactions. **UI-027-02 remains OPEN:** the objective card retains blank height after shorter instructions. The source adaptive fixture verifies UI bounds and Crumb interactions, but did not check projected Harbor actors. Functional route completion does not close either finding.

Corrected source and actual 0.2.5 package routes now include persistent objective/target cards as well as toasts in post-draw actor checks. Source route 14/806 and actual package 14/816 pass with zero named overlaps; all corresponding 10+10 frames are reviewed. Source and package adaptive UI 1,293/28 each also pass and are reviewed. These bounded closures do not establish whole-scene aesthetics. Preserve frozen rejected 0.2.3/0.2.4 evidence. Broader composition, materials, expression, animation, music, sound and transitions remain in [TT-028](PRESENTATION_GATE.md).

## Input and lifecycle

The existing scene rules remain authoritative. Parsed screen-touch/drag events drive a separate pad vector through the shared `movement_input()` helper; the pad never clears physical Input actions. Concurrent movement plus Small/Normal/Large, Use and Hop exercises actual Crumb scene actions. Large-at-tray refusal reaches the existing rule and visible explanation. Cancellation, leaving the pad, injected focus loss, Pause/reset and stale drag release are checked.

Actual injected keyboard/controller events change the footer and target context. Isolated K/L remaps appear in keyboard mode. The first touch after either external-input mode immediately restores and operates the pad. Held W survives a touch-only release. Controller/accessory-keyboard hardware and touch ergonomics remain unverified. Menu scrolling is exercised programmatically; physical swipe-scroll is a separate gate.

Application focus loss/pause releases physical and touch actions and pending jump, pauses actual tweens/audio, displays the pause menu, and writes the existing serializer synchronously. Foreground/resume restores audio availability while gameplay waits for explicit resume. `tests/platform/test_lifecycle.gd` passes **134 source headless checks** across VS01 and all three chapter stages: exact partial-resize transform freezing, duplicate notifications, fresh disk reload, and both interrupted Harbor voyages. A fresh Harbor process restores the canonical last mooring with its notice; the still-live app resumes its paused voyage only after the menu action. `evidence/platform_lifecycle/` explicitly labels injected notifications rather than physical OS suspension/termination.

All tests use unique disposable chapter/demo/settings paths, drain audio and restore global input/audio state. Existing profile formats and earned chapter completion remain intact; no account/cloud sync is introduced.

## Candidate exports and performance

Current 0.2.6 Mac and Windows exports each pass 85-resource/digest audits; Mac universal architecture and prearchive signature also pass. Actual distributed Mac execution passes mobile 825 +desktop 319 +orientation 23 +settings 91 +lifecycle 134 = **1,392 checks**, plus a manual startup/isolation smoke. All 26 final package PNGs are reviewed and two Workshop defects close in that scope. [Package identity and evidence](../evidence/PLATFORM_026_ACCEPTANCE.md). The 0.2.6 iOS preflight exits 2 for missing real Team ID; no project/IPA or physical-device execution. Windows export is not Windows execution.

Source-file hashes from `FileAccess` on `res://*.gd` identify snapshots, not compiled `.gdc` payloads. Exact app/PCK hashes and the targeted launcher identify the tested native package; audited payload digests provide independent archive integrity. A Windows export source manifest is not Mac runtime proof.

The actual 0.2.6 ten-minute attempt **FAILED** on `native_focus_lost` at 106.994 measured seconds after 60.017 seconds of valid active warmup. Its 6,417 retained frames and 9 completed flights are partial diagnostics, not sustained acceptance. The external cause is unknown. A bounded log query found no display/sleep/wake event; no immediate unchanged-condition repeat is planned. The prior 0.2.5 short focused baseline remains **120.02 s after 30.02 s warmup**, 7,201/7,201 focused frames, 10 flights, 0 paused; p50/p95/p99 16.642/17.162/19.084 ms, max 30.039 ms, active RSS peak 239.8 MiB. It is a prepared VS01 fixture, with collector overhead/audio/save I/O included, not ordinary-player or sustained/thermal evidence. The failed 0.2.3 twenty-minute workload remains a failure, not a valid comparison. [Prior short report](../evidence/platform_profile/macos_candidate_025_1080p_120s/README.md) and [failed-run review](../evidence/platform_profile/macos_candidate_023_1080p_20m/post_run_review/REVIEW.md) retain exact limits.

The prior full 15 source suites and 0.2.5 Harbor/UI/movie/audio checks have not all been rerun as 0.2.6; retain their recorded chronology. Figma local synchronization passes 266 checks, tokens unchanged; actual import remains unverified. The latest tool check still exposes no callable Figma integration; no installation or permission retry was made.

Final compact-phone Workshop stills show discontinuous diagonal grain and thin saucer rings at actual 666×374. That observed aliasing is not a motion-shimmer measurement or a human complaint; compare same-camera alternatives before a rendering change. The menu's roof/drawer coverage remains a human composition question. Neither observation warrants a claim that overall aesthetics are accepted. [Player validation](PLAYER_VALIDATION.md) requires normal-display human judgment without zoom, contextual feedback and actual devices when available. Audience question pending; no human satisfaction/demand results.
