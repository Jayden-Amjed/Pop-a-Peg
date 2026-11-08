# RBX-011 — Aquarium arcade and progression balance

- Owner: Codex coordinator; arcade_world, arcade_client and arcade_balance contributors.
- Status: IN PROGRESS
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: ad313f065c14c23ba67b2223424a8670ce9d2dc0
- Branch: task/RBX-011-arcade-balance
- Reservation: [#11](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/11)
- PR: NOT OPENED
- Implementation evidence SHA: pending
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Build a complete aquarium arcade hub with eight personal stations, walking avatars,
instant independent runs, return/resume and retry, earned evolution collection and
records. Diagnose and fix early self-sustaining score/restock explosions without
removing meaningful combinations. No monetization or production publication.

## Acceptance criteria

- [ ] Eight station assignments, independent runs and safe join/leave/mode transitions.
- [ ] Detailed walkable hub, functional station prompts, collection and records UI.
- [ ] Normal game controls and camera restored reliably through repeated transitions.
- [ ] Reproduced runaway builds corrected with regressions and balance simulations.
- [ ] Full checks and Studio gameplay pass; multiplayer observations recorded honestly.
- [ ] Current docs, playable build and verified main delivery.

## Dependencies and ownership

Root: server Main, session policy, profiles, integration, docs and sole Studio operator.
arcade_world: HubWorld native scenery and station API.
arcade_client: client Main and HubPresentation UI/lifecycle.
arcade_balance: Run/Board/Catalog and balance tests, plus earned evolution unlocks.
Each contributor uses its own checkout from accepted main; no overlapping Studio sync.

## Checks actually run

| Check | Result | Evidence |
| --- | --- | --- |
| Accepted main / reservations | PASS | Fetched ad313f0; no open tasks or PRs |
| Local checks | NOT RUN | Implementation in progress |
| Studio | NOT RUN | Reconfirm isolated peg-aero-qa before mutation |
| Main | NOT MERGED | Existing verified-delivery authorization applies |

## Handoff

- Owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/arcade.
- Accepted State Version: 5; proposed version: 6.
- Studio target: isolated peg-aero-qa; root only, Rojo disconnected.
- Published: NOT PUBLISHED.
- Next action: implement session ownership and integration while contributors build hub and balance fixes.
