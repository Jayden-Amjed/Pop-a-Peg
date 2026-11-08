# RBX-007 — Equipment evolutions and round stages

- Owner: Codex coordinator (rules/integration/Studio), evolution_ui (UI), evolution_effects (models/feedback), evolution_board (stage definitions/board art).
- Status: IN PROGRESS
- Reservation / issue: [#7](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/7)
- Reviewed: 2026-11-07 (America/Los_Angeles)
- Starting main: `fef03bb55a07b1cf4a5e0d68a6ac4635f9805acc`
- Branch: task/RBX-007-evolution-stages
- PR: NOT OPENED
- Implementation evidence SHA: pending
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Replace suggested partner displays with modeled evolution equations. Base equipment
levels increase one at a time through five. Two matching level-five ingredients
can combine through an eligible shop offer into one evolved item retaining both
max-level abilities. Evolution consumes the two ingredients and frees one slot;
the evolution itself has no extra coin charge or additional evolution recipe.
Keep four equipment offers and at most two Supplies. Add continuous round-goal
stages, improve the attached monitor, and increase activation spectacle with
bounded visual resources.

## Acceptance criteria

- [ ] Upgrades work at full capacity through level five; all upgrade sources agree.
- [ ] Eligible evolutions appear and validate atomically, including stale offers.
- [ ] All base items have modeled recipes; evolved cards omit recipe sections.
- [ ] Evolved items preserve both ingredients' max-level operations and triggers.
- [ ] Round goals, stage completion and campaign/endless transition are coherent.
- [ ] Board monitor decorations and item feedback are visible in Studio.
- [ ] Full local checks, isolated Studio tests/play, documentation and main delivery.

## Dependencies and overlapping paths

All contributor worktrees start at accepted main. Coordinator owns Catalog, Run,
rule tests, mapping checks and integration docs. UI contributor owns Presentation,
HoverInspector, EvolutionDisplay, ShopLayout and layout tests. Effects contributor
owns ItemModels, ItemMotion, Feedback, ItemFeedback and associated tests. Board
contributor owns BoardArt, Stages and stage tests. Root is the sole Studio operator.
Other worktrees and user Studio windows remain untouched.

## Implementation evidence

Pending implementation. Accepted predecessor has ten passing suites; that is not
evidence for this revision.

## Checks actually run

| Check | Result | Evidence / limitation |
| --- | --- | --- |
| Reservation / current Git | PASS | Clean predecessor, fetched main, no open issues/PRs before reservation |
| Local checks | NOT RUN | New revision pending |
| Studio checks | NOT RUN | Reverify isolated target before changes |
| Main acceptance | NOT MERGED | Existing user authorization applies after verification |

## Handoff

- Owner: Codex coordinator.
- Checkout: `.worktrees/evolution`; contributor checkouts have `evolution-` suffixes.
- Accepted State Version: 3; proposed State Version: 4.
- Studio: planned isolated peg-aero-qa session; root owns operations; Rojo disconnected.
- Published: NOT PUBLISHED; no production experience selected.
- Next action: implement rules and parallel presentation, then integrate and verify.
