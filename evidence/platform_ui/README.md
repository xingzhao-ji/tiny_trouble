# Adaptive UI evidence — native macOS viewport simulations

PASS: **1,265 assertions and 28 native PNG captures**, Godot 4.5.1, Apple M4 Pro/OpenGL Compatibility. The process exited 0 and `native.log` has no engine errors or warnings. All 28 capture instants reported window focus. This is source-native macOS evidence, **not iOS Simulator, physical iPhone/iPad, Windows, or a performance benchmark**.

Reproduce from the repository:

```sh
./run.command --script res://tests/platform/test_adaptive_ui.gd -- --touch-ui
```

An optional `--evidence-dir=res://evidence/another_directory` after `--` redirects the evidence. The script requires a native renderer, creates unique chapter/settings/demo paths before scene readiness, drains audio, restores InputMap/audio buses, and removes its disposable saves. Real player files are untouched.

| Requested desktop window | Actual PNG | Default + 1.25 text | 88-logical-unit target height in rendered pixels |
| --- | --- | --- | --- |
| 1280×720 landscape | 1280×720 | Both | 88.00 |
| 1024×768 tablet-shaped landscape | 1024×768 | Both | 70.40 |
| 844×390 phone-shaped landscape | 844×390 | Both | 47.67 |
| 667×375 small-phone-shaped landscape | 666×374 | Both | 45.71 |
| 390×844 portrait | 390×844 | Guidance at 1.25 | Touch disabled |

macOS rounded the odd requested 667×375 backing-store dimensions down by one pixel. The report retains requested dimensions, actual capture dimensions, logical viewport rectangles and measured touch sizes separately. The test permits only that bounded one-pixel reduction. Rendered pixels are not physical iOS points.

The safe area is an explicit asymmetric **logical** fixture: left 48, top 16, right 32, bottom 24. All eight action rectangles and the movement pad stay inside it; action targets measure at least 88 logical units in both dimensions and at least 44 rendered pixels in these landscape windows. A 12-rendered-pixel font-size floor is a bounded automated heuristic, not a human readability study or physical-device accessibility certification.

The live Crumb Crossing scene uses a legal seeded checkpoint 1 and a nearby player placement to isolate input. Actual `InputEventScreenTouch`/`InputEventScreenDrag` events pass through `Input.parse_input_event`, with positions transformed by the Window final transform and the control's canvas transform. A held pad moves the actual 3D character while a second finger shrinks/restores the spoon, receives its large-at-tray refusal, picks it up with Use, and jumps with Hop. These fixtures do not claim a complete ordinary-input stage solution.

Release, release outside the pad, cancellation (including `pressed=true`), injected focus loss, concurrent Pause, checkpoint reset and stale post-reset drags all clear touch movement. The touch vector is tested through the shared production `movement_input()` helper; releasing it preserves a separately held W key. Injected controller/keyboard events update the footer and live context, including isolated persisted K/L bindings. The first subsequent touch immediately restores and moves the pad. The two 844×390 hint captures show these injected modes; controller and accessory-keyboard hardware were not used.

Menus at text scale 1.25 fit horizontally and scroll vertically to their final actions. Menu scrolling is exercised programmatically; reset/resume use the actual `Button.pressed` signals. This does not verify a physical finger's menu-scroll gesture. Portrait transition pauses the live scene, rejects forced start/resume and gameplay touches, and clears held movement. Rotating back keeps the scene paused until explicit resume.

All **28 latest PNGs were visually inspected by the agent**: title, default/max-text gameplay, pause top/bottom and controls-menu bottom at all four landscape sizes; controller/keyboard hints at 844×390; portrait guidance and resumed landscape. The small default subgoal font and stale oversized toast panel found during development are closed in these final captures and assertions. Actual refusal feedback also fits its safe bounds and avoids both cards and all eight touch actions. Scroll viewport clipping at the top/bottom is intentional and the final menu actions are reachable.

`capture_report.json` contains every assertion and capture's dimensions/settings/focus. `review.json` records source and evidence SHA-256 values. Full uninterrupted motion, physical touch ergonomics, actual device safe-area/orientation handling, subjective audio, hardware controllers, thermal behavior and sustained performance remain unverified by this harness. The stable 0.2.2 package and three verified campaign stages are unaffected by this source test.
