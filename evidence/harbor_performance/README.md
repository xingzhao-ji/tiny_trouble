# Capture-free packaged route

Actual version 0.2.2 app, 1920×1080, `replay_harbor.gd --no-captures`. Route PASS 11. No other Godot or ffmpeg process was running when this measurement began.

697 active process-frame intervals after two seconds of warmup: p50/p95/p99 **16.664 / 18.148 / 18.621 ms**. Peaks: 378 draws, 622 rendered objects. Default 60 FPS cap and VSync enabled; the once-per-second FPS monitor's median, 95th percentile and maximum are 60. All twelve focus samples are false. Native Apple M4 Pro, macOS 26.6.2, Godot 4.5.1 Compatibility renderer.

No PNG requests or Movie Maker. Ordinary saves and reporting I/O remain. This is a bounded measurement on this machine, not an every-frame 16.67 ms guarantee or a foreground controls review. `replay_report.json` contains the measured conditions and route result.
