Native Matchbox Workshop review passed: **201 checks and six PNG captures** using Godot 4.5.1, macOS OpenGL Compatibility, Apple M4 Pro.

Reproduce from the project directory:

```sh
./run.command --script res://tests/chapter/test_workshop_capture.gd
```

The test creates unique disposable chapter/settings paths and removes them afterward. Fresh profiles use text size 1.0; saved and cleared fixtures use the maximum 1.25. The cleared fixture deliberately seeds all five completion IDs to confirm that four unbuilt stages remain unavailable. These are menu fixtures, not evidence of completing unbuilt levels.

| Fixture | 1280 × 720 | 1920 × 1080 | Menu in logical pixels |
| --- | --- | --- | --- |
| Fresh | [Fresh 720p](fresh_1280.png) | [Fresh 1080p](fresh_1920.png) | 470 × 507 at (713, 106) |
| Saved | [Saved 720p](saved_1280.png) | [Saved 1080p](saved_1920.png) | 470 × 562 at (713, 79) |
| Cleared | [Cleared 720p](cleared_1280.png) | [Cleared 1080p](cleared_1920.png) | 470 × 562 at (713, 79) |

Agent visual review inspected all six images: the complete open drawer, sleeve, Pip, workbench, and pull remain visible to the left of the menu; the menu does not cover them. The title, progression status, four disabled stage titles, original-demo button, and initial keyboard-focus border are readable. All controls stay inside the panel at both output resolutions. No visual correction was required.

The [machine report](capture_report.json) records each assertion and exact output dimensions; [capture.log](capture.log) contains the clean engine result. All windows reported unfocused. This is rendering/layout evidence, not a foreground-input or performance benchmark. Audio was muted through isolated settings, so these captures make no audio-audition claim.
