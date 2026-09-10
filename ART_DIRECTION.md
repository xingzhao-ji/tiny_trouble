# Tiny Trouble art direction

VS01 / ART-01, ART-02; scoped M2 W01S01 extension / September 9, 2026

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

## M2 first-stage extension: W01S01 Crumb Crossing

The accepted VS01 technical checkpoint is preserved at tag `vs01-technical-1` (commit `fd5a1cc`). The first M2 extension added the implemented breakfast-table stage W01S01; references to chapter slots do not imply completed future stages. Its native route and visual review live in `evidence/crumb_crossing/`, separately from accepted VS01 images. Shared `main.gd`/`hud.gd` now also supply the Matchbox Workshop title entry; existing VS01 world geometry remains the same. M2 source hashes are separately scoped in `ASSET_MANIFEST.json`.

`TTChapterArt` in `scripts/chapter/chapter_art.gd` adds four original procedural factories using the existing palette and `TTArt` mesh/material helpers. No new external model, raster texture, font or generated concept is required. `sugar_cube()` produces rounded cream sugar with shallow facets and 150 small crystalline grains in one MultiMesh. Its exact normal bounds are 1.35 × 1.35 × 1.35 with the floor at Y=0. W01S01 authors sugar ratios **0.35 / 1 / 2**; small sugar is 0.4725³. The reused spoon retains **0.5 / 1 / 2**. These ratios are deliberate stage choices rather than a global scale-rule change.

`paper_tray()` uses stage coordinates: floor X −10.8…−7.4, Z 1.8…4.6, Y 0…0.06. Three 1.0-high, 0.12-thick walls leave the right edge open. Cream paper, subdued teal rims, creases and batched fibres keep the silhouette legible without baked instructions. The 2.68-wide interior leaves 0.665 on each side of normal sugar and 1.10375 around small sugar, enough for the authored upper path near Z=2.45. Runtime owns collision, growth rejection and allowed transitions.

`crumb_friends()` exposes separate `CrumbL` and `CrumbR` floor pivots, each with `WaveArm/Hand`, `Body`, eyes and feet. Their combined default bounds are approximately 1.316 × 0.405 × 0.435. `paper_pinwheel()` exposes a `Rotor` at (0, 1.48, 0.02), rotating around local Z; folded blades, hub and pin belong to that pivot, while stem and paper foot remain static. Default overall bounds are 1.16 × 2.06 × 0.345. These are reactive stage details; animation and placement belong to the stage controller.

The stage reuses Pip, teaspoon, table dressing, teacup and saucer forms, alongside an original simple teal destination flag. `tests/chapter/capture_crumb_art.gd` validates actual native mesh bounds and captures the state atlas, normal and small tray poses, and friendly details at 1920 × 1080; its 21 checks pass. The eight 1280 × 720 route captures show readable character/route framing and fitting menus. A packaged title/completion recheck in `evidence/crumb_export/` verifies the corrected background target copy. Specific limitations are recorded in `evidence/crumb_crossing/VISUAL_REVIEW.md`; studio, route stills and the 10-check replay reports do not establish every moving contact or subjective visual quality.


## M2 second-stage extension: W01S02 Blueberry Ballast

W01S02 adds an original cardboard balance using `TTBallastArt` in `scripts/chapter/ballast_art.gd`. It reuses Pip, the blueberry family, table dressing and the established palette. No new external model, raster texture, font or generated image is used. The accepted VS01 checkpoint and W01S01 capture snapshots remain historical records; `ASSET_MANIFEST.json` scopes the accepted W01S02 sources and reviewed captures separately. Unimplemented chapter slots remain navigation scaffolding.

`balance_pan()` has a 2.7 × 4.4 footprint, floor top at local Y=0, thickness to Y=−0.14 and low rims reaching Y=0.10. `PocketFar` at (0,0,−1.12) is teal and `PocketNear` at (0,0,+1.12) is coral. `counterweight_tower()` has default bounds 1.9 × 3.46 × 1.7, with an exposed pulley and five named cream/amber cereal pieces under the independently translating `WeightStack`. `PulleyLeft`, `PulleyRight` and `WeightStack/ThreadAnchor` give runtime explicit connecting points. No readable numeric physics label is baked into the art.

`ramp(length=6.0, width=1.65)` starts at its near walking-surface origin and extends along +X. Its top is local Y=0 and all sidewalls, teal trims and corrugation remain at or below it, with default depth 0.28. `ledge()` has a clear 4 × 3.2 top at Y=1.8, a solid cereal-box body and a shallow friendly breakfast graphic. Pan corrugation, ramp flutes and weight scoring use translation-only MultiMeshes with baked mesh dimensions; the individual weights and key geometry remain editable. Exact bounds and animation anchors are in `evidence/ballast_art/README.md`.

The native studio passes 28 bounds/pivot/capture checks and its four 1280/1920-pixel frames have been inspected. Its radius-0.92 berries demonstrate available pocket clearance. W01S02 authors the existing blueberry ratios 0.5 / 1 / 2, whose large radius is about 0.6. Runtime supplies the pan motion, three visible threads, stack travel, rolling tracks and rising walkway. A stage-authored fold-out landing lip lets the low ramp remain outside the solid box and the balanced ramp meet the platform. Pip's stage-specific `SlopePose` and vertex-based foot lifts correct support contact without changing `TTArt.pip()`.

All nine final 1280 × 720 packaged views in `evidence/ballast_export/` have been inspected, including the new ramp-entry pose. The ten-check input route and 82 packaged scene checks pass; the latter report zero primary-foot penetration on sampled rendered supports. Earlier eight-view 1920 source and 1280 alternate-solution sets verify the layout at both resolutions but predate the final foot-contact correction. `evidence/blueberry_ballast/VISUAL_REVIEW.md` records the resolved low-ramp overlap and entry-toe findings, readable mechanism and menus, and limits of still review. Captures and automated reports do not establish all motion, focused human play, subjective visual quality or enjoyment. The aspirational reference's paper grain, fabric weave and rich indirect lighting remain simplified in the runtime.

The final encoded `evidence/Blueberry-Ballast-playthrough.mp4` also has four inspected extracts covering rolling, ramp entry, crossing and the completed flag scene. Its verification record reports 1,145 H.264 frames, 19.083333 seconds at 1280 × 720/60 fps, stereo AAC and a clean full decode. These are selected-frame and file-integrity checks; uninterrupted viewing, subjective audio audition and real-time performance are separate.


## M2 third-stage extension: W01S03 Milk Harbor

`TTHarborArt` in `scripts/chapter/harbor_art.gd` adds a toasted cereal raft, cream sugar parcel, fixed folding spoon dock and two cereal-ring friends. All are original editable procedural geometry using the existing palette and `TTArt` helpers. No new external model, raster texture, font or generated image is used. W01S03 source/art evidence is separately scoped in `ASSET_MANIFEST.json`; accepted W01S02/W01S01/VS01 snapshots remain historical and the remaining two chapter slots are not implemented-stage claims.

`cereal_raft()` has a floor pivot and normal bounds 1.6 × 0.30 × 1.6. Its torus has outer radius 0.80, inner radius 0.43 and height 0.24. The clear wafer `Deck` is 1.15 × 0.70 at top Y=0.30, also exposed by `DeckAnchor`. Grain and wafer-edge details use two MultiMeshes; ties and the teal bow stay outside the clear walking top. The 0.5 / 1 / 2 scale family reaches a 3.2-diameter ring and 2.30 × 1.40 deck at Large. Cargo and Pip remain separate siblings at their own scales when the raft grows.

`cargo_parcel()` has normal bounds 0.58 × 0.60 × 0.58, with a floor pivot, rounded cream wrapping, subtle sugar corner and continuous curved coral twine. Its own 0.5 / 1 / 2 scales remain independent of the raft. `folded_spoon_dock()` exposes `HingedDock` at the shore hinge, extending along −X for 2.2 units with width 1.1 and local top datum Y=0. Negative local Z rotation raises the spoon. The static axle is separate; runtime adds the rim support pin. This fixed dock reuses silver/teal spoon cues without adding another resizing spoon family. `cereal_friends()` exposes `CerealL`/`CerealR`, each with `WaveArm/Hand`, eyes, feet and connected legs. Default combined bounds are approximately 1.315 × 0.540 × 0.239.

The isolated native studio passes 38 actual-bounds/pivot/capture checks, and all six 1280/1920 images in `evidence/harbor_art/` have been inspected. Exact anchors and material decisions are documented there. In the stage, a pale ceramic serving dish holds cool-tinted milk at Y=0.42, a submerged warm crumb ridge marks the shallow stop, and small paired ripples help show immersion. Cargo changes the raft's draft; the stage supplies voyage, boarding, disembarking, supports and collision. The reviewed source uses moorings X±3.10 and a supported dock hinge (4.9,0.90,1.30), with its deployed tip at Y=1.10. These choices keep the bowl distinct from the ring and wafer.

All ten current source-route captures at 1280 × 720 and 1920 × 1080, plus ten final packaged 0.2.2 views at 1920 × 1080, have been inspected. Each ordinary-input route passes eleven checks. Water/ridge contrast, dock visibility and state-specific copy findings are resolved. Independent geometry checks clear the spoon against ring/deck in both vertex directions for all three cargo sizes. Source and packaged scene suites each pass 147 contact, animated-path, jump-recovery, grounded rim-walking, menu and lifecycle checks. `evidence/milk_harbor/VISUAL_REVIEW.md` records the reviewed views, corrections and limits; no further art change was indicated by these captures.

Five actual encoded samples from `evidence/Milk-Harbor-playthrough.mp4` cover the near mooring, sailing, settled dock, spoon-bowl pose and descending far-shore hop. The file verifies as 870 H.264 frames, 14.5 seconds at 1280 × 720/60 fps, stereo 48 kHz AAC and a clean full decode. This closes selected-frame and file-integrity review, not uninterrupted motion viewing or audio audition. Still routes and the movie were unfocused; capture stalls and fixed movie cadence are not foreground-performance evidence. Runtime texture and indirect lighting remain simpler than the aspirational generated references.
