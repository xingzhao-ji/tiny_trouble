# W01S03 Milk Harbor · Technical acceptance

**Available W01S03 technical gates are accepted within the evidence below.** Milk Harbor is implemented in source and the current stable local macOS package, version **0.2.2**. Crumb Crossing, Blueberry Ballast and Milk Harbor are three of the five Breakfast stages and three of the exact sixty campaign stages. M2 remains active; The Jam Detour and Toast Express remain unavailable. TT-026 The Jam Detour is the queued next task in `docs/W01S04_IMPLEMENTATION.md`.

## Preserved package

- Artifact: `builds/W01S03-verified-macOS.zip`.
- SHA-256: `a1411379fdacbdf8d89b6897f2fb3768e484b5b241ef164c5cb7597cb50bee89`.
- Version: 0.2.2; **81** audited runtime PCK resources and matching payload digests; universal arm64/x86_64 binary and prearchive ad hoc signature verification pass in `evidence/harbor_build.log`.
- Source checkpoint: tag `w01s03-technical-1`.
- Earlier W01S02/W01S01/VS01 verified ZIPs remain preserved. This is a local artifact without notarization or public publishing.

## Functional and recovery gates

| Scope | Result and evidence |
| --- | --- |
| Harbor pure rules | **2,791 checks pass**: draft, phase/passenger/dock invariants, resize refusal, canonical checkpoints and strict snapshot validation. `evidence/test_harbor_state.log`. |
| Actual Harbor scene | **147 checks pass in source and actual package**, with clean exits/logs. Actual body/feet vertices and bidirectional shell/ring/deck contacts, cargo/mooring states, both boarding directions, hull lift, shallows, checkpoints 0–3, walking-rim stop, jump/splash recovery, interrupted disk saves/notices, menus and atomic completion failure/retry. `evidence/harbor_scene_test.log`, `evidence/harbor_export/scene_checks.log`. |
| Ordinary-input route | Source 1280, regenerated final-geometry source 1920 and actual packaged 1920 each **PASS11**. Raft enlargement, boarding, grounded shoal, cargo reduction, onward voyage, unfolding dock, disembarkation and flag completion execute through ordinary input. Only prior-stage completion is seeded. `evidence/milk_harbor/`, `evidence/harbor_1920/`, `evidence/harbor_export/`. |
| Workshop/navigation | **307 checks and six native frames pass in source and actual package**. Real Button.pressed transitions preserve isolated chapter/settings/demo paths and a seeded shoal snapshot. Locked Harbor cannot bypass W01S02; Play/Continue/Replay reflects the profile, while W01S04/W01S05 stay disabled even in all-completed fixtures. `evidence/workshop_harbor/`, `evidence/workshop_harbor_export/`. These are explicit fixtures, not stage-solution evidence. |
| Complete regression run | All **thirteen suites pass**, exit 0, in `evidence/harbor_regression.log`: **10,178 regular assertions = 7,240 retained + 2,791 Harbor rules + 147 Harbor scene**, plus **15,262** separately counted swept flight-clearance checks. Native art/menu assertions are separate. Crumb scene coverage remains 223. |

The scene uses authored transit and draft states with exact supports. Interrupted voyages restore canonical checkpoints with an explanatory notice. Local reset, replay and navigation retain earned chapter history; completion and its snapshot commit atomically. Scene probes are bounded checks, not every-frame contact certification.

## Visual review and recording

All **ten source 1280 views, ten regenerated final source 1920 views, ten actual packaged 1920 views and five actual encoded movie samples** were reviewed. Dock/ring/wafer/rim, water and copy findings are resolved; no new concrete art defect remains in this reviewed scope. Earlier 1920 source views preceded the final geometry and are superseded. `evidence/milk_harbor/VISUAL_REVIEW.md` records the art review. The separate Harbor art studio passes 38 checks.

All six source and six packaged workshop views were also inspected. The 470px menu fits default and maximum 1.25 text settings at 1280×720/1920×1080, with a maximum logical height of 654; no clipping or Pip/drawer overlap was observed. These fixtures use muted music/effects, reduced motion and unfocused windows.

`evidence/Milk-Harbor-playthrough.mp4` records the actual 0.2.2 Movie Maker route, **PASS11**: **14.5 seconds, 870 H.264 frames at 60 FPS, 1280×720**, with **48 kHz stereo AAC**. The 4,942,661-byte movie fully decodes through ffmpeg with exit 0 and no errors. SHA-256: `afbab1e45ab747accf97d12b2b0d9dceca4025abccf067b73779fd580c248dc7`. `evidence/harbor_recording/verification.json` preserves verification; `scripts/record_harbor.sh` reproduces recording.

Reviewed encoded samples are 2.8s preboarding mooring, 8.6s sailing, 11.2s settled open dock, 12.1s Pip at the bowl and 12.6s descending past the rim. These five samples do not constitute a full uninterrupted motion review. Automated route duration is not first-play duration, and movie cadence is not real-time performance.

## Measured performance and limits

The capture-free packaged 1920×1080 run **PASS11** records **697 frame intervals**, p50/p95/p99 **16.664/18.148/18.621ms**, with peaks of **378 draws/622 objects**. Default cap 60/VSync and FPS-monitor p50/p95/max 60 are recorded. All **12 focus samples are unfocused**. The native Apple M4 Pro/macOS 26.6.2 run made no PNG requests, used no movie mode and started without competing Godot/ffmpeg processes; ordinary save/report I/O remains. `evidence/harbor_performance/replay_report.json`, `evidence/harbor_performance.log`.

These measurements do not guarantee every frame within 16.67ms, other-hardware performance or foreground hands-on feel. Human enjoyment, first-play timing, subjective audio balance, physical controller hardware, foreground control feel and full uninterrupted motion quality remain unverified. Those limits do not convert the remaining 57 campaign plans into completed content.
