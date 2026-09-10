# Tiny Trouble checkpoint

**Active milestone: M2 — Breakfast Chapter; verified task: TT-025, W01S03 Milk Harbor; queued next: TT-026, The Jam Detour.** Crumb Crossing, Blueberry Ballast and Milk Harbor are implemented and playable in source, connected through the minimal Matchbox Workshop. Three of the exact sixty campaign stages are source-implemented; 57 remain planned. The two unbuilt chapter entries stay disabled regardless of profile unlocks. VS01 and HUB01 are separate from the campaign count; M2 is not complete.

Milk Harbor is implemented in source: grow a cereal-loop raft, board and push off to a visible shoal, shrink its paper cargo to raise the waterline, then continue to an unfolding spoon dock and the far-bank flag. Transit restores canonical checkpoints when interrupted; all resize actions are refused in transit, and raft resizing is refused aboard or beyond the near bank. `docs/W01S03_IMPLEMENTATION.md` records the bounded contract. Harbor rules pass 2,791 checks; the final source scene suite passes 147 checks with clean logs, including shifted moorings, the raised offset dock, actual mesh/boarding contacts, walking-rim refusal and jump/splash recovery. The current 1280 source route passes 11 checks. The regenerated final-geometry 1920 source route also passes 11; earlier 1920 views are superseded. All thirteen suites pass 10,178 regular assertions plus 15,262 swept checks. The actual 0.2.2 package passes the 81-resource audit, route 11, scene 147 and workshop 307 gates. All ten source 1280 views, ten regenerated source 1920 views, ten actual package 1920 views and five actual encoded samples are reviewed. Dock/ring/wafer/rim, water and copy findings are resolved; no new concrete art defect remains in that scope. Full uninterrupted motion quality and subjective audio remain unclaimed. Version 0.2.2 is now the stable package.

Blueberry Ballast passes 3,201 pure-state checks and 82 actual scene checks. Its main and alternate source-native solutions each pass 10 ordinary-input route checks, including optional counterweight inspection. The alternate route predates the final foot-pose correction. Current source contact tests measure zero maximum foot penetration with an actual 0.02-unit threshold. The corrected final package passes 10 route, 82 scene and 247 workshop checks. All nine route frames and four actual encoded samples are reviewed; entry-foot, ramp-lip and copy findings are closed. `evidence/W01S02_ACCEPTANCE.md` records the bounded acceptance.

The original VS01 technical checkpoint is preserved at `fd5a1cc`, tag `vs01-technical-1`, and `builds/VS01-verified-macOS.zip`. W01S01/Workshop is preserved at `4568ced`, tag `w01s01-technical-1`, and `builds/W01S01-verified-macOS.zip`. Its historical 881-rule / 1,469-assertion chapter baseline remains labeled as such. Patch `b118d82` fixes malformed CrumbState stage types, raising current Crumb rules to 917.

W01S02 is preserved at source commit `a7561b5`, tag `w01s02-technical-1`, with the verified ZIP and digest below.

## Launch and build

```sh
./scripts/setup.sh
./run.command
./scripts/build_macos.sh
```

Setup is needed only when the project-local Godot 4.5.1 runtime is absent. On the title screen choose **Visit the Matchbox Workshop**, then Crumb Crossing, Blueberry Ballast or Milk Harbor. Ballast unlocks after W01S01, Harbor after W01S02; both show Play/Continue/Replay based on saved progress. The hub also returns to the original demo. The Jam Detour and Toast Express remain unavailable in source.

The current universal Mac app is `builds/Tiny Trouble.app`; its ZIP is `builds/Tiny-Trouble-macOS.zip`. Stable version 0.2.2 passes the 81-resource PCK/digest, universal architecture and prearchive signature audit, plus actual Harbor route 11/scene 147/workshop 307 checks. All ten source 1280 views, ten regenerated source 1920 views, ten actual package 1920 views and five actual encoded samples are reviewed. Dock/ring/wafer/rim, water and copy findings are resolved; no new concrete art defect remains in that scope. Full uninterrupted motion quality and subjective audio remain unclaimed. The stable prior 0.2.1 package is retained as `builds/W01S02-verified-macOS.zip`, SHA-256 `29bc3da9154801aa5998f13885856c3783d29c62dc0df0068b05339c79f832d8`; its 73-resource checkpoint remains historical. These are local ad hoc signed artifacts, not public releases. The preserved M1/W01S01 packages contained 47/63 resources.

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

1. Preserve the verified Milk Harbor checkpoint and begin queued TT-026 The Jam Detour; `docs/W01S04_IMPLEMENTATION.md` records the bounded plan.
2. Verify Jam Detour's parcel transport, physical supports, recovery, native presentation and source/package progression before advancing to Toast Express.
3. Complete W01S04/W01S05 and required chapter/hub integration before accepting M2 or starting World 2.

`check.sh` now lists thirteen suites. Confirmed Harbor results are **2,791 pure rules and 147 final source scene checks**; the full runner passes 10,178 regular assertions plus 15,262 swept checks in `evidence/harbor_regression.log`. The current workshop passes **307 native checks and six reviewed captures** at 1280/1920 with text 1.0/1.25; source and actual package Button.pressed transitions retain isolated settings and the complete seeded shoal snapshot. Its menu remains 470px wide and at most 654 logical pixels high. Crumb scene/navigation still passes 223. The preserved W01S02 eleven-suite result is 7,240 regular assertions plus 15,262 swept checks (M1 2,452; Crumb/profile/scene 1,505; Ballast 3,283). Historical W01S02 art/workshop counts remain 28/247, and the W01S01 baseline remains 881/1,469, art 21 and workshop 201; new checks do not rewrite earlier artifacts.

The preserved VS01 recording passes 15 checks and fully decodes. M1 performance figures apply only to its measured M4 Pro conditions; native windows remained unfocused. The W01S02 capture-free packaged 1920×1080 run passes 10 checks with 972 intervals: p50/p95/p99 16.651/18.327/18.671ms, peaks of 336 draws/585 objects, default 60 cap/VSync, all 17 focus samples false. No PNG stalls were included; ordinary I/O remained. Its verified MP4 is 19.083333 seconds/1,145 frames at 60 FPS, 1280×720 H.264 with 48 kHz stereo AAC; 10 route checks and full decode pass. This is automated route duration, not first-play timing; movie cadence is not performance. `evidence/ballast_recording/verification.json`. Human enjoyment, first-time duration, subjective audio balance, foreground hands-on feel and physical controller hardware remain unverified. Work proceeds during active authorized execution only; this file does not indicate a background development service.

The preserved W01S02 technical visual review is bounded to nine route captures and four encoded samples; full uninterrupted motion quality and subjective audio remain unclaimed. `evidence/W01S02_ACCEPTANCE.md`.

Harbor movie route PASS11 and full decode pass: `evidence/Milk-Harbor-playthrough.mp4`, 14.5 seconds/870 H.264 frames at 60 FPS, 1280×720, with 48 kHz stereo AAC. `evidence/harbor_recording/verification.json`. Five actual encoded samples are reviewed; final stage visual closure is complete within the reviewed scope. Movie duration/cadence do not measure first play or real-time performance.

The capture-free packaged 1920×1080 Harbor run passes 11 checks: 697 frame intervals measure p50/p95/p99 **16.664/18.148/18.621ms**, with peaks of 378 draws/622 objects. Default cap 60/VSync and FPS-monitor p50/p95/max 60 are recorded; all 12 focus samples are unfocused. This native M4 Pro/macOS 26.6.2 run makes no PNG requests and is outside movie mode; ordinary save/report I/O remains. It started without competing Godot/ffmpeg processes. These conditions do not establish every-frame 16.67ms, foreground hands-on feel or another-hardware performance. `evidence/harbor_performance/replay_report.json`.

The 0.2.2 package is preserved as `builds/W01S03-verified-macOS.zip`, SHA-256 `a1411379fdacbdf8d89b6897f2fb3768e484b5b241ef164c5cb7597cb50bee89`. Source checkpoint: tag `w01s03-technical-1`. Prior W01S02/W01S01/VS01 ZIPs remain preserved. `evidence/W01S03_ACCEPTANCE.md` records the current gate scope.
