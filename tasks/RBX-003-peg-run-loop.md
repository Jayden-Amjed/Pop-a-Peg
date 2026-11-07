# RBX-003 — Peg-bounce roguelike run loop

Owner: Codex gameplay coordinator; isolated module contributors.
Status: IN PROGRESS
Objective: Build a complete aimed peg-bounce run with escalating score targets and synergistic upgrades.
Starting main: `9349530edb7eaf536ceabfed5e922ae5b65499a6` (README seed).
Dependency base: starter PR #2 at `608c273d9f31022d2f161584c4c92188bb4405cd`; unmerged.
Branch: `task/RBX-003-peg-run-loop`
Worktree: `C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\game`
PR: [#4](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/4), draft; targets the starter branch until PR #2 is integrated.
Reservation: [issue #3](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/3).

## Scope and ownership

Fixed front-view 3D board; independent per-player runs; numbered pegs, aiming,
bouncing, pop/merge/refill scoring, round quotas, currency, shops, perks, run loss
and restart. Only records and unlocks carry between runs; power resets.
No production publication, monetization, or shared cooperative board in this task.
Coordinator owns server/session integration, project mapping, docs, task/status,
verification, and Studio. Contributors own declared shared simulation/progression
and client presentation modules in separate worktrees.

## Acceptance

- [ ] Aim and launch a visible ball; reliable collisions visibly pop numbered pegs.
- [ ] Peg values, merges, replenishment, quotas, and bonus counters form a complete loop.
- [ ] Currency purchases, random upgrades/perks, item ordering and upgrades affect play.
- [ ] Loss, restart, round transitions, and long-run progression are playable.
- [ ] Fixed camera, 3D board, readable counters, feedback, and responsive controls.
- [ ] Server validates actions and isolates each player's run.
- [ ] Records/unlocks survive run resets; persistent-store availability is explicit.
- [ ] Meaningful simulation/progression tests and Studio MCP playtests recorded.
- [ ] Review scope, evidence, and next useful task remain discoverable.

## Checks

Implementation: NOT RUN; task reserved and baseline inspected.
Studio: NOT RUN for gameplay. Starter evidence is in RBX-001.
Publishing: NOT PUBLISHED.

## Handoff

Owner: coordinator, active implementation.
Completed: scope selected, dependency verified, isolated worktree created.
Studio: no gameplay session selected; only coordinator may mutate its eventual target.
Blockers: starter PR #2 unmerged; use a dependent branch, do not assume accepted main contains it.
Next action: implement and verify the complete numerical board/run model and presentation.
