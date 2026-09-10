# Milk Harbor workshop integration review

The source-native workshop test passes **307 checks** and saves six actual rendered frames. `../workshop_harbor_capture.log` exits cleanly without engine errors. The retained Crumb scene suite passes **223 checks** in `../workshop_harbor_crumb_scene.log`.

Reproduce from the project directory:

```sh
./run.command --script res://tests/chapter/test_workshop_capture.gd
```

The existing `-- --evidence-dir=<directory>` override remains available for separate packaged captures. This run uses Godot 4.5.1, the native macOS Compatibility renderer and an Apple M4 Pro. All six focus samples are false. Settings use silent music/effects and reduced motion; this is menu/rendering evidence, not a performance, subjective audio or ordinary-input stage-solution claim.

| Fixture | Views | Text scale | Verified presentation |
| --- | --- | --- | --- |
| Fresh | `fresh_1280.png`, `fresh_1920.png` | 1.0 | Crumb Play; Ballast and Harbor locked with their respective prerequisite explanations. |
| Saved | `saved_1280.png`, `saved_1920.png` | 1.25 | Crumb/Ballast Replay; Harbor Continue from an explicitly seeded shoal checkpoint. |
| Cleared | `cleared_1280.png`, `cleared_1920.png` | 1.25 | Three implemented-stage Replay labels; even the all-completed profile fixture leaves stages 04 and 05 unavailable. |

All six actual images were inspected. Titles, saved-state explanations, focus text and the original-demo return remain legible; no menu clipping or overlap with Pip/the open drawer was observed. The menu is 470 logical pixels wide, 587 high at default text and 654 high at text 1.25, leaving 33 logical pixels above and below the larger menu. Both 1280×720 and 1920×1080 captures pass panel/child bounds checks.

Uncaptured fixture navigation exercises actual `Button.pressed` transitions: fresh and saved Ballast, fresh Harbor, Harbor → workshop → original demo → workshop → saved Harbor → workshop. The saved Harbor fixture is constructed through pure rules and written through the production profile API, then loaded by the actual scene before readiness. Its shoal phase, passenger state, cargo size, checkpoint and complete snapshot survive the roundtrip; no Harbor completion is invented. Unique disposable chapter, settings and demo paths are transferred and cleaned up; real user saves are untouched.

Locked Harbor commands are also forced while the profile is fresh and while only Crumb is cleared; both remain in the workshop and preserve profile contents. Earlier workshop evidence directories remain unchanged historical records. Current capture metadata and individual assertions are in `capture_report.json`.
