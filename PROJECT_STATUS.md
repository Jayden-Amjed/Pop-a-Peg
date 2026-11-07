# Current project state

State Version: 1 (proposal; no accepted main predecessor)
Reviewed: 2026-11-07, America/Los_Angeles
Objective: Bootstrap a neutral, reproducible Roblox starter and durable agent workflow.

Accepted source: NONE — remote main has not been initialized. Branch evidence is a proposal.
Implementation evidence: `f464e164ae43bb8016e101f6050d33aaec181923`; see [RBX-001](tasks/RBX-001-bootstrap.md).

| Capability | Verified state |
| --- | --- |
| Pinned Windows tools, Rojo place build, format/lint | PASS locally; detailed commands in task |
| Server/client/shared instance mapping, docs links/fields | PASS; built XML classes and source verified |
| Shared export → scratch syncback | PASS with generated XML fixture; live Studio export pending |
| Live Studio sync, play, branch transition | NOT RUN; user stopped desktop automation |
| GitHub CI / PR integration | NOT RUN yet; remote main absent |

Studio-tested source: NONE; Studio 0.746.0.7461269 detected; matching plugin installed.
Published: NOT PUBLISHED by this starter; no target experience/place selected.

Active task: [RBX-001 bootstrap](tasks/RBX-001-bootstrap.md), owner Codex coordinator,
branch `task/RBX-001-bootstrap`, [reservation #1](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/1).
PR: unavailable until main exists. Docs contributor uses isolated worktree; integrated locally.

Blockers / dependencies: main initialization was rejected by automatic approval review;
finish a reviewable task branch before asking for explicit initialization approval.
GitHub rulesets: none observed through API on 2026-11-07; no protections configured.
Unrun checks: clean clone install/build, CI, Studio runtime/sync/transition.
Next action: verify clean clone and CI on task branch, then request main initialization approval.
