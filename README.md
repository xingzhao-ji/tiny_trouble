# Tiny Trouble

[![Godot source checks](https://github.com/xingzhao-ji/tiny_trouble/actions/workflows/ci.yml/badge.svg?branch=main&event=push)](https://github.com/xingzhao-ji/tiny_trouble/actions/workflows/ci.yml?query=branch%3Amain+event%3Apush)

A solo tabletop puzzle adventure starring Pip and a Scale Spool. Shrink a sugar cube, grow a teaspoon bridge, balance blueberries and sail a cereal raft.

**Play locally on this Mac:** double-click `Play Tiny Trouble.command`. It verifies and opens the current 0.2.7 package. No AWS, account, LLM API or internet service is required for gameplay.

[Open the review hub](evidence/REVIEW-0.2.7.html) for Mac/Windows downloads, gameplay, screenshots and exact verification. This is the **Breakfast Preview**: three connected stages and the original standalone Toast Express demo. The full 60-stage campaign remains unfinished.

The Workshop now opens first, focuses your next unfinished stage and provides settings before play. WASD moves, Space hops, E interacts, Q/F resize, Tab changes targets, H hints, R resets the current puzzle and Escape pauses. Remap keys, adjust music/effects/text and enable reduced motion in Settings. Chapter progress and the original demo keep their separate local saves.

The actual Mac package passed 2,964 checks across 12 scenarios. Both exports contain 85 verified resources and engine/font notices. Windows execution is still unverified; Mac is ad-hoc signed and unnotarized. A sustained performance attempt could not acquire native focus and produced no measured gameplay frames. Human playtests, presentation/audio approval, physical controllers/iOS and market demand remain open.

[Changes](docs/IMPROVEMENTS-2026-09-14.md) · [Current state](PROJECT_STATE.md) · [Release preparation](docs/RELEASE-0.2.7.md) · [Store-copy/price proposal](docs/STORE-COPY-2026-09-14.md) · [Player validation](docs/PLAYER_VALIDATION.md)

For development, `./run.command` opens the Godot project; `./playtest.command --playtest-scene=workshop` uses isolated manual-playtest profiles. `./scripts/check.sh` runs the sequential source suites. Use `python3 scripts/prepare_release.py --output=builds/NEW-RELEASE` after committing runtime changes. Versioned 0.2.2 and 0.2.6 archives remain preserved. Run only one Godot game/test/export at a time.
