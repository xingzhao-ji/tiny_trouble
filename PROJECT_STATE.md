# Tiny Trouble checkpoint

**New measured Workshop defects remain open in 0.2.5:** UI-027-04 loses saved 1.25 text scaling in the mobile HUD (24 logical font units for labels/status instead of 30), and UI-027-05 allows Enter to navigate from portrait guidance into Crumb Crossing. The separate exported 0.2.5 PCK audit, hosted by the editor binary rather than the distributed app executable, records **732 assertions / 71 failures / 20 captures**: 70 repeated font checks and one portrait-navigation failure; bounds, scrolling, Pip separation and profile preservation pass. All 20 stills are reviewed. Pip stays visible; the centered menu covers much of the roof label/right drawer/workbench, a composition tradeoff awaiting human judgment. Evidence: `evidence/platform_refinement/workshop_mobile_025/`. These are the next 0.2.6 corrections; no production fix is claimed in this checkpoint.

**Current working package: 0.2.5; stable 0.2.2 remains separately preserved.** M2 Breakfast Chapter, TT-027 platform foundation and TT-028 core audiovisual acceptance remain open. Three of sixty campaign stages are implemented and retain their bounded technical checkpoints; 57 remain planned. TT-026 The Jam Detour is paused and its drafts stay unavailable under `development/paused_w01s04/`.

The actual Mac candidate passes **14 max-text Harbor route checks /816 visibility samples** with zero named actor/card/toast overlaps, **1,293 adaptive UI checks /28 captures**, lifecycle **134**, settings **91** and an isolated manual-launch smoke. All **38 actual package PNGs** and three encoded movie samples are reviewed within their stated scope. UI-027-01/02/03 close in this new evidence; rejected 0.2.3 and 0.2.4 artifacts remain preserved. Source also passes route 14/806 and UI 1,293/28, with all 38 source frames reviewed. [The 0.2.5 record](evidence/PLATFORM_025_ACCEPTANCE.md) distinguishes those gates.

Mac and Windows 0.2.5 each pass **85-resource/digest export audits**; Mac also passes universal architecture/prearchive signature. Windows has not run, and phone/tablet views are Mac simulations. The local Figma package passes **247 checks** with 205 static art-provenance checks; actual Figma import is unverified. iOS preflight exits 2 for a missing real Team ID. Source audio feedback 59/lifecycle 134/provenance 16 and the recorded movie's finite/headroom checks pass; subjective audio and full uninterrupted audiovisual review remain open.

A fresh actual 0.2.5 **short focused baseline passes**: 30.02-second active warmup plus 120.02-second measurement, 7,201/7,201 focused frames, zero paused frames and 10 complete flights. p50/p95/p99 **16.642/17.162/19.084 ms**, max 30.039 ms; active RSS peak 239.8 MiB. This is a prepared VS01 fixture with normal audio/save I/O, not an ordinary-player route or sustained/thermal certification. [The profile](evidence/platform_profile/macos_candidate_025_1080p_120s/README.md) records instrumentation/response/load limits. The frozen 0.2.3 twenty-minute workload failed and its [diagnostic review](evidence/platform_profile/macos_candidate_023_1080p_20m/post_run_review/REVIEW.md) remains unchanged; neither run warrants a material renderer reduction.

**Presentation acceptance precedes more content.** [Player validation](docs/PLAYER_VALIDATION.md) requires owner direction and recurring representative-player feedback, including human judgment of Pip, props, environment and UI at normal display size without zoom. Human enjoyment/satisfaction/demand, actual-device controls and uninterrupted visual/audio quality remain unverified; the audience question is pending. Tests and agent still reviews do not close that milestone. [Platform plan](docs/PLATFORM_PLAN.md) · [presentation matrix](docs/PRESENTATION_GATE.md).

## Launch and build

```sh
./scripts/setup.sh
./run.command
./scripts/build_macos.sh
```

Setup is needed only when the project-local Godot 4.5.1 runtime is absent. On the title screen choose **Visit the Matchbox Workshop**, then Crumb Crossing, Blueberry Ballast or Milk Harbor. Ballast unlocks after W01S01, Harbor after W01S02; both show Play/Continue/Replay based on saved progress. The hub also returns to the original demo. The Jam Detour and Toast Express remain unavailable. Stage-four drafts are isolated under `development/paused_w01s04/` behind `.gdignore` and export exclusions.

The working Mac paths `builds/Tiny Trouble.app` and `builds/Tiny-Trouble-macOS.zip` contain **0.2.5**, with 85 audited resources/digests, universal binaries and prearchive signature. `evidence/PLATFORM_025_ACCEPTANCE.md` records actual package gates and hashes. Stable 0.2.2 remains in `builds/W01S03-verified-macOS.zip`; rejected 0.2.3/0.2.4 ZIPs have distinct preserved names. These are local artifacts without public distribution.

The six actual packaged Harbor workshop frames have been reviewed: labels, focus, status and max-text bounds are clear, and Pip/the drawer remain visible. Both future stages stay disabled. The preserved 0.2.1 ZIP remains unchanged.

```sh
./scripts/check.sh
./run.command --script res://tests/chapter/replay_crumb.gd
./run.command --script res://tests/chapter/replay_ballast.gd
./run.command --script res://tests/chapter/replay_harbor.gd
./run.command --script res://tests/chapter/test_workshop_capture.gd
```

The route uses isolated settings and chapter progress, with ordinary input and physical movement. Native visual tests use explicitly seeded menu/art fixtures; they are not gameplay-route evidence.

## Decisions and durable state

- Crumb Crossing has two principal prop families: a sugar cube at authored scales 0.35/1/2, and a spoon at 0.5/1/2. Large sugar growth is refused inside the paper tray. The small cube opens a real side passage; the small carried spoon fits the cup handle and its large state bridges the saucers.
- Checkpoints are 0 opening, 1 past the sugar cube, and 2 bridge ready. Local reset, falls, pause/title during resizing, completion, exploration and replay restore safe scene states. Greeting the crumb friends and reacting to the pinwheel are optional.
- Blueberry Ballast uses two instances of the blueberry family. Authored channels roll enlarged berries onto two pockets of one cereal flap; both large berries over-raise the ramp. Shrinking either to Small aligns it. Checkpoints are normal starting trays, both large berries loaded, and the aligned Small/Large arrangement. Occupied-ramp guards prevent unsafe mechanism changes; counterweight inspection is optional. Internal mass arithmetic stays out of player UI.
- Milk Harbor uses the authored near/to_shoal/shoal/to_far/far phase sequence, exact raft/passenger/dock supports and cargo-dependent draft. Checkpoints restore the normal near-bank opening, large ready raft, moored shoal with Pip aboard and Normal cargo, or the far bank with Small cargo and Pip disembarked. Interrupted transit restores the last checkpoint with a notice; optional cereal greetings do not gate completion.
- `breakfast_chapter_v1.json` is separate from `toast_express_v1.json`; both use shared `settings.cfg`. Chapter saves validate bounded finite JSON, preserve good backups, reject future versions, and commit completion plus its stage snapshot atomically.
- Completion IDs form an ordered W01S01–W01S05 prefix. Unlocking a profile slot does not enable unimplemented content. Navigation assigns profile/settings paths before scene readiness and preserves isolated test paths through demo/hub/stage roundtrips.
- The workshop is an actual open matchbox drawer with Pip and a miniature workbench. Its 470px menu shows accurate Play/Continue/Replay status; its broader practice/decorations systems remain unbuilt.
- Proven VS01 input, settings, audio and toy-art helpers are reused. Original editable geometry/audio sources remain included; generated images are labeled concepts, separate from engine captures.

## Next three tasks

1. Retain the passing 0.2.5 technical checkpoint and correct measured mobile Workshop UI-027-04/05 in the next candidate and rerun its scoped evidence. Keep the repaired collector's 120-second focused pass separate from the still-open sustained workload/thermal gate.
2. Complete TT-028's composition/materials/character/animation/UI/music/sound/transition reviews and bounded corrections, including human normal-display judgment, actual audio audition and uninterrupted playback. Preserve Figma/Windows/mobile dependencies and use the isolated player protocol when participants are available.
3. Resume TT-026 only after required presentation acceptance. Stage-four drafts remain unavailable; M2 stays incomplete.

`check.sh` now lists fifteen suites. Its last full run passed 10,371 regular assertions +15,262 sweep checks before the final target-card adjustment; subsequent source/package UI 1,293 and route 14, package settings 91/lifecycle 134 passed separately. The preserved thirteen-suite result below is historical. Confirmed Harbor results are **2,791 pure rules and 147 final source scene checks**; the full runner passes 10,178 regular assertions plus 15,262 swept checks in `evidence/harbor_regression.log`. The preserved W01S03 workshop passed **307 native checks and six reviewed captures** at 1280/1920 with text 1.0/1.25; source and actual package Button.pressed transitions retain isolated settings and the complete seeded shoal snapshot. Its menu remains 470px wide and at most 654 logical pixels high. Crumb scene/navigation still passes 223. The preserved W01S02 eleven-suite result is 7,240 regular assertions plus 15,262 swept checks (M1 2,452; Crumb/profile/scene 1,505; Ballast 3,283). Historical W01S02 art/workshop counts remain 28/247, and the W01S01 baseline remains 881/1,469, art 21 and workshop 201; new checks do not rewrite earlier artifacts.

The preserved VS01 recording passes 15 checks and fully decodes. M1 performance figures apply only to its measured M4 Pro conditions; native windows remained unfocused. The W01S02 capture-free packaged 1920×1080 run passes 10 checks with 972 intervals: p50/p95/p99 16.651/18.327/18.671ms, peaks of 336 draws/585 objects, default 60 cap/VSync, all 17 focus samples false. No PNG stalls were included; ordinary I/O remained. Its verified MP4 is 19.083333 seconds/1,145 frames at 60 FPS, 1280×720 H.264 with 48 kHz stereo AAC; 10 route checks and full decode pass. This is automated route duration, not first-play timing; movie cadence is not performance. `evidence/ballast_recording/verification.json`. Human enjoyment, first-time duration, subjective audio balance, foreground hands-on feel and physical controller hardware remain unverified. Work proceeds during active authorized execution only; this file does not indicate a background development service.

The preserved W01S02 technical visual review is bounded to nine route captures and four encoded samples; full uninterrupted motion quality and subjective audio remain unclaimed. `evidence/W01S02_ACCEPTANCE.md`.

Harbor movie route PASS11 and full decode pass: `evidence/Milk-Harbor-playthrough.mp4`, 14.5 seconds/870 H.264 frames at 60 FPS, 1280×720, with 48 kHz stereo AAC. `evidence/harbor_recording/verification.json`. Five actual encoded samples are reviewed; final stage visual closure is complete within the reviewed scope. Movie duration/cadence do not measure first play or real-time performance.

The capture-free packaged 1920×1080 Harbor run passes 11 checks: 697 frame intervals measure p50/p95/p99 **16.664/18.148/18.621ms**, with peaks of 378 draws/622 objects. Default cap 60/VSync and FPS-monitor p50/p95/max 60 are recorded; all 12 focus samples are unfocused. This native M4 Pro/macOS 26.6.2 run makes no PNG requests and is outside movie mode; ordinary save/report I/O remains. It started without competing Godot/ffmpeg processes. These conditions do not establish every-frame 16.67ms, foreground hands-on feel or another-hardware performance. `evidence/harbor_performance/replay_report.json`.

The 0.2.2 package is preserved as `builds/W01S03-verified-macOS.zip`, SHA-256 `a1411379fdacbdf8d89b6897f2fb3768e484b5b241ef164c5cb7597cb50bee89`. Source checkpoint: commit `9da8d5a`, tag `w01s03-technical-1`. Prior W01S02/W01S01/VS01 ZIPs remain preserved. `evidence/W01S03_ACCEPTANCE.md` records the current gate scope.

Human enjoyment, satisfaction and demand remain **UNVERIFIED**. The audience question is pending. [Player validation](docs/PLAYER_VALIDATION.md) separates owner requirements, observed bugs and agent hypotheses, and requires recurring representative feedback plus human judgment of Pip/props/environment/UI at normal display size without zoom. No automatic beauty score or test count closes that gate. Current source and package UI each pass 1,293/28; these are technical gates only.
