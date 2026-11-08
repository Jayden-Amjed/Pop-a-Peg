# RBX-013 — Arcade presentation and interaction polish

- Owner: Codex coordinator; world/UI contributors and read-only audit.
- Status: IN PROGRESS
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: 3f54f7a1b04c813831a1d6d1394bead5d7e24d62
- Branch: task/RBX-013-arcade-polish
- Reservation: [#13](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/13)
- PR: pending
- Implementation evidence SHA: pending
- Confirmed merge SHA: NOT MERGED

## Objective and acceptance

Polish the existing eight-player arcade and its run transitions after a visual and
interaction audit. Preserve balance, independent runs and earned records. No payments
or Roblox publication. Existing verified main-delivery authorization continues.

- [ ] Better architectural depth, readable signs and station wayfinding.
- [ ] Clear hub controls, collection/records hierarchy and responsive interaction feedback.
- [ ] Address concrete transition/input issues identified by audit and playtest.
- [ ] Full checks, isolated Studio playtest, updated docs and verified main delivery.

## Ownership

Root: Main client/server, integration, tests/docs, sole Studio operator.
World contributor: HubWorld, optional HubAmbience only after coordination.
UI contributor: HubPresentation, HubLayout and their layout tests.
Audit contributor: read-only; report reproducible lifecycle/performance issues.
All implementation contributors use separate worktrees based on accepted main.

## Checks actually run

- PASS: clean accepted checkout; fetched main 3f54f7a; no open issues/PRs before reservation.
- NOT RUN: new implementation checks and runtime playtest.
- Studio discovery currently lists no sessions; launch a separate generated QA place.

## Handoff

- Owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/arcade-polish.
- Accepted State Version: 6; proposed version: 7.
- Studio: no connected target yet; no Rojo session; root sole operator.
- Published: NOT PUBLISHED.
- Next action: audit the current arcade, publish reservation and start bounded polish in isolated worktrees.
