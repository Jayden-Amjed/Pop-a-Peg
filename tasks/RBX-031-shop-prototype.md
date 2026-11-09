# RBX-031 — Desktop and landscape full-game UI

- Task ID: RBX-031
- Owner: Codex coordinator (sole Studio operator); read-only shop reviewer
- Status: READY FOR REVIEW
- Reservation / issue: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/31
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: 44762e38b5b4e3ad2f89c789ae6a7a6b6f6d4560
- Branch: task/RBX-031-shop-prototype
- Worktree / checkout: C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\shop-prototype
- PR: https://github.com/Jayden-Amjed/Pop-a-Peg/pull/32 (draft for user playtest)
- Implementation evidence SHA: 74f9b0ae0383c34721eda9518b304b2e2162f040 (full UI); original shop67967deb334519bea95fd36df9fbc793bc50b0ab
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Follow-up 2026-11-08: user requests the UI across everything, with additional
detail/refinement. Scope now includes shared theme, play HUD/rack, perks/events,
defeat/victory, inspector/recipes, loading/navigation, and all arcade/progression
panels. Proposal remains State16 above accepted15. Coordinator owns theme/run UI
and Studio; ui_hub owns only hub presentation; ui_review_fixture owns only new
UI preview/build/audit files in separate worktrees. Earlier shop evidence below
remains historical; full UI evidence and the latest handoff are below.

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
- [x] Shared theme covers gameplay HUD, perks/events, results, inspection and all arcade panels.
- [x] Desktop and two landscape phone presets pass all 15 screens, chest reveal and research.
- [x] Normal build and a 15-screen preview build supplied for Studio testing.

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

## Historical shop handoff

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

## Full UI checks and implementation

Final implementation: 74f9b0ae0383c34721eda9518b304b2e2162f040.
Integrated hub commit17beb86 and preview/build commit758a955; shared/run changes
a99030d; final landscape chest refinement74f9b0a. The shared palette, Fredoka
headings, outlined pearl panels and aqua ribbons now cover gameplay HUD/rack,
shop, perk/event choices, defeat/victory, inspections/recipes, connection card,
arcade navigation, collection, records, help, crew, rankings, chests and research.
Compact results fit without scrolling. Phone choice models use available height;
chests/rewards get a dedicated side column while retaining44px buttons.

`scripts/check.ps1` PASS after final code: zero lint warnings/errors, full gameplay,
catalog, loading/framing/audio/motion/effects contracts, three builds, mappings and
documentation checks. `scripts/build-ui-preview.ps1` PASS; normal entrypoints
disabled, landscape orientation, temporary synthetic profile with no saves/remotes.
All11 changed client/fixture source fingerprints match Studio after CRLF/outer
whitespace normalization: byte counts plus CRC32, recorded in
[source evidence](../docs/evidence/RBX-031/full-ui-source-fingerprints.json).

Final Studio session0061e41d-a6ef-42a6-9480-977ce8a50bde audits:

| Preset | Core-safe area | Screens | Blender Ready samples | Evidence |
| --- | --- | --- | --- | --- |
| HD1080 | 1919x1022 | 15 | 178 | [Desktop](../docs/evidence/RBX-031/full-ui-desktop.json) |
| iPhone13 landscape | 749x331 | 15 | 171 | [Cutout phone](../docs/evidence/RBX-031/full-ui-landscape-844.json) |
| iPhone7 landscape | 666x316 | 15 | 170 | [Small phone](../docs/evidence/RBX-031/full-ui-landscape-667.json) |

Each checks HUD/modal bounds, shop cards,44px perk/event actions and model loading;
then chooses a perk/event, restarts, enters Endless, buys/opens a chest through
panel pending/reveal logic, researches a locked blueprint and starts a run.
Chest animation completes before the reward/CONTINUE view; research charges the
correct amount and shows its reward. Actual pointer perk choice returns to aim;
actual Open click reveals Rain Catcher and enables Continue.
Visual inspection covered desktop HUD/perks/chests and landscape perks/results/chests.

Normal-entrypoint smoke in the same disposable session: temporarily disabled the
fixture and enabled the unchanged normal server/client Main scripts and avatars.
Both expected initialization logs appeared; pointer Play mounted the real run,
pointer Launch sent a server-owned shot, which scored and advanced to round2.
Pointer Arcade returned to the hub with RESUME RUN; Resume restored round2 at aim.
Normal entrypoint flags are restored to preview defaults after this smoke;
the generated normal build already has normal entrypoints enabled.
Final console has only the existing asset203785492 type warning, no game script errors.

Early fixture-only failures (numeric rewardedEndless seeded as a table, temporary
equipment ownership leaking into the synthetic profile, stale test profile
references) were fixed before these final audits. Review also caught and fixed
an empty notice panel and an unbounded result summary. Automatic approval review
rejected bulk core-source replacement in the old shop session; that path was
abandoned for the fresh disposable UI preview. Later changes there were bounded,
reviewed and source-verified. Existing sessions and native source remain preserved.

Physical touch hardware and multiplayer server checks: NOT RUN. Simulator QA is
not a physical-device claim. No kit purchase, balance/profile changes, merge or
Roblox publication. Accepted State15 remains; this branch still proposes16.

## Latest Handoff

- Owner / next owner: Codex coordinator → user for playtest feedback.
- Objective / completed work: shared cartoon UI across run/arcade, responsive refinements, 15-screen preview and three-preset QA.
- Checkout / branch / PR: checkout above; task/RBX-031-shop-prototype; draft PR32.
- Main re-fetched: 44762e38b5b4e3ad2f89c789ae6a7a6b6f6d4560, accepted15 unchanged.
- Evidence SHA / proposed version: 74f9b0ae0383c34721eda9518b304b2e2162f040;16.
- Checks / limitations: final checks and Studio audits PASS as above; physical hardware/multiplayer NOT RUN.
- Studio target / sync: UI-PREVIEW session0061e41d; sole coordinator operator; no live Rojo or port. Simulator reset; Play running with the UI PREVIEW menu open for the user. Normal Main scripts disabled and fixture enabled were rechecked.
- Normal game file: repository-root `build/Pop-a-Peg-FULL-UI.rbxlx`; SHA256 `00FB3EDFDCF123BF6C0419F5A8C84E91FF48B46CA667A49768FA5B22A381CFDC`.
- Screen preview file: repository-root `build/Pop-a-Peg-UI-PREVIEW.rbxlx`; SHA256 `6206C3E60CD4A884BD4B5EFEBEEACA076BDEC026998FE1537C918379C38315E9`.
- Both files match their worktree build outputs; original PLAYTEST and SHOP-PROTOTYPE preserved.
- Blockers: none for user review; PR remains draft and unmerged.
- Published experience / observed version: no publication requested or performed.
- Next executable action: open FULL-UI and press Play, or open UI-PREVIEW and use its top-right selector for each screen.

GitHub CI129 / run42555374151: SUCCESS for documentation head
c4a9578b7d2441e1855b25162c314a739a432b83, with implementation74f9b0a unchanged.
PR32 remains open/draft; GitHub head matches the pushed branch. This receipt is
documentation-only and does not assert a merge or publication.
