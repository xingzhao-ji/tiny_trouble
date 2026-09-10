# Tiny Trouble checkpoint

**Working package: 0.2.6; stable 0.2.2 separately preserved.** M2, TT-027 platform foundation and TT-028 audiovisual acceptance remain open. Three of sixty campaign stages retain their bounded technical checkpoints; 57 remain planned. TT-026 The Jam Detour is paused and its drafts remain unavailable.

The actual distributed Mac app passes **1,392 targeted checks** with clean full logs: mobile Workshop 825/20 captures, desktop Workshop 319/6, orientation 23, settings 91 and lifecycle 134; manual Workshop startup/isolation also passes. UI-027-04 saved-text scaling and UI-027-05 portrait navigation are corrected functionally; **all 26 package frames are reviewed**, closing UI-027-04/05 within the tested Mac viewport/input and still scope. [0.2.6 evidence](evidence/PLATFORM_026_ACCEPTANCE.md) records package hashes and test scope.

The chronology is preserved: exported 0.2.5 PCK hosted by editor failed 732/71; initial 0.2.6 source mobile 825/20 passed; additional early-layout/audio-drain portrait races reproduced 20/2, then fixed source 23/0 passed. The final actual app covers that corrected code. These failures navigated to a guarded Crumb title; gameplay did not start. Earlier 0.2.5 Harbor/UI/movie/profile checks and the full 15-suite source result are prior evidence, not new 0.2.6 reruns.

Both 0.2.6 Mac and Windows exports pass **85-resource/digest audits**; Mac also passes universal architecture/prearchive signature. Windows execution remains unverified. iOS preflight exits 2 for a missing real Team ID; no exported/signed iOS project. Local Figma synchronization passes 266 checks with unchanged tokens; actual Figma execution remains unverified. The actual 0.2.6 ten-minute attempt **FAILED** on `native_focus_lost` at 106.994 measured seconds after 60.017 seconds of valid active warmup. Its 6,417 retained frames and 9 completed flights are partial diagnostics, not sustained acceptance. The external cause is unknown. A bounded log query found no display/sleep/wake event; no immediate unchanged-condition repeat is planned. Prior 0.2.5 focused 120-second PASS and failed 0.2.3 twenty-minute workload stay separately recorded.

**Presentation acceptance precedes more content.** Human judgment at normal display size without zoom, representative-player feedback, subjective audio, uninterrupted motion and physical-device input remain unverified. The audience question is pending. The Workshop's roof-label/drawer coverage remains a human composition question; fine-detail aliasing is a later inspection item, with no rendering change claimed. [Player protocol](docs/PLAYER_VALIDATION.md) · [platform plan](docs/PLATFORM_PLAN.md) · [presentation matrix](docs/PRESENTATION_GATE.md).

## Launch and build

```sh
./scripts/setup.sh
./run.command
./scripts/build_macos.sh
```

Setup is needed only when the project-local Godot 4.5.1 runtime is absent. On the title screen choose **Visit the Matchbox Workshop**, then Crumb Crossing, Blueberry Ballast or Milk Harbor. Ballast unlocks after W01S01, Harbor after W01S02; both show Play/Continue/Replay based on saved progress. The hub also returns to the original demo. The Jam Detour and Toast Express remain unavailable. Stage-four drafts are isolated under `development/paused_w01s04/` behind `.gdignore` and export exclusions.

The working Mac paths `builds/Tiny Trouble.app` and `builds/Tiny-Trouble-macOS.zip` contain **0.2.6**, with 85 audited resources/digests, universal binaries and prearchive signature. `evidence/PLATFORM_026_ACCEPTANCE.md` records current actual-app gates/hashes; 0.2.5 is retained separately at commit `436967e` and `builds/platform-0.2.5-candidate-macOS.zip`. Stable 0.2.2 remains in `builds/W01S03-verified-macOS.zip`; rejected 0.2.3/0.2.4 ZIPs have distinct preserved names. These are local artifacts without public distribution.

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

1. Retain the final 0.2.6 targeted checks and 26 reviewed package frames. Retain the aborted ten-minute workload and investigate conditions before deciding on another run; keep the sustained gate open.
2. Continue the audiovisual matrix: normal-size human composition/material/expression review, fine-detail aliasing inspection, actual music/effects audition and uninterrupted playback. Record manual Workshop/Crumb feedback with isolated profiles; keep real-device/Figma dependencies explicit.
3. Resume TT-026 only after required presentation acceptance. Stage-four drafts stay unavailable and M2 stays incomplete.

`check.sh` now lists fifteen suites. Its last full run passed 10,371 regular assertions +15,262 sweep checks before the final target-card adjustment; subsequent source/package UI 1,293 and route 14, package settings 91/lifecycle 134 passed separately. The preserved thirteen-suite result below is historical. Confirmed Harbor results are **2,791 pure rules and 147 final source scene checks**; the full runner passes 10,178 regular assertions plus 15,262 swept checks in `evidence/harbor_regression.log`. The preserved W01S03 workshop passed **307 native checks and six reviewed captures** at 1280/1920 with text 1.0/1.25; source and actual package Button.pressed transitions retain isolated settings and the complete seeded shoal snapshot. Its menu remains 470px wide and at most 654 logical pixels high. Crumb scene/navigation still passes 223. The preserved W01S02 eleven-suite result is 7,240 regular assertions plus 15,262 swept checks (M1 2,452; Crumb/profile/scene 1,505; Ballast 3,283). Historical W01S02 art/workshop counts remain 28/247, and the W01S01 baseline remains 881/1,469, art 21 and workshop 201; new checks do not rewrite earlier artifacts.

The preserved VS01 recording passes 15 checks and fully decodes. M1 performance figures apply only to its measured M4 Pro conditions; native windows remained unfocused. The W01S02 capture-free packaged 1920×1080 run passes 10 checks with 972 intervals: p50/p95/p99 16.651/18.327/18.671ms, peaks of 336 draws/585 objects, default 60 cap/VSync, all 17 focus samples false. No PNG stalls were included; ordinary I/O remained. Its verified MP4 is 19.083333 seconds/1,145 frames at 60 FPS, 1280×720 H.264 with 48 kHz stereo AAC; 10 route checks and full decode pass. This is automated route duration, not first-play timing; movie cadence is not performance. `evidence/ballast_recording/verification.json`. Human enjoyment, first-time duration, subjective audio balance, foreground hands-on feel and physical controller hardware remain unverified. Work proceeds during active authorized execution only; this file does not indicate a background development service.

The preserved W01S02 technical visual review is bounded to nine route captures and four encoded samples; full uninterrupted motion quality and subjective audio remain unclaimed. `evidence/W01S02_ACCEPTANCE.md`.

Harbor movie route PASS11 and full decode pass: `evidence/Milk-Harbor-playthrough.mp4`, 14.5 seconds/870 H.264 frames at 60 FPS, 1280×720, with 48 kHz stereo AAC. `evidence/harbor_recording/verification.json`. Five actual encoded samples are reviewed; final stage visual closure is complete within the reviewed scope. Movie duration/cadence do not measure first play or real-time performance.

The capture-free packaged 1920×1080 Harbor run passes 11 checks: 697 frame intervals measure p50/p95/p99 **16.664/18.148/18.621ms**, with peaks of 378 draws/622 objects. Default cap 60/VSync and FPS-monitor p50/p95/max 60 are recorded; all 12 focus samples are unfocused. This native M4 Pro/macOS 26.6.2 run makes no PNG requests and is outside movie mode; ordinary save/report I/O remains. It started without competing Godot/ffmpeg processes. These conditions do not establish every-frame 16.67ms, foreground hands-on feel or another-hardware performance. `evidence/harbor_performance/replay_report.json`.

The 0.2.2 package is preserved as `builds/W01S03-verified-macOS.zip`, SHA-256 `a1411379fdacbdf8d89b6897f2fb3768e484b5b241ef164c5cb7597cb50bee89`. Source checkpoint: commit `9da8d5a`, tag `w01s03-technical-1`. Prior W01S02/W01S01/VS01 ZIPs remain preserved. `evidence/W01S03_ACCEPTANCE.md` records the current gate scope.

Human enjoyment, satisfaction and demand remain **UNVERIFIED**. The audience question is pending. [Player validation](docs/PLAYER_VALIDATION.md) separates owner requirements, observed bugs and agent hypotheses, and requires recurring representative feedback plus human judgment of Pip/props/environment/UI at normal display size without zoom. No automatic beauty score or test count closes that gate. Preserved 0.2.5 source/package UI passes 1,293/28 each; final 0.2.6 Workshop checks are separately recorded above.
