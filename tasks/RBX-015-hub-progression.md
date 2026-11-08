# RBX-015 — Hub progression, leaderboards and mobile polish

- Owner: Codex coordinator; backend, content and model contributors in isolated worktrees.
- Status: READY FOR REVIEW
- Starting / refreshed main: 9d516120dc4c925061c444f713fb3b40719e1688
- Implementation: b8329c800762f3d238f5d535261ab09cbdb18312
- Branch: task/RBX-015-hub-progression
- PR: [#16](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/16)
- Reservation: [#15](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/15)
- Reviewed: 2026-11-08, America/Los_Angeles

## Objective and acceptance

Full goal: hub rankings for time played, highest Endless round and experience Robux
spent; earned tiered run chests opened in the hub; tiered equipment unlocks that gate
future rolls; substantially more items; unique item/perk models and broader figure-eight
motion; another polish pass with clean mobile UI.

- [x] Three physical ranking screens and responsive category panel.
- [x] Tiered chest rewards, opening/research, migration, failure and replay safety.
- [x] Unlock-only shop pool and 18 new equipment definitions with multiple effects.
- [x] Distinct models for all items/perks/chests/events and animated choice previews.
- [x] Native phone portrait/landscape shop, choices, hub and progression inspection.
- [x] Local rules/persistence/layout checks, native ordinary gameplay and eight-client checks.
- [x] Updated onboarding, overview, assets and Studio procedures.
- [ ] Verified main integration and completion receipt.

No products, purchase prompts, paid chests or production publication. Robux means
spending in this experience, not account-wide spending. No purchase processor exists;
the zero-entry board explicitly says purchases are not enabled.

## Implementation and ownership

Root owns hub world/panels, integration, documentation and sole Studio operation.
Backend owns profiles/leases/chests/rankings; content owns catalog/rules and mobile
follow-up; models owns original geometry/animation. Separate worktrees used; root
starter checkout remained at 608c273 on task/RBX-001-bootstrap.

Integrated contributor source commits: 054ef82a78a859127cb09e6e36c627dd08a9c70a
(content), 8dbbc25fe3642bde3d471d83d1f5d7471685069f (models),
c8959ca2e9c82abf902d3c96b2639980cc96a9c1 and fc11dae119e01bbda326e0a39048db541bdef3e4
(backend), 49c702bb47d9074085f5fb7248e3a80f96a6767a,
062911ee3a5a7e29023393e72eee4f9237014766 and 5c3deb4ef7c51a1ae8e155ec01abd88b7b35b9aa
(mobile), 314f2bd2cd4f13f7a31630a8346e4b3605c7e80f (docs), and
c15792ff54ace4eaecaebc4274121d07d82914df (multiplayer harness).
Final integrated production source is the implementation SHA above.

Profile v2 keeps item ownership separate from legacy discoveries. Starter items:
Tap Driver, Sun Prism, Shore Meter, Landing Shell, Survey Lens, Reef Chime, Compass,
Seed Bank. Existing discovered base items and legacy category unlocks migrate.
New runs freeze ownership; parked runs retain their original pool.

Four tiers contain 14/12/8/6 base items. Available-tier roll weights are 60/28/10/2.
Common/uncommon/rare/legendary chests unlock an unowned item in their tier; exhausted
tiers grant 1/3/6/10 research. Targeted research costs 6/12/24/40.
Defeat qualifies after three cleared rounds. Milestone rewards occur at 15/40/65/100;
Endless rewards every 50 clears from 150. Award identities prevent duplicate settlement.

The 180-second renewable profile lease owns replacement saves for consumables.
Failed loads never silently become default profiles. Spending is serialized.
Newest 64 request receipts persist operation/target/result; retries restore the
original acknowledgment without another debit, including A/B/A replay and reload.
Very old IDs outside this bounded history are not an indefinite deduplication promise.

## Executed checks

Windows PowerShell; pinned repository tools:
- PASS scripts/check.ps1: 22 suites, StyLua, Selene 0 errors/warnings, Rojo build,
  38 exact source mappings and documentation links/required fields.
- PASS git diff --check.
- Discovery checks include 90 item/level activations, 60 mixed max-level cascades,
  20,000 weighted rolls and 3,200 starter-only offers.
- Persistence adapter checks inject UpdateAsync callback retries, pre/post-commit
  timeout, lease takeover, stale owners, unavailable load and release ambiguity.
- Layout checks cover seven run safe-area cases, seven progression safe-area cases,
  nine hub sizes, notch-aware camera math, all six offers and two perk choices.

Initial lint could not download Roblox metadata in the sandbox; network-enabled
check rerun passed. One opt-in report-global lint warning was documented locally
and resolved. Native test-command assertion mistakes referenced nonexistent helper
fields; corrected assertions used actual GUI objects. These were test commands,
not production exceptions.

## Native Studio evidence

Studio 0.746.0.7461269. Root operator, Rojo disconnected; isolated local PlaceId=0,
GameId=0. Target 0f901236-a3db-4178-890f-d0cb4929d1e1, peg-mobile-qa.rbxlx.
Earlier progression target 8ecac18a-88c0-4af2-ab3a-610b413816e9 remains stopped.

- ModelAudit: all 78 model identities have distinct geometry fingerprints excluding
  color/name. 2,557 parts total, 143 max per model; bounded geometry and exact
  activation restoration. Includes 18 new items, four chests and four event models.
- Hub world: 1,038 BaseParts, four-tier chest pavilion facing the entry path, three
  ranking screens, six-action dock; physical chest pavilion visually inspected.
- Temporary single-client fixture: chest opening reduced common count 2 to 1 and
  ownership 8 to 9. Research purchased Tide Clock for 12 (50 to 38). Time and Endless
  boards showed seeded values; Robux showed honest empty state. Seeded load source
  was removed before subsequent tests.
- Ordinary-action ProgressionPlay (no grants): eight shots, three successful round
  clears, defeat, one Meadow chest, Lily Pad unlock, new-run pool 8 to 9, return hub.
  19 actions, 20.4 seconds. This is gameplay evidence distinct from fixture tests.
- Phone emulator: portrait 401x719 core-safe area inside a 401x873 full screen and
  749x323 landscape. Corrected full-renderer camera fit; bottom peg y533.36 versus
  launch y619. Aim screen/world round-trip error below 0.000003 studs; FX anchor error 0.
- Actual window input opened/closed Stats and the shop rack; compact evolution button
  opened the full ordered-effects/equations inspector. Both layouts kept 4+2 offers
  visible. Perk choices had 104px previews and visible figure-eight motion.
- Five repeated Stats/Perks layouts retained silhouette Z exactly one below source.
  Compact shop previews enlarged to 52–64px and rack text changed to dark ink;
  verified in native window because MCP capture omitted two otherwise visible models.
- Chest request rejection with unchanged balances now rerenders the disabled action;
  native assertion passed after finding and fixing that lifecycle bug.
- Enhanced ExecuteMultiplayerTestAsync(8, ArcadeEightClients): ok=true, eight distinct
  stations. All eight passed ready, chestA, chestB, replayA, changed-target/operation
  rejection, research, start, run-view chest rejection, launch, hub and resume.
  Persisted profile checks passed for all eight after replay, rejection and research.
  Each owned 11 items after two chests and research; individual balances stayed isolated.
  Seven remaining clients passed idle; departed station 8 cleared.
- Multiplayer fixture seeded only Studio session profiles before Main startup.
  Cleanup restored both Main scripts, removed both ArcadeMultiQA scripts, and stopped
  Edit. All 41 normal source checksums match repository source.

Unrun: physical touch/gamepad, production DataStore/OrderedDataStore connectivity,
live Rojo forward/return sync this pass, and publication. Emulator and eight Studio
clients do not prove eight physical devices' performance. Human long-run balance
remains necessary. MCP captures can omit peg numbers/previews; native captures
verified visibility. Unrelated asset 203785492 warning remains. Presentation-only
fixture briefly had no State listener, causing a test-only queue warning; normal
client was restored and multiplayer used the real listener.

## Handoff

- Owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/progression-hub.
- Studio: target above, Edit, both normal Main scripts enabled; no QA scripts; Rojo disconnected.
- Build: build/peg-progression.rbxlx.
- SHA256: B800D286088FA0F0AB70FD9EDD039D963A7702E5C139853FC6BA647D8F80E036.
- Accepted State Version: 7. Proposed next material state: 8; fetched predecessor unchanged.
- Blockers: none. Final PR CI and authorized main integration pending.
- Published: NOT PUBLISHED.
- Next action: push the implementation/evidence, pass CI, merge PR #16, record GitHub's
  actual merge identity in one bounded completion receipt.
