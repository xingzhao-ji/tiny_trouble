# W01S02 technical checkpoint

Blueberry Ballast and its workshop integration pass the available functional, recovery, presentation and package checks on the recorded Mac. Two of five Breakfast stages are playable; M2 is still active. Two of the exact sixty main campaign stages are implemented. The separate VS01 demo remains accessible.

## Preserved package

Version 0.2.1 is a universal Mac application with 73 audited runtime resources and verified internal payload digests. Ad hoc signature validation ran before archiving. `builds/W01S02-verified-macOS.zip` has SHA-256 `29bc3da9154801aa5998f13885856c3783d29c62dc0df0068b05339c79f832d8`. This is a local artifact; no public publishing or notarization was performed. The earlier W01S01 and VS01 packages remain separate.

## Executed behavior

- [Final packaged route](ballast_export/replay_report.json): PASS 10 with nine captures, including an actual moving ramp-entry step, optional counterweight inspection and completion. Only the prerequisite W01S01 completion is seeded; W01S02 starts fresh and uses ordinary input without stage teleports or puzzle-state writes.
- Both Small+Large solutions pass native input routes. [Small far berry](ballast_alternate/replay_report.json) and [Small near berry at 1920](ballast_1920/replay_report.json) predate the foot-contact correction; the final package uses the corrected pose.
- [Packaged scene suite](ballast_export/scene_checks.log): PASS 82, including both physical crossings, occupied-support refusals, returning berry contact, pause/reset/reload, completion write failures and retry. Animated feet show 0.0000 m measured penetration against the actual rendered support planes; the test limit is 0.02 m.
- [Packaged workshop](workshop_ballast_export/capture_report.json): PASS 247, six reviewed 1280/1920 fixtures, true Button.pressed navigation and preserved chapter/demo/settings paths. Three unimplemented future stages remain disabled even in the completed-profile visual fixture.
- The final 11-suite source run passes 7,240 regular assertions plus 15,262 conservative VS01 flight checks. That includes 917 Crumb rules (the malformed stage-field crash was fixed), 365 chapter profiles, 223 Crumb scene, 3,201 Ballast rules and 82 Ballast scene checks, alongside the preserved 2,452 demo assertions. Native menu/art counts are separate.
- [New mechanism art](ballast_art/art_report.json): 28 bounded geometry/capture checks. [Visual review](blueberry_ballast/VISUAL_REVIEW.md) identifies the exact reviewed images and earlier/final pose versions.

## Recording and performance

[Blueberry Ballast playthrough](Blueberry-Ballast-playthrough.mp4) is an actual packaged Movie Maker run: PASS 10, 19.083333 seconds, 1,145 H.264 frames at 1280×720/60FPS, with 48 kHz stereo AAC. The full file decodes without errors. [Verification](ballast_recording/verification.json) records its hash and technical limits. This is a fast automated solution, not first-play duration or a real-time benchmark.

The separate [capture-free 1920×1080 route](ballast_performance/replay_report.json) passes 10 checks on Apple M4 Pro/macOS 26.6.2: 972 process-frame intervals, p50/p95/p99 of 16.651/18.327/18.671 ms, peak 336 draws and 585 rendered objects. Default cap 60 and VSync are enabled; the FPS monitor's median, 95th percentile and maximum are 60. All 17 focus samples are unfocused. Ordinary saves and reporting I/O remain. These results fit the working rendering budgets but do not prove every frame under 16.67 ms or performance on other hardware.

## Remaining scope

Human enjoyment, first-time duration, subjective audio balance, physical controller operation and focused foreground hands-on feel remain unverified. Reviewed stills and encoded samples do not certify every animation frame. The next approved stage is W01S03 Milk Harbor; W01S04 The Jam Detour and W01S05 Toast Express follow before M2 can be complete.
