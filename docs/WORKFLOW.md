# Development workflow

Use [AGENTS](../AGENTS.md) for the operating contract and
[PROJECT_STATUS](../PROJECT_STATUS.md) for current facts. A task record holds its
scope, evidence, and latest handoff; this document holds procedures.

## Start and reserve a task

From your own checkout, inspect before editing:

```powershell
git status --short --branch
git rev-parse HEAD
git remote -v
git fetch origin --prune
git log -1 origin/main
git show origin/main:PROJECT_STATUS.md
git branch -r
```

Inspect existing task files and GitHub's open issues/PRs too. Preserve unexplained
changes. Reserve an `RBX-###` ID through a coordinator or a GitHub issue number;
check for collisions with existing task records. Record an owner, scope, acceptance
criteria, and overlapping files. A local branch name does not reserve shared work.
Publish the reservation promptly through the authorized GitHub workflow.

Create an isolated checkout from accepted main (replace the example ID/path):

```powershell
git worktree add ..\Pop-a-Peg-RBX-002 -b task/RBX-002-short-description origin/main
Set-Location ..\Pop-a-Peg-RBX-002
Copy-Item .\tasks\TEMPLATE.md .\tasks\RBX-002-short-description.md
```

Fill the template, then commit that task record and push the branch. Open a draft
PR early so unmerged work is discoverable. Use one task/branch/PR where practical.
Independent agents get their own branches/worktrees; declare overlap dependencies
before implementing. Do not switch another session's checkout.

For a genuinely empty remote, `origin/main` and a PR base do not exist. Preserve
that fact in the bootstrap task, establish an explicitly authorized initial main
commit, then branch for the starter. Initial branch creation is not a PR merge.
If initialization is unavailable, finish local work and record the exact missing
connection without inventing accepted state.

## Build and check

Run from the task worktree:

```powershell
.\scripts\setup.ps1
.\scripts\check.ps1
.\scripts\build.ps1
```

The tool pins are Rojo **7.7.1**, StyLua **2.6.0**, and Selene **0.32.0**.
Setup is local to the checkout. Checks use these same tools locally and in CI.
Record command, environment, source SHA, exit/result, and limitations in the task.
Use `PASS`, `FAIL`, or `NOT RUN`; existing tests and prior logs are not new runs.
CI verifies its actual checkout only and does not prove Studio behavior.

## Studio sync and explicit return

Use the Rojo **7.7.1** Studio plugin with the pinned CLI. Install with
`& .\.tools\rojo.exe plugin install`, restart Studio, and verify the plugin version.
Open `build/dev.rbxlx`, emitted by `build.ps1`. Start
`.\scripts\serve.ps1 -Port 34872`, connect the plugin to `localhost:34872`, and
inspect the proposed changes. Bind one operator and worktree to this target.

**Forward direction:** local edits under the mapped `src/` directories reach Studio
while connected. The filesystem remains authoritative. Inspect Explorer to verify
`Script`, `LocalScript`, and `ModuleScript` types against the
[mapping table](SYSTEM_OVERVIEW.md#mapping-and-trust).

**Return direction:** this starter uses a deliberate, bounded XML export for the
shared-script subtree. It does not enable a second live script-sync system.

1. Stop playtesting. Disconnect Rojo before making the Studio-side source edit.
2. Edit a shared module under `ReplicatedStorage.Shared` in edit mode. Select the
   `Shared` folder and use **Save to File** to export XML as `scratch/Shared.rbxmx`
   (not the binary `.rbxm` format).
3. Run `.\scripts\import-shared.ps1 -InputModel .\scratch\Shared.rbxmx`.
   The helper copies current shared source into a new `scratch/import-<guid>/shared`,
   runs Rojo `syncback` preview and application against that disposable staging
   project, and prints the review command. It never writes into `src/` automatically.
4. Compare the staged module with `src/shared/Smoke.luau`; deliberately copy only
   the reviewed source change. Reject unexpected objects, paths, or content. Run
   checks and inspect `git diff` before reconnecting.
5. Reconnect to the same checkout, inspect incoming changes, and playtest again.

Only reviewed module `Source` may be promoted from this staging output.
Server/client scripts, models, arbitrary properties, terrain, and the entire place
are outside this workflow's scope.
For those, author the filesystem source or perform a separately reviewed explicit
asset export under the [ownership policy](SYSTEM_OVERVIEW.md#ownership-and-restoration).
The Studio file is staging, not a second authoritative copy. Keep intended Studio
edits before any reconnect; never use a broad “Keep Disk,” “Keep Studio,” or
syncback operation to resolve conflicts without inspection.

Verify this sequence in the task: local script edit appears in Studio; exported
module returns to the intended file; the branch transition below preserves work.
During Play, expected Output is `[Starter] server: shared module OK` and
`[Starter] client: shared module OK`, with no starter errors. Record actual output
and its server/client context rather than merely copying this expectation.
For multiplayer changes, run a local server with at least two clients and record
server/client observations. Builds alone do not establish any of these checks.

### Safe branch transition and recovery

Stop play → save/export and reconcile intended Studio edits → disconnect Rojo →
stop the serve process → inspect/preserve Git state → perform the Git operation →
run affected checks/build → restart the correct worktree's server → reconnect
deliberately and inspect incoming changes. Record place, port, branch, and operator.
Separate worktrees do not isolate a shared Studio/Team Create session.

If changes conflict, stop sync, preserve the Studio export and Git diff, identify
the authoritative owner for each changed path, and reconcile only the intended
changes. Rebuild into a separate generated file when unsure. Do not reset work or
overwrite a live place to make a conflict disappear. Missing assets require the
recorded source/access prerequisites, not guesses from a generated place.

Roblox's native **Script Sync** is an alternative for a Studio-first, code-only
project. It is not configured here. Adopting it is a separate migration decision:
disable Rojo ownership of the same subtree first and document restoration and
limitations; do not run competing synchronizers against it.

## Reconcile evidence and status

Before a material dashboard update, fetch and reread both main's status and the
branch copy. Record the main SHA examined. Compare **State Version and content**;
equal versions with divergent content still require reconciliation. Main's status
is accepted; branch changes are proposals. Preserve unresolved failures, blockers,
and unrun checks until evidence resolves them.

Advance exactly once from the accepted predecessor when that material update is
accepted through PR integration. Repeated candidate edits retain their proposed
version. If main advances, reconcile the proposal before acceptance. Version
numbers detect stale state; PR integration serializes acceptance and provides the
concurrency boundary. Update the task record with the same evidence.

Record exact already-existing implementation SHAs. A commit cannot contain its own
hash: commit implementation first, then record that evidence in a normal task/status
update. Distinguish evidence SHA from a later documentation-only branch tip. Keep
historical detail in the task; indexes and onboarding must link to the dashboard.

## Finalize, PR, and merge

Fetch again. If accepted main advanced, disconnect Studio first and merge it into
the published task branch; resolve conflicts deliberately and rerun affected checks.

```powershell
git fetch origin --prune
git merge origin/main
git status --short --branch
git diff --check
.\scripts\check.ps1
git push
```

Review the final diff for scope, generated outputs, and credentials. Complete the
[PR template](../.github/PULL_REQUEST_TEMPLATE.md), including task link, exact
validation, Studio checks, limitations, and status proposal. Task states are
`PLANNED → IN PROGRESS → READY FOR REVIEW → MERGED`, with `BLOCKED` and `CANCELLED`
when applicable. Address every acceptance criterion with evidence or an explicit
remaining check; do not silently turn `NOT RUN` into a pass.

Follow the user's authorization and the repository's actual review policy. Default
to merge commits, preserving task history. Do not bypass required review or invent
new approval gates. Confirm GitHub's actual merged state and merge SHA before
recording `MERGED`. Record the observed merge identity in the next normal update
or a bounded completion receipt; do not produce endless completion-only commits.
Written rules and workflow files do not prove branch protections are enabled;
the dashboard/task must record observed settings and remaining administration.

## Handoff and publishing

At each meaningful pause, fill the task's latest handoff: objective, completed work,
owner, absolute checkout, branch/PR, exact implementation evidence, executed checks,
blockers, proposed/accepted state, and next executable action. When Studio is involved,
include development target, operator, worktree, port, and whether sync/play are stopped.
A new agent follows the startup order and verifies live state before continuing.

Track **implemented → checked → Studio verified → merged → published** separately.
CI initially validates/builds; it does not publish Roblox. Production publication is
a separate user-authorized action. Its task records source identity, target experience
and place, observed published version, verification, and rollback reference. Store
credentials outside Git. If no version was observed, say `UNKNOWN`; if this starter
has never been published, say `NOT PUBLISHED`.

## Sources

- [Rojo documentation](https://rojo.space/docs/v7/) and
  [Rojo 7.7.1 release](https://github.com/rojo-rbx/rojo/releases/tag/v7.7.1).
- [Roblox Script Sync](https://create.roblox.com/docs/scripting/sync).
- [Reference workflow snapshot](https://github.com/HTr04/kenautics_mgps_integration/tree/d25563b5cc781fd20d0b34fd69bf915a0512e243):
  workflow inspiration only; no application code or historical project records copied.
