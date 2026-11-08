# RBX-009 — Full-rack shop guarantees

- Owner: Codex coordinator; full_rack_tests for independent regressions.
- Status: IN PROGRESS
- Reservation / issue: [#9](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/9)
- Reviewed: 2026-11-07 (America/Los_Angeles)
- Starting main: 35eb7e3468de31cfc14f565a657f153b6f123741
- Branch: task/RBX-009-full-rack-shop
- PR: NOT OPENED
- Implementation evidence SHA: pending
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Full-rack shop openings and rerolls reserve two equipment offers for valid owned
upgrades, with the remaining offers rolled normally. Prefer distinct items; reuse
one ID only when two upgrade levels remain. If fewer than two useful upgrades
remain, reserve only those that exist. Keep held offers, surplus prices, Supplies,
and evolution access without replacing guaranteed upgrade cards.

The same request asks for lobby and monetization ideas. These are recommendations,
not implementation of a hub, products, purchases, or persistent power.

## Acceptance criteria

- [ ] Full racks at every capacity receive two useful upgrade offers when possible.
- [ ] Random offers, holds, prices, rerolls, evolution cycling and Supply limits remain coherent.
- [ ] Purchases do not replenish sold guaranteed offers or bypass the level cap.
- [ ] Focused regressions, complete checks and isolated Studio purchase checks pass.
- [ ] Maintained docs and verified main delivery record the actual implementation.

## Dependencies and overlapping paths

Root owns Run, integration and docs. Test contributor owns ShopRolls.spec only in
an isolated worktree. Read-only research agents propose lobby/monetization options.
Root is sole operator of isolated peg-aero-qa Studio; user sessions untouched.

## Checks actually run

| Check | Result | Evidence |
| --- | --- | --- |
| Main/reservations | PASS | Clean accepted predecessor, fetched main, no open tasks/PRs |
| Local rules/build | NOT RUN | Implementation pending |
| Studio | NOT RUN | Reconfirm isolated target before edits |
| Main | NOT MERGED | Existing user delivery authorization applies |

## Handoff

- Owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/full-rack.
- Accepted State Version: 4; proposed version: 5.
- Studio target: isolated peg-aero-qa; root only, Rojo disconnected.
- Published: NOT PUBLISHED.
- Next action: implement reserved upgrade rolls and focused tests, then verify.
