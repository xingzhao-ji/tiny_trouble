# Version 0.2.3 · actual Mac package review

**Functional checks pass; mobile presentation is not accepted.** All 26 existing package PNGs were inspected directly: ten Harbor desktop frames at 1920×1080, ten Harbor touch-layout frames at 844×390, and six workshop frames at 1280×720/1920×1080. No renderer or capture process was launched for this review. The frozen 0.2.3 sustained measurement continues independently; 0.2.2 remains the stable checkpoint.

| Evidence | Verified scope |
| --- | --- |
| `harbor_desktop/replay_report.json` | Actual Mac package, 11 ordinary keyboard-input route checks; ten still frames reviewed. No new concrete bounds, contact-pose or focus-label defect observed in these views. |
| `harbor_touch/replay_report.json` | Actual Mac package, 11 route checks using injected ScreenTouch/ScreenDrag for gameplay and injected mouse for the title button; ten still frames reviewed. Native Mac viewport simulation, not physical touch or iOS Simulator. |
| `workshop/capture_report.json` | 319 actual-package assertions and six reviewed native captures. Isolated fresh/saved/cleared profile fixtures, actual Button.pressed transitions and preserved save/settings paths. Menus and Pip/drawer fit; two future entries remain unavailable. These fixtures do not constitute earned gameplay routes. |
| `../platform_packaged_lifecycle.log` | 134 headless actual-package checks using injected application notifications, separate from visual review. |

## Open findings

| ID | Observation and evidence | Required closure |
| --- | --- | --- |
| UI-027-01 | The centered toast fully hides Pip and the parcel in `harbor_touch/aboard.png`; `opening.png`, `raft_ready.png`, `grounded.png` and `lightened.png` also obscure the main interaction or its changed state. `dock_open.png` cuts across Pip's upper body. UI-to-UI bounds checks passed while this world-space visibility defect remained. | Measure projected Pip/cargo mesh bounds after the frame is drawn during the actual touch route, including the live toast. Reposition/limit the toast and review new default/max-text captures and uninterrupted boarding/draft/docking motion in the corrected package. |
| UI-027-02 | The top objective card retains blank height after shorter objectives, clearly visible in `aboard.png` and `dock_open.png`. It consumes scarce phone view space without conveying more information. | Recompute its minimum height after objective changes; verify long-to-short transitions, text 1.0/1.25 and safe insets in a fresh package. |

Root reports source changes for both findings; those changes are **untested here** and are not present in this frozen 0.2.3 evidence. The planned 0.2.4 follow-up must produce fresh evidence. Existing PNGs and route reports are preserved.

`review.json` hashes every reviewed PNG and supporting package report/log. The still review does not establish uninterrupted animation/transition quality, subjective music or effects balance, physical device usability, accessory/controller behavior, human enjoyment or sustained performance. Core audiovisual acceptance is a prerequisite for content expansion; see [the presentation gate](../../docs/PRESENTATION_GATE.md). The 1,265 source adaptive checks cover UI bounds and a Crumb interaction fixture, not Harbor actor visibility.
