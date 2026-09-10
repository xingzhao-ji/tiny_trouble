# Packaged Milk Harbor

Version 0.2.2, universal macOS app, executed from `builds/Tiny Trouble.app/Contents/MacOS/Tiny Trouble · Toast Express`. The external excluded harness is `tests/chapter/replay_harbor.gd`; `res://` game resources load from the app's PCK. At 1920×1080 the ordinary-input route passes 11 checks and saves ten native PNGs.

Only completion of W01S01 and W01S02 is seeded on an isolated profile before scene readiness. Milk Harbor begins fresh; its route uses input actions without stage teleportation or puzzle-state injection. The separate `scene_checks.log` contains 147 packaged fixture-based scene assertions; it is not an ordinary-input route.

`package_audit.json` preserves the 81-resource list and internal PCK payload-digest check. The archived app is `builds/W01S03-verified-macOS.zip`, SHA-256 `a1411379fdacbdf8d89b6897f2fb3768e484b5b241ef164c5cb7597cb50bee89`. Ad hoc signing was verified before archiving outside Desktop's metadata-injecting FileProvider.

Native Apple M4 Pro / macOS 26.6.2 / Godot 4.5.1 Compatibility renderer. Captures include synchronous PNG stalls and the window was unfocused. Separate performance and movie evidence retain their own conditions. See `../milk_harbor/VISUAL_REVIEW.md` for the bounded visual review.
