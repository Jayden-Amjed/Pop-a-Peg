# Agent operating contract

Read in order: **this file → [README / purpose](README.md) →
[system overview](docs/SYSTEM_OVERVIEW.md) → [current status](PROJECT_STATUS.md) →
assigned task**. Then read only relevant code and supporting material.

For model or art work, follow [MODEL_STYLE_GUIDE](docs/MODEL_STYLE_GUIDE.md) and
the relevant [modeling workflow](docs/MODELING_WORKFLOW.md). Verify actual rendered
geometry and motion; generated output or a successful audit alone is not visual acceptance.

User direction from RBX-027: freeze native item geometry and native animation.
Continue model, motion and effect work in Blender/catalog-specific modules.
RBX-029 explicitly authorizes adopting these models, motion, effects and sound
through new game adapters and call-site/mapping changes. Keep original native
builders and choreography unchanged. Native comparison remains a preserved
reference, not a second modeling target.

Human instructions determine authorization and scope. Resolve disagreements by
preferring actual implementation and reproducible behavior, then executed checks,
current status, task evidence, overview, other documentation, and chat/memory.
Report discrepancies instead of silently replacing observed facts with prose.

Before work, inspect the actual checkout, dirty files, branch, HEAD, fetched
`origin/main`, task reservations, remote branches, and open PRs. Preserve unrelated
or unexplained changes. Keep edits within the active task; never reset away work,
force-push published history, or switch another session's checkout.

Use a reserved `RBX-###` task, matching `task/RBX-###-short-description` branch and
PR where practical. Publish ownership promptly; a local branch is not a lock.
Independent agents use separate worktrees/checkouts based on accepted main.
Declare overlapping paths and dependencies before parallel implementation.

One operator owns sync for a target place/subtree. Worktrees do not isolate Studio
or Team Create. Before Git operations in a synced checkout: stop play, preserve
and reconcile intended Studio edits, disconnect, inspect Git, change Git state,
then deliberately reconnect to the correct checkout. Never use blanket conflict
choices as unexamined resolution.

Prefer Roblox Studio MCP for inspection, bounded edits, and runtime checks when
available. Select and verify the development session before mutations. MCP does
not replace Rojo mappings or Git; capture Studio-authored source explicitly as
described in the workflow, then review and commit it.

Follow [WORKFLOW](docs/WORKFLOW.md) for commands, reservations, status reconciliation,
validation, and publishing. Fetch again before finalizing and merge updated main
into published task branches. Reconcile both status content and State Version.
Main is accepted state; a branch ledger is a proposal. Preserve unresolved failures
and unrun checks. Advance once from the accepted predecessor at acceptance.

Record checks actually run and exact existing source SHAs. CI/build success is not
Studio runtime evidence. Implementation, checks, Studio verification, merge, and
publication are separate facts. Confirm GitHub's merge result before `MERGED`;
never infer Roblox publication from a merge or playtest.

At every meaningful pause, update the task's latest handoff: owner, objective,
branch/PR, evidence, checks, blockers, Studio target/sync state, and next executable
action. Keep [PROJECT_STATUS](PROJECT_STATUS.md) the only current dashboard;
historical detail belongs in task records. Do not invent extra approval gates.
