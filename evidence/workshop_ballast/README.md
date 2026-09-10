Workshop integration for Blueberry Ballast passes **247 native checks and six captures**, with a clean Godot 4.5.1 exit. The separate Crumb Crossing scene regression remains **PASS223** in [crumb_scene.log](crumb_scene.log). These files preserve new evidence without replacing the W01S01-only captures in `evidence/workshop/`.

Reproduce from the project directory:

```sh
./run.command --script res://tests/chapter/test_workshop_capture.gd
```

Fresh profiles show **Blueberry Ballast · Locked** and explain that Crumb Crossing must be cleared. A forced button signal cannot bypass this guard or create progress. After the prerequisite, the real stage button shows Play, Continue or Replay according to its snapshot and earned-clear status. The remaining three stages stay disabled even in a fixture containing all five completion IDs.

The executed `Button.pressed` flow is Workshop → fresh Blueberry Ballast → Workshop → original demo → Workshop → saved Blueberry Ballast. It verifies actual scene replacement, previous-scene cleanup, fresh/resumed state, and isolated chapter/settings/demo paths assigned before scene readiness. Completion IDs used for visual fixtures are seeded; this is not a stage-solution route or evidence that unbuilt levels were completed.

| Fixture | 1280 × 720 | 1920 × 1080 | Logical menu bounds |
| --- | --- | --- | --- |
| Fresh, text 1.0 | [Locked 720p](fresh_1280.png) | [Locked 1080p](fresh_1920.png) | 470 × 547 at (713, 86) |
| Saved, text 1.25 | [Continue 720p](saved_1280.png) | [Continue 1080p](saved_1920.png) | 470 × 608 at (713, 56) |
| Cleared, text 1.25 | [Replay 720p](cleared_1280.png) | [Replay 1080p](cleared_1920.png) | 470 × 608 at (713, 56) |

Agent visual review inspected all six final images. The full drawer, sleeve, Pip and workbench remain visible beside the panel. Both playable-stage names, prerequisite/status lines, three unavailable entries, focus border and demo return fit without cropping or overlap at both resolutions. No further visual correction was needed.

[capture_report.json](capture_report.json) records all assertions and dimensions; [capture.log](capture.log) records the clean native result. Rendering used macOS OpenGL Compatibility on Apple M4 Pro. All six captures reported unfocused windows and used muted, reduced-motion test settings. No performance, foreground hands-on, physical controller or audio-audition claim is made.
