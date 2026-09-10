# Tiny Trouble Game Design and Development Brief

Version 1.0 · September 9, 2026

## Purpose and project status

Build Tiny Trouble into a substantial, polished solo puzzle adventure about a tiny creature turning ordinary household objects into extraordinary playgrounds. A development agent should own implementation, assets, level assembly, testing, and iterative improvement. The user supplies creative direction and play feedback when available; routine development should proceed without repeated permission requests.

This document is a production specification and aspirational content plan. It is not evidence that the game, assets, playtests, or performance targets already exist. The companion file, Tiny_Trouble_Agent_Prompt.md, provides the execution instructions. Start from the first playable milestone and progressively earn the larger scope through completed, verified chapters.

The long-term vision is a connected house with 12 themed worlds and 60 main stages, supported by optional challenges, expressive characters, secrets, a growing workshop hub, and a sandbox. The release target is a complete solo campaign. Two-player cooperation is a later extension with its own design and validation work; no required solo puzzle should depend on a second person.

## How to use this brief

Read the binding contract first. It resolves scope and art expectations. Then read the core game design, the 60-stage campaign, and the production plan. The companion agent prompt turns this brief into an implementation assignment.

| Part | What it fixes |
| --- | --- |
| Binding project goals and scope | The game identity, authorized content, and deferred features |
| Locked art direction and visual acceptance | The style, deliverables, and inspectable quality standard |
| First milestone specification | The exact breakfast demo, object roles, solution, and recovery |
| Ordered milestones and continuous work | The work queue and rules that prevent drift |
| Core design sections | Controls, resizing, object systems, presentation, progression, and technical direction |
| Campaign contract and Worlds 1–12 | Exactly 60 main stages plus optional challenge examples |
| Production and verification sections | Asset generation, testing, evidence, checkpoints, and resumption |

## Binding project goals and scope

This contract incorporates the user's requirement for clear goals, clear expectations, excellent art, and focused continuous development. Within this design package, it takes precedence over optional suggestions elsewhere. Runtime, repository, and user instructions still govern the executing agent. Creative latitude applies to solving the specified game, not to replacing it with a different project.

| Requirement | Binding expectation | Evidence of compliance |
| --- | --- | --- |
| IDENTITY-01 | A solo, stylized 3D miniature puzzle adventure through an ordinary house | Every milestone contains the same protagonist, perspective, and core interaction |
| SCALE-01 | Eligible objects have readable small, normal, and large states with authored consequences | Demonstrate state changes, invalid transitions, and recovery for each object family |
| PLAY-01 | Scenes are interactive playgrounds with a clear objective, experiments, and a memorable payoff | Playable route, scene-specific interactions, and captured results |
| ART-01 | Cohesive, polished, handcrafted toy art is a first-class deliverable | Reference sheet, target frame, asset sheet, consistent captured gameplay |
| ART-02 | Every player-visible asset in a completed milestone meets its art contract | No unresolved placeholder or presentation defect hidden behind a completion claim |
| SCOPE-01 | Planned campaign: exactly 12 named worlds and 60 main stages | Campaign manifest lists W01S01 through W12S05 and their completion states |
| SLICE-01 | First integrating milestone: one breakfast demo with six principal props, three linked puzzles, one optional discovery, and toast-launch finale | A complete route from a clean launch, with checkpoints and a return path |
| SOLO-01 | Every required campaign stage works for one player | Solo solution and recovery route recorded for each stage |
| QUALITY-01 | Function, presentation, and recovery pass before breadth expands | Gate report names actual evidence and remaining unverified items |
| FOCUS-01 | Every work item belongs to the current milestone or fixes a regression in completed work | Task record identifies requirement, observed need, expected benefit, and acceptance check |
| CONTINUE-01 | Milestone completion leads to the next approved improvement during available authorized execution | Checkpoint and next task are updated; the agent proceeds without routine approval pauses |

The maximum planned content envelope is 60 main stages, up to 120 optional variants within those stages, the Matchbox Workshop, and sandbox/photo features using approved assets. “Enormous” describes the completed vision. It does not authorize unbounded new genres, unrelated features, or additional worlds beyond this brief.

### Decisions that are already made

The game is solo first. Its playable identity is changing the scale and use of household objects. Its camera is fixed or gently guided in a readable three-quarter view. Its visual treatment is a crafted toy diorama. Its first chapter is the Breakfast Table. Its campaign world order follows the scene bible. Its production order is one polished demo, then the first chapter, then the approved campaign in sequence.

The agent may independently tune controls, jump forgiveness, camera placement, object dimensions, timing, materials, effects, level layouts, and technical implementation to satisfy these requirements. It should record meaningful decisions and continue. A preference for a new framework, a new genre, or a fashionable feature is not a sufficient reason to restart.

### Work that stays deferred

Do not implement multiplayer, procedural campaign generation, general-purpose AI companions, live generative dialogue, crafting trees, combat systems, monetization, account systems, public leaderboards, new campaign settings, or an unrelated game editor during the approved solo campaign work. Local co-op remains a separately proposed future extension. Sandbox and photo tools enter production only at the named expansion milestone after the main campaign gates pass.

If a planned puzzle seems to require an entirely new system, first solve it with established systems. If a new system is still necessary, document the stage IDs that need it, the player benefit, the smaller alternatives considered, the complete art/test requirements, and the integration cost. Implement it only when it fits an already approved campaign need. Otherwise place it in the deferred list and select an in-scope task.

No milestone may be reported complete because code files exist or a menu loads. A milestone is complete only when its specified experience works and the evidence is recorded. If a visual or human check cannot be performed, state that explicitly; the missing check does not become an automatic pass.

## Locked art direction and visual acceptance

The ambition is world-class art direction and polished execution. That phrase expresses the standard of care, not a claim the agent can prove by awarding itself a score. Use a precise art contract so production has a stable target.

### The visual contract

**Medium:** an original miniature set made from painted resin, stitched fabric, paper, rounded wood, glazed ceramic, and a few restrained metal accents. Pip looks handmade and touchable. Props look deliberately designed rather than randomly collected from incompatible sources.

**Shape language:** broad, readable silhouettes; rounded exposed edges; mildly exaggerated handles, buttons, eyes, and contact surfaces; reduced microdetail. Preserve recognizability at all permitted sizes. Give important props one distinctive silhouette feature. Decoration should be simpler and lower contrast than current interactables.

**Pip's proportions:** start from a compact bean-shaped torso, oversized feet, a small fabric tail, and two expressive eyes. Keep the silhouette, relative eye spacing, tool attachment, and material families constant between animations and scenes. Establish proportions in the reference sheet before building a campaign asset library.

**Base palette:** cream `#F5E6CC`, toasted amber `#E5A54B`, soft coral `#C95C54`, muted teal `#4A9290`, and deep slate `#384657`. World palettes may shift within the identities described in the scene bible. Keep Pip, tool feedback, and interface colors consistent. Palette hex values are starting art decisions; changes require a documented readability or cohesion reason and a deliberate update to the reference sheet.

**Camera:** begin with a three-quarter view around a 45-degree horizontal angle and a 30–40-degree downward view, then tune to the actual scene. Use a stable orthographic or restrained perspective projection. Choose one projection for the first slice and retain it unless evidence shows a playability problem. Avoid sudden unrequested rotations during movement.

**Lighting:** a broad, warm key light, soft fill, clear contact shadows, and restrained highlights. The breakfast slice should feel like a welcoming tabletop set lit for a close-up photograph. Night-world lighting can be cooler, but Pip and interactables must stay readable. Avoid crushed dark areas and bright effects that conceal landing surfaces.

**Materials:** use a small family of reusable materials with intentional roughness and scale. Cloth gets restrained weave; paper gets clean edges and gentle grain; ceramic gets a broad glaze highlight; wood gets simple grain at an appropriate scale. Material appearance should remain coherent when an object grows. Avoid stretched textures, inconsistent texel scale, and accidental plastic gloss across every surface.

**Animation:** elastic anticipation, satisfying settling, clear weight, expressive reaction, and fast return to control. Idle motion should suggest life without constantly distracting from a puzzle. Important feedback must be present in motion and in a still frame where relevant.

**Interface:** a small, legible layer with rounded cards, restrained icons, readable typography, and stable placement. Use text contrast of at least 4.5:1 against the actual background as an internal design target for standard text. Validate this target where measurable; do not claim accessibility certification from a single contrast check. Keep text out of generated textures.

### Required art deliverables for the first slice

1. One art-direction sheet containing palette, material examples, camera framing, lighting, Pip proportions, and two representative prop designs.
2. One aspirational target frame showing the breakfast scene. Clearly label any concept render as a target rather than an actual game screenshot.
3. One actual in-engine comparison frame from the same composition. Track visible gaps between target and implementation.
4. Pip with the core movement, interaction, resize, celebration, and recovery animation states required by the route.
5. Six principal prop families with every exposed size state, contact behavior, material, and interaction effect completed.
6. A small supporting environment kit: table, dishes, crumbs, cloth, background silhouettes, landing area, and route markers.
7. Finished targeting, resize, checkpoint, hint, pause, settings, and completion UI for the slice.
8. Auditioned critical effects when audio playback is available, plus an initial music loop or an explicitly recorded audio limitation.
9. A provenance manifest and editable sources or reproducible generation inputs for all produced assets.

### Repeatable visual review

Capture six fixed views after substantial visual changes: opening composition, puzzle one, puzzle two, puzzle three, optional discovery, and finale. Capture all permitted states of each principal prop as a contact sheet. Also record the route when capture is supported. Compare the same viewpoints so changes can be judged against evidence rather than memory.

The inspectable visual gate requires: no visible placeholder assets or debug UI; no missing textures or broken shaders; no obvious clipping or floating contacts along the required route; readable targets and landing surfaces; distinguishable size states; consistent materials and lighting; complete movement and resize feedback; no distracting flicker; and legible, unclipped interface elements at every explicitly supported resolution and aspect ratio.

Start validation at 1280×720 and 1920×1080 if those render sizes are available. Add further formats only when supported and tested. Do not claim all resolutions work from two samples. During art work, preserve control responsiveness and revisit measured performance if effects or geometry increase cost materially.

Passing the visual gate establishes a coherent, inspectable production result. Human review is still needed to judge charm, composition, memorability, and whether the result merits a world-class description. If no human review is available, mark those judgments pending and continue with objective improvements and the approved production plan.

## First milestone specification

The first integrating milestone is **VS01 Toast Express Demo**, a self-contained breakfast scene sampling the mechanics that will populate World 1. The demo is a development milestone, not a 61st campaign stage. On conversion to the five-stage chapter, preserve and reuse its proven components; introduce the simple lessons in W01S01–W01S02 and build on the finale in W01S05.

The demo contains six principal interactive prop families: spoon, blueberry, cereal box, napkin, butter pat, and toaster assembly. The toaster assembly includes its lever and moving toast platform. Its base may remain fixed; not every decorative or mechanical subpart needs resizing. Supporting decoration must not introduce an extra required puzzle system.

**Opening:** Pip wakes beside a teacup and can see the matchbox landing flag across the table. A nearby prop reacts to movement. The player learns one action at a time and reaches the first resize opportunity promptly. The interface explains the current action in one short prompt.

**Puzzle one, the spoon bridge:** shrink the spoon to carry it through a cup handle, place it in a clearly suggested rest position, and enlarge it to cross a saucer gap. A later latch opens a permanent short return route, so moving the spoon cannot strand the player. Test both directions and an early reset.

**Puzzle two, blueberry ballast:** enlarge the blueberry on the cereal-box flap to raise a ramp. Carry a small butter pat to its marked wedge socket and resize it to hold the ramp safely. The blueberry can then be removed and reused without collapsing the required route. Weight changes are shown through the flap's movement and clear mechanical connections.

**Puzzle three, launch preparation:** position and enlarge the napkin at the visible landing zone. Use the blueberry to depress the toaster's toy lever and lower the toast platform. Board the platform, then shrink the blueberry from the intended target distance to release the launcher. The player's earlier setup determines the landing preparation; the flight itself uses a controlled path and generous recovery.

**Optional discovery:** use an alternate interaction on the existing cereal-box assembly to open a small panel revealing a tiny breakfast picnic and a short character reaction. This reuses an existing behavior and introduces no seventh principal prop family. The discovery never gates completion.

**Finale:** toast carries Pip through a cereal-box window and lands on the prepared napkin near the matchbox flag. Use a short musical payoff, elastic landing, nearby prop reactions, and a clear completion state. Give the player a way to replay, return to the start, or continue to the workshop when that exists.

**Recovery:** lost principal props return to a nearby known tray or restore through a local reset. Checkpoints exist before each puzzle and before launch. A bad landing must not require replaying the entire demo. Exiting and reloading at puzzle boundaries must restore a valid state.

The play-duration hypothesis is 8–12 minutes for a first-time player. The scope is fixed by interactions and quality gates, not by forcing that duration. Shorten dull traversal or repeated attempts if observed play suggests it.

### The definition of a completed demo

The demo launches from a documented command or executable, is playable through ordinary controls, has the specified six prop families and three puzzles, supports recovery and save/reload at the named boundaries, meets the visual gate, provides critical action feedback, and produces inspectable evidence. A list of known limitations remains explicit. Human enjoyment and unmeasured hardware performance cannot be silently marked verified.

## Ordered milestones and continuous work

| Milestone | Exact deliverable | Gate before advancing |
| --- | --- | --- |
| M0 Foundation | Repository setup, reproducible launch, Pip controller, targeting, resize transitions, local reset | A small test scene proves safe state changes and ordinary control |
| M1 Toast Express Demo | VS01 as specified, with finished first-slice art and feedback | Functional, recovery, visual, and available performance checks pass; missing external validation is stated |
| M2 Breakfast Chapter | W01S01–W01S05 and minimal Matchbox Workshop | Five distinct completed stages and working progression |
| M3 Campaign Chapters | Worlds 2–12, in order, five stages per world | Each world passes its gates before the next becomes the integrating milestone |
| M4 Campaign Polish | All 60 stages, complete save flow, onboarding, accessibility and presentation passes | End-to-end campaign verification with documented support matrix |
| M5 Approved Extensions | Up to 120 optional stage variants, sandbox/photo tools using campaign assets | Core campaign remains stable; each extension has clear player value and verification |
| M6 Ongoing Refinement | Fixes and improvements within the approved game, informed by evidence | Each retained change solves a documented issue or improves a defined quality dimension |

Only one milestone owns the integration frontier at a time. Parallel agents can work on bounded code, assets, sound, or verification inside that milestone. They must not start unrelated worlds merely because they have capacity. Early experiments for a future dependency are allowed only when they resolve a concrete risk to the current approved plan and do not become a competing project.

Each task record must include: task ID, parent milestone, requirement ID, observed problem or missing deliverable, expected player benefit, scope limit, implementation note, acceptance check, result, and evidence location. Keep task status honest: proposed, active, verified, blocked, or deferred. Keep “human review pending” separate from code defects and from passing technical checks.

Choose work in this order: crashes and corrupted saves; progression blockers and unrecoverable states; control and camera problems; current milestone omissions; art-contract failures; weak feedback or confusing puzzles; the next planned stage; approved optional content; and demonstrated polish opportunities in completed work. After each successful change, choose the next substantive task without asking whether to continue.

A stage does not have to reach an unknowable state of perfection before the next one can begin. It must meet explicit gates. This prevents endless polishing of one spoon while the rest of the approved game remains absent. Later improvements can revisit completed stages when new evidence reveals a real issue.

If all planned deliverables and known defects are exhausted, perform a focused audit of an under-reviewed quality dimension, such as save compatibility, camera behavior on unusual routes, readability under reduced effects, or a weak campaign transition. Keep changes only when the audit produces a concrete reason. Do not manufacture features, rewrite stable systems, or rerun unchanged tests solely to consume usage.

## The player promise

You are very small. Everything around you has unexpected potential. A spoon can become a bridge, a duck can become a ship, a sock can become a parachute, and a toy dinosaur can become a ride. Your power changes objects between small, normal, and large states. Every scene should invite the thought: “What happens if I make that bigger?”

The game should feel tactile, mischievous, surprising, and welcoming. Players should enjoy touching objects before they fully understand the puzzle. A wrong experiment can produce a funny, recoverable result. Success should transform the scene into a little spectacle that the player helped create.

The strongest form of this game is an adventure through interactive dioramas. Attractive backgrounds support the playable objects, routes, and character reactions. Scene variety comes from changing how familiar mechanics combine in a fresh setting.

## Creative identity

**Working title:** Tiny Trouble. Treat all character and feature names as provisional creative names, not verified trademarks.

**Protagonist:** Pip, a small handmade wind-up creature with rounded feet, expressive eyes, a fabric tail, and an oversized tool called the Scale Spool. Pip can communicate surprise, pride, uncertainty, and delight through posture and short nonverbal sounds. The character should remain readable at normal gameplay camera distance.

**Premise:** Pip accidentally scatters size sparks through a sleeping house while repairing a tiny workshop. Ordinary things begin behaving at the wrong scale. Pip must reconnect the rooms and repair their size anchors before the household's morning toy parade. Morning is a story frame, not a real-time campaign deadline.

**Hub:** The Matchbox Workshop. Rescued characters gather here, postcards record discoveries, and completed worlds contribute a working miniature exhibit. By the end, the workshop contains a small, moving model of the house that reflects the player's adventure.

**Recurring characters:** a cautious thimble caretaker, a boastful wind-up beetle, a lost sock that insists it is a cape, and an enormous household cat. The cat is a curious moving landmark and occasional playful obstacle. Encounters should avoid animal distress and prolonged punishment; its paws, tail, naps, and attention create readable environmental challenges.

**Narrative delivery:** environmental transformations, short conversations, character reactions, collectible illustrated notes, and scenes at the workshop. Keep dialogue brief during play. Let the player skip or replay story moments. The main route must make sense without reading every optional note.

**Tone:** warm comedy with occasional wonder and mild suspense. Humor comes from scale, timing, stubborn objects, overconfident characters, and unexpected consequences. Avoid constant quips or jokes that interrupt control.

## Product scale and priorities

| Layer | Planned scope | What unlocks the next layer |
| --- | --- | --- |
| Interaction prototype | One test room, one character, three sizes, six props | Movement, targeting, three-state resizing, and reset work reliably; subjective enjoyment remains pending human review |
| Polished vertical slice | One breakfast-table stage, three connected puzzles, a toast-launch finale | A complete start-to-finish route, clear feedback, reliable recovery, consistent presentation |
| First chapter | Five Breakfast Table stages plus a small workshop | The reusable scene and object systems support multiple distinct puzzles |
| Campaign alpha | Twelve worlds, five main stages each | Every stage passes its functional, recovery, visual, and available audio gates; campaign-wide integration remains to verify |
| Campaign beta | The same 60 finished stages with campaign-wide consistency, onboarding, accessibility, and regression passes | Campaign-wide technical issues have been addressed; human playtest findings and any pending review are explicitly recorded |
| Expanded edition | Optional challenge variants, sandbox, and photo tools within the approved campaign | Existing campaign quality remains stable while extensions are evaluated |

A target of 8–15 minutes per main stage yields roughly 8–15 hours for 60 stages before exploration, retries, or optional challenges. These are design targets derived from planned stage length, not measured completion times. Revise them after observation. The game should never pad playtime to meet a number.

The hierarchy is: playable interaction, clear objective, rewarding consequence, dependable recovery, coherent presentation, then more content. The 12-world plan is a direction for sustained development, not an instruction to create 60 unfinished scene files immediately.

## Core controls and moment-to-moment play

Provide movement, a forgiving jump where useful, interaction or grab, resizing, target selection, pause, and reset. Support keyboard and mouse first and gamepad as soon as the first slice is stable. Bindings should be configurable. Avoid making accurate mouse aim mandatory for gamepad play.

The basic loop is: notice an interesting object, inspect its size states, try a change, observe the reaction, use the resulting route or mechanism, discover a new combination, and trigger a satisfying payoff. Checkpoints should sit near experiments so the player can learn by doing.

Use a fixed or gently tracking three-quarter camera as the default. Allow a small number of deliberate viewpoint changes where they help a puzzle. The player must be able to judge landing surfaces and object scale. During a spectacular event, cinematic framing must preserve necessary control and return promptly to a useful gameplay view.

Targeted objects receive a clear outline, an icon showing permitted sizes, and a preview of the intended result. Feedback must not depend on color alone. A failed resize should communicate the reason, such as insufficient space, an object being anchored, or the target being temporarily occupied.

## Resizing rules

### A readable model

Objects use three discrete states: small, normal, and large. Begin with visible scale ratios such as 0.5, 1, and 2 relative to an object's authored normal size, then tune specific objects for readability and puzzle needs. Ratios are initial design values rather than universal laws. Some objects may expose only two states.

Each state owns explicit gameplay values: visual dimensions, collision shape, interaction sockets, carry permission, usable surfaces, weight category, wind response, buoyancy category, and any authored special response. Cartoon rules should remain consistent within an object family. Do not derive every property from physically realistic cubic mass scaling.

Changing an object must not silently launch a player through geometry, trap them inside a collider, or destroy a required item. Validate available space before committing a transition. If safe displacement is possible, show it clearly. If it is not, reject the transition with helpful feedback. Implement the policy once and reuse it.

Resizing should feel fast and elastic, with an anticipatory motion, a short transformation, and a settled result. Start around 0.25–0.5 seconds for a simple transformation, then tune through play. Preserve input responsiveness and provide reduced-motion settings. The original and resulting collision behavior must match the visible interaction.

### Player freedom without resource traps

Basic resizing is freely repeatable. Avoid a consumable energy meter in the first campaign design: experimentation is the main activity, and a depleted meter can turn a mistake into a softlock. If a later challenge uses a limited number of resizes, present it as an optional scored variant with an immediate restart.

An object's weight, reach, anchoring, and shape can create interesting constraints. State those constraints through animation, markings, examples, or short tooltips. A large item may be uncarryable but usable as a bridge; shrinking it may permit transport while removing that bridge.

A local reset restores the puzzle to a known state. Campaign progress already saved outside that puzzle remains intact. An undo feature is desirable when it can correctly reverse all affected state. Do not present incomplete undo as reliable; checkpoints are the baseline recovery mechanism.

### Ability progression

| Ability | Purpose | Introduction rule |
| --- | --- | --- |
| Basic resize | Change a reachable object between permitted sizes | First two minutes of the first stage |
| Carry and place | Move small props onto visible sockets or stable surfaces | After the player has seen one useful size change |
| Aim across a gap | Resize a visible object at longer range | Introduce after close-range rules are familiar |
| Anchor bookmark | Store a local configuration for quick retry | Add when puzzles involve three or more dependent objects |
| Delayed resize | Schedule a short, visible countdown transformation | Add only after a stable campaign foundation; solo timing puzzles must be recoverable |
| Size link | Change two specifically linked objects with one action | Late-campaign remix of existing rules, not a mandatory prerequisite for early content |

The first three abilities are sufficient for the initial campaign chapters. Later abilities must earn their place by enabling several strong puzzles. If an ability adds complexity without producing better play, revise or remove it and update affected stages.

## Reusable object and scene systems

The content ambition depends on a small set of dependable systems. Every new world should mostly reuse existing systems with new visual forms and combinations.

| System | Common props | Gameplay use | Essential verification |
| --- | --- | --- | --- |
| Bridge and ramp | Spoon, ruler, comb, book, plank | Change reach, height, or traversability | Collision matches the surface; scale transitions preserve a safe route or reset |
| Weight and balance | Fruit, buttons, cans, toy blocks | Operate seesaws and pressure switches | Thresholds are readable; objects settle predictably |
| Rolling | Marble, blueberry, spool, ball | Trigger distant mechanisms or ride guided paths | No uncontrolled tunneling; lost objects recover |
| Spring and launcher | Toaster, clothespin, toy spring | Send a prop or Pip to a visible destination | Aiming and landing are readable; failure recovers promptly |
| Buoyancy | Duck, cork, sponge, shell | Float, carry, block, or expose a route | Use authored buoyancy states; a simple water surface is sufficient |
| Airflow | Fan, dryer, vent, paper sail | Lift, glide, redirect, or hold objects | Effect boundaries are visible; repeat runs behave consistently |
| Track and conveyor | Toy railway, belt, moving shelf | Coordinate movement and timed transfers | Checkpoints preserve intended sequence state |
| Sockets and latches | Keys, pegs, clips, plugs | Make object placement understandable and stable | Correct placement feedback; no mandatory millimeter precision |
| Light and shadow | Lamp, mirror-like panel, cutout | Reveal a clue or align a silhouette | Accessible alternatives for low contrast; only add optical complexity when needed |
| Living reactions | Cat, toy beetle, sock character | Provide moving obstacles, hints, and comedy | Telegraphs are clear; recovery avoids long waits |
| Chain sequences | Mixed props and mechanisms | Produce spectacular chapter endings | Restartable from a known state; results actually depend on the player's setup |

These are gameplay abstractions. Simulate only what the player needs to understand and manipulate. A whirlpool can use a visible water effect plus a controlled current field; it does not require a computational fluid simulation. A toy train can follow an authored track. A cat can have a small number of readable actions instead of an elaborate general behavior system.

### Object contract

Every interactable should declare a stable identifier, object family, permitted sizes, state-dependent properties, available interactions, reset state, save behavior, feedback assets, and safety checks. Scene authors should be able to configure a familiar family without duplicating its implementation.

For example, a spoon declares small as carryable, normal as a short ramp, and large as a bridge that spans a particular gap when placed in a valid rest position. The spoon can use common materials and feedback while the scene defines its sockets and role in the puzzle. “Spoon becomes bridge” should be encoded in reusable behavior and scene data, not scattered through unrelated input handlers.

Keep gameplay state separate from visual presentation so that a new spoon material does not change puzzle logic. Save stable IDs and meaningful states rather than volatile scene pointers or incidental animation frames. Treat moving sequences carefully: restore at a known checkpoint state when exact mid-sequence restoration would be unreliable.

## Level design standards

Each main stage should contain a clear objective, one new idea or meaningful remix, a safe experiment, two to four connected applications, an optional discovery, and a visible payoff. Duration is a result of good pacing, not a requirement to insert extra steps.

Every stage must document at least one valid solution, intended alternate solutions, object recovery behavior, checkpoints, and likely player misunderstandings. A solution may be emergent, but the author must still prove that the required route exists. Unplanned shortcuts that are fun and do not invalidate progression can become supported solutions after review.

Use the sequence of introduction, variation, combination, and celebration. The first encounter with a rule should isolate it. A later encounter can combine it with another established rule. The final sequence should reward understanding with an event the player causes.

Every stage must include at least two optional, reactive details that support its personality: a cereal face sneezes when resized, a sock bows after becoming a sail, a toy applauds a successful launch, or a cat watches a rolling marble. They should reuse animation and event tools so expressive detail remains affordable.

Failure should be informative and brief. Preserve already understood progress when possible. Do not force a player to repeat an introductory conversation or a long animation after a missed jump. Mandatory precision, time limits, and complicated camera manipulation should be rare and adjustable.

### How a scene qualifies as fun

An authored scene is ready for a playtest when the player can identify something interesting within a few seconds, cause a clear reaction within the first minute, discover at least one useful relationship, and reach a payoff without reading a page of instructions. These are design goals to verify, not promises of actual enjoyment.

Human observation should answer: Did the player experiment? Did they understand why an attempt failed? Did they anticipate a funny outcome? Did they smile, comment, or try an optional interaction without prompting? Did they want to retry or see another scene? Record observations accurately. Automated route completion is evidence of functionality, not evidence that a player enjoyed the stage.

## Art and presentation direction

Build a coherent toy-like visual language: rounded silhouettes, slightly exaggerated proportions, tactile materials, warm highlights, soft contact shadows, and restrained detail. Maintain readable value contrast between Pip, interactables, hazards, and background dressing. Give each world a limited palette and distinct accent color while keeping shared UI and character materials consistent.

Create an art reference sheet before generating a large asset set. It should specify Pip's front, side, and three-quarter proportions; scale relative to common props; the material palette; lighting; camera elevation; icon language; and representative object shapes. Evaluate generated assets against this sheet. A collection of individually attractive but stylistically incompatible assets is unfinished work.

For agent-led production, construct editable geometry from reusable primitives and parameterized shapes where suitable. Use image generation for concept art, illustrations, decals, and textures when the capability is available. Raster concept art is a reference, not a substitute for a rigged, collidable in-game character. Document which tools created which assets and retain editable source files or reproducible generation parameters.

Prioritize one excellent protagonist, a consistent interaction effect, and a small set of highly readable props before making dozens of decorative models. Background detail should improve composition and scale perception. Avoid adding visual noise that makes the route harder to understand.

### Animation direction

Pip needs idle, walk, run if supported, jump, fall, landing, grab, carry, tool aim, resize action, celebration, surprise, and recovery. Animation can use simple rigs, procedural motion, and reusable curves. Foot placement and contact deserve attention even in a stylized game. A character sliding without relation to the ground reads as unfinished.

Props need resize anticipation, transformation, settling, impact, refusal, and special-reaction states. Maintain consistent timing families so objects feel related. Use animation and sound to communicate weight: a large rubber duck should settle differently from a metal thimble.

Spectacle can include squash and stretch, particles, confetti, splashes, dust, camera easing, and reaction animations. Expose controls to reduce camera shake, motion effects, and flash intensity. Essential information must remain visible when those effects are reduced.

### Sound and music

Use a small, memorable musical motif that changes instrumentation across worlds. The kitchen may use percussion and warm plucks; the bathroom may use watery tones; the attic may use soft music-box textures. Keep loops unobtrusive and crossfades smooth. Prioritize responsive effects before producing a large soundtrack.

Create a sound list for movement, tool targeting, resizing, invalid actions, grabbing, impacts, water, fans, mechanisms, characters, checkpoints, discoveries, and celebrations. Simple synthesized effects can cover many interactions. Use available audio-generation or editing capabilities when appropriate, and retain provenance. If a required capability is unavailable, build an explicit placeholder and continue with another productive task; do not claim finished audio exists.

Balance levels across repeated sounds. Avoid harsh peaks, stacked identical effects, and constant vocal chatter. Provide separate music, effects, and dialogue or vocalization controls. Give important audio cues a visual counterpart.

## Progression and the expanding workshop

Completing a main stage repairs part of the world anchor and opens the next stage or route. Finishing a world adds a moving exhibit to the Matchbox Workshop and a character interaction that reflects the player's accomplishment. The workshop should become increasingly alive, making campaign progress visible.

Collectibles are optional and meaningful: illustrated discovery cards, costume pieces, workshop decorations, and photographs of unusual solutions. They should reward observation and experimentation. Do not make basic quality-of-life settings or critical abilities depend on grinding collectibles.

Provide a stage select with completion state, discovered secrets, optional objectives, and a clear way to replay. Separate main-route completion from optional perfection goals. Let the player finish the campaign without completing every challenge.

For an expanded edition, offer two optional challenge variants per main stage, creating a target of 120 variants. Typical variants are a limited number of resizes, a different starting object state, an alternate route, a gentler exploration task, or a replayable timing challenge. Variants should alter decisions, not merely move a collectible. The 12 world-level optional challenges described later are examples within this eventual pool, not 12 additional mandatory stages.

## Solo design and future two-player cooperation

The solo campaign is authoritative. Pip must be able to complete every required stage with the available tools and predictable object persistence. Never introduce an unavoidable simultaneous two-person action into a solo stage.

A separately approved future local co-op mode could introduce a second tiny character with the same core controls. Cooperation should come from shared objects, complementary positions, optional simultaneous bonuses, and playful rescue. Player two should have meaningful agency rather than spend the level opening doors for player one. Revise levels explicitly for co-op instead of assuming that spawning a second character completes the feature.

If the user later authorizes co-op production, start with shared-screen local play and two distinct input devices. Define camera limits, offscreen recovery, respawn, puzzle resets, independent settings where possible, and simultaneous resize arbitration. Online networking is a separate expansion requiring authority rules, synchronization, disconnect recovery, and dedicated testing. It must not delay completion of the solo foundation.

## Accessibility and player comfort

Offer remapping, controller support, adjustable text size, readable contrast, icon-plus-color targeting, separate volume controls, subtitle support when needed, reduced motion, camera shake control, and input alternatives for long holds or rapid taps. Pause should work throughout solo play except a clearly explained short transition that cannot safely pause.

Provide optional jump assistance, more generous timing windows, stepwise hints, and local puzzle reset. Hints should progress from pointing attention to explaining a relationship to describing a next action. They should not immediately reveal an entire solution. An assist mode should preserve the satisfaction of causing the final scene.

Prepare UI text for localization using stable keys. English is the initial text language; Simplified Chinese is a useful planned second language. Test expansion, line wrapping, fonts, and controller prompts. Do not bake essential text into textures.

## Product and technical direction

The default implementation candidate is Godot with a stylized 3D scene and a constrained camera, provided the available environment supports building, running, and inspecting it. Inspect the existing repository and installed tools before committing to a stack. Preserve an established suitable project rather than restarting for preference alone. Use official current documentation for version-sensitive choices.

If the required game runtime cannot be exercised in the available environment, document that limitation and choose a supported implementation that preserves the core design or continue work that is independently verifiable. A browser-based prototype can be useful when interactive inspection is available, but it must implement actual movement, resizing, and puzzle state. A static mockup cannot satisfy a playable gate. Follow the environment's existing site or repository workflows when they apply.

Prefer modular gameplay code, data-configured objects, reusable scenes, stable save identifiers, and separate art and audio sources. Build a small scene validation tool before mass content generation. It should check missing references, invalid starting states, required objects, reset availability, and goal definitions.

Target smooth play at 60 frames per second on a specifically recorded reference machine and resolution once hardware is available. Record frame-time percentiles, scene counts, and test conditions rather than making unsupported performance claims. If measurement is unavailable, mark performance unverified. Establish actual budgets for draw calls, textures, particles, and object counts from the measured slice.

Keep the main campaign playable offline. Cloud accounts, subscriptions, analytics services, monetization, public servers, and storefront publishing are unnecessary for the initial product and are not implied by this brief. Development agents may use their authorized tools to build the game; the game itself does not require a live language model to run.

## Campaign contract

The aspirational campaign contains **12 worlds with five main stages each: 60 main stages total**. World 12 includes the finale. The permanent hub and optional challenges are additional spaces or variants. This is the full-campaign horizon. The first playable milestone remains the breakfast demo.

Every stage centers on changing objects among small, normal, and large states, each granting explicit affordances. Stages combine reusable systems and introduce at most one new relationship. Core verbs remain inspect, resize, grab, place, push, activate, and reset. Hazards cause recoverable setbacks; progress never requires another person, perfect reflexes, or a guide.

The aesthetic resembles handcrafted toys: rounded forms, readable faces, stitched details, pleasant impacts, and exaggerated reactions. Resize animations preserve object identity; musical intervals reinforce size changes without relying on color. Each world has distinctive materials and sounds.

## Permanent hub: Matchbox Workshop

A matchbox workshop inside a sewing basket becomes home, with a handkerchief bed and button lanterns marking discovered routes. Household souvenirs return here as resizable decorations. A paper floor plan provides world entrances and direct stage replay, while a practice tray demonstrates discovered relationships without penalty.

The window gradually brightens toward morning across the campaign. Friendly handmade creatures gradually populate the nook; postcards preserve memorable scenes. Decorations and character expressions reward exploration without a repetitive currency grind. Hub visits are brief by default, and essential progression remains directly accessible from the map.

## World 1: Breakfast Table — The Toast Express

A warmly lit breakfast table becomes a landscape of ceramic cliffs, soft cereal dunes, and lakes of milk. This world teaches the full basic interaction grammar through short, visible cause-and-effect puzzles; its setpiece is a toast launch whose landing is forgiving. Butter-yellow highlights, blue gingham, and warm wood pair with spoon chimes, bread squeaks, and pleasantly exaggerated crunches.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 1.1 Crumb Crossing | Shrink a blocking sugar cube, carry a teaspoon through a narrow handle, and enlarge it across a saucer gap. | The enlarged spoon settles visibly into place as a bridge. |
| 1.2 Blueberry Ballast | Enlarge blueberries and roll them onto a cereal-box flap; shrink one to balance the rising cardboard ramp. | Exposed counterweights reveal why changing ballast transforms the route. |
| 1.3 Milk Harbor | Enlarge a cereal loop into a raft and reduce cargo until it clears a shallow milk channel. | A spoon dock unfolds while cereal creatures applaud. |
| 1.4 The Jam Detour | Resize biscuit platforms and a butter-knife ramp to carry a wrapped seed parcel over sticky jam. | Jam prints record experiments combining transport, reach, and ballast. |
| 1.5 Toast Express | Position a soft landing napkin, resize toast to fit the launcher, and tune a spring platform before boarding. | A slow-motion flight passes through a cereal-box window and lands at the bedroom entrance. |

**Optional challenge:** deliver three crumbs to a picnic using the same spoon, without a default countdown.

## World 2: Bedroom Toybox — Cardboard Kingdom

The floor is a bustling toy city whose residents need help staging a parade. Roads are fabric seams, buildings are blocks, and a train circles a cardboard castle. Primary colors, chunky painted wood, and felt flags accompany woodblock steps, spring squeaks, and tiny brass fanfares under crisp toy-stage lighting.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 2.1 Gate of Buttons | Shrink loose buttons to carry them into a toy drawbridge mechanism, then enlarge selected buttons as counterweights. | The milk-harbor buoyancy lesson gives way to a familiar, visibly connected bridge puzzle. |
| 2.2 Train at the Seam | Resize track connectors and remove oversized cargo to guide a slow toy train across a rug ridge. | Matched connection points preserve object function across sizes. |
| 2.3 Block City Detour | Enlarge building blocks into steps and shrink a tunnel arch so the parade route passes above it. | One object can block the ground route while supporting an elevated solution. |
| 2.4 Wind-Up Helpers | Create ramps and ballast stops that redirect wind-up animals toward two switches in sequence. | Autonomous props follow short predictable loops, and oversized toy feet produce comic pavement rattles. |
| 2.5 Dinosaur Parade | Resize a saddle, complete a raised track, and ride a friendly wind-up dinosaur through the finished route. | Previously helped toys celebrate throughout the moving setpiece. |

**Optional challenge:** photograph three ridiculous forced-perspective parade scenes using a fixed toy camera.

## World 3: Bathroom — Rubber Duck Regatta

A shallow bath becomes an ocean surrounded by tiled coves, soap islands, and towel cliffs. Introduce authored wet-object states and stable floating platforms rather than unrestricted fluid simulation. Turquoise water, coral soap, glossy ceramics, and bubble highlights meet rubber squeaks, dripping percussion, and muffled underwater notes beneath luminous reflected caustics.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 3.1 Sinkside Ferry | Enlarge a soap dish into a ferry, shrink its cargo, and use a toothbrush as a docking bridge. | Familiar resizing and floating work on a larger stage with optional safe splashing routes. |
| 3.2 Sponge Garden | Move small dry sponges into marked puddles, let them swell, and arrange the resulting springy steps. | Absorbent props have readable dry and wet states, indicated by shape, texture, and sound. |
| 3.3 Comb Canyon | Resize combs to bridge tiled gaps while leaving enough space for rolling bubble capsules. | Bridge height and opening width become a shared spatial puzzle with visible endpoints. |
| 3.4 Duck Dock | Assemble a duck-sized landing, resize floating bumpers, and release a low current through a toy gate. | An overlooking platform allows safe rehearsal before committing. |
| 3.5 The Great Drain | Ride an enlarged rubber duck, redirect bumpers, and reach a towel ramp as a cartoon whirlpool grows. | The apparent urgency hides generous checkpoints; falling returns the duck to its most recent dock. |

**Optional challenge:** guide three tiny ducklings home without touching the water, using only existing floats and bridges.

## World 4: Laundry — Sock Weather

A motionless laundry area becomes a landscape of woven hills, basket towers, and sock windsocks. Airflow joins the existing toolbox through visibly bounded fans and vents; appliances operate only as stylized, authored toy mechanisms. Lavender fabric, white cotton, and red clothespins pair with fabric flutters, basket creaks, and soft rhythmic thumps in diffuse skylight.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 4.1 Basket Staircase | Shrink clothespins through basket slots and enlarge them into sturdy footholds along the outer wall. | Clear snapping points make foothold placement predictable. |
| 4.2 Sock Sail School | Enlarge a sock sail and reduce a sled's ballast to cross a fan lane between towel banks. | Area and weight influence airflow only through a small, consistent set of authored responses. |
| 4.3 Lost Mitten Station | Resize wool balls to hold flaps open and create routes for a wandering mitten puppet. | The puppet follows visible tracks and waits safely when the player rearranges its path. |
| 4.4 Tumble Tunnel | Adjust foam drum paddles and ballast in a slowly rotating, transparent toy-drum passage. | A pause lever allows planning each transfer. |
| 4.5 Pillowcase Skyship | Build a clothespin gondola, tune its cargo, and sail a pillowcase between three sheltered laundry perches. | The flight reveals earlier routes below and rescues a mitten. |

**Optional challenge:** land a sock glider on three increasingly silly targets, with instant retries.

## World 5: Pantry — Midnight Snack Market

Shelves become market streets operated by charming packet and tin creatures preparing a feast. This world develops object routing and conveyor timing using existing rolls, ramps, switches, and weight plates. Spice reds, paper browns, translucent candy colors, and tin roofs sound like shaker percussion, crinkling wrappers, and gentle can drums under warm market lanterns.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 5.1 Tin Town Lift | Place resizable beans into exposed lift cups and balance two shelf elevators to reach the upper market. | The elevators visibly exchange height, with enough landing space to stop and reconsider. |
| 5.2 Pasta Plumbing | Carry small pasta elbows into place, enlarge them, and connect a short rolling-pea route. | A transparent preview shows junction direction, while missing pieces can be recovered from catch trays. |
| 5.3 Cracker Customs | Resize wrapped parcels to pass inspection frames and restore their size on the correct delivery platforms. | Shape silhouettes define destinations, making the sorting puzzle readable without text dependence. |
| 5.4 Jelly Bridge | Use enlarged crackers as supports and jelly pads as springs to reconnect a broken serving route. | Overloaded jelly wobbles conspicuously before gently depositing cargo in a nearby recovery bowl. |
| 5.5 The Supper Bell | Prepare a chain in which a pea tips a cup, releases a cart, and rings the market bell. | One activation starts dinner service; a local reset allows unlimited rehearsals. |

**Optional challenge:** serve a tiny three-course meal using a restricted prop tray; successful variations earn different comic customer reactions.

## World 6: Balcony Garden — Dewdrop Festival

Flowerpots become islands connected by stems, garden labels, and watering tools. Growth uses discrete authored states triggered by clearly routed water drops, reusing the pantry's transport systems. Leaf greens, terracotta, luminous dew, and felt-like moss accompany wooden insect clicks, leaf rustles, and hollow watering-can tones in golden backlight.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 6.1 Terracotta Steps | Enlarge fallen seed shells into footholds and balance a plant-label seesaw across two flowerpots. | The stage restates bridge and counterweight rules through a fresh silhouette and softer materials. |
| 6.2 Water for Three | Resize leaf gutters and route a fixed supply of large cartoon droplets to three thirsty sprouts. | Each watered sprout grows one step, visibly transforming the route. |
| 6.3 Snail Post | Shrink a seed parcel, create a gentle ramp, and adjust ballast to open the snail courier's gate. | The snail provides a calm, predictable escort. |
| 6.4 Pinwheel Pollination | Resize wind shields and pinwheel paddles to send floating pollen tokens through marked flower rings. | Airflow and routing combine without requiring precise midair aiming. |
| 6.5 Lantern Bloom | Complete three dew routes, enlarge protective leaves, and activate a blooming chain around a moonflower pavilion. | Flowers unfold into a glowing evening festival, revealing a paper bridge toward the art desk. |

**Optional challenge:** arrange a miniature garden that satisfies three creature preferences, with many valid layouts.

## World 7: Art Desk — The Unfinished Picture

An abandoned craft project invites the player to finish a pop-up landscape. Cardboard, tape, stamps, and paper hinges reinterpret established object systems; color remains expressive decoration rather than an obscure combination lock. Pastel cardstock, saturated paint dabs, and exposed stitched edges meet paper snaps, pencil scratches, and stamp pops under a warm desk lamp.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 7.1 Pencil Ridge | Resize pencils into rolling bridges and use erasers as stops to cross a crumpled-paper ravine. | Different-sized cylinders roll predictably until blocked, reinforcing explicit cause and effect. |
| 7.2 Folded Forest | Shrink paper trees into hinge sockets, enlarge them, and balance their folding platforms with clay pebbles. | Pop-up scenery doubles as geometry, so restoring the picture visibly creates new routes. |
| 7.3 Stampede of Stamps | Route rolling ink-free stamp toys across marked plates by resizing guide rails and ramps. | Each correctly triggered plate adds a cheerful animal illustration to the unfolding scene. |
| 7.4 Shadow Puppets | Resize cutouts between a lamp and screen to form three clear target silhouettes. | The camera provides an aligned viewing position; adjustable hints expose the required silhouette relationships. |
| 7.5 Pop-Up Premiere | Place the final bridge, tune paper-spring platforms, and trigger the book's opening sequence from its cover. | The player rides through a moving paper forest as earlier stamps become a cheering illustrated audience. |

**Optional challenge:** create a postcard from collected shapes, stamps, and characters, without aesthetic grading.

## World 8: Living-Room Sofa — Cushion Kingdom

The sofa becomes a theatrical landscape of cushion mountains, blanket caves, and a sprawling floor-lava game. Its materials emphasize soft displacement through bounded animations rather than unstable full cloth simulation. Plum velvet, warm orange lamps, plaid blankets, and button-eyed cushions produce bassy bounces, upholstery squeaks, and muffled applause in soft lamplight.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 8.1 Remote Ravine | Enlarge remote-control buttons as stepping stones and shrink a coin to carry it into a flap mechanism. | Large ordinary buttons become inviting platforms with clear travel distance and visible activation states. |
| 8.2 Blanket Caverns | Resize support props and weigh down blanket corners to open a sequence of stable cloth tunnels. | The blanket moves among authored poses, preserving the illusion of softness while keeping navigation reliable. |
| 8.3 Cushion Catapult | Balance a cushion seesaw, position a soft catcher, and tune a spring launch across the sofa gap. | An optional landing marker supports accessible experimentation. |
| 8.4 Floor Is Lava | Chain enlarged coasters and magazine bridges across pretend lava while recovering three stranded toy performers. | Falling produces a silly theatrical splash and immediate return, without consuming lives or collected progress. |
| 8.5 The Blanket Dragon | Resize props around a friendly cushion dragon to support its wings and guide its rolling treasure chest. | The dragon rises into a blanket fort that becomes a new optional hub decoration. |

**Optional challenge:** build a continuous cozy route connecting five sofa landmarks using a limited assortment of familiar soft props.

## World 9: Garage Workbench — Button-Powered Machines

A tidy workbench hosts oversized toy mechanisms with transparent housings and rounded, harmless-looking parts. Mechanical complexity comes from combining known switches, wheels, ramps, and ballast, not from simulated engineering tolerances. Teal paint, brass-colored fittings, amber panels, and rubber wheels accompany ratchets, toy-engine putters, and spring boings beneath clear task lighting.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 9.1 Washer Workshop | Resize chunky washers to fit matching axles, then use the assembled wheels to move a small platform cart. | Connection previews show valid assemblies, allowing discovery without pixel-perfect alignment. |
| 9.2 The Friendly Clamp | Adjust rubber ballast and wooden wedges to hold a broad toy clamp open across a workbench gap. | The clamp closes gently when released and resets objects to a nearby tray. |
| 9.3 Chain Reaction Bench | Arrange rolling nuts, ramps, and spring pads to press three large switches in a required visible order. | The sequence can be tested one segment at a time before running the complete arrangement. |
| 9.4 Cargo Cart Trial | Resize wheels and cargo to balance a cart across short bumps, narrow passages, and a weighted bridge. | Each obstacle reveals a distinct tradeoff, and checkpoints retain the player's latest successful configuration. |
| 9.5 The Impossible Delivery | Combine the tuned cart with a launch ramp and overhead cup lift to deliver a tiny bell assembly. | A machine parade carries the player toward the music corner. |

**Optional challenge:** build an intentionally overcomplicated machine that rings one bell using at least five existing interactions.

## World 10: Music Corner — The Quiet Orchestra

A shelf of toy instruments has lost its ability to play together. Resizing changes reach, weight, and authored pitch states; musical puzzles always provide visual equivalents. Cherry wood, cream keys, felt mallets, and bright sheet-music ribbons accompany a gentle motif that gains instruments as routes are restored under theatrical spotlights.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 10.1 Keyboard Causeway | Enlarge felt blocks to hold selected keys down and create a stable crossing above a toy keyboard. | Depressed keys light matching icons, connecting weight puzzles to clearly visible musical responses. |
| 10.2 Bell Tower Tune | Resize three bells and route a rolling striker through their labeled targets in a displayed sequence. | Notes, shapes, and positions communicate the same solution, avoiding dependence on pitch recognition. |
| 10.3 Drumskin Bounce | Adjust soft drum ballast and mallet size to create a sequence of predictable jumps between music stands. | Familiar springs gain rhythmic feedback without requiring beat-perfect inputs. |
| 10.4 Ribbon Rehearsal | Shape a rolling-ball route across oversized score markers and test each instrument trigger separately. | Pausing and restarting rehearsal preserves placement, making diagnosis part of the musical play. |
| 10.5 One-Creature Concert | Activate the prepared route and travel between scenic observation platforms while the toy orchestra performs. | The campaign motif plays in full, with optional, forgiving player-triggered flourishes. |

**Optional challenge:** compose an eight-step toy melody using visual note blocks, then save the arrangement as a hub music variation.

## World 11: Attic — Dust-Star Observatory

An attic full of decorations, luggage, and old keepsakes becomes a gentle celestial playground. Mirrors and shutters provide a final spatial variation, with light paths rendered as clear rays and broad target zones. Deep indigo, warm brass, translucent marbles, and dusty gold pair with suitcase thumps, crystal notes, and quiet wind chimes in dusty moonbeams.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 11.1 Suitcase Switchbacks | Shrink handles to open passages and enlarge luggage tags into bridges between stacked suitcases. | Familiar travel objects create a readable vertical route with scenic rest ledges. |
| 11.2 Marble Constellations | Resize marbles and route them into star-shaped sockets using sloped picture frames and soft bumpers. | Completed constellations illuminate the ceiling and reveal the next destination. |
| 11.3 Moonbeam Gallery | Resize mirrors within fixed-angle holders and open shutters with counterweights to illuminate broad hanging targets. | The challenge is routing and occlusion rather than fiddly angular precision or physically exact optics. |
| 11.4 Ornament Orbit | Tune ornament ballast and wind shields to stabilize a suspended mobile long enough to cross it. | Stable mobile states provide safe crossings; excessive motion resets gently. |
| 11.5 Paper Comet Ride | Restore a lantern glider, resize its sail, and ride through illuminated hoops toward the entrance hall. | The connected house appears below, establishing the final route home. |

**Optional challenge:** arrange an original constellation from found marbles and project it onto the hub ceiling as a keepsake.

## World 12: Front Hall — Welcome Home

The final world takes place among shoes, coat hooks, umbrellas, mail, and the familiar front door. A gentle draft has scattered the household's welcome-home decorations; restoring them combines established relationships without introducing a new mandatory mechanic. Dawn amber, raincoat yellow, postage-stamp colors, and soft reflections accompany musical callbacks from all eleven earlier worlds.

| Main stage | Player actions | Discovery or payoff |
|---|---|---|
| 12.1 Shoelace Station | Resize lace-loop footholds and button ballast to build a route over shoes carrying rescued household guests. | Guests' familiar animations show the impact of earlier help. |
| 12.2 Umbrella Weather | Adjust umbrella size, counterweights, and wind shields to open a sheltered route through a playful indoor draft. | Airflow, bridge building, and soft landing systems combine in a broad, readable final traversal. |
| 12.3 Mail Mountain | Shrink parcels for transport, enlarge envelopes into ramps, and route welcome cards to matching display frames. | Souvenirs form a visual recap of completed worlds. |
| 12.4 Doorbell Overture | Assemble the recovered bell, prepare rolling and spring segments, and rehearse the full welcome mechanism with checkpoints. | Each segment supports independent inspection, testing, and reset. |
| 12.5 A Very Big Little Home | Ring the bell to trigger the house-wide celebration, then take a guided scenic ride ending at Matchbox Workshop. | The hub unfolds into a neighborhood of rescued friends; free play resumes. |

**Optional challenge:** remix the final celebration using unlocked props and instrument variations, without affecting completion.

## Content discipline and implementation order

Worlds 1–3 establish bridges, ballast, launches, rolling, transport, and buoyancy. Worlds 4–6 add airflow, sequencing, and discrete growth. Worlds 7–9 combine those systems; Worlds 10–12 emphasize mastery and celebration. Reskins alone do not qualify as new stages.

Polish one breakfast-table prototype, then **World 1**, before expanding. Each stage must work from a fresh save and recover from failed experiments. Finales reuse established systems with controlled staging, cameras, and sound. Optional challenges never gate progression. Internal milestone builds can contain three or six worlds. They must be labeled partial campaign builds.

This section defines production and verification for the development agent. Build the game according to the binding contract and ordered milestones above. The full campaign contains twelve miniature worlds and sixty authored stages. Prove the core experience before multiplying its content.

## Production principles

Prefer Godot when the available environment can run, export, and inspect it reliably. If it cannot, choose a supported engine with equivalent capabilities and document the reason. Use a stylized 3D diorama presentation, fixed or gently guided cameras, simple expressive characters, and discrete object sizes. The player should understand a puzzle through movement, shape, sound, and reactions rather than through long instructions.

Build resizing as an authored interaction system. Each eligible object has three deliberately designed size states and clear placement rules. Scaling should produce predictable gameplay consequences: a spoon becomes a bridge, a blueberry becomes a counterweight, a cracker becomes a raft. Do not assume that arbitrary physics simulation will produce fair puzzles. Use physics for amusing motion where it is reliable, and explicit state transitions for progress-critical interactions.

## The first playable scene

Build the breakfast table before any other world. Target a first-play duration of roughly eight to twelve minutes, subject to later human testing. Give it a short opening, three connected puzzles, an optional discovery, and a toast-launch finale. Introduce movement, interaction, and resizing one at a time. Make the exit visible early so that exploration has a purpose.

The scene contains six principal interactive props: a spoon, blueberry, cereal box, napkin, butter pat, and toaster. Supporting scenery establishes a lively household without obscuring paths. Teach bridge-making with the spoon, weight transfer with the blueberry, and a launch preparation sequence using the other props. The player must be able to experiment before understanding the intended solution.

Accept the vertical slice only when these gates pass:

1. **Playable route:** a fresh launch reaches the finale through ordinary controls, without debug commands. The completion state and return-to-play path work.
2. **Readable interaction:** eligible props are identifiable; selecting and resizing them produces immediate feedback. Invalid actions explain themselves through restrained visual or audio feedback.
3. **Recoverable mistakes:** falling, losing a required prop, resizing inside geometry, and interrupting an animation cannot permanently block progress. Recovery preserves reasonable recent progress.
4. **Control quality:** camera framing preserves the character and relevant target; movement does not catch on decorative seams; keyboard and gamepad mappings work if supported and claimed.
5. **Presentation:** no obvious missing assets, clipping UI, silent critical actions, illegible prompts, or inconsistent prop styles remain in the complete route.
6. **Durability:** save, exit, reload, and scene restart work at the opening, each puzzle boundary, and the finale. Corrupt saves fail safely with a recoverable fallback.
7. **Performance:** state the tested hardware and settings, then meet the agreed frame-time target there. Do not claim universal performance from an unattended or headless run.
8. **Evidence:** save an inspectable build, a recorded playthrough when capture is available, representative screenshots, and a short test report listing remaining limitations.

Advance only after the applicable functional, recovery, and art gates pass and all unavailable checks are explicitly recorded. Human enjoyment remains unverified until observed playtesting; that pending review does not block other useful approved work.

## Agent-generated production components

Generate code, scene assemblies, UI, original props, animations, effects, and audio using tools actually available. Keep all outputs editable. Establish a small visual style guide first: palette, proportions, material roughness, outline treatment if any, interface typography, and animation exaggeration. Maintain an asset manifest recording source, generation method, intended use, and any relevant license information.

Prefer reusable low-complexity geometry and procedural materials for common objects. Use image generation for appropriate textures, illustrations, and concept references when available. A rendered image is not automatically a usable rigged 3D asset. When a required production capability is missing, make a simpler coherent substitute and document the substitution.

Build a shared animation vocabulary: squash on landing, anticipation before launches, object wobble after interaction, and expressive idle reactions. Generate simple sound effects through supported synthesis or audio tools; maintain consistent loudness and provide independent music and effects controls. Do not report generated audio as auditioned unless it was actually heard or inspected through a supported playback workflow.

Define reusable level components for checkpoints, resize targets, moving platforms, weight switches, currents, launchers, collectibles, and endings. Keep each world's distinctive mechanic visible in its authored arrangements. Reuse production systems without repeating the same puzzle five times.

## Expansion toward twelve worlds

Develop in the ordered milestones. Complete the breakfast demo and all five World 1 stages, then World 2, then World 3 and the remaining named worlds. The first three worlds expose bridges, ballast, launches, rolling, transport, and buoyancy, providing evidence that shared systems support varied scenes. Keep each world as the current integration frontier until its gates pass.

For each subsequent world, deliver an introduction level, a combination level, an exploration level, a difficult variation, and a finale. This five-level pattern is an initial planning aid, not a requirement that every world feel identical. Every level must have a stated player goal, an interaction novelty, a recovery plan, and at least one memorable visual event. Redesign weak stage slots to provide distinct decisions and payoffs; do not fill a slot with repetitive content simply to reach the count. Maintain the approved 60-stage campaign manifest.

## Continuous improvement contract

Continue working through the highest-value available improvements during the authorized execution window. A completed prototype, passing test suite, or finished milestone is a checkpoint, not an automatic stopping point. When a milestone is stable, select the next substantive improvement, implement it, inspect the result, and preserve the evidence.

Use this repeated cycle:

1. Inspect the current build, outstanding defects, recent changes, and available execution capacity.
2. Select one concrete player-facing improvement or a necessary enabling task, with an observable completion criterion.
3. Implement the smallest coherent change that satisfies it.
4. Run focused checks, then play or replay the affected route when possible.
5. Inspect captured output for visual regressions and unexpected behavior.
6. Keep the change if supported by evidence; revise or revert it if it makes the game worse.
7. Commit or otherwise durably checkpoint the working state, update the next-task record, and continue.

Prioritize crashes and lost progress first, then blocked routes and confusing controls, then weak interactions and presentation, and finally content breadth. Avoid consuming capacity through repeated unchanged tests, cosmetic renaming, speculative rewrites, or endless parameter adjustments without a hypothesis. Use parallel agents for independent, bounded work only when coordination overhead is justified; one integration owner reviews their outputs.

Actual quota and remaining runtime may be invisible. Do not invent a remaining-usage counter. Checkpoint early and after meaningful changes. Continue while execution remains available, but stop when the user stops the task, an unavoidable authorization decision blocks all useful work, or the platform ends the run. Do not bypass limits, purchase capacity, spawn replacements to evade a stop, or claim background continuation. If another run is needed, leave a precise resumption state.

## Verification and honest quality claims

Maintain replayable tests for progress-critical state changes, resizing constraints, checkpoints, save migrations, and recovery from lost objects. Use deterministic inputs or seeds where they make failures reproducible. A headless state test cannot establish camera quality or control feel; an attractive screenshot cannot establish that a puzzle is solvable. Collect both behavioral and visual evidence.

Treat enjoyment as a human validation item. Ask playtesters whether they understood their goal, what they attempted spontaneously, where they became confused, and whether they wanted another scene. Record observed completion time, failed interactions, hints requested, and optional experimentation. Unprompted experimentation and voluntary replay are useful signals, not proof of commercial demand. Without human testing, mark enjoyment hypotheses as unverified and continue improving demonstrable qualities.

At every checkpoint, preserve the buildable source, generated source assets, dependency/setup notes, save-format version, latest successful build, known issues, and the next three prioritized tasks. Keep a stable baseline separate from experimental work. Checkpoint new source and assets before risky changes; use migration or explicit compatibility handling when saves change. Never describe a milestone as complete if its gates remain unmet. The project's enduring goal is a better playable game, supported by evidence, across as many authorized development cycles as are available.

## Required campaign manifest and evidence records

Create stable world and stage IDs before mass content production. Use W01S01 through W12S05 for main stages and separate IDs for VS01, the hub, and optional variants. Each entry records title, goal, object families, prerequisite, valid solution, alternate routes, checkpoints, reset behavior, art requirements, evidence paths, completion status, and unresolved issues. A title in this document is a planned stage, not an implemented one.

Every retained improvement should connect back to a requirement or a specific stage. A compact change record is sufficient: task, player benefit, result, checks, limitations, and next task. Screenshots demonstrate appearance; recorded or interactive runs demonstrate behavior; measurements demonstrate performance only under their recorded conditions.

Keep implementation source, asset sources, project settings, dependency versions, save-schema versions, and current launch instructions together. Preserve a known-good state before a risky change. Follow the existing repository or hosting workflow when one exists, and do not describe a local commit as remotely saved until its actual persistence step succeeds.

## Reference and capability note

This is an original design proposal informed by the user's selected concept. Scope, durations, visual values, and production gates are design targets, not market forecasts or claims of completed implementation.

Godot documents command-line scene execution, headless operation, and recording output, which can support an agent-driven build and verification workflow. The executing agent must confirm the installed version, renderer, capture support, and export requirements in its own environment: [Godot command-line tutorial](https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html).

The continuous-development directive operates only while an authorized runtime is actually executing. It cannot extend a chat session or replenish usage. No paid capacity, external publication, or background process is created by this design brief. The durable product of each development run should be a better playable game and an exact resumption record.
