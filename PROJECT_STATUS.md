# Current project state

State Version: 2 (proposal dependent on starter version 1; neither accepted on main)
Reviewed: 2026-11-07, America/Los_Angeles
Objective: Independent peg-bounce runs with clear rewards, varied hybrid builds, and an aquatic glass presentation.

Accepted source: `9349530edb7eaf536ceabfed5e922ae5b65499a6` (README-only main seed; fetched again).
Dependency: starter [PR #2](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/2), unmerged,
at `608c273d9f31022d2f161584c4c92188bb4405cd`. Main has no accepted status ledger.
Previous implementation: `b1cf8886a2b5c7f79e3147984ff140cb55900fa1` in dependent
[PR #4](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/4).

New polish revision: IN PROGRESS. Larger grouped shop/rack controls, stable model
selection, white accents, perk tracking, figure-eight idle motion, counter pulses,
and scenery stability are being implemented. Evidence below is the previous build.
The user authorized main integration after the new version is playtested.

| Capability | Verified state |
| --- | --- |
| Board, quotas, restocks, run/shop/perk/event/reset rules | PASS standalone and Studio; 28 progression cases |
| Hybrid effects and themed synergies | PASS ordered operations, costs, fish-pair scoring, bounded relay chains |
| Full rack and capped upgrades | PASS L1 Seed Bank upgrades for 5 coins with 7 occupied slots; L2 displays MAX LEVEL |
| Fixed shop and rack interactions | PASS 30 offer/text/bounds cases across five sizes; click/select/clear/swap, pending acknowledgments |
| Shot history and perk cash-out | PASS counts held through shop until Next Round; decline pays exactly 5 coins |
| Item geometry and animation | PASS 39 models at both levels; all 78 return to exact rest transforms after retriggers |
| Item feedback | PASS target beams, separate growth/cost labels, score arrival/bounce, 33 bounded electronic motifs and mute |
| Repository checks | PASS pinned format/lint/tests/build/source mapping/docs |
| Production Studio sources | PASS all 20 restored exactly; ordinary server/client play and scoring checked |
| GitHub CI | PASS push and PR checks at implementation SHA |

Studio-tested source: `b1cf8886a2b5c7f79e3147984ff140cb55900fa1`.
Visual tests include deterministic fixtures; ordinary production startup/play was
checked separately. See [RBX-003](tasks/RBX-003-peg-run-loop.md) for evidence and limits.
Published: NOT PUBLISHED; no production experience/place selected.

Active task: RBX-003, owner Codex gameplay coordinator, branch `task/RBX-003-peg-run-loop`.
Current playable file: generated `build/peg-aero.rbxlx` in the game worktree.
Studio: isolated `peg-aero-qa.rbxlx` stopped in Edit; production sources restored; Rojo disconnected.
The user's separate existing place/play windows were not modified.
Blockers / dependencies: no implementation blocker; PR #2 must precede PR #4 integration.
Unrun: physical mobile/touch, two clients in one server, cloud persistence, live plugin sync, merge/publish.
Limits: only the upgrade shop guarantees no scrolling; other compact choice menus may scroll.
Human playtesting is still needed to judge balance, variety, visual preference, and the sound mix.
Observed limitation: unrelated Studio asset-type warning for 203785492; no project source reference.
Next action: complete polish, verify in Studio, then merge starter PR #2 and gameplay PR #4 into main.
Repository administration: main remains unprotected; default branch remains the starter branch.
