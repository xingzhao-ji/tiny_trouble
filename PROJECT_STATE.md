# Tiny Trouble checkpoint

**Active milestone: M2 — Breakfast Chapter.** W01S01 Crumb Crossing and minimal Matchbox Workshop navigation are implemented in source and the 0.2.0 native package. One of the exact sixty main campaign stages is implemented; W01S02–W12S05 remain planned. VS01 and HUB01 are separate from that count.

Crumb Crossing's source and final packaged native routes each pass all 10 ordinary-input checks with clean exits. Chapter rules, durable progress, scene recovery and navigation pass 1,469 assertions; the actual packaged app also passes all 223 scene/navigation checks. Final packaged title/completion review closes both stale-caption issues. W01S01's available bounded gates are verified; the five-stage M2 milestone is not complete.

The original VS01 technical checkpoint remains available at commit `fd5a1cc`, tag `vs01-technical-1`, and `builds/VS01-verified-macOS.zip`. Its accepted route, recording and support limits are preserved in `evidence/M1_ACCEPTANCE.md`; the original demo remains accessible in the current application.

## Launch and build

```sh
./scripts/setup.sh
./run.command
./scripts/build_macos.sh
```

Setup is needed only when the project-local Godot 4.5.1 runtime is absent. On the title screen choose **Visit Matchbox Workshop**, then Play/Continue/Replay Crumb Crossing. The hub also returns to the original demo. The other four chapter buttons remain visibly unavailable regardless of profile unlock state.

The current universal Mac export is `builds/Tiny Trouble.app`; its ZIP is `builds/Tiny-Trouble-macOS.zip`. Version 0.2.0 contains 63 audited PCK resources, including both playable scenes and the hub. These are local ad hoc signed artifacts, not public releases. The preserved M1 package contained 47 resources.

```sh
./scripts/check.sh
./run.command --script res://tests/chapter/replay_crumb.gd
./run.command --script res://tests/chapter/test_workshop_capture.gd
```

The route uses isolated settings and chapter progress, with ordinary input and physical movement. Native visual tests use explicitly seeded menu/art fixtures; they are not gameplay-route evidence.

## Decisions and durable state

- Crumb Crossing has two principal prop families: a sugar cube at authored scales 0.35/1/2, and a spoon at 0.5/1/2. Large sugar growth is refused inside the paper tray. The small cube opens a real side passage; the small carried spoon fits the cup handle and its large state bridges the saucers.
- Checkpoints are 0 opening, 1 past the sugar cube, and 2 bridge ready. Local reset, falls, pause/title during resizing, completion, exploration and replay restore safe scene states. Greeting the crumb friends and reacting to the pinwheel are optional.
- `breakfast_chapter_v1.json` is separate from `toast_express_v1.json`; both use shared `settings.cfg`. Chapter saves validate bounded finite JSON, preserve good backups, reject future versions, and commit completion plus its stage snapshot atomically.
- Completion IDs form an ordered W01S01–W01S05 prefix. Unlocking a profile slot does not enable unimplemented content. Navigation assigns profile/settings paths before scene readiness and preserves isolated test paths through demo/hub/stage roundtrips.
- The workshop is an actual open matchbox drawer with Pip and a miniature workbench. Its 470px menu shows accurate Play/Continue/Replay status; its broader practice/decorations systems remain unbuilt.
- Proven VS01 input, settings, audio and toy-art helpers are reused. Original editable geometry/audio sources remain included; generated images are labeled concepts, separate from engine captures.

## Next three tasks

1. Preserve the verified W01S01/Workshop checkpoint and stable VS01 artifact while starting W01S02 Blueberry Ballast.
2. Give W01S02 distinct ballast decisions, recoverable geometry, durable chapter progress and fresh source/packaged native evidence.
3. Complete W01S03–W01S05 and the required chapter/hub integration before accepting M2 or starting World 2.

`check.sh` runs all nine suites. Current checks: 881 Crumb rules + 365 chapter profiles + 223 scene recovery/navigation = **1,469 chapter assertions**. Native art contributes 21 checks and workshop captures 201. All six M1 regressions remain clean: 2,452 regular assertions plus 15,262 swept flight-clearance checks. These are separate scopes, not a full-campaign acceptance claim.

The preserved VS01 recording passes 15 checks and fully decodes. M1 performance figures apply only to its measured M4 Pro conditions; native windows remained unfocused. Current chapter stills are not a performance benchmark. Human enjoyment, first-time duration, subjective audio balance, foreground hands-on feel and physical controller hardware remain unverified. Work proceeds during active authorized execution only; this file does not indicate a background development service.
