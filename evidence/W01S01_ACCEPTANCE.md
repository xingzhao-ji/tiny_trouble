# W01S01 technical checkpoint

Crumb Crossing and the minimal Matchbox Workshop meet their available bounded technical gates on the recorded Mac. M2 remains active: only the first of five Breakfast stages is implemented, and only one of sixty main campaign stages. The original VS01 demo is separate.

- Current native Mac package version 0.2.0: 63 runtime resources audited against source bytes, universal executable, ad hoc signature verified before archiving.
- Preserved package: `builds/W01S01-verified-macOS.zip`, SHA-256 `de29738d39d92fe3f7d2a481e7021951506e42caaeac76001ae048275066aa8f`.
- [Packaged input route](crumb_export/replay_report.json): PASS10, ordinary input with no teleports or puzzle-state writes; final title and completion copy visually reviewed.
- [Packaged scene checks](crumb_export/scene_checks.log): PASS223, including recovery, occupied supports, completion write retry and stage/workshop/demo round trips preserving isolated settings/profiles.
- 881 pure stage rules +365 chapter profile +223 scene checks =1469 chapter assertions. All three source suites pass in `test_crumb_state.log`, `test_chapter_progress.log` and `test_crumb_scene.log`.
- Existing M1 regressions remain passing after launcher integration: 2452 regular assertions plus15262 swept flight checks. `scripts/check.sh` now includes all nine suites.
- [Stage visual review](crumb_crossing/VISUAL_REVIEW.md), [21 art checks](crumb_art/art_report.json), [201 workshop checks](workshop/capture_report.json) preserve their exact scopes and view sizes.

These results do not establish human enjoyment, first-play duration, subjective audio balance, physical gamepad operation or focused foreground hands-on feel. Chapter stills are not a performance benchmark. M1's recording and performance data remain historical demo evidence. Public distribution/notarization has not been performed.

Next approved work is W01S02 Blueberry Ballast, followed by Milk Harbor, The Jam Detour and Toast Express. Preserve this build while implementing and validating each distinct stage.
