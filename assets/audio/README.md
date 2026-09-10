# Breakfast audio

Reproduce every WAV and its metadata with `python3 scripts/generate_audio.py` from the repository root. The generator uses only Python's standard library. These are original synthesized project assets with no external samples or quoted melodies.

The effects use soft struck wooden resonators, quiet fabric transients, and rounded chimes. `music.wav` is an original 20-second, eight-bar loop in 3/4 at 72 BPM. Its resonance and room tails wrap across the boundary. Use seamless looping in the runtime rather than repeatedly starting a stopped player. The generator leaves headroom: the music peaks at −18 dBFS and effects between −12 and −17 dBFS. Playback gains remain a runtime mix decision.

| File | Intended cue |
| --- | --- |
| `resize_up.wav` | Accepted growth; ascending interval |
| `resize_down.wav` | Accepted shrinking; descending interval |
| `pickup.wav` | Grab a carryable prop |
| `place.wav` | Prop settles in a socket or tray |
| `reject.wav` | Invalid resize or placement, paired with a clear visual reason |
| `checkpoint.wav` | Safe progress checkpoint |
| `jump.wav` | Pip leaves the ground |
| `land.wav` | Pip settles on a surface |
| `launch.wav` | Toaster releases |
| `complete.wav` | Prepared napkin landing and demo completion |
| `discovery.wav` | Optional cereal-panel picnic |
| `music.wav` | Gentle breakfast ambience |

`manifest.json` preserves source, format, duration, peak/RMS levels and SHA-256 hashes. `technical_report.json` records post-generation WAV decoding and peak checks. Passing these checks does not establish perceived sound quality. Audio audition, in-game balance and independent settings controls remain unverified until supported playback is reviewed.
