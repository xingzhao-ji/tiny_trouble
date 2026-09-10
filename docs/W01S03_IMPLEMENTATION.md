# W01S03 · Milk Harbor implementation record

**Status: source implemented; available technical gates verified.** TT-025 is verified through its available gates; TT-026 The Jam Detour is queued next. W01S01 and W01S02 retain verified checkpoints; Milk Harbor is the third source-implemented campaign stage. Its 2,791 pure rules, 147 final scene checks, two 11-check source routes and 307-check source workshop capture/navigation suite pass. Version 0.2.2 is now the stable local package; the prior verified W01S02 ZIP remains preserved. M2 is not complete.

| Field | Record |
| --- | --- |
| Task | TT-025 · W01S03 Milk Harbor |
| Parent | M2 · Breakfast Chapter |
| Requirements | SCALE-01, PLAY-01, QUALITY-01 |
| Observed need | The chapter needs its distinct third stage; the existing ramp puzzle does not demonstrate raft draft or cargo clearance. |
| Player benefit | See cargo size change a raft's waterline, use that change to clear a visible shallow ridge, and recover safely from experiments. |
| Prerequisite | W01S02's available technical gates passed; source checkpoint `a7561b5`, tag `w01s02-technical-1`. |
| Scope boundary | One cereal-loop raft, one paper cargo parcel, one authored near-bank → shoal → far-bank journey, and its spoon dock. Reuse existing input, audio, settings, navigation and chapter persistence. No general fluid simulation or later-stage implementation. |

The preserved prior artifact is `builds/W01S02-verified-macOS.zip`, version 0.2.1, SHA-256 `29bc3da9154801aa5998f13885856c3783d29c62dc0df0068b05339c79f832d8`. Its evidence remains scoped to W01S02 in `evidence/W01S02_ACCEPTANCE.md`; it does not establish Milk Harbor results.

## Authored puzzle

The cereal loop begins at Normal size beside the near bank, with a paper cargo parcel on its deck. Enlarging the loop makes a boardable raft. Pip boards at the near bank, then uses the interact action, default **E**, to push off on a short controlled journey to a visible shallow ridge.

At the shoal, Normal or Large cargo leaves the raft grounded. Shrinking the cargo to Small raises the raft's waterline enough to clear the ridge. The lower cargo load, changing draft and exposed ridge must explain the result visually; hidden clearance rules do not become numerical instructions in the player UI. With Small cargo, **E** continues to the far bank.

Arrival visibly unfolds the spoon dock. Pip uses **E** to disembark around the cargo onto shore, then reaches the flag to complete the stage. Arrival and disembarkation must not silently award completion before the flag. Optional cereal creatures greet Pip or applaud; their reactions do not gate progress.

Motion and support are authored: a controlled raft path, explicit draft/clearance states and exact player/deck/dock contacts. Experiments at a safe mooring remain reversible. All resizing is refused during transit; raft resizing is also refused while Pip is aboard or once the raft has left the near bank. A refusal explains the current reason and leaves state and geometry unchanged.

## State and checkpoints

The implemented `HarborState` contract has phases `near`, `to_shoal`, `shoal`, `to_far` and `far`, with explicit `aboard` and `dock_open` state. Transit phases require the established controlled movement and a supported passenger. The spoon dock opens only on far-bank arrival. Final source geometry uses shifted moorings and a raised, offset dock. The 147-check scene suite verifies bounded actual mesh/support and transition contacts; actual packaged scene checks also pass 147. All ten source 1280 views, ten regenerated source 1920 views, ten actual package 1920 views and five actual encoded samples are reviewed. Dock/ring/wafer/rim, water and copy findings are resolved; no new concrete art defect remains in that scope. Full uninterrupted motion quality and subjective audio remain unclaimed.

| Checkpoint | Canonical arrangement | Recovery intent |
| --- | --- | --- |
| 0 · Opening | Normal raft at the near bank, Normal cargo, Pip safely ashore, dock closed. | Restore a readable introduction and access to raft resizing. |
| 1 · Raft ready | Large raft at the near bank, Normal cargo, Pip safely ashore, dock closed. | Keep the completed enlargement and restore a safe boarding approach. |
| 2 · Shoal | Large raft moored at the shoal, Pip aboard, Normal cargo, dock closed. | Retain the first journey while exposing the cargo/draft decision. |
| 3 · Far bank | Large raft at the far bank, Small cargo, dock open, Pip disembarked safely ashore. | Preserve the crossing and provide a stable approach to the completion flag. |

An interrupted journey restores the last canonical checkpoint and gives an explanatory notice, rather than loading an unsupported transit pose. Reset, fall recovery, pause/title/reload and interrupted resizing must restore coherent phase, raft/cargo sizes, passenger support and dock pose. A recovered transit must never invent far-bank arrival, disembarkation or earned completion.

Stage snapshot validation must reject malformed types, invalid sizes/phases, impossible passenger/dock dependencies and incompatible versions without partially mutating live state. Reuse the chapter profile's atomic completion-plus-snapshot commit and good-backup recovery. Failed durable completion remains retryable; earned history survives replay, reset and navigation. Tests use isolated chapter, demo and settings paths. Unlocking later profile slots does not enable unavailable stage content.

## Implementation responsibilities

- Runtime owner: physical geometry, board/disembark actions, passenger support, controlled journeys, draft/contact states, resize refusals, feedback, checkpoints and stage/hub integration.
- Asset owner: cereal-loop raft and paper parcel, readable milk channel and shallow ridge, visible waterline change, unfolding spoon dock and optional creature reactions in the established toy palette.
- Rules owner: pure phase/passenger/dock invariants, draft decision, canonical checkpoints, interrupted-transit recovery and strict snapshot validation.
- Production record: preserve this bounded task and add acceptance results only after reported evidence exists.

## Acceptance work

| Gate | Required evidence | Current result |
| --- | --- | --- |
| Pure rules | Normal/Large cargo grounds the raft; Small cargo clears; valid phase transitions; all transit resize refusals; raft resize guards; canonical recovery; malformed snapshot rejection. | PASS: 2,791 checks. `evidence/test_harbor_state.log`. |
| Actual scene and recovery | Real deck/passenger support throughout transit; visible draft and ridge clearance; no unsafe overlaps; dock unfolds on arrival; safe disembarkation around cargo; reset/fall/title/reload and interrupted journeys restore the stated checkpoint. | PASS: 147 final source checks, clean exit/log. Actual body/feet and shell/ring/deck probes, all cargo/mooring states, both boarding directions, shifted moorings/raised offset dock, grounded-rim walking stop, jump/splash, checkpoints and interrupted disk recovery. `evidence/harbor_scene_test.log`. Actual packaged scene suite also PASS147; `evidence/harbor_export/scene_checks.log`. |
| Chapter durability/navigation | Isolated paths survive hub/demo/stage button transitions; W01S02 prerequisite and Play/Continue/Replay are truthful; atomic flag completion is retryable and retains history; unbuilt later stages stay disabled. | PASS in source: 307 workshop checks and six reviewed captures, actual Button.pressed Harbor/hub/demo roundtrips, isolated paths/settings and exact seeded shoal snapshot. Source scene tests cover atomic completion failure/retry; Crumb regression remains 223. Actual package PASS307 with six reviewed workshop images; no observed menu clipping or Pip/drawer overlap. |
| Source native route | Fresh ordinary input grows the raft, boards, reaches the shoal, demonstrates grounding, shrinks cargo, continues, disembarks and reaches the flag without direct puzzle-state injection or teleporting. Optional reactions remain optional. | PASS: 11 ordinary-input checks at 1280×720 and regenerated final-geometry 1920×1080. `evidence/milk_harbor/replay_report.json`, `evidence/harbor_1920/replay_report.json`. Earlier 1920 captures are superseded. |
| Presentation | Review actual 1280×720 and 1920×1080 scenes, including cargo/raft sizes, grounded and cleared waterlines, Pip contacts, transit, unfolded dock, disembarkation and readable HUD/menu at supported text scale. | Art studio reports 38 checks; source workshop passes 307 with six reviewed frames and menu bounds at text 1.0/1.25. Actual package route PASS11 with ten views. All 30 current source/package views and five encoded samples are reviewed, with dock/ring/wafer/rim, water and copy findings resolved; art studio is separate from final gameplay geometry. |
| Native export | Audit the real package and added resources; repeat the ordinary-input route and actual recovery/navigation checks against the package; retain the verified W01S02 artifact. | Version 0.2.2 PASS: 81-resource PCK/digest/universal/prearchive signature audit, actual route 11/scene 147/workshop 307. Stable W01S02 ZIP remains preserved. |
| Retained regressions | Run the complete existing source suite and any newly added Milk Harbor suites without rewriting historical counts as stage-three evidence. | PASS: all thirteen suites, 10,178 regular assertions (7,240 + 2,791 + 147) plus 15,262 swept flight checks; clean exit. `evidence/harbor_regression.log`. Native art/menu counts remain separate. |

Any recording or performance evidence must report the actual package, resolution, focus state, capture conditions and measured results separately from route correctness. Human enjoyment, first-play duration, subjective audio balance, physical controller hardware, foreground hands-on feel and full uninterrupted motion quality remain unverified unless actually reviewed. W01S04, W01S05 and the wider campaign remain outside this task.

Harbor movie route PASS11 and full decode pass: 14.5 seconds/870 H.264 1280×720 frames at 60 FPS, 48 kHz stereo AAC. `evidence/harbor_recording/verification.json`. Five actual encoded samples are reviewed; final stage presentation closure is complete within the reviewed scope. TT-026 The Jam Detour is queued in `docs/W01S04_IMPLEMENTATION.md` behind the current stage gates; it is not implemented by this task.

The capture-free packaged 1920×1080 Harbor run passes 11 checks: 697 frame intervals measure p50/p95/p99 **16.664/18.148/18.621ms**, with peaks of 378 draws/622 objects. Default cap 60/VSync and FPS-monitor p50/p95/max 60 are recorded; all 12 focus samples are unfocused. This native M4 Pro/macOS 26.6.2 run makes no PNG requests and is outside movie mode; ordinary save/report I/O remains. It started without competing Godot/ffmpeg processes. These conditions do not establish every-frame 16.67ms, foreground hands-on feel or another-hardware performance. `evidence/harbor_performance/replay_report.json`.

The 0.2.2 package is preserved as `builds/W01S03-verified-macOS.zip`, SHA-256 `a1411379fdacbdf8d89b6897f2fb3768e484b5b241ef164c5cb7597cb50bee89`. Source checkpoint: tag `w01s03-technical-1`. Prior W01S02/W01S01/VS01 ZIPs remain preserved. `evidence/W01S03_ACCEPTANCE.md` records the current gate scope.
