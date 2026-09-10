# Milk Harbor — corrected phone text1.25 still review

All ten actual 844×390 PNGs were inspected at native image dimensions on 2026-09-09. This is source candidate0.2.5, default camera1.0 and text1.25, captured in a macOS viewport with injected touch events. It is not a physical iPhone test or human presentation approval.

**The previous ashore character occlusion is resolved in this captured route.** In [ashore.png](ashore.png), the persistent target card moves left of Pip and the flag. The full character, including both feet, remains visible; the card stays above the size buttons and clear of the joystick. This closes the specific static finding in the historical [0.2.4 review](../phone_max_024/VISUAL_REVIEW.md), without changing that earlier capture's rejected status.

| Inspected frame | Observation |
| --- | --- |
| [Title](title.png) | Heading, description and both buttons fit the foreground modal. The dim world and inert target-card edge remain visible behind it; the modal covers world content intentionally. |
| [Opening](opening.png) | Objective and target help wrap within their cards. Pip, the normal parcel and the near boarding area remain visible. |
| [Cereal crew](cereal_crew.png) | Greeting text fits, Pip and the near crew are visible, and size buttons remain separate from the target card. |
| [Raft ready](raft_ready.png) | Enlarged cereal ring, normal parcel, Pip and the near boarding location remain distinguishable. The feedback toast sits beside the active objects. |
| [Aboard](aboard.png) | Pip and cargo remain clear on the warmer wafer deck. Shorter objective text leaves more world area above the raft. |
| [Grounded](grounded.png) | Three-line feedback fits at right. The full raft outline, rider, parcel and ridge remain visible. The toast covers some optional far-shore dressing. |
| [Lightened](lightened.png) | Shorter feedback refits; the small parcel and Pip remain visible. The parcel is tiny at this camera distance, so size comprehension still requires human testing. |
| [Dock open](dock_open.png) | Wrapped dock instructions and feedback fit. Pip, cargo, the open spoon and useful far landing remain visible. |
| [Ashore](ashore.png) | Target card shifts horizontally left, exposing Pip's whole body and feet at the flag. Card and touch controls remain separated in this still. |
| [Complete](complete.png) | Completion heading, description and three buttons fit the modal. A dim target-card edge persists behind the modal; the foreground remains readable. This menu is not a final-pose test. |

The [route report](replay_report.json) records **PASS14** and **806 render-post-draw/card-visibility samples**, with zero Pip/persistent-card, Pip/toast and aboard-cargo/toast overlaps. Conservative projected actor height min/p50 is31.07/34.93 pixels. Its method projects actual mesh AABB corners; it is not pixel segmentation or a human visibility threshold. The fixture seeds only the two completed predecessor stages and reports no current-stage puzzle writes or teleports.

No additional blocking overlap was observed in these ten stills. Dynamic card movement comfort, normal-size proportions, visual cohesion, uninterrupted animation, audio audition and physical-device reach/readability remain **human pending**. The camera0.8 experiment remains an unaccepted separate study. Neither this review nor the technical report claims a final package pass. No runtime, art or image bytes were changed by the review. [review_sources.json](review_sources.json) binds the inspected files.
