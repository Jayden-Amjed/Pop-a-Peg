# RBX-023 — Expressive individual trigger animations

- Owner: Codex coordinator; sole Studio operator.
- Status: IN PROGRESS
- Reservation: [23](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/23)
- Reviewed: 2026-11-08
- Starting main: 83a1a611df86f2737179ab9ed54e7ac0f53b9f6b; accepted State Version 11.
- Branch: task/RBX-023-expressive-motion
- PR: [24](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/24)
- Implementation evidence: pending

## Acceptance

The approved models need stronger, distinct trigger performances across all 78
IDs: anticipation, impact, whole-model bounce/growth, suitable completed spins,
articulated follow-through and smooth return to the existing figure-eight idle.
Preserve geometry, imported asset identity, palette and gameplay rules.

- [ ] Unique purposeful choreography for every catalog model, including evolutions.
- [ ] Shared native/Blender behavior, exact restoration and smooth endpoints.
- [ ] Camera bounds, repeated triggers, normal/reduced motion checked.
- [ ] All-model Studio audit plus representative visual playback and game smoke.
- [ ] Animation guide, evidence, status and review branch updated.

## Ownership

Root owns ItemMotion, choreography integration/curves, adapters, viewport fitting,
tests, project mappings, docs, Studio and GitHub. Separate mechanical/nature/reward
contributors own only their respective new src/client/motion/* module and a
matching choreography description. All start from accepted main; root integrates
their commits. Existing checkouts and user-open galleries remain untouched.

## Checks actually run

Accepted main, clean checkouts, remote branches and reservations inspected.
No open PR overlaps. Issue19 is a stale reservation for already-merged pilots.
Implementation checks: formatting, lint, 23 suites and catalog adapter contracts pass. All three builds and 39 source mappings pass. Documentation field validation exposed a missing capitalized Acceptance heading, now corrected. Studio runtime checks: NOT RUN.

## Handoff

Root owns .worktrees/motion-life. All prior sync connections remain disconnected.
A new isolated Studio place will be built for this task; user-open gallery copies
are preserved. Next action: integrate unique motion families, exercise contracts,
then verify the actual animations and framing in Studio. No experience publication.
