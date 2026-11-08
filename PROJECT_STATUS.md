# Current project state

State Version: 2 (proposal dependent on starter version 1; neither accepted on main)
Reviewed: 2026-11-07, America/Los_Angeles
Objective: A complete independent peg-bounce run with a fixed 3D board and upgrade combinations.

Accepted source: `9349530edb7eaf536ceabfed5e922ae5b65499a6` (README-only main seed; fetched again).
Dependency: starter [PR #2](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/2), unmerged,
at `608c273d9f31022d2f161584c4c92188bb4405cd`. Main has no accepted status ledger.
Implementation: `c73e29012c40053bab943d03d5412ae05b89ad7a` in dependent
[PR #4](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/4); complete and READY FOR REVIEW.

| Capability | Verified state |
| --- | --- |
| Board values, quotas, restocks, swept collisions | PASS standalone and in-engine contracts |
| Run/shop/perk/event/boss/endless/reset rules | PASS 14 progression cases; natural-action samples include round-80 wins |
| Profile validation and monotonic merge | PASS; local restart preserves only records/unlocks |
| Format/lint/build/source mapping/docs | PASS with pinned tools |
| Studio controls, first shop, purchases, held offers, reorder, restart | PASS server + one client |
| Six menu layouts and expanded shop | PASS desktop fixture and screenshot checks |
| GitHub implementation CI | PASS push and PR checks at implementation SHA |
| Published cloud saves, same-server multiplayer, physical touch | NOT RUN |

Studio-tested source: normal gameplay `d3e7556036925b9c6a09ff923abf52bbb93bde9e`;
final layout and exact equality of all 11 sources `c73e29012c40053bab943d03d5412ae05b89ad7a`.
See [RBX-003](tasks/RBX-003-peg-run-loop.md) for commands, evidence, limits, and CI links.
Published: NOT PUBLISHED; no production experience/place selected.

Active task: RBX-003, owner Codex gameplay coordinator, branch `task/RBX-003-peg-run-loop`.
Development files: generated `build/peg-run.rbxlx` and `build/peg-run-qa.rbxlx`.
Studio: QA stopped, normal source restored, Rojo disconnected; user's separate play window left available.
Blockers / dependencies: no implementation blocker; PR #2 must precede PR #4 integration.
Unrun: two clients in one server, physical mobile/touch, cloud persistence, live plugin sync, merge/publish.
Observed limitation: unrelated Studio asset-type warning for 203785492; no project source reference.
Next action: human playtest and PR review; run multiplayer/mobile/cloud checks before a release.
Repository administration: main remains unprotected; default branch remains the starter branch.
