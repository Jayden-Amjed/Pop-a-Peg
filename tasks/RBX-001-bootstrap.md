# RBX-001 — Reusable Roblox starter

Owner: Codex bootstrap coordinator; documentation contributor in isolated worktree.
Status: READY FOR REVIEW (PR #2 open; not merged)
Objective: Provide the requested neutral starter and small, durable collaboration workflow.
Scope: source mapping, smoke scripts, pinned tools, build/sync helpers, CI, docs, evidence.
Non-goals: gameplay framework, game design, production publishing, full-place round trip.
Starting main: NONE (empty remote inspected 2026-11-07); local seed `9349530edb7eaf536ceabfed5e922ae5b65499a6`.
Branch: `task/RBX-001-bootstrap`
Worktree: `C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg`
PR: [#2](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/2), base `main`, OPEN.
Reservation: [GitHub issue #1](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/1).
Dependencies: PR review, current GitHub checks, and merge authorization; pending Studio checks below.
Overlapping paths: repository-wide bootstrap. Docs contributor owns README, AGENTS, overview/workflow, task/PR templates in `.worktrees/workflow`; coordinator owns implementation and current evidence.

## Acceptance

- [x] Fresh checkout installs pinned tools and builds.
- [x] Formatting/lint, script classes/source mapping, docs links/fields pass.
- [x] Bounded exported shared module imports to scratch and preserves source (generated fixture; real Studio export pending).
- [x] Local source reaches Studio via Rojo build/reopen; real Studio source returns through explicit MCP capture.
- [x] Smoke Output observed on server and client.
- [ ] Live Rojo plugin propagation and disconnected/reconnected branch transition (not tested by MCP capture).
- [x] New agent can find purpose, verified state, ownership, and next task (independent review).
- [x] CI and GitHub settings inspected; unavailable checks remain explicit.
- [x] Task branch and evidence discoverable; merge/publish distinct.
- [x] Main initialized from seed and PR #2 opened after explicit user approval.
- [ ] PR integration (not authorized by the create-main/open-PR approval).

## Implementation evidence

Final implementation/cleanup SHA: `755ac2539fd913e664dd48fe97a91ea046ec3da0`.
Base implementation SHA: `f464e164ae43bb8016e101f6050d33aaec181923`. Docs integrated from isolated contributor
commit `a99f43ccdeaa44b798f859141e6fb95732ef6d31` as `1c3fa5e`.
Tool pins: Rojo/plugin 7.7.1, StyLua 2.6.0, Selene 0.32.0; Windows x64 archives
and official SHA256 digests in `tools.lock.json`.

## Checks

Environment: Windows x64; PowerShell 7.6.9 and Windows PowerShell 5.1;
Studio executable 0.746.0.7461269, matching Rojo plugin installed.

| Check | Result / evidence |
| --- | --- |
| `scripts/setup.ps1` | PASS; all three version outputs match pins |
| `scripts/build.ps1` | PASS; `build/dev.rbxlx` generated |
| StyLua `--check src` | PASS, exit 0 |
| Selene `src` | PASS, 0 errors/warnings/parse errors |
| `import-shared.ps1` generated Shared fixture | PASS; one changed Smoke.luau staged, authoritative src unchanged |
| Full `check.ps1` | PASS: formatting, lint, build, exact classes and source text, relative doc links, essential task/status fields |
| Fresh clone `setup.ps1` + `check.ps1` | PASS at `04bf35cba0a3a82cddc08d99abd1ade8f5658192`; clone stayed clean |
| PowerShell 5.1 check + scratch syncback | PASS; same pins; UTF-8 staging JSON works without BOM |
| `serve.ps1 -Port 34872` | PASS; endpoint `/api/rojo` responds; process stopped after check |
| MCP runtime and explicit source round trip | PASS; detailed probe evidence below |
| Live Rojo plugin sync / branch reconnect | NOT RUN; desktop automation stopped with Escape, no further desktop-control calls |
| Real Studio XML export; two simultaneous clients | NOT RUN; generated XML and server + one client tested |
| GitHub rulesets / protection | PASS inspection: empty rulesets, branch `protected: false`; enforcement NOT CONFIGURED |
| GitHub CI | PASS: [baseline run](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42423505387), [probe run](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42423951632), [pre-PR evidence run](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42424275218) at `ade0ab5b7d5160d73136fbb56f8e73e7633b98d4`; PR checks cover subsequent head updates |
| Main / PR | PASS: main initialized at seed and PR #2 confirmed OPEN on 2026-11-07 |
| Merge / publish | NOT RUN; no merge authorization or Roblox production identity selected |

Initial Rojo execution in the sandbox failed with OS error 5 (access denied).
The same pinned command passed with approved execution outside that sandbox.
This is an execution-environment limitation, not claimed as a passing first attempt.

### User-requested MCP expanding-ball demonstration

1. Started the installed Roblox MCP proxy and verified `list_roblox_studios`.
   The unrelated local `Place1` had no scripts and was left unchanged. Opened the
   generated `build/dev.rbxlx` via Studio's documented `--task EditFile` CLI.
2. Verified edit-mode service paths/classes and starter source through MCP.
   Created `ServerScriptService.Server.WorkflowProbe` in Studio through MCP;
   read its complete Source into scratch, checked its path/class, and promoted it
   to `src/server/WorkflowProbe.server.luau` with no source changes.
3. Played through MCP. Output contained `[Starter] server: shared module OK`,
   `[Starter] client: shared module OK`, `[WorkflowProbe] start diameter=2`,
   and `[WorkflowProbe] complete diameter=8.0`. Runtime assertions in both
   Server and Client confirmed size `8, 8, 8` and `ExpansionComplete=true`.
4. Stopped play, checked/built, committed and pushed probe
   [`9a9ee6b57678a551e593cc5df749fda126d6e70d`](https://github.com/Jayden-Amjed/Pop-a-Peg/commit/9a9ee6b57678a551e593cc5df749fda126d6e70d).
   GitHub fetch returned the exact captured file; CI passed. Probe source SHA256:
   `17bea4a74b6cc4c7fee153f0741155b641c5c5fb359383d933bf811d0cb64baf`.
5. Opened `build/probe-rebuilt.rbxlx`, verified exact source equality with the
   local captured file, replayed, and repeated server/client assertions and Output.
   Stopped play. This proves explicit Studio → file → GitHub → Rojo build → Studio
   transfer; it does not claim automatic live plugin sync.
6. Removed the probe from default source and original dev edit model; retained its
   exact source in the linked commit. Cleanup is `755ac2539fd913e664dd48fe97a91ea046ec3da0`.
   Neutral starter checks passed after cleanup.

Output also reported asset-type mismatch warnings for `rbxassetid://203785492`;
that ID is not referenced by the starter or probe. Their origin was not diagnosed.
The run is not claimed to have a completely clean Studio Output log.

## Handoff

Owner: Codex coordinator; next owner follows AGENTS startup order.
Studio targets: original `build/dev.rbxlx` (session `ee894903-4105-4304-bb24-4547ce546f45`, probe removed)
and temporary `build/probe-rebuilt.rbxlx` (session `aca94005-79f9-41ee-a19e-6eebb80ae743`, probe retained for inspection).
Both playtests stopped. No production identity selected. IDs are session evidence,
not durable selectors; relist Studio before acting.
Sync: no Rojo plugin connected; serve command stopped; endpoint was `127.0.0.1:34872`.
Completed: neutral starter, pinned setup/checks/CI, docs, clean clone, explicit MCP round trip.
Resolved blocker: automatic approval review initially denied direct main initialization.
The user explicitly approved creating main from the minimal seed and opening the PR;
both completed on 2026-11-07. That approval did not include merging the starter.
MCP: local `Roblox_Studio` configuration exists; chat tools were not loaded, but a
read-only stdio diagnostic proved the installed server works. User then authorized
the MCP workflow test. A temporary ignored client was used; no machine-specific
bridge or credentials are part of the starter. Prefer normal MCP tools in a fresh
client session. Do not resume desktop control without user direction.
Remote main reviewed: `9349530edb7eaf536ceabfed5e922ae5b65499a6`, README only,
confirmed ancestor of the task branch. No accepted status ledger exists, so candidate
State Version remains 1. The task branch is still the repository's temporary default.
Next action: review PR #2, check its current CI, and resolve pending validation;
merge only when authorized. Inspect/configure required `validate` CI protection via
an admin-capable route; the connector exposes reads but no settings mutation.
After authorized merge, confirm GitHub's merge result and set default branch main.
Pending live plugin/XML/two-client checks above must stay explicit.
