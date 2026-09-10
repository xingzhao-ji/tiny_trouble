# Tiny Trouble quality checkpoint

**M2 Breakfast Chapter is active, with two source-implemented campaign stages and a minimal Matchbox Workshop.** W01S01 Crumb Crossing retains its accepted checkpoint. W01S02 Blueberry Ballast passes its available technical gates: the corrected 0.2.1 packaged route, scene and menu checks pass, and all nine route views plus four actual encoded samples are reviewed. Entry-foot, ramp-lip and copy findings are closed; `evidence/W01S02_ACCEPTANCE.md` records the bounded acceptance. The other 58 campaign stages remain planned. Milk Harbor, The Jam Detour and Toast Express remain unavailable in the hub; M2 is not complete.

## Current chapter gates

| Gate | Evidence and result |
| --- | --- |
| Crumb rules/profiles/scene | Current source checks pass **917 + 365 + 223 = 1,505**. Patch `b118d82` adds strict malformed-stage-type validation to CrumbState; its 36 new assertions are separate from the original 881-check rule result. |
| Ballast pure rules | **3,201 checks pass**, covering both Small/Large solutions, reversible imbalance, invariant rejection, canonical checkpoints and save validation. `tests/test_ballast_state.gd`, `evidence/test_ballast_state.log`. |
| Ballast actual scene | **82 source checks pass** for tray/channel/pocket contacts, mechanism occupancy guards, safe traversal, canonical recovery and durable state. The contact check uses a real 0.02-unit foot-penetration bound and reports a measured maximum of zero. `tests/test_ballast_scene.gd`, `evidence/test_ballast_scene.log`. The actual packaged suite also passes 82 checks with a maximum of 0.0000; `evidence/ballast_export/scene_checks.log`. |
| Both source-native solutions | Main 1920 route and alternate far-berry route each pass **10 ordinary-input checks**, including counterweight inspection. `evidence/ballast_1920/replay_report.json`, `evidence/ballast_alternate/replay_report.json`. Alternate captures precede the final foot-pose fix and are not evidence of its corrected contact. |
| Corrected packaged route | Final version 0.2.1 route passes **10 checks**, with nine captures including the ramp-entry pose. `evidence/ballast_export/replay_report.json`. All nine final views are reviewed and the entry-foot, ramp-lip and copy findings are closed. Four actual encoded MP4 samples are also reviewed; uninterrupted motion quality remains unclaimed. |
| Mechanism art | **28 native geometry/pivot/capture checks pass** at 1280×720 and 1920×1080. The authored pan, pockets, exposed five-weight stack, pulley, ramp and ledge remain editable. `evidence/ballast_art/art_report.json`. This studio is separate from final gameplay placement/contact review. |
| Workshop and button navigation | **247 native checks and six captures pass in both source and actual package**, including the maximum 1.25 text size. Source captures were all reviewed; packaged results are in `evidence/workshop_ballast_export/capture_report.json`. Locked/Play/Continue/Replay states follow actual prerequisite/snapshot/completion data. Real Button.pressed flow runs workshop → Ballast → workshop → demo → workshop → saved Ballast with isolated paths. Three unbuilt entries stay disabled even in completed-profile fixtures. `evidence/workshop_ballast/README.md`. |
| Final native build | Version **0.2.1** passes the **73-resource** PCK/digest audit, universal arm64/x86_64 check and ad hoc signature verification. `evidence/ballast_build.log`, `builds/package-audit.json`. Development/test/evidence files stay excluded. |
| Retained regressions | All **eleven** suites in `check.sh` pass. M1 remains 2,452 regular assertions + 15,262 conservative sweep checks; current Crumb/profile/scene totals 1,505; Ballast adds 3,201 + 82 = 3,283. The complete eleven-suite total is **7,240 regular assertions plus 15,262 swept checks**. Settings 91 was rerun after the footer change. These source-suite results are distinct from packaged checks and native capture fixtures. |

Ballast's two berries use the existing family and authored rolling channels. Both large berries over-raise the ramp; shrinking either aligns it. Its checkpoints are normal trays, both large berries loaded, and a canonical Small/Large balance. Occupied-ramp changes are refused, imbalance remains reversible, and completion plus its snapshot saves atomically. Internal mass arithmetic is absent from player-facing UI. Counterweight inspection is optional.

Final review of all nine route captures and four actual encoded samples is complete; entry-foot, ramp-lip and copy findings are closed. The actual packaged scene/contact test already passes 82 checks, and packaged workshop navigation passes 247 checks. The current ZIP is preserved as `builds/W01S02-verified-macOS.zip`, SHA-256 `29bc3da9154801aa5998f13885856c3783d29c62dc0df0068b05339c79f832d8`. Existing alternate-solution captures remain explicitly older than the final foot-pose correction.

The **capture-free packaged 1920×1080** run passes 10 checks on Apple M4 Pro (`evidence/ballast_performance/replay_report.json`). Its 972 frame intervals measure p50/p95/p99 **16.651/18.327/18.671ms**, with 336 peak draws and 585 objects. Default cap 60/VSync and FPS-monitor p50/p95/max 60 are recorded. All 17 focus samples are false. PNG stalls are excluded; ordinary I/O remains. These are measured native conditions, not an every-frame 16.67ms guarantee, a foreground feel review or another-hardware claim.

The packaged movie route passes 10 checks with `movie_mode=true`. `evidence/Blueberry-Ballast-playthrough.mp4` contains **1,145 H.264 frames at 60 FPS, 1280×720, 19.083333 seconds**, plus 48 kHz stereo AAC. Full ffmpeg decode exits 0 with no errors. The 6,554,200-byte artifact has SHA-256 `6edfb5120b5ec7728212ae7bc0f7772e4cb33c5c9ebc678fe5148e2d302e6eab`; `evidence/ballast_recording/verification.json` records the verification. Fast automated duration does not measure first play, and movie cadence is not performance.

Human enjoyment, first-play duration, subjective audio, physical controller and foreground hands-on feel remain unverified. W01S03 Milk Harbor is next after W01S02's bounded acceptance; M2 still has only two of five stages implemented.

## Preserved W01S01 checkpoint

Commit `4568ced`, tag `w01s01-technical-1`, and `builds/W01S01-verified-macOS.zip` preserve the first-stage package with 63 resources. Its historical chapter result is **881 + 365 + 223 = 1,469**, with 21 art checks and 201 workshop checks. Source and packaged Crumb routes pass 10 checks; the packaged scene suite passes 223. Eight source views and final packaged title/completion frames were reviewed, closing stale captions. `evidence/crumb_crossing/VISUAL_REVIEW.md`, `evidence/crumb_export/`, `evidence/workshop/` retain that scope.

Crumb's carried spoon overlaps part of Pip in projection, crumb details are small at gameplay distance, and milk is a stylized nearly flat boundary. Still review does not certify every animated contact. The newer 917-rule source result is recorded above without rewriting the historical artifact.

## Preserved M1 technical checkpoint

VS01's three connected puzzles, optional picnic, toast flight and recording retain their bounded acceptance in `evidence/M1_ACCEPTANCE.md`. The source checkpoint is commit `fd5a1cc`, tag `vs01-technical-1`; its package is `builds/VS01-verified-macOS.zip`. All six M1 regressions remain clean: **2,452 regular assertions plus 15,262 swept flight-clearance checks**. The following recorded gameplay/performance figures apply to VS01, not to the new chapter.

| Gate | Evidence and result |
|---|---|
| Rules | 2,091 checks pass, including full solution, invalid transitions, state invariants and corrupted saves. |
| Durable profiles | 38 checks pass: legacy migration, backup-only recovery, safe corruption fallback, interrupted flights, retained earned completion. |
| Scene safety | 62 checks pass: prospective solid overlap, occupied supports, pause/controls/resume and title roundtrips during resize, optional discovery after launch preparation, protected launcher/window while aboard. |
| Scene recovery | 170 checks pass: actual reset/respawn/visual restoration at all checkpoints, milk recovery, return crossings both directions, interrupted-flight reload and exploration history. |
| Settings | 91 checks pass: live volume/comfort controls, persistence, key conflicts, remapped prompts/hints/footer, large text layouts and invalid numeric/key recovery. |
| Flight clearance | 15,262 conservative swept mesh checks pass through the real cereal window. Minimum conservative clearance: 0.0852 scene units. |
| Playable route | Source and standalone native app input replays complete all 15 route checks, including the picnic and finale. Harness moves through Input actions; it does not teleport Pip or write puzzle state. |
| Visual consistency | Six native views, prop-state atlas, menu captures, matched table optimization comparison, and source/target distinction are recorded in `evidence/VISUAL_REVIEW.md`. |
| Contrast | Five opaque HUD palette pairs exceed 4.5:1 (minimum 5.347:1). `evidence/ui_contrast.json`. This is a bounded design check, not accessibility certification. |
| Recording | 36.9-second actual Movie Maker playthrough, 2,214 frames at 60 FPS, H.264/AAC; all 15 checks pass and the MP4 fully decodes. `evidence/recording/verification.json`. |
| Preserved M1 package | Universal arm64/x86_64 app and ZIP; 47 actual PCK resources/digests verified at the preserved checkpoint; strict signature checked outside Desktop's metadata-injecting FileProvider. The subsequent W01S01 and W01S02 packages contain 63 and 73 resources respectively. |
| Audio | Original effects and 20-second loop generated, decoded and integrated. Separate music/effects controls tested. Subjective audition remains unverified. |
| Human/device review | Enjoyment, first-time duration, physical gamepad and subjective aesthetic review remain pending. Desktop CUA inspection could not proceed because OS Accessibility/Screen Recording permissions were unavailable. Dedicated engine captures and native input replays remain independently verified. |

## Performance and support

Reference machine: MacBook Pro, Apple M4 Pro (14 CPU cores, 20 GPU cores), 48 GB RAM. Godot 4.5.1 Compatibility renderer through native OpenGL/Metal. No universal hardware claim is made.

The first exported 1280×720 run measured raw wall-clock frame spacing after a two-second warmup: p50 16.684ms, p95 18.139ms, p99 21.744ms, with 2,443 samples and a 648-draw-call peak. Static table batching subsequently reduced its isolated draw calls from 131 to 23 (82.44%). Matched 1920×1080 captures differ in only 77 of 2,073,600 pixels, with no visible difference at the reviewed scale. Normals were corrected before accepting this change. The HUD avoids rebuilding unchanged styles every frame.

The optimized exported route in `evidence/final_1280/replay_report.json` passed all 15 checks and peaked at 524 draw calls / 766 rendered objects. Its uncapped wall-clock spacing was p50 2.819ms, p95 3.240ms, p99 3.412ms across 11,972 samples. Display pacing was not recorded for that earlier run, so the timing difference must not be attributed solely to batching.

The shipped project now defaults to a 60 FPS cap with VSync enabled. `evidence/capped_1280/replay_report.json` verifies the effective cap and completes all 15 checks: p50 16.665ms, p95 17.342ms, p99 21.398ms across 2,012 samples. The display reports 120Hz at 2× scale; the once-per-second FPS monitor's median is 60. This automated native window was unfocused and the measurements include synchronous PNG-capture stalls. A separate capture-free 1920×1080 run passes all 15 route checks with p50 16.675ms, p95 17.577ms and p99 19.908ms across 2,025 samples. Its 34 sampled FPS readings are all 60; the engine processing-interval peak reaches 14.611ms. The app requested foreground activation, but all 34 focus samples remain false, so this is explicitly an unfocused native measurement (`evidence/performance_1080/replay_report.json`). These are measured conditions, not a guarantee that every frame takes at most 16.67ms.

The report distinguishes raw frame spacing from Godot's once-per-second processing maxima, which include draw work/waits and are not OS CPU utilization or GPU time. Power consumption has not been measured. Movie-mode timings are explicitly labeled and must not be treated as real-time performance.

Review sizes are 1280×720 and 1920×1080. English and keyboard/mouse are the tested presentation/input path. Gamepad controls are mapped but physical hardware remains untested. The source includes configurable controls, progressive hints, local reset, reduced motion, text size and independent music/effects volume. Simplified Chinese and campaign-wide accessibility validation remain planned.

## Reproduce and interpret

Run `./scripts/check.sh` for all eleven suites: six retained M1 suites, three Crumb/profile suites and two Ballast suites. Run `./scripts/build_macos.sh` for the native app. `tests/replay_export.gd` exercises the packaged VS01 route with an external, excluded test harness; `tests/chapter/replay_crumb.gd` exercises Crumb Crossing and `tests/chapter/replay_ballast.gd` exercises Blueberry Ballast. `tests/chapter/test_workshop_capture.gd` reproduces native menu fixtures. `./scripts/record_route.sh` records the VS01 route and encodes an MP4.

Concept PNGs are explicitly labeled aspirational. Native images show actual generated meshes; route recordings show actual game behavior. Automated completion does not establish human enjoyment or the brief's 8–12-minute first-time duration hypothesis. The toy materials are intentionally simpler than the concept's fabric/paper microtexture and indirect lighting. No “world-class” aesthetic score has been claimed.
