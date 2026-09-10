# Tiny Trouble quality checkpoint

**VS01 Toast Express is a runnable native demo.** The three puzzles, optional picnic, toast flight, save/recovery and replay are implemented. The five-stage Breakfast Chapter, Matchbox Workshop, and the rest of the 60-stage campaign are not implemented. Available M0/M1 technical gates are recorded in `evidence/M1_ACCEPTANCE.md`; M2 Breakfast Chapter is next.

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
| Native package | Universal arm64/x86_64 app and ZIP; 47 actual PCK resources/digests verified; strict signature checked outside Desktop's metadata-injecting FileProvider. |
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

Run `./scripts/check.sh` for the headless regression suites. Run `./scripts/build_macos.sh` for the native app. `tests/replay_export.gd` exercises the actual packaged game with an external, excluded test harness; see README for its command. `./scripts/record_route.sh` records that input route and encodes an MP4.

Concept PNGs are explicitly labeled aspirational. Native images show actual generated meshes; route recordings show actual game behavior. Automated completion does not establish human enjoyment or the brief's 8–12-minute first-time duration hypothesis. The toy materials are intentionally simpler than the concept's fabric/paper microtexture and indirect lighting. No “world-class” aesthetic score has been claimed.
