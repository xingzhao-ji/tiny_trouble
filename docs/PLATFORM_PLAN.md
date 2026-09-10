# Platform foundation · TT-027

**New measured Workshop defects remain open in 0.2.5:** UI-027-04 loses saved 1.25 text scaling in the mobile HUD (24 logical font units for labels/status instead of 30), and UI-027-05 allows Enter to navigate from portrait guidance into Crumb Crossing. The separate exported 0.2.5 PCK audit, hosted by the editor binary rather than the distributed app executable, records **732 assertions / 71 failures / 20 captures**: 70 repeated font checks and one portrait-navigation failure; bounds, scrolling, Pip separation and profile preservation pass. All 20 stills are reviewed. Pip stays visible; the centered menu covers much of the roof label/right drawer/workbench, a composition tradeoff awaiting human judgment. Evidence: `../evidence/platform_refinement/workshop_mobile_025/`. These are the next 0.2.6 corrections; no production fix is claimed in this checkpoint.

**Working package 0.2.5; stable 0.2.2 preserved. TT-027 and TT-028 remain active before content expansion.** TT-026 is paused and its drafts stay unavailable. Three of sixty campaign stages retain bounded Mac technical checkpoints; 57 remain planned. The requested targets are macOS, Windows, iPad and iPhone with adaptive inputs/layouts, a real Figma workflow and measured sustained performance.

Source and actual Mac adaptive UI each pass **1,293/28**, source max-text Harbor **14/806 samples** and actual package **14/816** with zero named actor/card/toast overlap. All 38 source and 38 package PNGs were reviewed. UI-027-01/02/03 close in those recorded states; broader human presentation remains open. Actual package lifecycle 134/settings 91/manual startup pass; 85-resource Mac/Windows audits pass, but Windows execution is unverified. [Current acceptance](../evidence/PLATFORM_025_ACCEPTANCE.md) records exact package hashes, validation chronology and review limits. The separate mobile Workshop audit now establishes UI-027-04/05 as open defects; their correction is the next refinement.

| Task field | Record |
| --- | --- |
| Parent / requirements | M2; PLAY-01, ART-02, QUALITY-01, FOCUS-01 and the new user platform/Figma requirement |
| Missing deliverable | Demonstrated platform-appropriate design, input, lifecycle and sustained performance across the requested targets |
| Player benefit | Readable, usable controls on desktop/tablet/phone layouts and safe recovery when play is interrupted |
| Scope | Existing VS01, HUB01 and W01S01–W01S03; shared UI/input/lifecycle, export support and evidence |
| Available source gates | Adaptive UI **1,293/28 reviewed captures**, Harbor route 14/806, lifecycle 134; local Figma 247 and art-provenance 205. Actual Mac package checks are separately recorded |
| Remaining gates | Human audiovisual acceptance and representative feedback; valid sustained measurement; actual Windows/mobile/Figma execution. Workshop UI-027-04/05 open; next candidate correction pending |

## Capability and execution matrix

[`platform_inventory.json`](../evidence/platform_inventory.json) is a sanitized read-only inventory. It distinguishes installed software from an operational runtime or physical device. It contains no device serials, UDIDs, personal device/VM names, account details or private paths. No VM boot, device pairing/installation, account inspection or signing configuration was performed by the inventory.

| Target or capability | Confirmed | Limit |
| --- | --- | --- |
| Physical Mac | Apple M4 Pro, 48 GiB, macOS 26.6.2, Godot 4.5.1; native gameplay, new adaptive captures and a focused 60-second stable-package baseline | Apple Silicon host only; universal Intel architecture inspection is not Intel hardware execution; twenty-minute workload failed; repaired collector requires a valid sustained rerun |
| Apple tooling | Xcode 26.6/17F113; iPhoneOS and Simulator 26.5 SDKs | iOS preflight actually exits 2 because a real Team ID is absent; no Xcode project, IPA, signing, installation or iOS execution |
| iOS Simulator | Local simctl queries timed out; no local device definitions observed | Godot 4.5 officially does not support iOS Simulator export; desktop viewport fixtures must not be called Simulator tests |
| Physical iPhone/iPad | USB family scan empty; xcdevice failed and devicectl timed out | No reachable mobile device established; wireless availability remains unresolved, rather than a claim that no device exists |
| Windows | Parallels/VirtualBox/UTM/QEMU tools are installed; 0.2.5 Windows x64 candidate exports and passes PE32+/85-resource digest audit | No accessible Windows guest or native Windows host established; one listed VirtualBox VM is inaccessible. Export is not execution |
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

Current 0.2.5 Mac/Windows exports each pass 85-resource/digest checks; Mac universal architecture and prearchive ad hoc signature pass. Actual Mac max-text touch route 14, adaptive UI 1,293, settings 91, lifecycle 134 and manual-launch smoke pass. Desktop Movie Maker route 11 and full AVI/MP4 decode pass; three encoded stills are reviewed separately. The movie's 14.5 seconds/870 frames are not real-time pacing evidence. The working ZIP paths and exact hashes are in [0.2.5 acceptance](../evidence/PLATFORM_025_ACCEPTANCE.md). Stable 0.2.2 and rejected 0.2.3/0.2.4 have distinct preserved ZIPs.

The updated actual 0.2.5 profile passes after 30.02 s active warmup plus 120.02 s measurement on M4 Pro/macOS 26.6.2 at 1920×1080, cap 60/VSync/120 Hz/AC power: 7,201/7,201 focused frames, 0 paused, 10 complete flights, 4,122 walking-motion and 1,860 flight-motion frames. p50/p95/p99 **16.642/17.162/19.084 ms**, max 30.039 ms; active RSS peak 239.8 MiB, whole 244.4 MiB. Active CPU p50/p95 is 28.7%/30.6%. All 95 injected render-state probes change, p50/p95 27.639/33.414 ms; this is not physical input-to-photon latency. The prepared VS01 fixture runs audio and saves with no PNG/movie mode; collector overhead remains included. [Report](../evidence/platform_profile/macos_candidate_025_1080p_120s/README.md).

This is a **short updated baseline**, not sustained/thermal, leak, battery, physical-input or other-device certification. In-process scene ready/first-post-draw probes may have warm caches; they do not establish cold-launch distributions. The older 0.2.2 focused 60-second baseline remains separately preserved. No material rendering/resource reduction is justified by current measured data; a valid long traversal and hardware measurements are still required.

The frozen 0.2.3 twenty-minute workload **failed**: 71,963 mixed-focus intervals, zero walking/completed flights/resets/probes. Its p50/p95/p99 16.637/17.200/17.556 ms and RSS +2.453 MiB describe a stalled scene. Raw data and the [focus/rolling/RSS review](../evidence/platform_profile/macos_candidate_023_1080p_20m/post_run_review/REVIEW.md) remain unchanged. Collector repair has healthy/injected-failure checks and the new short pass; this does not turn the failed long run into thermal success.

Source audio feedback 59/provenance 16 and decoded runtime-mix integrity pass; subjective audition remains unverified. Figma local preparation 247 and art provenance 205 pass; actual import remains unverified. [Player validation](PLAYER_VALIDATION.md) requires owner direction, representative feedback and normal-display human judgment without zoom, on actual devices when available. Audience question pending; no human sessions or market-demand results. Complete required TT-027/TT-028 gates before resuming TT-026.
