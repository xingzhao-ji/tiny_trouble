# Tiny Trouble checkpoint

**Active milestone: M2 — Breakfast Chapter; verified task: TT-024, W01S02 Blueberry Ballast; next implementation: W01S03 Milk Harbor.** Crumb Crossing and Blueberry Ballast are implemented and playable in source, connected through the minimal Matchbox Workshop. Two of the exact sixty campaign stages are source-implemented; 58 remain planned. Three unbuilt chapter entries stay disabled regardless of profile unlocks. VS01 and HUB01 are separate from the campaign count; M2 is not complete.

Blueberry Ballast passes 3,201 pure-state checks and 82 actual scene checks. Its main and alternate source-native solutions each pass 10 ordinary-input route checks, including optional counterweight inspection. The alternate route predates the final foot-pose correction. Current source contact tests measure zero maximum foot penetration with an actual 0.02-unit threshold. The corrected final package passes 10 route, 82 scene and 247 workshop checks. All nine route frames and four actual encoded samples are reviewed; entry-foot, ramp-lip and copy findings are closed. `evidence/W01S02_ACCEPTANCE.md` records the bounded acceptance.

The original VS01 technical checkpoint is preserved at `fd5a1cc`, tag `vs01-technical-1`, and `builds/VS01-verified-macOS.zip`. W01S01/Workshop is preserved at `4568ced`, tag `w01s01-technical-1`, and `builds/W01S01-verified-macOS.zip`. Its historical 881-rule / 1,469-assertion chapter baseline remains labeled as such. Patch `b118d82` fixes malformed CrumbState stage types, raising current Crumb rules to 917.

## Launch and build

```sh
./scripts/setup.sh
./run.command
./scripts/build_macos.sh
```

Setup is needed only when the project-local Godot 4.5.1 runtime is absent. On the title screen choose **Visit the Matchbox Workshop**, then Crumb Crossing or Blueberry Ballast. Blueberry Ballast is locked until W01S01 is completed and then shows Play/Continue/Replay based on saved progress. The hub also returns to the original demo. The other three chapter entries remain unavailable.

The current universal Mac export is `builds/Tiny Trouble.app`; its ZIP is `builds/Tiny-Trouble-macOS.zip`. Final version 0.2.1 passes a 73-resource PCK/digest, universal architecture and signature audit, including the corrected foot-pose and return-roll contact changes. These are local ad hoc signed artifacts, not public releases. The preserved M1 and W01S01 packages contained 47 and 63 resources respectively. The current package is retained as `builds/W01S02-verified-macOS.zip`, SHA-256 `29bc3da9154801aa5998f13885856c3783d29c62dc0df0068b05339c79f832d8`.

```sh
./scripts/check.sh
./run.command --script res://tests/chapter/replay_crumb.gd
./run.command --script res://tests/chapter/replay_ballast.gd
./run.command --script res://tests/chapter/test_workshop_capture.gd
```

The route uses isolated settings and chapter progress, with ordinary input and physical movement. Native visual tests use explicitly seeded menu/art fixtures; they are not gameplay-route evidence.

## Decisions and durable state

- Crumb Crossing has two principal prop families: a sugar cube at authored scales 0.35/1/2, and a spoon at 0.5/1/2. Large sugar growth is refused inside the paper tray. The small cube opens a real side passage; the small carried spoon fits the cup handle and its large state bridges the saucers.
- Checkpoints are 0 opening, 1 past the sugar cube, and 2 bridge ready. Local reset, falls, pause/title during resizing, completion, exploration and replay restore safe scene states. Greeting the crumb friends and reacting to the pinwheel are optional.
- Blueberry Ballast uses two instances of the blueberry family. Authored channels roll enlarged berries onto two pockets of one cereal flap; both large berries over-raise the ramp. Shrinking either to Small aligns it. Checkpoints are normal starting trays, both large berries loaded, and the aligned Small/Large arrangement. Occupied-ramp guards prevent unsafe mechanism changes; counterweight inspection is optional. Internal mass arithmetic stays out of player UI.
- `breakfast_chapter_v1.json` is separate from `toast_express_v1.json`; both use shared `settings.cfg`. Chapter saves validate bounded finite JSON, preserve good backups, reject future versions, and commit completion plus its stage snapshot atomically.
- Completion IDs form an ordered W01S01–W01S05 prefix. Unlocking a profile slot does not enable unimplemented content. Navigation assigns profile/settings paths before scene readiness and preserves isolated test paths through demo/hub/stage roundtrips.
- The workshop is an actual open matchbox drawer with Pip and a miniature workbench. Its 470px menu shows accurate Play/Continue/Replay status; its broader practice/decorations systems remain unbuilt.
- Proven VS01 input, settings, audio and toy-art helpers are reused. Original editable geometry/audio sources remain included; generated images are labeled concepts, separate from engine captures.

## Next three tasks

1. Preserve the verified W01S02 artifact and begin W01S03 Milk Harbor in approved order.
2. Give Milk Harbor distinct raft/cargo decisions, safe recovery, durable chapter progression and source/packaged native evidence.
3. Complete W01S03–W01S05 and required chapter/hub integration before accepting M2 or starting World 2.

`check.sh` runs eleven suites. Current source checks are 917 Crumb rules + 365 chapter profiles + 223 Crumb scene/navigation = **1,505**, plus **3,201 Ballast rules and 82 Ballast scene checks**. Mechanism art contributes 28 native checks; the updated workshop contributes 247 checks and six reviewed captures. All six M1 suites retain 2,452 regular assertions plus 15,262 swept checks, with settings91 rerun after the footer change. The eleven-suite total is 7,240 regular assertions plus 15,262 swept checks. The preserved W01S01 baseline remains 881/1,469, art 21 and workshop 201; new totals do not rewrite historical evidence.

The preserved VS01 recording passes 15 checks and fully decodes. M1 performance figures apply only to its measured M4 Pro conditions; native windows remained unfocused. The W01S02 capture-free packaged 1920×1080 run passes 10 checks with 972 intervals: p50/p95/p99 16.651/18.327/18.671ms, peaks of 336 draws/585 objects, default 60 cap/VSync, all 17 focus samples false. No PNG stalls were included; ordinary I/O remained. Its verified MP4 is 19.083333 seconds/1,145 frames at 60 FPS, 1280×720 H.264 with 48 kHz stereo AAC; 10 route checks and full decode pass. This is automated route duration, not first-play timing; movie cadence is not performance. `evidence/ballast_recording/verification.json`. Human enjoyment, first-time duration, subjective audio balance, foreground hands-on feel and physical controller hardware remain unverified. Work proceeds during active authorized execution only; this file does not indicate a background development service.

Final technical visual review is bounded to nine route captures and four encoded samples; full uninterrupted motion quality and subjective audio remain unclaimed. `evidence/W01S02_ACCEPTANCE.md`.
