# Current project state

State Version: 1 (proposal; no accepted main predecessor)
Reviewed: 2026-11-07, America/Los_Angeles
Objective: Bootstrap a neutral, reproducible Roblox starter and durable agent workflow.

Accepted source: `9349530edb7eaf536ceabfed5e922ae5b65499a6` (README-only seed on main).
Starter implementation and this first status ledger remain proposed in PR #2.
Implementation evidence: `755ac2539fd913e664dd48fe97a91ea046ec3da0`; see [RBX-001](tasks/RBX-001-bootstrap.md).

| Capability | Verified state |
| --- | --- |
| Fresh checkout, pinned Windows tools, build, format/lint | PASS; PowerShell 5.1 and 7 tested |
| Server/client/shared instance mapping, docs links/fields | PASS; built XML classes and source verified |
| Studio → MCP source capture → GitHub → rebuilt Studio | PASS with temporary expanding-ball probe |
| Shared XML → scratch syncback | PASS with generated fixture; real Studio XML export NOT RUN |
| Rojo serve command | PASS; localhost endpoint responds; stopped after check |
| Live Rojo plugin propagation / branch reconnect | NOT RUN; explicit build/reopen tested instead |
| GitHub CI / PR integration | CI PASS at `ade0ab5`; PR #2 OPEN, NOT MERGED |

Studio-tested source: `9a9ee6b57678a551e593cc5df749fda126d6e70d`, Windows Studio
0.746.0.7461269, Rojo/plugin 7.7.1; server + one client. Probe removed at implementation SHA above.
Published: NOT PUBLISHED by this starter; no target experience/place selected.

Active task: [RBX-001 bootstrap](tasks/RBX-001-bootstrap.md), owner Codex coordinator,
branch `task/RBX-001-bootstrap`, [reservation #1](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/1).
PR: [#2](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/2) OPEN; task READY FOR REVIEW.

Blockers / dependencies: review and merge remain pending. User authorized main creation
and PR opening; both completed. Task branch remains the temporary default.
Rulesets: none; main is unprotected (API, 2026-11-07).
Unrun: live plugin round trip/branch reconnect, real XML export, two-client test, merge/publish.
Observed limitation: Studio Output contains asset-type warnings for ID 203785492 (not referenced by starter source).
Next action: review PR #2 and resolve pending checks; merge only when authorized.
Repository setup remaining: required CI/review protection and default main after integration.
