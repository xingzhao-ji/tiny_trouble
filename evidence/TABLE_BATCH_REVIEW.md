# Static table batching review

M1 / performance and ART-02 / September 9, 2026. This change affects only noninteractive table dressing in `scripts/art.gd`. Pip, principal props, animation pivots and named carton geometry are unchanged.

The authored factories still assemble the complete table. `TTArt.table(false)` retains the individual meshes for editing and comparison; the default `TTArt.table()` replaces repeated grain, knots, dishes, stitches and crumbs with material-compatible MultiMeshes. It preserves materials, overlays, shadow mode, render layers, GI mode and culling margin. The slab, distant floor and cloth remain individual meshes.

| Fixed native table-only measurement | Before | After |
| --- | ---: | ---: |
| Draw calls, including shadow pass | 131 | 23 |
| Rendered objects, engine counter | 131 | 23 |
| MeshInstance3D nodes | 82 | 3 |
| MultiMeshInstance3D nodes | 0 | 9 |
| Wall-clock frame p50, ms | 1.550 | 1.343 |
| Wall-clock frame p95, ms | 1.681 | 1.459 |
| Wall-clock frame p99, ms | 1.774 | 1.490 |

Draw calls fell **82.44%** in this controlled table-only view. Timing is a single short native observation, subject to system load and scheduling; it does not establish the full game's 60fps gate. The integration owner measures the complete route separately.

Native captures use Godot 4.5.1 GL Compatibility on Apple M4 Pro, 1920 × 1080, a fixed orthographic camera and identical static lighting. Sixty frames warm up, followed by 120 measurement frames. See `table_before.json`, `table_after.json` and their logs.

Before/after frames were inspected directly. Numerical comparison found 77 changed pixels out of 2,073,600 (0.003713%). Mean absolute RGB difference is 0.00008761 on an 8-bit channel scale. Twenty-five pixels differ by more than 2 levels; ten differ by more than 8; the maximum is 26. Differences are confined to tiny edges. `table_diff.png` amplifies absolute differences eightfold for inspection; the original native screenshots are unchanged. This is a close visual match, not a claim of byte-identical rendering.

An initial instancing attempt changed the appearance of anisotropically scaled wood knots and dish rims and was rejected. The final code groups instances by scale, bakes positions with that scale and normals with its inverse transpose, and sends only rotation/translation transforms to MultiMesh. Tangents are transformed and UVs retained. This avoids the observed Compatibility instancing shading change. A naive `SurfaceTool.append_from()` merge was also unsuitable because the [Godot 4.5 implementation transforms normals with the supplied raw basis](https://github.com/godotengine/godot/blob/4.5/scene/resources/surface_tool.cpp#L971-L978).

Reproduce from the project root:

```sh
./tools/Godot.app/Contents/MacOS/Godot --path . --script tests/benchmark_table.gd --resolution 1920x1080
./tools/Godot.app/Contents/MacOS/Godot --path . --script tests/benchmark_table.gd --resolution 1920x1080 -- --after
./tools/Godot.app/Contents/MacOS/Godot --headless --path . --script tests/compare_table_frames.gd
```

The grouping assumes the explicit factory lists continue to share geometry and render state. Different future decorative meshes or materials should get separate groups. MultiMesh uses a group bounding box, so another camera may draw offscreen members of a visible group; these small fixed tabletop groups are intentionally bounded. Final route rendering and aggregate performance remain integration checks.
