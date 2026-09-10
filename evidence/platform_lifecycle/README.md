# Injected application lifecycle evidence

**PASS134**, source headless Godot4.5.1 on macOS, exit0 and clean engine log. `report.json` records scope and hashes. This is injected-notification evidence, not physical iPhone/iPad/Windows execution.

```sh
./run.command --headless --script res://tests/platform/test_lifecycle.gd -- --touch-ui
```

The original demo and all three chapter scenes run their actual resize tweens, input helpers, audio players and serializers with unique disposable saves/settings. Injected application focus loss and pause freeze exact prop/player transforms, clear held keyboard/touch/jump input, pause audio and synchronously recreate the isolated save. Duplicate notifications preserve suspended tweens. Fresh scenes reload those files; foreground/resume restores audio availability while gameplay stays visibly paused until the actual Back to Pip button is pressed.

Both Harbor transit phases are interrupted while their real voyage runs. Fresh disk loads restore the canonical last mooring/cargo/rider with the recovery notice. The still-live scene keeps its voyage paused and completes it only after explicit resume. These legal fixtures test interruption behavior, not a complete player route. The harness drains audio, restores InputMap/audio buses, and removes its test files. Actual OS suspension/termination, device multitouch and performance remain separate gates.
