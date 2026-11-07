# RBX-001 — Reusable Roblox starter

Owner: Codex bootstrap coordinator; documentation contributor in isolated worktree.
Status: IN PROGRESS
Objective: Provide the requested neutral starter and small, durable collaboration workflow.
Scope: source mapping, smoke scripts, pinned tools, build/sync helpers, CI, docs, evidence.
Non-goals: gameplay framework, game design, production publishing, full-place round trip.
Starting main: NONE (empty remote inspected 2026-11-07); local seed `9349530edb7eaf536ceabfed5e922ae5b65499a6`.
Branch: `task/RBX-001-bootstrap`
Worktree: `C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg`
PR: NOT CREATED — main is absent.
Reservation: [GitHub issue #1](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/1).
Dependencies: explicit main initialization approval; installed Studio; GitHub checks after push.
Overlapping paths: repository-wide bootstrap. Docs contributor owns README, AGENTS, overview/workflow, task/PR templates in `.worktrees/workflow`; coordinator owns implementation and current evidence.

## Acceptance

- [ ] Fresh checkout installs pinned tools and builds.
- [x] Formatting/lint, script classes/source mapping, docs links/fields pass.
- [x] Bounded exported shared module imports to scratch and preserves source (generated fixture; real Studio export pending).
- [ ] Local source edit reaches Studio; real Studio edit returns to intended file.
- [ ] Smoke Output and disconnected branch transition observed.
- [x] New agent can find purpose, verified state, ownership, and next task (independent review).
- [ ] CI and GitHub settings inspected; unavailable checks remain explicit.
- [ ] Task branch/PR, evidence and latest handoff are discoverable; merge/publish distinct.

## Implementation evidence

Source SHA: `f464e164ae43bb8016e101f6050d33aaec181923`. Docs integrated from isolated contributor
commit `a99f43ccdeaa44b798f859141e6fb95732ef6d31` as `1c3fa5e`.
Tool pins: Rojo/plugin 7.7.1, StyLua 2.6.0, Selene 0.32.0; Windows x64 archives
and official SHA256 digests in `tools.lock.json`.

## Checks

Environment: Windows x64; PowerShell 7.6.9; Studio executable 0.746.0.7461269.

| Check | Result / evidence |
| --- | --- |
| `scripts/setup.ps1` | PASS; all three version outputs match pins |
| `scripts/build.ps1` | PASS; `build/dev.rbxlx` generated |
| StyLua `--check src` | PASS, exit 0 |
| Selene `src` | PASS, 0 errors/warnings/parse errors |
| `import-shared.ps1` generated Shared fixture | PASS; one changed Smoke.luau staged, authoritative src unchanged |
| Full `check.ps1` | PASS: formatting, lint, build, exact classes and source text, relative doc links, essential task/status fields |
| Fresh clone install/build | NOT RUN yet |
| Live Studio checks / multiplayer | NOT RUN; user stopped desktop automation with Escape; no further UI actions taken; no multiplayer behavior changes |
| GitHub rulesets | PASS inspection: empty list; enforcement NOT CONFIGURED |
| GitHub CI / PR / merge | NOT RUN; no main exists |

Initial Rojo execution in the sandbox failed with OS error 5 (access denied).
The same pinned command passed with approved execution outside that sandbox.
This is an execution-environment limitation, not claimed as a passing first attempt.

## Handoff

Owner: Codex coordinator, completing file-based verification.
Studio target: local `build/dev.rbxlx`; no production identity selected.
Sync: not connected; intended endpoint `127.0.0.1:34872` from this worktree.
Completed: neutral sources/mapping, pinned setup, build/import helpers, consolidated docs, automated checks.
Blocker: automatic approval review denied direct main initialization; do not bypass it.
Studio verification limitation: local MCP config has `Roblox_Studio` using Roblox's
`mcp.bat` / `StudioMCP.exe`, but this chat exposes no Roblox tools. Configuration
is not evidence of a working connection. Do not resume desktop control after the
user stopped it; use an available, verified Studio MCP connection for follow-up.
Next action: verify clean clone install/build, publish task branch and inspect CI,
then request approval for the specific initial main/PR setup.
