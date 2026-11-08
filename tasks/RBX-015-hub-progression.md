# RBX-015 — Hub progression, leaderboards and mobile polish

- Owner: Codex coordinator with backend, content and model contributors.
- Status: IN PROGRESS
- Starting main: 9d516120dc4c925061c444f713fb3b40719e1688
- Branch: task/RBX-015-hub-progression
- PR: pending
- Reservation: [#15](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/15)
- Reviewed: 2026-11-08 (America/Los_Angeles)

## Objective and Acceptance

Full active goal: hub leaderboards for most time played, highest Endless round and
experience Robux spent; earned tiered run chests opened in the hub; tiered equipment
unlocks that gate future shop rolls; substantially more items; unique item/perk
models and broader figure-eight idle animation; another polish pass with clean mobile UI.

- [ ] Three readable hub leaderboard displays plus responsive leaderboard panel.
- [ ] Durable tiered chest rewards and opening/research loop with failure/replay safety.
- [ ] Unlock-only shop pool, migration and 18 new equipment definitions/effects.
- [ ] Distinct models for all new items/chests and all perks; animated choice previews.
- [ ] Mobile portrait/landscape shop, choice, hub and progression UI inspected and fixed.
- [ ] Local rules/persistence/layout checks, isolated Studio runtime and multiplayer.
- [ ] Updated docs, verified main integration and accurate publication status.

No purchase prompts/products or paid chests. Robux leaderboard means this experience,
not account-wide spending. No purchase history exists yet; show an honest empty state.
No production publication authorized.

## Ownership / interfaces

Root owns HubWorld, HubPresentation/HubLayout, Main.client, Presentation and layout/
inspector polish; integration, docs and sole Studio operation.
Backend contributor owns Profile/ProfileStore/ArcadeSessions/Main.server plus chest
and leaderboard modules/tests. Content contributor owns Catalog/Run/ItemFeedback and
content/rule tests. Models contributor owns ItemModels/ItemMotion and model tests.
All contributors use separate worktrees based on accepted main.

Profile v2: itemUnlocks separate from legacy unlocks; chest counts per common,
uncommon, rare, legendary; research, playSeconds, bestEndlessRound, robuxSpent.
Starter equipment: tap_driver, split_prism, wall_meter, landing_fund, survey_lens,
resonator, compass, seed_bank. Existing discoveries migrate into ownership.
New runs freeze their unlocked pool; opening chests affects the next new run.

Hub snapshot: chests={tiers=[{id,name,count,remaining,total,researchValue}],research,
unlocks=[{id,tier,owned,cost}],lastOpened={serial,tier,itemId?,research?,allCollected?}}.
Actions: openChest {tier,requestId}; researchItem {id,requestId}.
leaderboards={mode,updatedAt,categories={time={entries},endless={entries},robux={entries}}};
each entry {userId,name,value}. Studio uses explicit session boards.

## Checks / evidence

- PASS: main fetched at 9d516120dc4c925061c444f713fb3b40719e1688, clean accepted
  worktree, no open issues/PRs before reservation; root starter checkout preserved.
- PASS: previous isolated peg-polish-qa Studio target is connected and in Edit.
- NOT RUN: new implementation checks and runtime validation.
- Accepted State Version: 7. Proposed next material state: 8.

## Handoff

- Owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/progression-hub.
- Studio: root sole operator; previous isolated target 47b8ff46-9f49-43de-9f9e-8fb2198ecb09
  stopped in Edit, Rojo disconnected. New generated target will be selected explicitly.
- Blockers: none; implementation underway across isolated contributors.
- Published: NOT PUBLISHED.
- Next action: implement mobile-aware hub chest/leaderboard UI and physical displays;
  integrate contributor contracts and validate full goal.
