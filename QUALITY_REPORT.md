# Tiny Trouble quality checkpoint

VS01 / M1. This is a partial game, with the 60 campaign stages still planned.

| Gate | Current evidence | Status |
|---|---|---|
| Runtime foundation | Godot 4.5.1 native OpenGL/Metal compatibility scene on Apple M4 Pro | Passed |
| Authored rules and safe saves | 2,091 state checks and 38 scene persistence checks | Passed |
| Full physical route | First native real-input replay: 15 checks, all three puzzles, optional picnic, landing completion | Passed on first revision; new safety/contact revision under replay |
| Prop safety | Radial and rotated solid footprint growth checks; occupied bridge/ramp shrink guards | Targeted tests running |
| Recovery | Canonical model snapshots before puzzles/launch; corruption fallback and interrupted-flight restoration | Model/persistence passed; scene recovery under review |
| Six review compositions | `evidence/opening.png`, `puzzle_one.png`, `puzzle_two.png`, `puzzle_three.png`, `optional_discovery.png`, `finale_scene.png` | Captured / being refreshed after contact corrections |
| Art references | Two labeled generated concepts, editable meshes, native prop-state atlas | Passed for availability and provenance |
| Contact and flight clearance | Spoon handle top and cereal cutout reviewed against geometry | Corrections under validation |
| UI | Title, pause, controls, completion captured at 1280×720 and 1920×1080; bounds report | Passed for captured menus; recent message/contrast refinements pending refresh |
| Audio | 11 critical effects and original 20-second music, reproducible WAV sources and technical stats | Generated and decoded; subjective audition unverified |
| Performance | Initial native 1280×720 replay: p50/p95 16.67ms, p99 18.05ms, 2,523 samples | Measured on Apple M4 Pro only; includes captures, no universal claim |
| Standalone app | Universal macOS package and ad-hoc signing checks | In progress |
| Player experience | No outside player observation | Pending human review |

## Evidence interpretation

Concept art demonstrates an intended look. The studio prop atlas demonstrates actual geometry and materials. The input replay demonstrates one route through the game, and the state tests exercise many action orders. None establishes human enjoyment or an 8–12-minute first-time play duration.

The reference machine is a MacBook Pro with Apple M4 Pro (14 CPU cores, 20 GPU cores), 48 GB RAM. Measured gameplay is native Compatibility rendering at the stated window resolution. Movie capture/fixed-FPS samples will be reported separately from real-time measurements.

Current supported evidence resolutions are 1280×720 and 1920×1080. Gamepad mappings exist; physical gamepad validation is pending. Keyboard/mouse is the tested control path. English is implemented; Simplified Chinese is planned.

## Known limitations

- Campaign chapters and Matchbox Workshop are not implemented yet.
- Procedural cloth, paper and resin use simplified material detail compared with the aspirational concept. Human aesthetic review is pending.
- The native local app is not a notarized public distribution.
- No outside playtest, subjective audio audition, or controller hardware test has been claimed.
