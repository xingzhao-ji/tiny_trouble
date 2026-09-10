# Milk Harbor phone camera A/B — bounded still review

Reviewed all ten `phone_camera_080` PNGs and the ten corresponding `phone_024a` PNGs at their native 844×390 dimensions on 2026-09-09. These are actual macOS viewport captures from injected touch routes, not physical iPhone captures. The default remains camera scale1.0. Scale0.8 is an unaccepted study candidate for manual A/B review.

Both reports record PASS across thirteen route/visibility steps, with only predecessor completions seeded. Their projected-mesh checks record zero toast/Pip and zero toast/aboard-cargo overlap. This is technical evidence about those bounds; it does not include every part of the raft silhouette, nor establish human comfort or preference.

## Frame-by-frame comparison

| Matched state | Default1.0 versus candidate0.8 — observed in the stills |
| --- | --- |
| [Title](title.png) / [default](../phone_024a/title.png) | The menu dimensions, text and controls remain consistent, with no observed clipping. The closer background crops peripheral plates and cloth more tightly. The modal covers the central mechanism in both; neither frame demonstrates character acting. |
| [Opening](opening.png) / [default](../phone_024a/opening.png) | Candidate Pip, the normal parcel and near mooring are larger. Both shores, standing dock and destination flag remain visible. The candidate's table dressing is more tightly cropped. The centered toast covers part of the milk/ridge region in both, while the actor and parcel remain above/left of it. |
| [Cereal crew](cereal_crew.png) / [default](../phone_024a/cereal_crew.png) | Candidate makes Pip's face and the ring friends' eyes easier to inspect in this pose. Its toast is centered over part of the ridge; default places the same feedback on the right, leaving more uninterrupted channel visible. The optional greeting context is visible in both. |
| [Raft ready](raft_ready.png) / [default](../phone_024a/raft_ready.png) | Candidate enlarges the deck, parcel twine and edge flutes. Its centered toast sits immediately beneath the hull, reducing clear space around the waterline. Default's right-side toast leaves the full raft outline and nearby milk unobstructed. |
| [Aboard](aboard.png) / [default](../phone_024a/aboard.png) | Pip and cargo remain separately identifiable on the warmer deck in both. Candidate gives more space to inspect their shapes, but the toast again sits tightly beneath the cereal hull and interrupts the channel. This static pose cannot assess boarding weight or settling. |
| [Grounded](grounded.png) / [default](../phone_024a/grounded.png) | **Concrete candidate defect:** the centered toast covers the near/lower part of the cereal hull. Pip and cargo remain clear, so the narrower projected-bounds test passes. Default places the toast at right and preserves the entire raft silhouette. The occlusion weakens visual inspection of the grounded hull/contact state. |
| [Lightened](lightened.png) / [default](../phone_024a/lightened.png) | The small parcel and its coral binding are larger in the candidate, but its toast still covers the near/lower hull. That hides part of the shape useful for comparing draft before/after lightening. Default exposes the full ring and more surrounding ripple space. Neither still pair establishes how clearly a person perceives the vertical change in motion. |
| [Dock open](dock_open.png) / [default](../phone_024a/dock_open.png) | Candidate moves feedback to the upper left, leaving Pip, parcel, full raft, spoon and far flag visible together. The enlarged silver bowl, teal handle inset and wafer edge are easier to distinguish. The immediate far landing remains in frame. No obvious new static mesh intersection is observed here. |
| [Ashore](ashore.png) / [default](../phone_024a/ashore.png) | Candidate gives a larger silhouette beside the flag, with the dock and parcel still visible behind Pip. The target card is close to the approach in both; candidate Pip stands just to its right. These are settled poses, not evidence of safe/comfortable continuous disembark framing. |
| [Complete](complete.png) / [default](../phone_024a/complete.png) | The three-button modal and wrapped completion title remain contained and visually consistent. The closer background removes more peripheral context; the modal prevents assessment of the complete character/raft grouping in either view. |

## Measured scope and visible tradeoffs

The route reports' conservative projection of actual mesh AABB corners records Pip height min/p50 of **30.74/34.93 pixels** for default and **38.45/43.67 pixels** for candidate, across 812 and801 render-post-draw samples respectively. The roughly25% increase is consistent with the closer orthographic study. These are projected bounds across sampled animation, not image segmentation, eye-feature measurements, readability thresholds or physical-device point sizes. State-matched captures are separate runs, not identical animation frames.

The candidate makes existing construction cues more visible without changing their geometry: cream Pip and teal feet, the tan wafer, amber cereal ring, coral parcel binding and silver/teal dock retain their established families. It also gives pale milk more screen area and leaves less peripheral tabletop context. This is a composition tradeoff. Greater apparent size does not, by itself, establish that normal-size proportions are appealing or the materials are cohesive to a human viewer.

No important object is visibly cut off by the viewport edge in the eight gameplay stills; peripheral dressing is cropped. UI occlusion remains distinct from viewport cropping. The candidate's grounded/lightened hull occlusion is a specific finding that is not covered by the existing actor/cargo-only visibility pass.

## Candidate hypotheses for the required human review

1. Retain default1.0 as the baseline. Compare0.8 as a candidate after protecting the visible raft/contact outline from transient feedback, especially at grounded and lightened states. Enlarging the toast avoidance region to include the relevant hull is a bounded hypothesis; its effect on placement stability must be reviewed in actual motion.
2. Compare the complete greeting, resize, boarding, grounded-to-lightened and dock/disembark sequences. Ask the human reviewer to identify Pip's intent, the changed object and the next safe landing, and separately judge normal-size proportions and material cohesion. Do not reduce that decision to pixel dimensions or route success.
3. Inspect camera movement and toast relocation together during manual A/B play. The saved stills show different toast locations, but cannot reveal whether transitions distract, jump abruptly, lag or obscure an action briefly. Reduced-motion behavior and the actual small display need their own review.

This review closes inspection of these twenty static images only. Human normal-size proportion/cohesion approval, camera comfort, uninterrupted motion, emotional response and audio audition remain open. No camera, art, HUD, runtime or capture files were changed by this review.

`review_sources.json` records the compared PNG/report hashes and dimensions. The original reports describe the fixtures and measurement method: [candidate](replay_report.json), [default](../phone_024a/replay_report.json).
