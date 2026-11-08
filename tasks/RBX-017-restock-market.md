# RBX-017 — Restock market, sound and model cleanup

- Task ID: RBX-017
- Owner: Codex coordinator (sole Studio operator), isolated backend/audio/model contributors
- Status: READY FOR REVIEW
- Reservation / issue: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/17
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: a056cfc4773b69df2ef986d72c1c483ac3bd4c10
- Branch: task/RBX-017-restock-market
- Worktree / checkout: C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\restock-market
- PR: https://github.com/Jayden-Amjed/Pop-a-Peg/pull/18
- Implementation evidence SHA: 21ac14748710be87635fb7e0d40ec9f65d6bc683
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Save extra restocks (all beyond the first earned per settled shot) as currency
across runs, spent only in the hub on chosen chest tiers. Prices are Common100,
Uncommon250, Rare500, Legendary1000. This supersedes automatic random-tier grants.
Preserve board/coin/ball rewards and milestone/defeat chests; play up to five full
refill/merge sequences. Add light/rounded/heavy electronic sound contrast.

The user also requested model artifact cleanup and a durable art/Blender workflow.
Remove reproduced duplicate render layers and floating generic upgrade decoration;
preserve identity/motion. No Blender conversion, monetization or publication.

## Acceptance criteria

- [x] Saved server-owned wallet credits each settled shot's extras once.
- [x] Hub wallet, four prices, separate Buy/Open, validated and retry-safe spending.
- [x] Simulated and ordinary native runs recorded with earning-rate limitations.
- [x] At most five full visual cycles; exact rewards and final board preserved.
- [x] Native light/heavy sound loading/playback, overlap limits, mute and cleanup.
- [x] Yellow screen border resolved; user confirmed after our capture runtime reset.
- [x] Model cleanup and native geometry/motion/remount audit; before/after comparison.
- [x] Modeling guides linked from README/AGENTS; local checks and source audit.
- [ ] Remote CI and authorized main integration confirmed.

## Dependencies and overlapping paths

Root owns UI/timeline/integration/status and Studio. Backend owns profile/chests/
server handling/tests; audio owns SoundEffects/ItemFeedback/asset audio notes;
model contributor owns ItemModels and ModelAudit. Backend contributor subsequently
authored only the two new modeling guides. Separate worktrees all started at the
accepted main. Root bootstrap, older task worktrees and the user's playing
peg-progression.rbxlx remain untouched. Rojo is disconnected.

## Implementation evidence

- 1f04f672c6f9ce7ac2544fe283ec1cb9e164f943 integrated backend
  fccbdaff6491bd65a3ff16fb4336313aea3b1642.
- Audio contributor: 0c3a8325a2b0dbe5772c12b4af2f501d11ddb9ad.
- Market/timeline final source before model cleanup:
  9df1e0b275c3c06150f3892bd58dd6f276207c80.
- Final production source: 21ac14748710be87635fb7e0d40ec9f65d6bc683,
  integrating model contribution bd35328b7affa871a916ce2dab235823c9bf9e8a.
- Guide contribution: 53b5c57d15977491c11d91b8ef1797e47ffd6852,
  integrated at3fc180b (documentation only).
- Native harness f742bfe retains rejection acknowledgements across state snapshots.
  1254f7b adds natural runs, c4a6666 the explicit UI fixture,2752c36 the model gallery.

## Checks actually run

| Check | Exact source / environment | Result |
| --- | --- | --- |
| Startup/final fetch | a056cfc, Windows | PASS: accepted main unchanged, version8 reconciled before proposing9. |
| scripts/check.ps1 | final21ac production plus proposed docs | PASS:23 suites, clean StyLua/Selene, Rojo build,38 mappings, docs. |
| Independent review | 1f04f67 | PASS: no blocking findings; narrow footer concern corrected at9df1e0b. |
| Native audio | 015882d audio sources, Studio0.746.0.7461269 | PASS: resonator light pitch1.122; spring_coil/moss_capacitor/bubble_reactor reach0.25; loaded/playing; max12voices/16pending; mix0.340000005; mute/cleanup. |
| Earned-chest loop twice | 1f04f67 sources | PASS: clear3 then controlled early endings;8shots each; Common unlock; pool8→9→10. Functional loop, not natural earning-rate proof. |
| Two natural native runs | 9df1e0b sources, harness1254f7b | PASS: clears8/7; shots13/12;44.20/37.65s at4×; no manual endings; max1restock,0extras; hub wallets agree. |
| Eight native clients | 9df1e0b production, harnessf742bfe | PASS:251–258 isolated wallets, one Uncommon250 each, persisted balances1–8; retries/rebind/insufficient/run-view rejections; resume/departure,7remain. |
| Initial multiplayer attempt | prior harness9df1e0b | FAIL: brief rejection overwritten before test poll; retained notice sequence and reran successfully. No production bug found. |
| Real market buttons | 9df1e0b, explicit350-credit session fixture | PASS: Common350→250 stores1; opening unlocks Rain Catcher without wallet debit; Uncommon250→0 stores1; disabled Buy and wallet agree. |
| Desktop/phone UI | 9df1e0b; iPhone17Pro portrait402×778 | PASS: native captures/TextFits; four prices, wallet, Buy/Open and widened footer. Default viewport restored. |
| Model audit | final21ac | PASS:78 distinct models,2557 L1 parts,max143; zero exact coincident geometry at L1/L5;78 remount checks; disabled physics and activation restoration. |
| Native model comparison | before2752c36 / after21ac | PASS: L5 fishbowl/seed_bank/biolume_jar no enlarged black copy or floating generic gold trim. Single geometry pass. |
| Final Studio source audit | final21ac | PASS: all41 normal sources match normalized UTF8 checksums; both Main scripts enabled, fixtures removed, Edit stopped. |
| Yellow capture border | Windows | PASS: reset Node visual-testing runtime; its capture helper exited; user confirmed border gone. Privacy settings unchanged. |

### Economy measurements

Executed .tools/luau.exe tests/RestockEconomy.playtest.luau at backend fccbdaff
(same earnings implementation integrated at1f04f67). All24 runs buy real offers
at real costs; no scores/items/coins/currency granted. Discovered cohorts preown
blueprints only. Preview aim uses visible first-hit information. Oracle aim
simulates25 full shots before choosing: an upper bound, not human play evidence.

Each cell is successful clears / extra restocks earned:

| Seed | Preview starter | Preview discovered | Oracle starter | Oracle discovered |
| ---: | ---: | ---: | ---: | ---: |
| 17 | 8 / 0 | 8 / 0 | 100 / 221 | 100 / 99 |
| 23 | 4 / 0 | 4 / 0 | 100 / 474 | 95 / 0 |
| 41 | 6 / 0 | 6 / 0 | 100 / 495 | 100 / 168 |
| 79 | 10 / 0 | 10 / 0 | 100 / 317 | 31 / 0 |
| 137 | 18 / 0 | 9 / 0 | 100 / 540 | 100 / 136 |
| 613 | 2 / 0 | 2 / 0 | 100 / 322 | 100 / 68 |

Starter oracle first100 at rounds88/66/64/80/57/69; max12 restocks within campaign
cap. Rare/Legendary reduced from proposed600/1500 to500/1000. Purchases are optional
long-term targeting; free milestone and qualifying-defeat chests remain the early
discovery path. Human pacing is unproven. Wider catalogs can weaken this simple
buying bot. Modeled time estimates are not measured human completion times.

### Model diagnosis and future workflow

Before capture RBX017_ModelBefore showed expanded black copies through/around glass.
Both outlined and unoutlined versions had floating gold rails/nodes generated from
bounds rather than authored attachment points. After capture RBX017_ModelAfter
shows their removal; each builder's authored details and UI level badges remain.
Remount ownership prevents accumulated geometry/cameras. The native audit found
no exactly coincident geometry; this does not prove every possible visual join.

[Style guide](../docs/MODEL_STYLE_GUIDE.md) defines palette, shape/material hierarchy,
clean joins, motion clearance, project budgets and acceptance.
[Modeling workflow](../docs/MODELING_WORKFLOW.md) proposes three Blender pilots,
editable .blend sources, GLB/FBX export, import/pivot normalization and comparison
against native fallbacks. No Blender command/default install or MCP tool was
found; portable installs elsewhere unknown. No installation/import/upload done.

## Limitations and blockers

No production DataStore/OrderedDataStore, physical touch/gamepad, live plugin sync
or Roblox publication tested. Native audio loading is separate from subjective
listening quality/speaker response. Fixtures use session storage only. Existing
unrelated203785492 asset warning remains. No monetization added.

## Handoff

- Objective / completed work: implemented, locally checked and Studio verified; remote CI/merge pending.
- Owner / next owner: Codex coordinator.
- Absolute checkout / branch / PR: checkout above; task/RBX-017-restock-market; PR18.
- Main SHA inspected / accepted State Version: a056cfc4773b69df2ef986d72c1c483ac3bd4c10 /8.
- Evidence SHA / proposed State Version:21ac14748710be87635fb7e0d40ec9f65d6bc683 /9.
- Checks and remaining limitations: above; CI and merge pending.
- Studio version / development target / operator:0.746.0.7461269; peg-restock-qa.rbxlx; fcaa7ed5-f945-4708-abd8-d081f39a8ee2; root.
- Sync state: Rojo disconnected; explicit source handoff, Play stopped in Edit;41 sources verified, fixtures removed.
- Playable output: build/peg-restock-market.rbxlx.
- Build SHA256:E4611D91B7F2D0682EFA1D6C64E9CC109E826CC9977940FD4366238E80E32FF7.
- Published experience / place / observed version: NOT PUBLISHED; local PlaceId/GameId0.
- Preserved work: user's running place and unrelated checkouts untouched.
- Next smallest executable action: publish final PR head, observe CI, merge under existing authorization.
