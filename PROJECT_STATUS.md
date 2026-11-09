# Current project state

State Version: 16 (RBX-031 proposal; accepted predecessor remains 15).
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Hold-style UI, rack-only compact hover, ordered drain playback and visible event restocks.

Active proposal: [RBX-031](tasks/RBX-031-shop-prototype.md), Codex coordinator,
branch task/RBX-031-shop-prototype, [draft PR32](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/32).
Main re-fetched at 44762e38b5b4e3ad2f89c789ae6a7a6b6f6d4560; accepted State15 unchanged.
Implementation / Studio-tested source: 8a9b1a723bad80f9ccd23e9517c09bd97aa67e31.
Hold audit: 9ecf135d50ef1661d71caa91de9f57a844bc8c3d.
Drain audit: cc41eb1 (full identity and earlier retouch history in task).

Applicable panels, buttons, name/model/evolution compartments share the Hold
gradient, navy outline and rounded shadow. Semantic trigger/effect colors and
selected/disabled states stay distinct. Passive inspection is restricted to the
seven UI rack slots and reduced40% in width/height; explicit details remain full-size.
Natural-drain activations play sequentially before restoration/rewards; Last Word
animates its target twice without extra beam-triggered performances. Growth events
visibly change pegs, shuffle, then award one free restock, coin and capped ball.
The confusing halves label now explicitly means pegs halved by items.

Windows scripts/check.ps1 and build-ui-preview.ps1 PASS at implementation.
Final audit formatting/lint and documentation checks PASS. Fresh unpublished
Studio3765c183-4057-43e6-89cb-d085ed12b6cb matches all59 normalized source fingerprints.
All15 screens PASS style, retouch/layout and interaction audits at HD1080,
iPhone13 landscape and iPhone7 landscape (safe areas1919x1022,749x331,666x316).
Style checks cover645/609/607 marked surfaces and block62/70/70 non-rack anchors.
[Desktop style](docs/evidence/RBX-031/hold-style-desktop.json),
[layout](docs/evidence/RBX-031/hold-retouch-desktop.json) and
[flow](docs/evidence/RBX-031/hold-flow-desktop.json); all presets linked in the task.

[Drain/event runtime](docs/evidence/RBX-031/drain-event-runtime.json) PASS:
five actual Blender-model activations in order at1x/4x, Skip cleanup, changed peg
values before physical shuffle, then free restock/ball. Normal pointer Play/Launch
advanced to round2; Arcade/Resume retained round2 and aim. Rack-only pointer hover
also passed. Console has no game-script errors; existing asset203785492 type
warning remains. No screenshots/recording used for this follow-up; visual appearance
by screenshot, physical touch hardware and multiplayer NOT RUN. Initial audit
failures and the runtime-discovered duplicate-pulse fix are preserved in the task.

User files at the repository root:
- Screen selector: `build/Pop-a-Peg-HOLD-UI.rbxlx`.
- Normal game: `build/Pop-a-Peg-HOLD-GAMEPLAY.rbxlx`.

Fresh preview is stopped in Edit, preview defaults restored and simulation stopped.
Press Play, then use **UI PREVIEW**. Coordinator is sole Studio operator; no live
Rojo/port or syncback. Generated copies match; exact hashes and restoration evidence
are in the task. Historical files/sessions and unrelated root outputs are preserved.
Local checks and Studio evidence are separate from GitHub CI on the pushed branch.

Accepted source: 212c76260a5a6ce44dfd8ba5d10bd3ab77a25c4e.
Accepted task: [RBX-029](tasks/RBX-029-blender-game.md), merged through
[PR30](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/30).
Published: no experience update. RBX-031 is not merged; accepted State15 is unchanged.
Next action: user playtests HOLD-UI or HOLD-GAMEPLAY and provides feedback.
Repository administration: main unprotected; temporary default remains starter.
