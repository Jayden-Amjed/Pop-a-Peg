# RBX-031 — Desktop and landscape shop prototype

- Task ID: RBX-031
- Owner: Codex coordinator (sole Studio operator); read-only shop reviewer
- Status: READY FOR REVIEW
- Reservation / issue: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/31
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: 44762e38b5b4e3ad2f89c789ae6a7a6b6f6d4560
- Branch: task/RBX-031-shop-prototype
- Worktree / checkout: C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\shop-prototype
- PR: https://github.com/Jayden-Amjed/Pop-a-Peg/pull/32 (draft for user playtest)
- Implementation evidence SHA: 67967deb334519bea95fd36df9fbc793bc50b0ab
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Implement an original pearl/aqua cartoon shop close to the accepted visual
concepts, with real Blender model previews, desktop and landscape mobile layouts.
Preserve authoritative purchases, upgrades, evolutions, holds, rerolls, Supplies,
selling and rack management. Do not change frozen native art, run balance or
profiles. Provide an isolated local Studio build for immediate user testing.
No experience publication or merge requested.

## Acceptance criteria

- [x] Four equipment offers and up to two horizontal Supplies remain readable.
- [x] Models use the adopted Blender catalog and survive unrelated refreshes.
- [x] Shop actions, inspection and rack management use existing game rules.
- [x] Required source checks and representative Studio interactions pass.
- [x] Desktop and landscape device layouts verified; limitations recorded.
- [x] Reproducible opt-in fixture opens directly to the shop for user testing.

## Dependencies and overlapping paths

Based on accepted RBX-029 / State 15. No open PRs found at start.
Coordinator owns Presentation, ShopLayout, new shop styling, fixtures and tests.
Reviewer is read-only and has no Studio ownership. Root checkout and existing
Studio files remain preserved. No live Rojo connection belongs to this worktree.

## Checks actually run

`scripts/check.ps1` PASS on implementation 67967de (full above), Windows PowerShell,
pinned tools: zero lint errors/warnings, all gameplay contracts, catalog
motion/effects/audio/playback/loading/framing, three builds, source mappings and docs.
Repeated after adding the ShopView mapping and final evidence/docs, PASS.
`scripts/build-shop-prototype.ps1` PASS; 477 actual catalog MeshParts, disabled
ordinary Main scripts, landscape orientation, no profile/persistence path.

Studio 3e22698e-f555-4b13-94ab-278c0d6e411d, local unpublished prototype, source
67967de. All four changed runtime modules compare to filesystem source (normalized
line endings). Eight audit groups PASS on each preset:

| Simulator preset | Actual core-safe area | Evidence |
| --- | --- | --- |
| HD1080 (1920x1080) | 1919x1022 | [Desktop](../docs/evidence/RBX-031/desktop.json) |
| iPhone13 landscape (844x390) | 749x331 | [Cutout phone](../docs/evidence/RBX-031/landscape-844.json) |
| iPhone7 landscape (667x375) | 666x316 | [Small phone](../docs/evidence/RBX-031/landscape-667.json) |

Each audit checks six visible offers, 44px purchase/hold/footer targets,
18 Blender Ready model samples and 912 visible geometry corners; stable mounts
after selection/hold/upgrade; six-coin Seed Bank L2 to L3; eight-coin slot-free
Supply; one-coin reroll retaining held price; full/max rejection and full-rack
upgrade; free Aquarium consuming exactly two L5 ingredients; slot purchase/sale.
Actual MCP pointer clicks additionally verified upgrade, item inspection/close,
rack opening, slot selection, sell, drawer close and Next Shot. Continue hides the
shop, restores rack Z30 and removes shop-preview framing for gameplay.

Visual inspection used actual Studio renders with visible models on desktop and
both phones. All three audits restore the standard scenario. Earlier startup nil
viewport, small-screen sizing, sidebar overlap and desktop recenter issues were
fixed before the final checks. Historical asset-type warning for203785492 persists
(not referenced by the changed source); no final game script error observed.

Physical touch hardware and full multi-player server flows: NOT RUN. The fixture
uses the real Run action implementation locally; server code/rules are unchanged.
No purchased art, native model/choreography edits, merge or publication.

## Handoff

- Owner / next owner: Codex coordinator
- Objective / completed work: original responsive shop, actual model previews, isolated fixture and three-device QA complete
- Absolute checkout / branch / PR: as above; PR32 draft for user testing
- Main SHA inspected / accepted State Version: 44762e3 (full above), 15
- Evidence SHA / proposed State Version: 67967deb334519bea95fd36df9fbc793bc50b0ab; 16 proposal
- Checks and limitations: PASS as above; physical hardware/multiplayer not run
- Studio target / operator: local SHOP-PROTOTYPE, session3e22698e; coordinator, then user
- Sync worktree / endpoint / port: none; no live Rojo
- Published experience / place / observed version: no publication requested
- Preserved work: root outputs and all existing worktrees/Studio sessions
- Next smallest executable action: user tests the shop using Reset shop / Full rack / Evolution / Back to shop

Delivered root file: `build/Pop-a-Peg-SHOP-PROTOTYPE.rbxlx` (same bytes as worktree build).
SHA256: CBAA5946F87ECBB817837899D7F748FBE2A784E3259882036D635E4D7FFF3294.
Device simulation reset to default after comparisons. No live Rojo; ordinary game
playtest file and every prior Studio session preserved. User-facing handoff opens
the standard local test shop; restarting Play resets its temporary coins/rack.
