# W01S03 Milk Harbor asset studio

`TTHarborArt` in [harbor_art.gd](../../scripts/chapter/harbor_art.gd) adds four original editable procedural factories using the established `TTArt` palette, rounded meshes and rough materials. No new external model, raster texture, font or generated image was added. Raft and cargo supply the new stage assets; the fixed spoon dock does not add a resizing spoon family. The studio reuses bundled Nunito and the original Pip for scale.

| Factory | Actual native bounds and integration convention |
| --- | --- |
| `cereal_raft()` | Normal X/Z ±0.80, Y 0…0.30. `CerealRing` has outer radius 0.80, inner radius 0.43 and height 0.24. `Deck` is 1.15×0.066×0.70 with top Y=0.30; `DeckAnchor` is (0, 0.30, 0). Small 0.5 gives overall 0.80×0.15×0.80; Large 2 gives 3.20×0.60×3.20 and a 2.30×1.40 deck. |
| `cargo_parcel()` | Normal X/Z ±0.29, Y 0…0.60, including continuous coral twine and knot. Small 0.5 is 0.29×0.30×0.29; Large 2 is 1.16×1.20×1.16. `WrappedSugar`, `CoralTwine/WrappedThreads`, `CoralTwine/Knot` and `SugarCorner` remain editable. |
| `folded_spoon_dock()` | `HingedDock` spans X −2.20…0, Z ±0.55, Y −0.12…0 when open. Root and child pivot at the far-shore hinge. Its flat metal surface is 0.012 below the top datum, with the teal handle inset at Y=0; side edges are beveled. `OuterAnchor` is (−2.2, 0, 0), `LandingCenter` is (−1.65, 0, 0), both under `HingedDock`. Negative local Z rotation raises the dock; −PI/2 puts its tip at Y=2.2. |
| `cereal_friends()` | Combined default bounds approximately 1.315×0.540×0.239 with minimum Y=0. `CerealL`/`CerealR` are independent floor pivots at X −0.36/+0.36. Each exposes `WaveArm/Hand`, `Body`, eyes, feet and short connecting legs. Their faces look toward +Z. |

The dock's root-level `FixedHinge` is a stationary axle along Z, centered (0, −0.065, 0), with footprint 0.11×0.34. It adds 0.055 beyond the movable dock's positive X end, so the whole open factory spans X −2.2…+0.055. Runtime supplies shore supports, folding angle, collision and interaction; the spoon-like shape is a dock, not an additional resizing spoon prop.

Raft grains (72) and wafer-edge marks (36) use two translation-only MultiMeshes with baked mesh dimensions and no detail shadows. The bow sits beyond the deck's X extent, and no decorative vertex rises through its clear walking rectangle. The parcel's two cords are one continuous curved mesh, preserving a paper-wrapped silhouette without floating straight corner joins. The dock uses one beveled mesh plus its inset, three tiny grip marks and a fixed axle. Key animation nodes remain separate.

Cargo and Pip in the large-raft studio view are siblings of the scaled raft, at normal absolute scale. Their positions illustrate available deck space only. Runtime owns cargo attachment offsets, buoyancy, milk waterline, shallow ridge, raft motion, boarding and exact landing supports.

Run from the repository root:

```sh
./tools/Godot.app/Contents/MacOS/Godot --path . --resolution 1280x720 --script tests/chapter/capture_harbor_art.gd
```

[art_report.json](art_report.json) and [studio.log](studio.log) record **38 passing native checks**, including actual mesh/MultiMesh bounds, all three raft/parcel scales, deck clearance, folding direction and independent wave pivots. Headless dummy-renderer MultiMesh transform readback is not used. All six native Godot 4.5.1 OpenGL Compatibility images were inspected:

| Studio | 1280×720 | 1920×1080 |
| --- | --- | --- |
| Raft scales and fixed-size cargo | [1280](raft_states_1280.png) | [1920](raft_states_1920.png) |
| Parcel scales | [1280](parcel_states_1280.png) | [1920](parcel_states_1920.png) |
| Dock open/folded and friends | [1280](dock_friends_1280.png) | [1920](dock_friends_1920.png) |

The ring opening, clear wafer deck, coral parcel binding, metal edge highlight and friendly ring silhouettes are readable. Straight cord joins and an initially hard dock edge were refined within unchanged bounds, and short legs close the gap between ring bodies and feet. The folded metal face is darker because it faces away from the studio key; its edge and teal inset remain visible. Fine grain, knots and faces need a separate check at the actual gameplay camera distance. These captures demonstrate isolated assets and sampled static poses, not a completed W01S03 route, all moving contact, water readability, performance, human play, audio or subjective quality. Source and capture digests are saved in [artifact_snapshot.json](artifact_snapshot.json); accepted stage 2/M1 assets and manifests were not edited.
