# Current project state

State Version: 2 (proposal dependent on starter version 1; neither accepted on main)
Reviewed: 2026-11-07, America/Los_Angeles
Objective: An independent peg-bounce run with clear automatic rewards, modeled upgrades, and a fixed 3D board.

Accepted source: `9349530edb7eaf536ceabfed5e922ae5b65499a6` (README-only main seed; fetched again).
Dependency: starter [PR #2](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/2), unmerged,
at `608c273d9f31022d2f161584c4c92188bb4405cd`. Main has no accepted status ledger.
Implementation: `e4953887985930b08514ebcee2c0d392570a861e` in dependent
[PR #4](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/4); READY FOR REVIEW.

| Capability | Verified state |
| --- | --- |
| Board, pass-through pegs, quotas, five-ball life accounting | PASS standalone and Studio contracts |
| Run/shop/perk/event/boss/endless/reset rules | PASS 18 progression cases; revised heuristic balance samples recorded |
| Flying score, repeating quota meter, automatic restoration/refill/merge/rewards | PASS Studio fixtures, including 3 and 10,000 restocks, skip, exact final balances, and counter races |
| Original native models | PASS all 37 instantiated and visually reviewed; upgraded equipment and pulse reset checked |
| Green interface and modeled choices | PASS 25 menu/layout/text cases across five sizes; purchase/upgrade click verified |
| Sound effects | PASS five public assets loaded; ten cues played, produced nonzero signal, stopped, and muted |
| Format/lint/tests/build/source mapping/docs | PASS pinned checks; all 16 Studio production sources restored exactly |
| GitHub implementation CI | PASS push and PR checks at implementation SHA |
| Published cloud saves, same-server multiplayer, physical touch | NOT RUN |

Studio-tested source: `e4953887985930b08514ebcee2c0d392570a861e`.
Visual tests include isolated fixtures; normal production startup and keyboard play
were checked separately. See [RBX-003](tasks/RBX-003-peg-run-loop.md) for evidence and limits.
Published: NOT PUBLISHED; no production experience/place selected.

Active task: RBX-003, owner Codex gameplay coordinator, branch `task/RBX-003-peg-run-loop`.
Current playable file: generated `build/peg-feedback.rbxlx` in the game worktree.
Studio: isolated QA target restored to production sources; Rojo disconnected.
The user's separate existing place/play windows were not modified.
Blockers / dependencies: no implementation blocker; PR #2 must precede PR #4 integration.
Unrun: physical mobile/touch, two clients in one server, cloud persistence, live plugin sync, merge/publish.
Limits: short landscape menus scroll; subjective audio balance still benefits from human listening.
Observed limitation: unrelated Studio asset-type warning for 203785492; no project source reference.
Next action: playtest the revised build and review PR #4; select a separate development experience before release checks.
Repository administration: main remains unprotected; default branch remains the starter branch.
