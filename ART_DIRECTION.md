# Tiny Trouble art direction

VS01 / ART-01, ART-02 / September 9, 2026

The slice is an original handcrafted breakfast diorama. Its fixed palette is cream `#F5E6CC`, toasted amber `#E5A54B`, soft coral `#C95C54`, muted teal `#4A9290`, and deep slate `#384657`. Quiet warm wood, pale paper and an indigo derivative for blueberry support those anchors. Principal objects have clear silhouettes and broad, deliberately rounded contact edges.

## Reference and evidence

- `assets/reference/art_sheet_concept.png`: generated **concept reference**, with Pip views, palette, material samples, spoon, toaster and a lighting sketch. It is not runtime evidence.
- `assets/reference/breakfast_target_concept.png`: generated **aspirational target**, explicitly captioned as concept art. It is not a playable screenshot or proof of the route.
- `assets/reference/prop_states_engine.png`: actual Godot 4.5.1 rendering of the editable runtime meshes at ratios 0.5, 1 and 2, plus Pip. This studio capture demonstrates geometry and materials, not puzzle functionality. Cereal and fixed toaster appear at all ratios for library inspection; the game owns their permitted transitions.
- `assets/reference/art_review.gd`: editable studio capture scene. `assets/reference/art_review.log` records its successful native GL render on Apple M4 Pro at 1920 × 1080.
- Actual game composition and the six fixed route captures are recorded separately by the integration owner. Do not relabel the concept target or studio mesh atlas as those captures.

The exact prompts are preserved beside their PNGs. Both concept images use the built-in image generation tool. No paid CLI fallback, downloaded third-party model, or raster-to-3D conversion was used.

## Runtime library

`TTArt` in `scripts/art.gd` returns editable Godot Node3D hierarchies. `pip()`, `prop(kind)` and `table()` are the public interface. Materials and common rounded meshes are cached. Convex rounded geometry uses generated vertices with explicit smooth normals; spheres, cylinders and tori supply complementary toy details. Spoon and cloth are custom curved surfaces. All principal shapes are real geometry, and generated concept PNGs are not used as in-game meshes or textures.

All prop pivots sit at the centre of the floor contact. +Y is up, Pip faces +Z. Typical normal dimensions are spoon 2.8 along X, blueberry diameter 0.6, cereal 2.3 × 3.4 × 1.2, napkin 1.8 × 1.4 in XZ, butter 0.75 × 0.35 × 0.5, toaster body 2 × 1.4 × 1.4 excluding its protruding lever, and toast approximately 1.3 × 0.17 × 1.1. Collisions, socket offsets, permitted ratios, animation and authored consequences belong to the game controller.

Pip has a cream bean torso, oversized teal feet, a teal fabric tail, slate oval eyes with restrained highlights, coral cheeks, belly stitches, and a coral/amber spool attached at the right hip. The total height is about 0.92 units. Direct animation nodes are `Body`, `EyeL`, `EyeR`, `FootL`, `FootR`, `Tail` and `Tool`; rest positions are authored in `pip()`.

The spoon has a shallow concave metal bowl, rolled rim, rounded handle, teal handle inset and three cream grip dots. The source sheet suggests a wood handle; the runtime uses a quiet metal handle with a teal inset to keep a thin scalable bridge readable. This is an intentional runtime simplification, not evidence of exact target matching.

The blueberry has a muted indigo bloom, a five-lobed crown and restrained pale speckles. The cereal carton is warm paper with coral closure, cream window trim and a cereal-ring emblem. Its actual open window spans approximately local X −0.81 to +0.81, Y 1.38 to 2.75 through both broad faces. `SecretPanel` and initially hidden `Picnic` are direct children. The controller can hide/open the panel and reveal the miniature tea plates.

The napkin has a softly undulating cloth surface, teal stitched border and a folded corner. Analytic normals keep it smooth, and the thin cloth surface does not cast self-shadows, avoiding diagonal shadow acne at tiny scale. Border and fold retain contact cues. Butter has softly melted edges and four shallow score lines. The toaster has a teal rounded body, slate base and feet, brushed top, dark slots, cream dial, amber indicator dots and a coral lever grip. `Lever` is a direct pivot child at local `(1.08, 1.04, 0)`. The toast has a broad rounded crust, double crown and light toasted crumb surface.

The table library provides a 25.4 × 15.4 rounded wood slab with its top at Y=0, low-contrast grain lines, distant neutral floor, two edge dishes, a folded corner cloth and deterministic crumbs. Main route extents X −12…12, Z −7…7 remain under integration control. No principal prop or teacup is placed by `table()`.

## Light and material decisions

Use a warm broad key, restrained soft fill, clear contact and stable orthographic framing. For the Compatibility renderer, the studio capture uses key energy 0.58, ambient energy 0.26 and linear tonemapping; brighter initial settings clipped cream materials and were reduced after actual rendering. Game lighting must be tuned against game captures, not copied blindly. Nonmetal surfaces use roughness around 0.73–1.0; metal accents use restrained metallic response and roughness around 0.25–0.3; toaster enamel is broader and softer than its metal trim.

Reproduce the studio evidence from the repository root:

```sh
./tools/Godot.app/Contents/MacOS/Godot --path . --script assets/reference/art_review.gd --resolution 1920x1080 --rendering-method gl_compatibility
```

## Target gaps and pending reviews

The runtime uses editable procedural toy geometry and a smaller material vocabulary than the aspirational image. Fabric weave, paper grain, resin microtexture, complex warm indirect bounce, styled kitchen background and subtle cinematic contact are simplified. The screenshot's lower camera and extra decorative plant/book silhouettes are reference suggestions, not new gameplay scope. Ground-level reference proportions and the gameplay camera require further composition comparison in the actual scene.

Native studio rendering has been inspected for missing meshes, material failures, silhouette recognizability and size differences. Runtime-only array typing and napkin face orientation defects found during that check were corrected. Route animation, resize effects, clipping against gameplay collisions, the launch through the carton, UI, 1280 × 720 game readability and live performance must be verified in the integrated build. No universal visual quality or human enjoyment claim is made. Charm, cohesion and target quality remain pending human review.

## Integrated review update

The first gameplay opening capture exposed excessive lighting and eye animation that overwrote the authored eye mesh scale; the integration owner corrected those issues. The spoon handle was widened from 0.29 to 0.44 normal units after reviewing its large-state walking surface, and the prop atlas was regenerated. The enlarged handle spans approximately world X −5.34 to −1.38 when placed at the bridge socket X −4.2, with its principal upper surface at Y=0.52. Its overlap above the spoon bowl supplies the crossing surface within the milk gap; the bowl remains concave by design.

Menus now use a centered layout and the full control list is arranged as two action/key pairs per row. A native TextServer check found that Godot required the variation key `weight`, rather than `wght`, to apply Nunito weight 600. The heavier typography has been verified in actual native captures. `tests/capture_hud.gd` renders title, pause, controls and completion at both 1280 × 720 and 1920 × 1080. All eight captures fit the 1280 × 720 logical canvas; the larger window scales that canvas to 1920 × 1080. The controls panel measures 680 × 555 logical pixels, safely below the 670-pixel height limit. Evidence is `evidence/ui_*.png`, `evidence/ui_layout_report.json`, and `evidence/ui_layout.log`.


## Flight aperture verification

The first flight audit found that the decorative cream trim narrowed the original structural opening enough to intersect the combined toast and Pip silhouette. The carton opening is now 1.62 units wide and 1.37 units high, from local X −0.81 to +0.81 and Y 1.38 to 2.75. Its outer silhouette remains 3.4 units tall. Cream trim sits outside the clear opening rather than intruding into it. Named front/back panels and trim nodes let the test derive dimensions from the generated meshes.

`tests/test_flight_clearance.gd` invokes the actual `main.update_flight()` trajectory at 2,401 points on an unattached scene owner; it does not load saves, open a window or run completion side effects. Each moving mesh's local AABB is transformed directly into carton space and swept between consecutive poses whenever it overlaps the carton thickness. All crossing intervals are confined to the fixed-yaw linear segment, so those merged bounds conservatively enclose the continuous translation between samples. The check conservatively includes Pip's 1.04 flying stretch and a maximum 0.048-unit bob. The completed audit performs 15,262 mesh checks over 561 crossing samples, with no penetrations and a minimum clearance of 0.08520 units at Pip's head. Evidence is `evidence/flight_clearance.json` and `evidence/flight_clearance.log`. This geometric pass does not replace actual motion, camera or route review.
