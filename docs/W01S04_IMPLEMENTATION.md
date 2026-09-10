# W01S04 · The Jam Detour implementation plan

**Status: proposed; queued behind W01S03 Milk Harbor's acceptance gates.** This is a bounded next-stage plan, with no stage-four implementation, playable-scene or verification claim. Milk Harbor retains the current integration frontier. This record does not change the default build, workshop availability or campaign completion counts.

| Field | Record |
| --- | --- |
| Task | TT-026 · W01S04 The Jam Detour |
| Parent | M2 · Breakfast Chapter |
| Requirements | SCALE-01, PLAY-01, SOLO-01, ART-02, QUALITY-01, SCOPE-01 |
| Missing deliverable | The distinct fourth Breakfast stage: carrying a seed parcel across sticky jam using resized biscuit platforms and a butter-knife ramp. |
| Player benefit | Combine familiar carrying, reach and ballast rules in a route whose supports and destination are visible, with safe local recovery after experiments. |
| Scope limit | W01S04 only: two instances of the biscuit family, one butter knife, one wrapped seed parcel, authored jam and receiving rests. Reuse existing chapter architecture and interaction systems. |
| Implementation note | Recommended layout and states below are design decisions to prove when the stage becomes active, not measured geometry or finished assets. |
| Acceptance check | Fresh solo route; real spatial constraints; reversible experiments; canonical recovery and durable delivery; native presentation and actual export/navigation checks. |
| Result / evidence | Pending. This document is the planning record; no stage-four test, capture or package evidence exists. |

## Binding campaign entry

The [design bible's World 1 table](../Tiny_Trouble_Design_Bible.md#world-1-breakfast-table--the-toast-express) specifies:

> Resize biscuit platforms and a butter-knife ramp to carry a wrapped seed parcel over sticky jam.

Its specified discovery/payoff is:

> Jam prints record experiments combining transport, reach, and ballast.

Breakfast Table contains exactly five main stages, in this order: **W01S01 Crumb Crossing; W01S02 Blueberry Ballast; W01S03 Milk Harbor; W01S04 The Jam Detour; W01S05 Toast Express.** VS01 and the Matchbox Workshop are separate. W01S04 depends on W01S03; it does not replace the fifth-stage toast finale or complete M2 by itself.

## Recommended puzzle

The near bank shows Pip, a wrapped seed parcel and its receiving rest across a glossy coral jam patch. Two biscuits and a butter knife establish a short detour with a dry central working area. Target sizes begin from the established Small/Normal/Large model; initial 0.5/1/2 scale ratios may be tuned to actual supports and readability.

| Prop | Recommended role |
| --- | --- |
| `biscuit_a` | An anchored stepping platform. Large expands its useful footprint enough to connect the near bank to the central dry working area; smaller states leave a visible gap. |
| `biscuit_b` | A biscuit platform seated on the knife's near handle. Its Large state supplies the visible ballast that brings the blade toward the far landing. It remains there when the parcel is carried onward. |
| `knife` | A butter knife in an obvious pivot/rest assembly. Large supplies the required reach; its useful ramp alignment also depends on Large `biscuit_b`. The base and rests are supporting geometry, not additional resize families. |
| `parcel` | A wrapped seed parcel. Small is carryable through the route; Normal/Large are visibly bulky and remain on a safe rest. Its delivery, not a hidden mass value, is the objective. |

The intended solo solution has four connected applications:

1. Enlarge `biscuit_a` from the dry bank to expose the first supported crossing. Shrink the seed parcel, pick it up with the existing interact action and carry it to the central dry rest.
2. Set the parcel down on that clearly suggested rest. Enlarge the butter knife; its blade visibly reaches the far landing region but is not yet aligned for traversal.
3. Enlarge `biscuit_b` from a safe position clear of the mechanism. The biscuit depresses the near handle and lifts the long blade into the receiving rest at the higher far bank. The visible pivot, biscuit and blade explain the ballast relationship without numerical instructions.
4. Pick up the Small parcel, walk the stable knife ramp, and place the parcel on the far receiving rest. Reach the nearby completion flag. The counterweight stays in place, so returning across the knife remains safe.

The ballast and knife may be prepared in either order when the player can safely reach their targets. Early preparation is allowed; checkpoint or delivery flags must not demand an invisible action order. Further alternate routes are unauthored until a real scene demonstrates them. The required solution remains solo, untimed and free of precision placement.

Jam prints provide the promised visible experiment history: differently sized biscuit impressions and brief Pip footprints remain on the jam as local decorative feedback. Two optional reactions reuse existing tools: inspect a print from a safe edge to reveal a tiny stamped pattern, and greet a crumb helper beside the parcel rest. Neither reaction nor the number of prints gates delivery. Prints do not require a new persistent painting or fluid system.

## Ambiguities and recommended resolutions

The bible does not identify the ballast actor. Use `biscuit_b` as persistent ballast. Making the deliverable parcel the only counterweight would require a further latch or a route that collapses when its objective is picked up; the biscuit already supplies the specified platform family and can remain in place.

The bible also leaves sticky jam's failure behavior open. Use a brief, clearly visible sticky-footprint reaction followed by local recovery. Jam never consumes the seed, imposes a long struggle, or creates an unrecoverable dropped object. Its depth, boundary and contact feedback must be visible. Author this as a stage hazard with controlled recovery, without general sticky-body physics.

The butter knife need not become another transported item. Keep it on its visible rest and let resizing alter reach; the parcel supplies the carry puzzle. This avoids requiring Pip to juggle two carried objects and keeps the stage distinct from Crumb Crossing's carried teaspoon. These are recommended implementation choices, not additions to the bible's fixed stage identity.

## Spatial safety and recovery

The scene must prove the actual footprint and reach relationships. A smaller first biscuit leaves a real gap; an undersized knife visibly stops short; insufficient biscuit ballast leaves a visibly misaligned blade. If movement or jump forgiveness permits a safe alternative, either support and test it or tune physical geometry. Do not use an invisible prerequisite wall to manufacture the resize requirement.

Validate Pip's feet and carried parcel against actual transformed prop geometry throughout walking, turning, stepping and ramp traversal. The parcel must clear biscuit edges, the knife handle/pivot and the receiving rest in the supported camera views. Test the complete knife/pivot pose and both biscuit contacts at every allowed state; changing the child's scale must not separate the ballast biscuit from its support. Name actual tolerances when implementation is measured.

Refuse changes that remove an occupied biscuit, rotate the knife under Pip or a placed parcel, or grow an object through another support. Refuse growing a carried parcel. Leave state and geometry unchanged and explain the immediate reason using the current input bindings. Safe empty-platform experiments remain reversible; the central parcel rest stays independent of moving geometry.

| Checkpoint | Recommended canonical recovery |
| --- | --- |
| 0 · Near bank | All props Normal, biscuits/knife in their authored rests, parcel on its near tray, Pip safely ashore. |
| 1 · Parcel reaches the central rest | Large first biscuit, Normal ballast biscuit and knife, Small parcel on the dry central rest, Pip beside it. Award this only after actual transport to that area. |
| 2 · Ramp ready | Both biscuits Large, knife Large and aligned, Small parcel on the central rest, Pip on the independent dry area. Require the parcel's earned central arrival before recording this checkpoint; early mechanism preparation remains valid. |
| 3 · Parcel delivered | Stable Large route, Small parcel in the far receiving rest, Pip safely on the far bank. Completion remains separate until the flag is reached. |

A fall, jam contact or interrupted unsafe transition restores the last earned canonical checkpoint, including a carried or misplaced parcel, with a short explanatory notice. It must not relocate cargo to a destination it never reached. Reset, pause/title/reload and failed saves preserve earned chapter history without inventing delivery. Test replay and exploration after completion, safe return crossings, and recovery after changing an unoccupied mechanism again.

## Existing architecture and acceptance

Use `scripts/chapter/chapter_stage.gd` for shared lifecycle, menus, settings and audio. A stage-owned pure rules object supplies stable IDs, size/socket dependencies, checkpoint snapshots and strict `restore` validation. The runtime owns physical ranges, supports and destination contact. Reuse `chapter_progress.gd` for bounded finite JSON, backup recovery and atomic completion-plus-snapshot writes; a failed completion remains retryable. Reuse `chapter_navigation.gd` so isolated chapter, settings and demo paths are assigned before scene readiness.

When W01S04 becomes available, its workshop entry is locked until W01S03 is completed, then shows Play/Continue/Replay from actual profile state. W01S05 remains unavailable until its distinct content is implemented. A seeded completion prefix must never enable missing content.

| Gate | Required evidence | Status |
| --- | --- | --- |
| Pure state | Valid solution and preparation orders; independent biscuit identities; size/carry/socket invariants; delivery prerequisites; canonical checkpoints; malformed snapshot rejection without partial mutation. | Pending. |
| Real scene | Actual gaps, knife alignment and visible contacts; carried-parcel clearance; occupied-support refusals; jam/fall recovery; pause/title/reload during resize; safe return crossings and actual delivery/flag contact. | Pending. |
| Profiles and navigation | Isolated save/settings/demo paths, fresh and resumed states, atomic completion retry, retained history after reset/replay, valid backups, actual stage/hub/demo button transitions and truthful stage availability. | Pending. |
| Ordinary-input route | Fresh source route transports the parcel across both applications and reaches completion without injected puzzle state or teleportation. Optional prints/reactions remain optional. | Pending. |
| Presentation | Actual 1280×720 and 1920×1080 views: opening, each useful size/contact state, cargo clearance, jam reaction/prints, optional details and delivery. Review maximum supported text scale and remapped prompts; no debug labels, floating supports or clipped HUD. | Pending. |
| Package and regressions | Actual export resource/digest/signature audit; packaged route and recovery/navigation; complete retained source suites. Preserve the preceding verified artifact until stage-four gates pass. | Pending. |

Any future motion recording and performance measurements must identify their actual conditions and review scope. Human enjoyment, first-play timing, subjective audio balance, physical controller hardware and foreground hands-on feel remain unverified unless actually evaluated. No historical stage result is counted as a Jam Detour result.
