# Tiny Trouble quality checkpoint

**M2 Breakfast Chapter is active, with W01S01 Crumb Crossing and a minimal Matchbox Workshop implemented.** The first stage passes its available functional, recovery, native presentation and packaged-route gates. One of sixty campaign stages is implemented; the other 59 remain planned. The hub lists W01S02–W01S05 as unavailable even when profile slots are unlocked. This does not accept the entire five-stage M2 milestone.

## M2 first-stage gates

| Gate | Evidence and result |
| --- | --- |
| Crumb Crossing rules | 881 checks pass for sugar passage, small spoon handling, bridge dependencies, invalid transitions, checkpoint recovery and state restoration. `tests/test_crumb_state.gd`. |
| Chapter profiles | 365 checks pass: sequential completion, isolated snapshots, atomic writes, valid backup recovery, nonfinite/oversized data rejection and future-version protection. Eight added checks verify completion and its snapshot commit together. `tests/test_chapter_progress.gd`. |
| Actual scene recovery/navigation | 223 checks pass in source and in the actual packaged app (`evidence/crumb_export/scene_checks.log`) across physical sugar clearance, handle/bridge guards, local recovery, resize/title transitions, completion save failure/retry and stage/hub/demo navigation. Unique save/settings paths are assigned before scene readiness and preserved through transitions. `tests/test_crumb_scene.gd`. |
| Source and packaged route | Both `evidence/crumb_crossing/replay_report.json` and `evidence/crumb_export/replay_report.json` pass all 10 ordinary-input checks. Pip passes the small sugar, carries the spoon through the cup handle, builds and crosses the bridge, greets optional friends and completes the stage. No teleports or puzzle-state writes; final packaged run exits cleanly. |
| Stage geometry and views | 21 native art geometry/capture checks pass. Eight source route frames were reviewed; the final packaged title/completion frames close both stale background-caption issues. No missing mesh, cropped action or obvious Pip-through-solid defect was observed in the bounded review. `evidence/crumb_art/art_report.json`, `evidence/crumb_crossing/VISUAL_REVIEW.md`, `evidence/crumb_export/`. |
| Workshop | 201 native capture/layout checks and six reviewed PNGs at 1280×720 and 1920×1080. Fresh, saved and cleared fixtures show accurate Play/Continue/Replay text; max text size 1.25 fits. The actual open 3D drawer and Pip remain visible left of the 470px menu. All four future stages stay disabled. `evidence/workshop/README.md`, `evidence/workshop/capture_report.json`. |
| Current native package | Version 0.2.0 exports universal arm64/x86_64 app and ZIP with 63 audited PCK resources and verified payload digests. Both playable scenes and the workshop are included; test/evidence/development files are excluded. `builds/package-audit.json`. |

The chapter regression total is **1,469 assertions** (881 + 365 + 223). Native art and workshop checks are separate visual-fixture scopes; seeded completion fixtures do not mean unbuilt levels were played. Crumb Crossing uses authored sugar scales 0.35/1/2, with large growth refused in the tray, and spoon scales 0.5/1/2. Its checkpoints are opening, past the cube, and bridge ready. The optional crumb greeting and pinwheel reaction do not gate completion. Chapter completion and its final snapshot save atomically in a profile distinct from the demo.

Remaining presentation limits include the carried spoon's overlap with part of Pip's head in projection, small crumb details at gameplay distance, and a stylized nearly flat milk boundary. The first-stage still review does not certify every animated contact. No chapter-specific performance, recording, human enjoyment, subjective audio or physical controller gate is claimed. Workshop windows reported unfocused and used muted capture settings. Next approved stage: W01S02 Blueberry Ballast.

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
| Preserved M1 package | Universal arm64/x86_64 app and ZIP; 47 actual PCK resources/digests verified at the preserved checkpoint; strict signature checked outside Desktop's metadata-injecting FileProvider. Current 0.2.0 package has 63 resources. |
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

Run `./scripts/check.sh` for all nine suites: six retained M1 suites and three chapter suites. Run `./scripts/build_macos.sh` for the native app. `tests/replay_export.gd` exercises the packaged VS01 route with an external, excluded test harness; `tests/chapter/replay_crumb.gd` exercises Crumb Crossing. `tests/chapter/test_workshop_capture.gd` reproduces native menu fixtures. `./scripts/record_route.sh` records the VS01 route and encodes an MP4.

Concept PNGs are explicitly labeled aspirational. Native images show actual generated meshes; route recordings show actual game behavior. Automated completion does not establish human enjoyment or the brief's 8–12-minute first-time duration hypothesis. The toy materials are intentionally simpler than the concept's fabric/paper microtexture and indirect lighting. No “world-class” aesthetic score has been claimed.
