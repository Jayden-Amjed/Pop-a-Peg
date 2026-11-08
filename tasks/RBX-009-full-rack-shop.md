# RBX-009 — Full-rack shop guarantees

- Owner: Codex coordinator; full_rack_tests for independent regressions.
- Status: COMPLETE; MERGED
- Reservation / issue: [#9](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/9)
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: 35eb7e3468de31cfc14f565a657f153b6f123741
- Branch: task/RBX-009-full-rack-shop
- PR: [#10](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/10)
- Implementation evidence SHA: a34b8e57c1a0648294de72d07a42496d37f75daa
- Confirmed merge SHA: a896e56a91041d6f8aaea9c7cefa19439a0897b5

## Objective and scope

Full-rack shop openings and rerolls reserve two equipment offers for valid owned
upgrades, with the remaining offers rolled normally. Prefer distinct items; reuse
one ID only when two upgrade levels remain. If fewer than two useful upgrades
remain, reserve only those that exist. Keep held offers, surplus prices, Supplies,
and evolution access without replacing guaranteed upgrade cards.

The same request asks for lobby and monetization ideas. These are recommendations,
not implementation of a hub, products, purchases, or persistent power.

## Acceptance criteria

- [x] Full racks at every capacity receive two useful upgrade offers when possible.
- [x] Random offers, holds, prices, rerolls, evolution cycling and Supply limits remain coherent.
- [x] Purchases do not replenish sold guaranteed offers or bypass the level cap.
- [x] Focused regressions, complete checks and isolated Studio purchase checks pass.
- [x] Maintained docs and verified main delivery record the actual implementation.

## Dependencies and overlapping paths

Root owns Run, integration and docs. Test contributor owns ShopRolls.spec only in
an isolated worktree. Read-only research agents propose lobby/monetization options.
Root is sole operator of isolated peg-aero-qa Studio; user sessions untouched.

## Checks actually run

| Check | Result | Evidence |
| --- | --- | --- |
| Main/reservations | PASS | Clean accepted predecessor, fetched main, no open tasks/PRs |
| Local rules/build | PASS | Fourteen suites; 13 shop contracts including 800 seeded rolls at capacities 4–7; formatter, linter, build, 21 exact mappings and docs checks |
| Independent review | PASS | Read-only review found no actionable regressions; separately authored test-only commit e2b334a74c636ab7ed14e4c7adbfb84ae5682881 integrated as 661cb3f |
| Studio suites | PASS | All fourteen suites in Client runtime; 13 shop contracts also in Server runtime |
| Studio UI | PASS | Native clicks purchased Wave Spring L4→5 and Tap Driver L1→2 in a full seven-slot rack, 90→81 coins; sold cards remained sold; two-upgrade reroll, scarce and capped cases verified |
| Production smoke | PASS | All 26 normal sources restored exactly; actual remote launch entered flight with 34 snapshots, no notices or project errors |
| CI | PASS | Push 42460978053 and PR 42460982630 at 78246be728692fd57fc2eb0a245a5a21b24d7487 |
| Main | MERGED | PR #10 returned a896e56a91041d6f8aaea9c7cefa19439a0897b5; fetched main confirms; issue #9 closed |

## Implementation notes and limits

- Reserved cards carry `guaranteedUpgrade`; evolution refresh never replaces them,
  even after purchase. Other cards retain normal random rolls or ready evolutions.
- Distinct eligible IDs are preferred. A repeated ID needs enough remaining levels
  across owned copies for both purchases. At one or zero remaining levels, only
  useful upgrades are reserved. Eligibility does not promise affordability.
- Held upgrades move to position 1; other held cards move out of reserved positions.
  Prices, hold state and the stored held index are retained. Surplus discounts apply.
- Capacity changes do not reroll an existing shop. Partial racks keep the previous
  single-upgrade opportunity. Supplies remain capped at two from round 11.
- Ignored QA artifacts: root scratch/full-rack-{ui-assert,engine-suite,server-result,
  production-result,production-console}.json. The temporary UI fixture was removed.
- The existing unrelated 203785492 asset-type warning remains; no new project errors.
- Hub recommendation: compact aquarium arcade, independent run pods, earned
  evolution collection and cosmetic previews; same-place sessions first.
- Monetization recommendation: transparent permanent cosmetic packs first; keep
  run coins, slots, upgrades and evolution power earned through play. Pricing is a
  proposal to test. No product IDs, purchase flows or hub systems were added.
- Multiplayer capacity, cloud saving, touch/gamepad and live payments were not tested.

## Handoff

- Owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/full-rack.
- Accepted State Version: 5, advanced once from version 4.
- Studio target: isolated peg-aero-qa; root only, Rojo disconnected.
- Published: NOT PUBLISHED.
- Playable output: build/peg-full-rack.rbxlx in this checkout.
- Next action: human playtest the new build; hub and monetization proposals await a separate implementation scope.
