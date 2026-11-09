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
- Implementation evidence SHA: 05f1d16deda43a0721a51e318990a9e4503678ae (annotated retouch; Studio verified); historical full UI74f9b0ae0383c34721eda9518b304b2e2162f040
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Active annotated retouch follow-up: shop currency/model margins/complete inspection,
structured Supplies and perk/event cards (confirmed name above model), larger stable
rack, lower side HUD, larger currency/life icons, grouped action/speed controls,
music mute glyph, common Recipe detail card and workshop name placement. Shared
straight white Bevel strips removed. Root owns Theme/run UI/Studio; retouch_shop,
retouch_hub and retouch_review own disjoint shop/detail, hub and audit paths in
separate worktrees based on accepted main plus explicit dependency96ac86a.
Prior full-UI evidence below remains historical; fresh retouch evidence is recorded below.

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

## Historical full-UI handoff

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

## Annotated retouch implementation and checks

Source 05f1d16deda43a0721a51e318990a9e4503678ae implements the annotated follow-up.
The user clarified that Perks and Spare Parts names belong above their models.
Both choice types now use separate name/model/trigger-effect/action compartments.
The rack keeps the same larger model region across aim and choices; gameplay
activation playback remains enabled. Desktop side stacks sit below the raised
rack, and Launch/Jumble and speed buttons have their own larger rounded panels.
The music glyph uses a red diagonal slash when muted and preserves existing
sound-toggle behavior. Currency and life previews are larger.

Shop equipment has an inset model window. Numeric prices precede real coin models,
including narrow purchase buttons. Supplies use the annotated left-model and
right-name/price/action structure. Shared ItemDetailCard owns the model, name,
colored catalog trigger/effect rows and every applicable evolution equation.
Long content scrolls at readable type sizes. Shop inspection is inline; the
extra details button and hint are removed. Recipe detail reuses this card with
a fixed return to Gallery. Workshop only moves names above models. Shared
surfaces use contained gradients and rounded borders instead of white Bevel strips.
Results/victory and collection gallery layouts are otherwise unchanged.

Checks actually run: scripts/check.ps1 PASS at05f1d16 and again at
997988317ea859ec56f5cc31be3e40d29bef7de9 (zero lint warnings/errors, all
gameplay/catalog contracts, three builds, mappings and documentation links).
scripts/build-ui-preview.ps1 PASS at05f1d16; production source unchanged since.
Read-only review caught score/level overlap and undersized medium-landscape
controls; both were fixed before these checks. The latter and shortest fallback
have source/layout coverage, not separate runtime device receipts.

### Retouch Studio verification

User opened fresh local UI-RETOUCH. Selected and verified unpublished session
cdcbb509-40c9-42ce-98d6-6d5cc363469f, with root as sole operator and no Rojo.
All34 normalized client/fixture source fingerprints match the filesystem:
[byte-count/CRC32 evidence](../docs/evidence/RBX-031/retouch-source-fingerprints.json).
Normalization uses LF and trimmed outer whitespace; this is source comparison,
not a cryptographic integrity claim.

UiRetouchAudit at9979883 and UiPreviewAudit at05f1d16 both PASS:

| Preset | Actual safe area | Retouch model samples | Flow model samples | Evidence |
| --- | --- | --- | --- | --- |
| HD1080 (1920x1080) | 1919x1022 | 242 | 192 | [Retouch](../docs/evidence/RBX-031/retouch-desktop.json), [Flow](../docs/evidence/RBX-031/retouch-flow-desktop.json) |
| iPhone13 landscape (844x390) | 749x331 | 230 | 183 | [Retouch](../docs/evidence/RBX-031/retouch-landscape-844.json), [Flow](../docs/evidence/RBX-031/retouch-flow-landscape-844.json) |
| iPhone7 landscape (667x375) | 666x316 | 229 | 182 | [Retouch](../docs/evidence/RBX-031/retouch-landscape-667.json), [Flow](../docs/evidence/RBX-031/retouch-flow-landscape-667.json) |

All15 screens checked: Aim, Perks, Event, Shop, Recipe, Workshop, Defeat, Victory,
Arcade, Collection, Records, Help, Chests, Rankings and Crew. Every sampled model
was Blender Ready. These are repeated model samples, not distinct model counts.
Retouch audits check control/HUD containment,44px actions, readable target/meter,
name-first choice compartments, catalog trigger/effect text and colors, complete
inspection/equations, scrolling reachability, Recipe return and Workshop order.
Worst fixture inspection includes six effects and two recipes. Phone audits
also exercise unaffordable purchase, upgrade and sold compact currency states.
All screens are checked for removed Bevel strips; each audit restores Aim.

Full-flow audits exercise eight local preview-controller actions: choosePerk,
chooseEvent, restart, endless, buyChest, openChest, researchItem and startRun.
Chest animation/reveal and charged research/reward complete before assertions.
These synthetic local flows do not establish multiplayer/production-remote coverage.
The initial desktop flow run was interrupted by the operator selecting Aim while
it was still executing, causing researchItem timeout. The complete sequential
rerun passed, followed by both phone runs without concurrent screen changes.

Actual Studio screenshots visually inspected desktop Aim/Perks/Shop/Recipe/
Workshop/music; iPhone13 Aim/Perks/Shop; and iPhone7 Spare Parts. Real Blender
models, inset spacing, name-first choices and grouped controls rendered.
Simulator screenshots are fit to the Studio window; audit dimensions above
describe the actual simulated safe-area geometry.

Manual MCP pointer clicks independently verified Recipe's Gallery return
(changed panel title to EVOLUTION AQUARIUM) and the music toggle both ways
(Muted attribute and visible diagonal slash track the same state).

### Normal entrypoint smoke and restoration

In this disposable session only, stopped Play and temporarily enabled normal
client/server Main plus character spawning, disabling UiPreview. Expected client
and server startup logs appeared. Actual pointer Play mounted the normal run;
Launch entered KEEP THE COMBO GOING and settled back to READY TO LAUNCH at round1
with0/10 score (the shot missed; no round-advance claim). Arcade exposed RESUME RUN;
Resume restored round1 at aim and preserved muted=true/slash=true with the
GameFeedback sound group at volume0. Pointer unmute cleared the slash and restored
volume0.7. Final console had no game-script errors, only the existing203785492
asset-type warning.

Stopped normal Play, then restored fixture enabled, normal client/server scripts
disabled, CharacterAutoLoads=false, and stopped device simulation. Rechecked
those properties. The session is left in Edit for the user to press Play.
No Studio source edits were promoted, and delivered file hashes remain unchanged.
Physical touch hardware and multiplayer checks: NOT RUN.

## Latest Handoff

- Owner / next owner: Codex coordinator → user for playtest feedback.
- Objective: annotated retouch implemented, checked and Studio verified; ready for review.
- Checkout / branch / PR: checkout above; task/RBX-031-shop-prototype; draft PR32.
- Main re-fetched: 44762e38b5b4e3ad2f89c789ae6a7a6b6f6d4560; accepted15 unchanged, proposal16.
- Implementation / Studio-tested SHA: 05f1d16deda43a0721a51e318990a9e4503678ae.
- Retouch audit SHA: 997988317ea859ec56f5cc31be3e40d29bef7de9.
- Checks: source/build PASS; three retouch audits, three flow audits, manual pointer checks and bounded normal-entry smoke PASS as above; physical-device/multiplayer NOT RUN.
- Target / sync: root build/Pop-a-Peg-UI-RETOUCH.rbxlx, sessioncdcbb509-40c9-42ce-98d6-6d5cc363469f; sole coordinator operator, no Rojo/port. Play stopped in Edit; preview defaults restored; simulation stopped.
- Preview SHA256: BFAF9E03A1E54439597ED34C73674ED1808006168BAEC1B232BFA0E84179FA53.
- Normal game: root build/Pop-a-Peg-FULL-UI-RETOUCH.rbxlx; SHA256 873C3F0FE1D5705721E643F09381E2271B8E78C7289C49B71750D16AD4755605.
- Preservation: old UI-PLAYTEST907b1894 saved as build/Pop-a-Peg-UI-PLAYTEST-preserved-20261108.rbxl and closed previously; old UI-PREVIEW0061e41d no longer listed after user opened fresh retouch. Other historical sessions/files and unrelated root outputs preserved.
- Previous blocker resolved: user opened the fresh file; Studio MCP captures and runtime tests succeeded. No remaining blocker for review.
- Next executable action: press Play in the open UI-RETOUCH and use UI PREVIEW, or open FULL-UI-RETOUCH for the normal game.
- Merge / Roblox publication: neither requested nor performed.
