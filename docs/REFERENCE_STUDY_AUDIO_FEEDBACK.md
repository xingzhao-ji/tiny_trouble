# Reference study: musical structure and readable feedback

Reviewed 2026-09-09 for TT-028. These are specific design observations and proposed Tiny Trouble improvements, not an equivalence claim. The other three requested references are covered by the companion visual study. The fixed solo household-diorama identity and exact sixty-stage campaign remain unchanged.

## Overcooked: readable work and immediate feedback

The unchanged [publisher comparison image](https://www.team17.com/hs-fs/hubfs/Comparison3.jpg?length=1000&name=Comparison3.jpg), linked from [Team17's game page](https://www.team17.com/games/overcooked-all-you-can-eat), was downloaded and visually inspected. The work surface occupies a bounded central region, with brighter counters separating work from the darker leafy perimeter. Ingredients use large, isolated icons. White chef hats help separate characters from the floor. These observations concern this particular still; they do not establish animation timing or the whole game's readability.

Team17 also documents scalable UI and options that reduce visual disturbance. Tiny Trouble should retain its own comfortable text, reduced-motion and input treatments as it improves presentation. [Publisher accessibility description](https://www.team17.com/news/overcooked-all-you-can-eat-updated-faqs)

| Tiny Trouble evidence/gap | Original improvement | Verification |
| --- | --- | --- |
| Packaged phone Harbor toasts cover Pip, cargo and the growing raft. `evidence/platform_export/harbor_touch/` contains the observed failures. | Place transient feedback around the active actor and useful prop; shrink stale card height when objectives shorten. | Project actual Pip/cargo mesh bounds at render-post-draw; require no toast intersection throughout the injected-touch route, then inspect new screenshots. |
| The small phone capture makes Pip's face and cargo-size change difficult to inspect at a glance. This is an agent visual concern, not a measured universal threshold. | Measure projected character/prop dimensions and compare a closer, guided phone camera against the current route framing. Keep the next landing and interaction visible. | Record both camera candidates at identical route moments and actual framebuffer dimensions; inspect the complete boarding/resize/dock transitions. Do not approve from a geometry threshold alone. |
| Resize acceptance/rejection is technically present, but full comedic timing has not been reviewed. | Give accepted scale changes a controlled anticipation and settle, and a distinct brief refusal gesture, using Pip's existing handmade rig. Avoid frantic motion. | Review actual complete engine recordings in normal and reduced-motion modes, plus input latency and contact tests. Static frames cannot close this gate. |

## Stardew Valley: identity across distinct moods

The [composer's official soundtrack catalog](https://concernedape.bandcamp.com/album/stardew-valley-ost) distinguishes seasonal, location and character pieces, including an opening theme and quieter destination cues. This establishes deliberate musical organization; catalog metadata does **not** establish perceived melody, instrumentation or emotional effect. No reference audio was auditioned through the available tools.

Tiny Trouble currently ships one original twenty-second breakfast loop for its demo, workshop and implemented chapter scenes. Its generator documents an eight-bar phrase, but the current runtime does not establish contrasting arrangements for exploration, the workshop and the harbor. Source inspection and decoded audio statistics are evidence of structure and routing only.

| Gap | Original improvement | Verification |
| --- | --- | --- |
| A single short loop provides limited scene identity. | Develop a recognizable original Pip motif with contrasting breakfast and workshop arrangements, restrained harbor color and occasional space between phrases. Reuse the motif in earned-success cues. Keep the existing warm wood/fabric/chime sound family. | Preserve a written motif/arrangement map, deterministic source and hashes; audition complete repeated loops and context transitions in the actual engine. Listener notes must identify the file/build, output device and listening conditions. |
| Musical repetition and emotional warmth have not been assessed by listening. | Prepare a repeatable listening route with quiet exploration, repeated resize refusals, a checkpoint, harbor travel and completion. | Review an actual engine recording and live playback with independent music/effects settings. Record masking, fatigue, abrupt entrances and loop seams; do not substitute RMS/peak measurements for audition. |
| Environmental moods currently depend mainly on visuals. | Add sparse original room/prop ambience and event-specific movement sounds only where they support scene readability. | Compare music-only, effects-only and full mix at the same gameplay events; verify no missing feedback or constant distracting layer. Physical speaker/headphone and mobile balance checks remain separate. |

The available tool inventory exposes no verified audio-listening or video-playback analysis tool. Native playback can produce sound, but issuing a playback command does not prove that the agent heard or assessed it. Subjective audition remains unverified until a supported listening path or actual listener review is available. Useful composition, integration, technical checks and visual refinement can continue without closing that gate.

## Reference provenance

`design/reference_study/overcooked_official_comparison3.jpg` is an unchanged, third-party publisher reference, retained only for this local study. It is not original Tiny Trouble artwork and must never enter a game export. No reference character, environment, melody, recording or sound effect is being reused as a game asset. The Figma board must retain this provenance and distinguish it from original concepts and actual engine captures.
