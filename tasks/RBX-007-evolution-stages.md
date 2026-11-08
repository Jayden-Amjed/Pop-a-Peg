# RBX-007 — Equipment evolutions and round stages

- Owner: Codex coordinator; evolution_ui, evolution_effects and evolution_board contributors.
- Status: MERGED
- Reservation / issue: [#7](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/7)
- Reviewed: 2026-11-07 (America/Los_Angeles)
- Starting main: fef03bb55a07b1cf4a5e0d68a6ac4635f9805acc
- Branch: task/RBX-007-evolution-stages
- PR: [#8](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/8)
- Implementation evidence SHA: 5047ee70100b7e2b154f795d024cf25726222584
- Confirmed merge SHA: e94fb7ec6146ab037b5da8c90bb4f66c1ac54571

## Objective and scope

Replace partner displays with modeled evolution equations. Equipment upgrades one
level at a time through five. Two level-five ingredients combine through a free
shop evolution into one unique device retaining both max-level abilities. It
consumes the two ingredients, frees one slot and has no further evolution panel.
Thirteen recipes cover all 22 base items, including alternate paths.

Keep four equipment offers and at most two Supplies. Hidden eligible evolutions
cycle through existing cards for free. Refresh and atomic validation handle
upgrades, sales, moves and stale expected IDs. Normal rolls favor practical
progress by ensuring an owned upgrade opportunity when possible.

Continuous levels require successful round clears at 15, 40, 65, 100, then every
50 rounds. Victory/endless moves to 100. Decorated board monitor has 235 parts.
All thirteen evolved devices have distinct models, animations and note motifs.
Dense native bursts, beams, impacts and ribbons retain bounded visual/audio work.

## Acceptance criteria

- [x] Full-rack upgrades through level five; Supply/event/duplicate rules agree.
- [x] Eligible evolutions validate atomically and remain accessible in four cards.
- [x] Modeled equations show readiness; evolved/perk/Supply cards omit recipes.
- [x] Both original max-level ability channels and fixed operation costs preserved.
- [x] Stage success/failure boundaries, bosses and round-100 endless transition.
- [x] Monitor decorations and item effects inspected in isolated Studio.
- [x] Final normal-source playtest, CI and main delivery receipt.

## Dependencies and overlapping paths

Contributors used isolated worktrees from accepted main. Coordinator owned rules,
integration, selection acknowledgment, mapping checks and Studio. UI contributor
owned Presentation, HoverInspector, EvolutionDisplay, ShopLayout and CounterProgress.
Effects contributor owned models, motion, feedback and signatures. Board contributor
owned Stages/BoardArt, evolution regression tests and maintained design docs.
Other worktrees and user Studio windows were preserved. No Rojo live sync or
publication was used.

## Implementation evidence

Current implementation: 5047ee70100b7e2b154f795d024cf25726222584.
Core rules initially recorded at 8d20a83a418df01f4a9a1d76ff08daa3f91e02b4;
extreme-number fixes at 1cc23355a0891af2070880c12486465bcea00677.
Final follow-up marks a just-cleared goal full before advancing to the next level.

Review caught two engine edge cases: level-five relay branching could require
1,582,031 activations, and a held offer could make the last hidden evolution
unreachable. A shared 4,096 item/perk activation budget now terminates such chains;
cyclic hidden-offer navigation covers every eligible alternative.

Studio found and corrected clipped compact recipe labels, a missing glyph font,
default-layer outlines covering colored models, and huge-number quota modulo
producing a negative remainder / invalid palette index. Boss quotas also stay at
or below the maximum score. These failures are retained here as resolved findings.

## Checks actually run

| Check | Result | Evidence / limitation |
| --- | --- | --- |
| Local scripts/check.ps1 | PASS | Final implementation: formatting, lint 0 warnings, thirteen suites, 21 mapping/source checks, build and doc links |
| Evolution/progression | PASS | 20 evolution cases plus 28 progression cases; every recipe, 26 individual channels and 13 combined activations |
| Studio shared suites | PASS | All thirteen on 1cc2335; same rule sources as final except completed-goal presentation |
| Shop layouts | PASS | Six sizes 390×844 through 1920×1080; 36 inspected offers, no clipping or escaping controls; 30 previews stayed mounted per case |
| Evolved inspection | PASS | 13 evolved items × six sizes = 78 tooltips; no recipe panels, no text/bounds failures |
| Actual mouse input | PASS | Full-rack Goldfish L4→L5, new Aquarium EVOLVE button, free atomic fusion, slot 2 freed, coins unchanged at 85 after evolution |
| Models/motion/FX | PASS | 260 variants, 13 evolved models, exact rest restoration; 184 decorative peak, 30 reward arrivals, cleanup; corrected silhouette visually captured |
| Board | PASS | 235 opaque, anchored, shadowless, noncolliding parts; unchanged projection anchors; four stage lights and ten settlement segments |
| Stress loadout | PASS | On 1cc2335: seven evolved items, score 5.46e107, 4,096 activations, peak 203 effects; completed settlement and advanced round 41→42 perk choice without project errors |
| Feedback races | PASS | Final normal modules: wallet race, receipt ordering/replay, score/coin/restock bounce, no reserve-icon launch and perk cues |
| Fresh normal-source play | PASS | Final source:167 seconds, round41,47 shots,8 shops,7 upgrades,4 Supplies,3 perks,5 purchases; no notices or project errors |
| CI / main receipt | PASS | Push 42458549807 and PR 42458553472 passed; PR #8 merged as e94fb7ec6146ab037b5da8c90bb4f66c1ac54571 |
| Roblox publication | NOT RUN | No production place selected |

Studio: isolated peg-aero-qa.rbxlx, id e848e7a7-b569-4600-b4e6-14ec13ecbaac.
Private QA fixtures and captures live in ignored scratch, not the playable build.
The known unrelated asset-type warning for 203785492 remains; no project source
references that ID. Captures can omit peg BillboardGui numbers.

## Limitations

Physical touch/gamepad, two-client isolation, cloud saves, real Rojo plugin round
trip and Roblox publication remain unrun. Dense FX is bounded, but device-specific
performance still needs human testing. Numerical equivalence and directed stress
tests do not establish long-run balance for every possible build.

## Handoff

- Owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/evolution.
- Branch / PR: task/RBX-007-evolution-stages / #8.
- Accepted State Version: 4.
- Source: 5047ee70100b7e2b154f795d024cf25726222584.
- Playable build: build/peg-evolutions.rbxlx, generated from normal sources.
- Studio: sole root operator; Rojo disconnected; stopped in Edit, all26 normal sources restored exactly.
- Published: NOT PUBLISHED.
- Next action: human playtest the generated build; reserve follow-up tuning or deployment verification separately.

Final goal-display verification on5047ee7: all four completed goals render progress1.
An immediate event observer initially read the previous frame before the normal
snapshot handler; explicit post-render checks resolved that QA timing race.
Final six-layout/36-hover rerun also passed; all26 normal sources restored and
Studio confirmed stopped in Edit. Generated dev.rbxlx and peg-evolutions.rbxlx match.

Acceptance receipt: PR #8 merged to main as e94fb7ec6146ab037b5da8c90bb4f66c1ac54571.
Push CI: https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42458549807
PR CI: https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42458553472
Fetched main contains the exact tested source, tests and check script from 5047ee7.
No Roblox publication was performed. This receipt advances State Version once to 4.
