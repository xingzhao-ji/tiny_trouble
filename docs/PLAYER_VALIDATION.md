# Player validation and decision evidence

**Human enjoyment, satisfaction and demand are UNVERIFIED. No playtest participants or human results are recorded.** The owner has made core audiovisual acceptance a prerequisite for content expansion and asked that actual players, rather than agent scores, guide substantial product decisions. TT-027/TT-028 remain active; stage-four work stays paused and unavailable. The pending audience question has not been answered; its default option is not an approved audience.

## Intended audience: what is explicit and what is assumed

| Evidence type | What the approved material actually establishes | Boundary |
| --- | --- | --- |
| Explicit identity | Solo stylized 3D household puzzle adventure; experiment with object size, clear authored consequences, recoverable setbacks, crafted toys and expressive Pip. [Binding contract](../Tiny_Trouble_Design_Bible.md#binding-project-goals-and-scope), [locked identity](../Tiny_Trouble_Agent_Prompt.md#locked-game-identity). | The [player promise](../Tiny_Trouble_Design_Bible.md#the-player-promise) explicitly seeks tactile, mischievous, surprising and welcoming play. These goals are not a demonstrated demographic or market. |
| Explicit play comfort | Forgiving jump, stepwise hints/reset, configurable controls, adjustable text and reduced motion; progress should not require perfect reflexes or a guide. [Controls](../Tiny_Trouble_Design_Bible.md#core-controls-and-moment-to-moment-play), [comfort](../Tiny_Trouble_Design_Bible.md#accessibility-and-player-comfort), [campaign contract](../Tiny_Trouble_Design_Bible.md#campaign-contract). | These requirements motivate testing different experience/access needs; they do not prove accessibility for any person or device. |
| Explicit language/platform direction | English is initial text; Simplified Chinese is planned. Latest owner direction requests macOS, Windows, iPad and iPhone plus adaptive controls/Figma. | Actual Windows/mobile execution and actual Figma import remain unverified. Do not recruit a phone test around a Mac simulation and call it device evidence. |
| Working audience hypothesis | People interested in gentle solo spatial puzzles and miniature toy worlds, including a range of 3D/input familiarity, may value this design. | This is an agent inference from the tone and comfort contract. No age range, family/child audience, player-skill mix, purchase intent or demand is explicitly established. |
| Pending owner choice | Optional audience question offers cozy/mixed-experience, families/younger players with separated experience, or experienced puzzle players. | No option is selected by this record. Update the protocol when the owner answers; do not convert the question into market evidence. |

The brief gives the owner creative direction and play-feedback authority; the implementation agent handles routine assembly and objective fixes. It explicitly states that aesthetics and enjoyment require human judgment. [Agent role and art expectations](../Tiny_Trouble_Agent_Prompt.md#art-expectations), [verification and honest claims](../Tiny_Trouble_Design_Bible.md#verification-and-honest-quality-claims).

## Smallest useful current slice

Use **Crumb Crossing** as the first session: it introduces resizing, actual carrying, a visible route and a payoff without requiring the three-stage chapter. Use the stable 0.2.2 Mac build for desktop feedback, or a later corrected candidate only after its relevant functional/presentation gates. Label the exact build/hash. The 0.2.3 phone presentation is known defective; source improvements are not a device-ready release. Use Harbor only as a short follow-up when testing cargo-draft readability, the toast fix or camera framing. Do not require participants to play the whole campaign or silently substitute seeded completed profiles for earned progress.

### Local manual launcher

Current 0.2.6 actual-app manual Workshop startup/isolation smoke passes; no human input session or preference result is recorded. The 1,392 package checks include separate scripted Workshop/settings/lifecycle tests; they do not add human participants. All 26 Workshop package stills are agent-reviewed.

The local external harness has a clean **source Harbor/closer startup-and-isolation smoke** in `evidence/platform_manual_launcher_revised.log`. This checks setup, a fresh Harbor state and disposable save paths; it contains no human play, automatic route input, recording, score or preference result. Actual 0.2.4 package validation subsequently passed seven final cleanup smokes (six Harbor/closer and one default demo) plus expected replay-argument rejection; this still establishes only launcher behavior, not a human session. That package remains visually rejected for UI-027-03.

```sh
./playtest.command
./playtest.command --playtest-scene=crumb
./playtest.command --playtest-scene=workshop
./playtest.command --playtest-scene=workshop --touch-ui
./playtest.command --playtest-scene=harbor
./playtest.command --playtest-scene=harbor --touch-ui
./playtest.command --playtest-scene=harbor --camera-variant=closer --touch-ui
```

The default opens a fresh manual Toast Express demo; Crumb is the smaller first-session option. Workshop launches a fresh isolated menu for orientation, labels and home-scene review; it is not a complete gameplay session. To inspect saved maximum text manually, enter the original demo, change text size in its settings, then return to Workshop within the same isolated session. Record those steps and the resulting setting. Harbor starts fresh with **only W01S01/W01S02 prerequisite completion flags seeded**; it does not complete Harbor for the player. Every launch creates unique demo/chapter/settings paths and navigation retains that isolation. The launcher resolves its own folder, prefers the current local `builds/Tiny Trouble.app`, and falls back to the project-local Godot editor if no app exists. Record which executable/build was used; a source smoke does not certify the packaged manual flow. The external harness is excluded from game exports.

`--camera-variant=closer` applies the 0.8 study only to Harbor. Its known toast coverage of the lower raft hull/part of the ridge must be fixed before a clean preference A/B. Until then it is a diagnostic alternative with a known confound, not a candidate recommended to participants. Production default remains unchanged. `--touch-ui` on this Mac is a desktop simulation, not physical phone testing. No automatic input, capture or feedback collection is added by these commands.

This is a proposed **15–25-minute session budget**, not a measured completion target. The brief's 8–12-minute demo and 8–15-minute stage durations remain design targets. Let the person stop, ask for help or skip; record that choice without treating it as personal failure.

1. **Setup, about 2 minutes.** Ask permission for the session and separately for any screen/audio recording. Use an anonymous session code; collect only relevant self-described puzzle/3D/input familiarity and optional access needs. Record actual hardware, window, input, text/motion/audio settings, build/hash and prior exposure. Use a disposable save and explain that this is a partial build. No names, emails, device identifiers or account data are required.
2. **First encounter, up to 10–12 minutes.** Start Crumb from a fresh stage. Give only the neutral instruction: “Try this scene as you normally would. You can stop or use the game's help.” Do not explain the size solution. Observe what they notice, target, attempt and expect; record errors, hint use, resets and progress with timestamps. Avoid mandatory continuous think-aloud if it disrupts play; brief contextual questions can follow a pause or attempt.
3. **Contextual probes, about 3–5 minutes.** Ask “What do you think will happen?” before a naturally chosen action, then “What changed?” afterward. If they stall, first ask what they are trying to do; record any moderator hint before giving it. At a frustration/clarity/audio moment, capture the specific context and build state rather than asking for an abstract quality score. Use a brief Harbor follow-up only for a declared hypothesis; label inherited/seeded checkpoint exposure.
4. **Debrief, about 3–5 minutes.** Ask what the objective seemed to be, what felt satisfying/confusing, whether a cue was noticeable or tiring, and what they would change first. Offer a real choice to stop, explore/replay or try another scene; record the voluntary choice without pressure. Ask whether the session matched the kind of puzzle they expected. A “yes, another scene” response is a signal, not purchase or market demand.
5. **Synthesis.** Separate observed behavior, verbatim feedback and agent interpretation. Link each finding to the scene/time/input, compare repeated and contrasting cases, implement a bounded change with a stated hypothesis, then return to affected participants or a fresh comparable group. Preserve contradictory feedback and unsuccessful changes.

## Mandatory visual judgment at normal viewing size

The latest owner requirement makes **human judgment of proportions, cohesion and aesthetics at normal display size, without zooming, mandatory**. Check the relationship between Pip, props, environment and UI together. Mathematical ratios, mesh bounds, non-overlap assertions, agent opinions and automated beauty scores do not establish that the scene looks right. Use actual target devices when available; record unavailable device/human review explicitly.

Before close-up debugging, let the person play and view stills at the intended window/device size and normal viewing distance. Record OS scaling, window/fullscreen state, orientation, text scale and viewing context; do not enlarge a phone capture on a desktop and call it phone validation. Review both motion and stills for floating contacts, clipping, stretched materials/shapes, clutter and unhelpful empty space. A zoomed diagnostic view may explain a finding afterward, but it cannot replace the normal-view judgment.

Ask specific, contextual questions without identifying the agent's preferred answer:

- “Where does your attention go first? What looks important to interact with?”
- “How do Pip, the objects and the surrounding space feel in relation to each other? Does anything seem out of proportion?”
- “Can you tell which object and size are selected from this normal view?”
- “Does any object appear to float, intersect, stretch or change shape unexpectedly as it moves?”
- “Does this view feel crowded, empty or about right? Point to the part that gives you that impression.”
- “How does the interface fit with the scene? Does it hide anything you want to see?”
- “Do the materials, character and interface feel like the same world? What seems out of place?”
- “Which moment looked or felt best, and which would you change first?”

For a substantial material/camera/UI variant, use the same scene, pose, action, input and normal-size context; alternate presentation order across participants when practical. Include short uninterrupted motion, not only a flattering still. Record concrete preference reasons, task visibility and discomfort separately. Do not decide from a single player's vote or average rating; retain disagreement, owner direction and the relevant audience/experience context. **There is currently no human normal-size visual judgment or physical-device result in this record.**

## Representation, ownership and recurring feedback

Until the owner selects an audience, recruit only through an owner-provided or explicitly authorized channel; this document sends no invitations. As a **proposed exploratory round**, include several relevant players with both lower and higher 3D/puzzle familiarity, record that mix, and avoid describing a convenience sample as representative of a market. If families/younger players become the chosen audience, define separate cohorts and appropriate consent/supervision before sessions; do not infer children's suitability from adult testing. Actual phone/controller/accessibility questions require corresponding hardware and participants, not injected events alone.

The owner accepts creative direction and decides substantial tradeoffs. Representative-player observations inform whether the design works for its intended audience. Agents may autonomously close reproducible bugs, run checks, prepare comparisons and recommend changes; an agent's visual preference, synthetic rating, automation pass or one player's enthusiasm is not human acceptance or market proof. Record owner decisions separately from player findings. Keep useful objective work moving while external participation is unavailable; retain the human gate as unverified and do not expand content past the owner's presentation boundary.

Collect feedback repeatedly at meaningful changes: first encounter/onboarding, after a substantial UI/audio/material/camera change, after a correction to a recurring problem, and before accepting the presentation milestone. Compare the same task and settings when feasible, use fresh players for first-discovery questions, and counterbalance comparison order when testing two variants. Avoid pooling returning players' learned solutions with first-play completion times. Do not optimize a single average rating while hiding confusion, discomfort or a subgroup's blocked interaction.

## Substantial-decision evidence ledger

“Owner requirement,” “observed technical issue” and “agent hypothesis” are different evidence types. None of the rows below contains a human test result.

| Decision | Evidence type and concrete basis | Current action / evidence | Human or owner boundary |
| --- | --- | --- | --- |
| Presentation before stage expansion | **Explicit owner requirement**, reinforced by QUALITY-01. | TT-028 gap matrix active; W01S04 drafts isolated under `development/paused_w01s04/` with `.gdignore` and export exclusions. | Owner directs acceptance; no agent score certifies appeal. |
| Requested four platforms and Figma | **Explicit owner requirement**; capability limits are observed inventory results. | Mac-native evidence, Windows structural export, local Figma plugin 247 checks; iOS Team ID/device and Figma execution unverified. [Platform plan](PLATFORM_PLAN.md). | Device support and owner design approval are not inferred from installed SDKs or a plugin build. |
| Initial landscape phone gameplay, portrait guard | **Agent implementation decision** within the requested platforms and readable-camera contract. | Injected layout/lifecycle tests; actual phone-shaped source route. | Whether orientation and pad layout are comfortable needs owner direction plus actual relevant-device sessions. |
| Touch target size and input-mode hints | **Agent hypothesis backed by technical bounds/input checks**, not measured ergonomics. | Recorded 88-logical-unit targets, safe-inset fixtures, keyboard/controller hint switching. Current source and actual package adaptive runs each pass 1,293/28 reviewed frames; physical ergonomics remain untested. | Mac rendered pixels are not physical iOS points. Players must validate reach, legibility and discoverability on real devices. |
| Move toast / shrink objective card | **Observed technical issue**: frozen 0.2.3 hides Pip/cargo; new gate reproduces 694/387 overlap samples out of 818. | Corrected 0.2.5 source route 14/806 and actual package 14/816 pass with all 10+10 frames reviewed; bounded UI-027-01/02 closure, not a human clarity result. | Objective visibility can be fixed without waiting for preference feedback; clarity and noticeability still need play observation. |
| Persistent target card at max text | **Observed technical issue UI-027-03**: `phone_max_024/ashore.png` hides Pip body/feet even though toast-only bounds pass. | Historical 0.2.4 remains rejected; corrected 0.2.5 route 14/816 and direct still review close the named defect. This is prior evidence, not a full 0.2.6 route rerun. | Evaluate Pip/prop/environment/UI together at normal display size. No isolated mathematical gate or agent score substitutes for human judgment. |
| Bounded audio pool and duplicate-cue removal | **Implementation finding/change**, separate from subjective quality. | Source feedback tests pass 59 and revised lifecycle passes 134; provenance migration/fixtures pass 16 while preserving shipped audio bytes. Listening remains unperformed. `evidence/platform_audio/`. | Listening, cue distinction, repeated-cue fatigue and mix balance require actual playback/human evidence. |
| Warmer Harbor deck color | **Agent art-direction hypothesis**, grounded in the crafted warm material contract. | Source viewed in six phone frames; accepted as a direction for further review, not full material acceptance. | Compare readability/material identity in context; owner/player reactions remain unrecorded. |
| Camera scale 0.8 study | **Agent hypothesis**, not an owner-selected framing change. | Study route passes 13 actor-bound checks, but art review reports its toast covers the lower raft hull/part of the ridge. Production default retained; full normal-size human framing review pending. | Route completion alone cannot choose composition or judge motion comfort. Compare actual normal-play footage and player observations before adopting. |
| Cap 60 and sustained profiling | **Explicit brief performance target** plus measured reference-host evidence. | Stable short 60-second run passed; frozen 0.2.3 twenty-minute workload failed, despite low callback percentiles. The repaired collector subsequently passed the 0.2.5 focused 120-second workload; the 0.2.6 ten-minute attempt aborted at 106.994 s measured on native focus loss; sustained gate remains open. [Measured failure](../evidence/platform_profile/macos_candidate_023_1080p_20m/post_run_review/REVIEW.md). | No renderer downgrade, thermal claim or smooth-play satisfaction claim follows from an invalid workload. |

Add a row before a substantial product change: requirement/finding, hypothesis, smallest comparison, owner decision needed if any, build/evidence, observed result, contradictory evidence and retain/revise/revert outcome. Routine reversible fixes remain authorized; this ledger is not a new approval ceremony.

## Anonymous feedback template

Copy this blank record for an actual session. Leave unknown fields unfilled; never populate them with simulated players or predicted responses. Store the minimum necessary data locally and honor the participant's recording/retention choice.

```text
Session code:
Date / moderator:
Build version + hash / scene / fresh or seeded save:
Actual platform, input, display/window, text/motion/audio settings:
Prior exposure to this build:
Self-described puzzle / 3D / input familiarity:
Optional comfort/access needs relevant to this session:
Recording consent and retention choice (or no recording):
Declared question/hypothesis for this session:

Observed timeline (timestamp | action/context | outcome | moderator help):
Goal stated in the player's words:
Spontaneous experiment(s):
Confusing or failed interaction(s):
Hints/resets requested; hints supplied by moderator:
Completion/stop time and reason (not an imposed success label):
Normal viewing context (no zoom, actual device or declared desktop simulation):
Pip / prop / environment / UI proportion and cohesion comments:
Floating, clipping, stretch, clutter or empty-space observations in stills and motion:
Variant order and contextual preference reasons (if comparing):
Specific visual, control, motion or audio comfort comments:
Optional anchored rating, if useful: clear goal 1=not at all ... 5=very clear; N/A allowed:
What felt satisfying? What would you change first?
Voluntary next choice: stop / explore / replay / another scene / undecided:
Verbatim feedback (only if recorded accurately):

Agent interpretation (separate from observation):
Related decision/gap ID:
Alternative explanation or contradictory evidence:
Proposed bounded change and next verification:
Owner direction/decision, if supplied:
Follow-up session/build and result:
Human enjoyment status: UNVERIFIED until this actual record supports a scoped finding.
Market demand status: UNVERIFIED; this session cannot establish it.
```

**Current human-evidence ledger: zero sessions, zero participant responses, no enjoyment or demand finding.** Automated tests establish behavior under their conditions; screenshots show sampled appearance; recordings/measurements have their declared technical scopes. Satisfaction, taste and demand require appropriately scoped human evidence.

Current Workshop decision evidence: UI-027-04 saved scaling and UI-027-05 portrait navigation, including early-layout/audio-drain races, are corrected in 0.2.6. Actual app 825 mobile +319 desktop +23 orientation checks and 26 agent-reviewed stills close the bounded defects. Original 0.2.5 editor-hosted PCK 732/71 and initial 0.2.6 source 825/20 precede the extra race 20/2 →fixed 23/0 evidence. This is observed correctness work, not a player preference.

The final compact-phone max-text still at actual 666×374 shows dotted diagonal grain and thin saucer rings. This observed aliasing is not proof of shimmer or a human complaint. Pair any later alternatives at the same camera/display context and inspect motion; ask whether detail clarity improves without overwhelming Pip. The centered mobile menu's roof/drawer coverage remains a separate open composition question. No redesign or human acceptance is inferred from the functional fixes.
