# RBX-005 — Modeled synergies and board presentation

Owner: Codex coordinator; isolated UI, model and board contributors.
Status: VERIFIED — final CI and integration pending
Objective: Make upgrades readable at a glance, show modeled synergy ownership, and give the board a cohesive aquatic presentation.
Starting main: `60b579aa2fba2b2ca4d3bdf0e421f8db6ed51fa2`.
Branch: `task/RBX-005-synergy-presentation`
PR: [#6](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/6), draft against main.
Reservation: [issue #5](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/5).

## Scope and ownership

Coordinator owns structured catalog details, tests, integration, documentation and Studio.
Isolated gallery-ui owns Presentation, UiTheme, ShopLayout and hover UI.
Isolated gallery-models owns ItemModels and ItemMotion.
Isolated gallery-board owns the new BoardArt module; UI contributor integrates its hooks.
All use the accepted main above. No gameplay/economy changes or production publication.

## Acceptance

- [x] Idle figure-eight is twice as fast and activation/resume remains smooth.
- [x] Shop shows modeled synergy partners with OWNED/NEED labels.
- [x] Structured hover/focus/tap inspection uses trigger/gain/cost colors without tradeoff paragraphs.
- [x] Reclaimed detail-bar space enlarges models and text; supply wording is concise.
- [x] Rack expands in play and contracts for shops; all choice screens share white accents and readable models.
- [x] Connected board monitor presents settlement stages without covering the board.
- [x] Non-perk display circles are removed; outer silhouette rendering is tested in Studio.
- [x] Score/restock panels stay pearl white after earning rewards; bounce and layered meter remain.
- [ ] Final ordinary play, CI and main integration receipt recorded.

## Checks

Implementation: de334ecdb6f393bb904a6de6698769b44fb0dacb. Prior evidence remains in RBX-003.

- PASS pinned check.ps1: format, Selene zero errors/warnings, ten contract suites,
  28 progression cases, Rojo build, 18 exact source mappings, documentation links/fields.
- PASS all ten suites inside Studio against the normal modules. Existing receipt,
  stale-wallet, counter pulse, perk cue and no-launch-icon feedback regression passes.
- PASS 36 shop inspections, six rack/HUD layouts and 24 perk/event/result/victory
  screens at 390x844, 844x390, 1046x524, 1280x720, 1280x850 and 1920x1080.
  Text fits; hover panels remain on screen; shop and perk/event choices need no scrolling.
  Both choice buttons are inside the visible body. Fixtures are not physical devices.
- PASS actual mouse hover: tooltip opens with zero clicks. Ordered Gain Dial benefit
  and cost colors are correct, with level-up amounts and three modeled pair boxes.
- PASS actual full-rack Seed Bank upgrade: 33 to 28 coins, L1 to L2. All 30 shop
  previews survive selection/purchase. Ownership changes immediately after inventory
  changes. Reroll charges one coin, preserves the same viewport objects, and refreshes
  an already-open tooltip from Seed Bank to Reef Chime.
- PASS score/restock BackgroundColor3 stays exactly RGB 250,254,255 before and after
  quotas/rewards, including pulses. Previous quota-earned aqua tint was removed.
- PASS all 39 idle models: 4.2-second closed loop, bounded facing, rapid retriggers,
  smooth resume, prism direction, Reduced Motion opt-out and cleanup.
- PASS visible 20-preview silhouette comparison and ten masks: geometry/mesh types,
  Scale/Offset and animated CFrames match; visibility follows primary viewports;
  destroying a primary removes its mask. Perk pedestals remain; equipment/supply/coin
  display circles are removed. Tiny pair previews intentionally omit the mask.
- PASS BoardArt: 166 anchored noninteractive parts, clear peg lanes, five status
  mappings, progress segments and cleanup. Attached monitor and compact fallback
  were visually checked; it no longer covers the board center.
- PASS all 23 production sources restored exactly. Ordinary server/client play ran
  120 seconds across three runs, reached round 20, and observed five shops and one
  perk choice without rejected actions or project errors. The driver attempted
  42 launches; it did not mutate run state or force shot endings. Restarts waited
  for the visible terminal menu and completed settlement. This is functional
  smoke coverage, not a human win-rate or balance claim.

Resolved during QA: initial tiny camera viewport caused a monitor clamp error;
layout now waits for a usable viewport and bounds projection. Short choice subtitles
and hidden action buttons were fixed. A private fixture supplied three perk offers;
it was corrected to the server's actual two-offer contract before final layout checks.
First captures may show unrendered viewport mounts; subsequent real frames show them.
MCP captures omit peg BillboardGui text; the user previously confirmed actual numbers.
Unrelated asset-type warning 203785492 remains. No project errors remain after startup fix.
NOT RUN: physical touch/gamepad, two clients, published persistence, live Rojo propagation,
Roblox publication. UI/code review does not establish human balance or audio approval.

## Handoff

Owner: coordinator.
Checkout: `C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\gallery`.
Main/status: accepted State Version 2 at starting main; proposed revision uses Version 3.
Source: de334ecdb6f393bb904a6de6698769b44fb0dacb; later evidence commits do not change gameplay source.
Studio target: isolated peg-aero-qa.rbxlx stopped in Edit with all normal sources;
Rojo disconnected; existing user-owned peg-polished.rbxlx untouched.
Published: NOT PUBLISHED.
Next action: verify final CI and integrate; record observed merge receipt.
