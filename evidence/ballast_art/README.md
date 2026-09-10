# W01S02 mechanism art

`scripts/chapter/ballast_art.gd` defines `TTBallastArt`, an independent editable procedural library built with the existing `TTArt` palette and rounded primitives. It adds no external model, texture, font, generated image or physics label. Runtime owns positioning, thread paths, collisions, berry scale/rolling, balance logic and animation.

| Factory | Measured local bounds and conventions |
| --- | --- |
| `balance_pan()` | X ±1.35, Z ±2.2, Y −0.14…0.10. The `Floor` top is Y=0. `PocketFar` is (0,0,−1.12), teal; `PocketNear` is (0,0,+1.12), coral. Both radius-0.92 berries fit inside the low rims. `SuspensionAnchor` is (0,−0.14,0). |
| `counterweight_tower()` | X ±0.95, Z ±0.85, Y 0…3.46. `Pulley` at (0,3.12,0.04) rotates about local Z. Fixed `PulleyLeft`/`PulleyRight` anchors are (−0.308,3.12,0.05)/(+0.308,3.12,0.05). |
| `ramp(length=6.0, width=1.65)` | Default X 0…6, Z ±0.825, Y −0.28…0. The origin is the near end at walking-surface height. `Surface`, `EdgeTrimNear/Far` and `SidewallNear/Far` remain at or below Y=0; there is no raised rail. `NearAnchor` is origin and `FarAnchor` is (length,0,0). Width must be at least0.6; length at least0.6. |
| `ledge()` | X ±2, Z ±1.6, Y 0…1.8. `LandingTop` supplies a clear 4×3.2 surface at Y=1.8. `BreakfastGraphic` is shallow geometry on the +Z face; it stays below the top and inside the footprint. |

`WeightStack` is an independently translatable direct tower child at (0,0.35,0.28). It contains exactly five visible cream/amber cereal weights, `Weight0`…`Weight4`, plus `Cradle`, `WeightScoring`, `StackSpindle`, `HangingLoop`, and `ThreadAnchor`. The anchor is (0,1.59,0) in stack space, default tower-space (0,1.94,0.28). The studio verifies an independent +0.75 vertical translation. Runtime must choose its allowed travel and connect the exposed anchors; the studio intentionally does not invent thread paths or assert a functioning balance.

Corrugated pan edges, ramp flutes and weight scoring use MultiMeshes with translation-only instances. Mesh dimensions are baked, preserving correct normals without nonuniform instance transforms. The small surface details do not cast extra shadows. The five individual weights and pulley remain named editable nodes.

Run `./tools/Godot.app/Contents/MacOS/Godot --path . --resolution 1920x1080 --script tests/chapter/capture_ballast_art.gd`. It reuses the earlier studio's actual-vertex bounds walker, validates both default and alternate ramp dimensions, and captures native 1280×720 and 1920×1080 frames. Headless dummy-renderer MultiMesh readback is insufficient for these checks. `art_report.json` and `studio.log` record 28 passing bounds/pivot/capture checks.

All four PNGs were visually inspected: pockets, exposed five-piece stack, pulley, cardboard edge thickness, open walking plane and cereal graphic are legible at both resolutions. The studio uses existing blueberries scaled3.05 for an approximately0.92 radius, and an illustrative tilted-ramp/ledge arrangement with Pip for scale. This is asset evidence, not proof of final gameplay placement, counterweight travel, continuous contact, physics or performance. Final route framing and actual connecting threads require integration review.
