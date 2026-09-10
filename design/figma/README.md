# Tiny Trouble Figma development package

This is a **locally compiled, unexecuted Figma development plugin**, not a `.fig` file, published library or verified Figma prototype. The integration request was interrupted without a connection confirmation. The engine and this package share `tokens.json`; `asset_snapshot.json` preserves source hashes and copied image provenance.

The plugin creates one new page per run containing:

- An art-direction board with nine palette swatches, Nunito 600 typography, two clearly marked generated concepts and two unchanged engine reference captures.
- A separate TT-028 reference-study board with seven unchanged official stills from Monument Valley, It Takes Two, Animal Crossing and Overcooked. Each card separates observed qualities, original Tiny Trouble applications and still-only limits, with source hyperlinks and complete provenance in plugin data. A Stardew Valley catalog card explicitly states that reference audio has not been auditioned.
- A reusable Button component set with Desktop/Touch and Normal/Hover/Pressed/Focus/Selected/Disabled variants; editable label property. A Card set with Objective/Target/Toast variants and Auto Layout. Toast uses the shared width480/minimum-height90 logical-unit tokens; its runtime placement avoids the actor/action region and refits changing text. The persistent target card also shifts horizontally to avoid Pip and controls. The prototype does not simulate these positioning algorithms; human motion comfort remains pending.
- Menu → Play → Pause → Resume/Title links for desktop 1280×720, tablet 1024×768, wide phone 844×390 and compact phone 667×375, plus compact-phone text scale1.25. Gameplay art in these frames is an editable schematic framing proxy; actual engine images remain on the evidence board.

Desktop mobile-size captures simulate layout on macOS. They establish neither physical iPhone/iPad rendering nor iOS point sizes. Only navigation is linked in this prototype; resize, movement and settings behavior remains in the game. The script loads Nunito SemiBold when available, otherwise uses an explicitly recorded Inter fallback that requires correction before font parity can be approved.

Run from this directory:

```sh
npm ci
npm run build
npm run check
```

Figma assigns plugin IDs. This package deliberately retains `manifest.template.json` with an obvious placeholder. In Figma Desktop, create a Run once development plugin and then run:

```sh
python3 build.py --figma-manifest /absolute/path/to/figma-generated/manifest.json
```

This writes `manifest.json` using the real assigned ID. Import that generated manifest through Figma's development-plugin menu and run it in a design file with edit access. The plugin appends a new page; it does not replace existing work or transmit file data. Review its new page and all five starting flows before recording successful Figma execution. See [the workflow](../../docs/FIGMA_WORKFLOW.md) for sync and acceptance steps.

The study is documented in [REFERENCE_STUDY_VISUAL.md](../../docs/REFERENCE_STUDY_VISUAL.md) and the [companion audio study](../../docs/REFERENCE_STUDY_AUDIO_FEEDBACK.md). `reference_study.json` is the editable annotation/provenance source; `reference_study_snapshot.json` identifies its unchanged copied images. Third-party references are local study material and must never enter a game export.

Normal builds preserve the four current project image copies and `asset_snapshot.json`. Only an intentional `python3 build.py --refresh-runtime-snapshot` replaces that baseline; update the study's token/snapshot binding and rerun the engine/design checks after a refresh. The initial TT-028 reference study preserved the original baseline. An authorized synchronization added the existing runtime toast dimensions and first used candidate0.2.4 grounded Harbor. After a separate max-text ashore occlusion was corrected, the phone reference was refreshed to `evidence/platform_refinement/phone_max_025a/ashore.png`, labelled **source candidate0.2.5 / Milk Harbor / text1.25 / macOS viewport simulation**. The persistent target card now sits left of the full visible character, clear of touch controls in this still. The packaged desktop0.2.2 image, two concepts, official study images and token bytes remain unchanged by this refresh. The [10-frame route review](../../evidence/platform_refinement/phone_max_025a/VISUAL_REVIEW.md) and [28-frame UI review](../../evidence/platform_refinement/ui_025a/VISUAL_REVIEW.md) are bounded source evidence, not complete motion, human presentation or physical-device approval.

Local validation covers hashes, image dimensions, source metadata, API types and existing control geometry; it does not render the new study board or approve Figma text wrapping. `reference_study.json` records the intentional baseline change and previous token hash.
