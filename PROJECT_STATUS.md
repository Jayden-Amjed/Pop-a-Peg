# Current project state

State Version: 2 (proposal dependent on starter version 1; neither accepted on main)
Reviewed: 2026-11-07, America/Los_Angeles
Objective: Complete the independent peg-bounce run loop with a fixed 3D board and meaningful upgrade combinations.

Accepted source: `9349530edb7eaf536ceabfed5e922ae5b65499a6` (README-only main seed).
Dependency: starter [PR #2](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/2), unmerged,
at `608c273d9f31022d2f161584c4c92188bb4405cd`.
Gameplay work remains proposed in [PR #4](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/4),
which targets the starter branch. Main has no accepted status ledger yet.

| Capability | Verified state |
| --- | --- |
| Peg values, quotas, restocks, fixed-step collisions | PASS in standalone Luau tests |
| Run phases, shop transactions, triggers, reset boundaries | PASS, 14 progression cases |
| Profile validation and monotonic record merge | PASS in standalone Luau tests |
| Integrated format/lint/build and mapped source | PASS |
| 3D presentation and complete server/client loop | Implemented; Studio NOT RUN |
| GitHub CI for gameplay implementation | NOT RUN; implementation not pushed yet |
| Published cloud saves and simultaneous clients | NOT RUN |

Studio-tested source: gameplay NOT RUN. Historical starter round-trip evidence is
in [RBX-001](tasks/RBX-001-bootstrap.md); it does not establish gameplay behavior.
Published: NOT PUBLISHED; no production experience/place selected.

Active task: [RBX-003](tasks/RBX-003-peg-run-loop.md), owner Codex gameplay coordinator.
Branch: `task/RBX-003-peg-run-loop`; PR #4 DRAFT; reservation #3.
Studio: coordinator only; gameplay target not opened, no live Rojo sync connected.
Blockers / dependencies: PR #2 remains unmerged; dependent development is proceeding.
Unrun: gameplay Studio playtest, two-client test, live plugin sync, cloud persistence, merge/publish.
Next action: verify the built game and controls through Studio MCP.
Repository administration: main remains unprotected; default branch remains the starter branch.
