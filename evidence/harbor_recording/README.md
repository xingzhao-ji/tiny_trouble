# Packaged Milk Harbor recording

Reproduce with `./scripts/record_harbor.sh` after building version 0.2.2. The script chooses the actual packaged app when present. This run used that app with an external route harness and Movie Maker at fixed 60 FPS; all eleven route checks pass.

`../Milk-Harbor-playthrough.mp4` contains 870 H.264 frames at 1280×720/60 FPS, duration 14.5 seconds, plus 48 kHz stereo AAC. The full file decodes without errors. `verification.json` records the artifact digest and technical checks; `engine.log` and `replay_report.json` identify the executed recording conditions.

Five `encoded_*s.png` images are extracted from the encoded MP4 at 2.8, 8.6, 11.2, 12.1 and 12.6 seconds. The other ten PNGs are native route captures. Visual review scope is recorded in `../milk_harbor/VISUAL_REVIEW.md`.

This is a fast automated solution. Its duration does not measure first play; Movie Maker cadence is not real-time performance. Decoding the audio does not establish subjective audition, and sampled stills do not establish full uninterrupted motion quality.
