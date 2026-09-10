# Milk Harbor — phone text1.25 still review

All ten actual844×390 PNGs were inspected at their native image dimensions on 2026-09-09. The source route uses default camera scale1.0 and text scale1.25, after the toast font-size fix. This is a macOS viewport simulation with injected touch input, not physical iPhone testing or human visual approval.

**Finding: text containment passes this bounded inspection, but full character visibility remains unresolved.** In [ashore.png](ashore.png), the taller persistent target card covers most of Pip's body and feet beside the flag. Only the upper head remains visible above the card. This is a concrete static occlusion; the toast-only visibility measurements do not cover it. Root was informed before the manifest snapshot was appended.

| Inspected frame | Observation |
| --- | --- |
| [Title](title.png) | Title, description and both buttons fit the modal. The larger labels remain contained. The dimmed world is intentionally covered by the menu. |
| [Opening](opening.png) | The objective and target instructions wrap inside their cards. The right-side toast fits two lines. Pip and the normal parcel remain visible. The taller target card uses more lower-channel space. |
| [Cereal crew](cereal_crew.png) | Greeting feedback and target text fit; Pip's face and the near crew are visible. Disabled size labels remain separate from the card. |
| [Raft ready](raft_ready.png) | The short toast fits beside the scene. Pip, normal cargo, full enlarged cereal hull and near boarding location remain visible. |
| [Aboard](aboard.png) | Objective height contracts for shorter text; two-line target help remains contained. Pip and cargo are clear on the deck. |
| [Grounded](grounded.png) | The enlarged three-line toast fits at right; it leaves Pip, cargo and the full raft outline visible. It partly covers the far optional crew, which is separate from the active grounding task. |
| [Lightened](lightened.png) | Two-line toast and target text fit. The small parcel remains visible, although tiny at this camera distance; still inspection does not establish human size-change comprehension. |
| [Dock open](dock_open.png) | Dock instruction wraps inside the target card, and the two-line toast fits. Pip, parcel, spoon bowl/handle and useful far landing remain visible in this still. |
| [Ashore](ashore.png) | **Unresolved:** target card rises to approximatelyy231 and overlaps Pip at the flag. The upper head shows above it; the lower character is hidden. Toast is safely at upper left. |
| [Complete](complete.png) | Wrapped completion title, description and all three buttons fit within the modal. This menu frame cannot establish the character's final pose. |

The [route report](replay_report.json) records **PASS13**, text1.25 and camera1.0. Its806 render-post-draw samples show zero toast/actor overlap and zero toast/aboard-cargo overlap. Conservative projected Pip AABB height min/p50 is30.72/34.93 pixels. These are technical measurements with a specifically named scope, not pixel segmentation or human readability thresholds. The fixture seeds only W01S01/W01S02 completion before readiness; it reports no current-stage state writes or teleports.

The next visibility check should include persistent objective/target cards against the actual actor, in addition to transient toasts. The ashore capture must be refreshed after a correction. Changes should preserve text1.25, accessible touch targets and usable approach space. The separate camera0.8 study is not accepted as a fix for this issue.

No art, camera, HUD or capture files were edited by this review. Human normal-size proportions, material cohesion, camera comfort, uninterrupted motion and audio audition remain pending. This is a bounded still review with an open finding, not a presentation-gate approval. `review_sources.json` binds the ten image and report hashes reviewed here.
