# W01S02 · Blueberry Ballast implementation record

**Status: verified through available W01S02 technical gates.** W01S02 is implemented in source and version 0.2.1. Pure rules pass **3,201 checks**; source and actual packaged scene tests pass **82 checks** each. Both native source solutions and the corrected packaged route pass **10 checks**. The build, recovery and actual packaged workshop navigation gates pass. All nine final route frames and four actual encoded samples are reviewed; entry-foot, ramp-lip and copy findings are closed. Recording metadata and full decode are verified. This does not complete M2.

| Field | Record |
| --- | --- |
| Task | TT-024 · W01S02 Blueberry Ballast |
| Parent | M2 · Breakfast Chapter |
| Requirements | SCALE-01, PLAY-01, QUALITY-01 |
| Delivered scope | A distinct second campaign stage that teaches visible ballast and ramp alignment. Available technical gates are verified within the recorded limits. |
| Player benefit | The player can see how changing a familiar object's size changes a counterbalanced route, then recover safely from experiments. |
| Prerequisite | W01S01 Crumb Crossing's available technical gates have passed. |
| Scope boundary | One authored cereal-flap mechanism, two instances of the blueberry family, existing chapter persistence/navigation and established input/audio/art helpers. No general physics engine or later-stage implementation. |

The preceding checkpoint is preserved at commit `4568ced`, tag `w01s01-technical-1`, and `builds/W01S01-verified-macOS.zip`. Its recorded SHA-256 is `de29738d39d92fe3f7d2a481e7021951506e42caaeac76001ae048275066aa8f`. The original VS01 artifact remains separate.

## Authored puzzle

Two named instances, `berry_a` and `berry_b`, start at normal size in separate trays. Both belong to the existing blueberry family. The player enlarges each berry and uses the existing interact action, default **E**, to roll it through an authored toy channel into its corresponding pocket on one cereal-box flap. Rolling is a controlled, readable stage action, with a defined destination and recovery behavior.

The mechanism exposes five fixed counterweights. Its internal abstract masses are Small = 1, Normal = 2, Large = 4; the alignment target is 5. These numbers describe implementation rules and tests. They must not appear as arithmetic requirements in the player UI. The visible counterweights, flap motion and ramp's contact with the landing explain the outcome.

With both large berries seated, the total is 8 and the ramp rises beyond the landing. Shrinking either seated berry to Small leaves 1 + 4, aligning the ramp with its landing. Both solutions are equally valid:

| Solution | berry_a | berry_b | Result |
| --- | --- | --- | --- |
| A | Small | Large | Ramp aligned; safe crossing available. |
| B | Large | Small | Ramp aligned; safe crossing available. |

Other authored size combinations produce visible, reversible imbalances. An experiment must not destroy a berry, lose access to a required control, or permanently close the route. Mechanism changes are refused while Pip occupies the moving ramp or another support that would become unsafe. The refusal must explain the immediate spatial reason and leave state and geometry unchanged.

Optional **E** inspection of the exposed weights is implemented and exercised by the 10-check native routes. It rewards curiosity without adding a required step or numerical puzzle UI.

## Checkpoints and durability

| Checkpoint | Canonical arrangement | Recovery intent |
| --- | --- | --- |
| 0 · Opening | Both normal berries in their starting trays. | Restore a clear introduction and accessible authored channels. |
| 1 · Both pockets loaded | Both large berries seated on the flap. | Preserve the completed rolling work; expose the over-raised ramp and remaining balance decision. |
| 2 · Ramp aligned | One Small and one Large berry seated, with a defined canonical arrangement. | Restore a stable aligned crossing and safe Pip position. Both solved arrangements remain valid before reset. |

Local reset and fall recovery restore the current canonical checkpoint, its berry sizes/locations, mechanism pose and safe player position together. An in-progress roll or resize must not reload as an unsupported intermediate state. Exploration after solving may change the balance again when Pip is clear; recovery must remain available.

Reuse the distinct chapter profile and its atomic completion-plus-snapshot commit. Save/load validation belongs to the stage rules and must reject impossible sizes, pocket occupancy, mechanism dependencies and incompatible snapshot versions. Failed durable completion remains retryable. Earned completion survives local reset, exploration, replay and navigation; demo progress stays separate. Profile unlocks do not enable any stage whose content is still unavailable.

## Implementation responsibilities

- Runtime owner: build physical traversal, authored roll/resize transitions, ramp occupancy guards, contextual feedback, checkpoints and stage/hub integration.
- Asset owner: author the cereal flap, two channels, two berry pockets and exposed counterweights in the existing toy palette, with visible supports and an unmistakable landing-alignment payoff.
- Rules owner: implement the pure stage state, symmetric valid solutions, mechanism invariants, canonical recovery and snapshot validation.
- Production record: retain this bounded task and its acceptance criteria; add results only after actual evidence exists.

Reuse the existing blueberry art, Pip, input bindings, HUD conventions, sound cues, comfort settings and chapter navigation. Avoid introducing a new shared framework merely to express this one mechanism.

## Acceptance work

| Gate | Required evidence | Current result |
| --- | --- | --- |
| Pure rules | Both symmetric solutions; reversible intermediate imbalances; invalid actions; checkpoint transitions; canonical resets; malformed snapshot rejection. | PASS: 3,201 checks in `tests/test_ballast_state.gd`. |
| Actual scene recovery | Real contacts, completed roll placement, occupied-ramp guard, safe crossings, checkpoint reset/fall recovery and durable completion. | PASS: 82 checks in source and actual package. Foot-contact checks use a 0.02-unit limit and measure 0.0000 maximum penetration. `evidence/test_ballast_scene.log`, `evidence/ballast_export/scene_checks.log`. |
| Chapter profile/navigation | Fresh/resumed stage, retained completion, isolated chapter/settings/demo paths, truthful stage availability and scene cleanup. | Workshop PASS: 247 checks in source and actual package, with six captures each. Real Button.pressed flow visits Ballast → workshop → demo → workshop → saved Ballast. Three unbuilt stages remain disabled. |
| Source native route | Ordinary input loads both pockets, over-raises then aligns the ramp, crosses, inspects weights and completes. Both solutions execute without teleporting or writing puzzle state. | Main `evidence/ballast_1920/` PASS10; far-berry `evidence/ballast_alternate/` PASS10. Alternate captures predate the final foot-pose fix and are not evidence for that correction. |
| Visual presentation | Actual 1280×720/1920×1080 views of mechanism states, Pip contacts and readable HUD; distinguish studios from final runtime evidence. | Mechanism art PASS: 28 checks. Updated workshop source and packaged captures PASS: 247 checks. Corrected final package has nine captures including ramp entry; all nine route frames and four encoded samples are reviewed; entry-foot, lip and copy findings are closed. |
| Native export | Audited real package, ordinary-input route, actual scene tests and included hub/navigation resources. | Version 0.2.1 passes 73-resource/digest/universal/signature checks, route 10, scene 82 and workshop 247. `evidence/ballast_build.log`, `evidence/ballast_export/`, `evidence/workshop_ballast_export/`. |
| Retained checkpoints | Keep VS01/W01S01 playable and artifacts preserved; run the complete source regression runner. | All 11 suites pass: M1 2,452 regular +15,262 sweep; current Crumb/profile/scene 1,505; Ballast 3,283. Settings 91 rerun after footer change. Prior W01S01 baseline 881/1,469 remains historical. |
| Native performance | Record actual capture-free stage conditions separately from route screenshots or movie throughput. | Packaged 1920×1080 PASS10, 972 intervals: p50/p95/p99 16.651/18.327/18.671ms, peaks 336 draws/585 objects. FPS monitor p50/p95/max 60; default 60 cap/VSync. All 17 focus samples false. No PNG stalls; ordinary I/O remains. |
| Recording | Actual native packaged route encoded and decoded, with metadata and digest retained. | PASS: movie-route 10, 19.083333 seconds/1,145 H.264 frames at 60 FPS, 1280×720, 48 kHz stereo AAC; full ffmpeg decode exits 0 with no errors. `evidence/ballast_recording/verification.json`. Four actual encoded samples are reviewed; uninterrupted motion quality remains unclaimed. |


Acceptance remains scoped to recorded evidence and tested conditions. Earlier M1/W01S01 checks are prerequisites, not results for this stage. Human enjoyment, first-play duration, subjective audio balance, physical controller hardware, and foreground hands-on feel remain unverified until those reviews actually occur. W01S03–W01S05 and the wider campaign remain outside this task.

The final 0.2.1 package is preserved as `builds/W01S02-verified-macOS.zip`, SHA-256 `29bc3da9154801aa5998f13885856c3783d29c62dc0df0068b05339c79f832d8`. `evidence/ballast_performance/replay_report.json` records the measured native conditions; they do not guarantee every frame is within 16.67ms. Recording metadata and full decode pass; final route/encoded-frame art review is complete, with the scope and limitations in `evidence/W01S02_ACCEPTANCE.md`. W01S03 Milk Harbor is the next approved stage.

The complete eleven-suite source run totals 7,240 regular assertions plus 15,262 swept checks. Native art and menu counts remain separate. Full uninterrupted motion quality, subjective audio and the previously stated human/device limits remain unverified.
