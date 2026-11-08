# RBX-005 — Modeled synergies and board presentation

Owner: Codex coordinator; isolated UI, model and board contributors.
Status: IN PROGRESS
Objective: Make upgrades readable at a glance, show modeled synergy ownership, and give the board a cohesive aquatic presentation.
Starting main: `60b579aa2fba2b2ca4d3bdf0e421f8db6ed51fa2`.
Branch: `task/RBX-005-synergy-presentation`
PR: pending draft
Reservation: [issue #5](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/5).

## Scope and ownership

Coordinator owns structured catalog details, tests, integration, documentation and Studio.
Isolated gallery-ui owns Presentation, UiTheme, ShopLayout and hover UI.
Isolated gallery-models owns ItemModels and ItemMotion.
Isolated gallery-board owns the new BoardArt module; UI contributor integrates its hooks.
All use the accepted main above. No gameplay/economy changes or production publication.

## Acceptance

- [ ] Idle figure-eight is twice as fast and activation/resume remains smooth.
- [ ] Shop shows modeled synergy partners with OWNED/NEED labels.
- [ ] Structured hover/focus/tap inspection uses trigger/gain/cost colors without tradeoff paragraphs.
- [ ] Reclaimed detail-bar space enlarges models and text; supply wording is concise.
- [ ] Rack expands in play and contracts for shops; all choice screens share white accents and readable models.
- [ ] Connected board monitor presents settlement stages without covering the board.
- [ ] Non-perk display circles are removed; outer silhouette rendering is tested in Studio.
- [ ] Checks, responsive layouts, model lifecycle and normal play verified.

## Checks

NOT RUN for this revision. Previous evidence is in RBX-003 and remains historical.
MCP server is connected; selected QA session will be relisted and checked before mutation.
No live Rojo sync; coordinator is the only Studio operator.

## Handoff

Owner: coordinator.
Checkout: `C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\gallery`.
Main/status: accepted State Version 2 at starting main; proposed revision will use Version 3.
Studio target: isolated peg-aero-qa.rbxlx; existing user-owned peg-polished.rbxlx untouched.
Published: NOT PUBLISHED.
Next action: integrate contributor changes, verify in isolated Studio, and publish a reviewable build.
