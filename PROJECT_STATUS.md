# Current project state

State Version: 6 (proposed aquarium arcade and progression balance; accepted predecessor 5)
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Deliver a shared eight-player aquarium arcade with independent runs and prevent early runaway restock loops.

Accepted source: ad313f065c14c23ba67b2223424a8670ce9d2dc0 (predecessor).
Implementation: 131d04598e3162c747e7e3dc3a19fb34f0b05dc2.
Active task: [RBX-011](tasks/RBX-011-arcade-balance.md), Codex coordinator.
Branch: task/RBX-011-arcade-balance; [PR #12](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/12).
Main: NOT MERGED for this task; predecessor remains accepted until GitHub confirms integration.

| Capability | Verified state |
| --- | --- |
| Arcade | Walkable original 820-part aquarium hub, eight cabinets, seven fish, gallery, records kiosk, seating and gardens |
| Ambient motion | Ten client-local fish/bubble groups, 65 moving parts; reduced motion and exact cleanup |
| Multiplayer | Eight native Studio clients received unique stations, played independently, returned/resumed and survived another player's departure |
| Run lifecycle | Hub-first join, private runs, safe pause/resume between shots, victory preserves Endless, lost runs reset power |
| Hub UI | Play/Resume, collection with modeled evolution recipes, personal records and eight-player roster; six responsive layouts |
| Balance | Causal ancestry blocks self-triggering loops; direct score items scale with quota; stage caps 6/8/10/12 and progressively doubled restock costs |
| Existing equipment | Levels 1–5, 13 distinct evolutions; full racks guarantee two useful upgrades when possible; four equipment + at most two Supplies |
| Stages / presentation | Clear 15/40/65/100 then every 50; 52 item models, 235-part board, 46 motifs, bounded dense FX and white counter surfaces retained |
| Local checks | 17 suites, Selene clean, Rojo build, 27 exact source mappings and documentation checks |
| Studio checks | Affected balance/session/layout/counter suites; six UI transitions; collection interactions; eight native clients |
| Gameplay sample | 38 shots across three live runs in 120.3 seconds, reached round 15, max one restock; no game errors |
| Campaign sample | 30 legal seeded simulations: 25 clear round 40; max early restocks 2, total 3, activations 79; optimistic aim search, not human difficulty |

Studio-tested source: 131d04598e3162c747e7e3dc3a19fb34f0b05dc2.
Published: NOT PUBLISHED; no production experience/place selected.
Playable output: build/peg-arcade.rbxlx in the arcade worktree.
Studio target: isolated peg-aero-qa; root sole operator; Rojo disconnected.
The saved eight-client harness also passed on the final implementation. Studio is
stopped in Edit with 32 normal sources and both temporary QA scripts removed.

Blockers: none. Final branch push, CI and merge receipt pending.
Unrun: physical touch/gamepad, cloud persistence, live plugin sync, production publication.
Limits: eight Studio clients do not measure eight-device performance; human long-run
difficulty still needs playtesting. MCP captures can omit peg numbers; unrelated
203785492 asset warning remains. Detailed evidence and resolved failures are in the task.
Monetization: none.
Next action: merge the verified PR, then open
build/peg-arcade.rbxlx for human playtesting. Configure production Max Players = 8
when a production target is chosen.
Repository administration: main unprotected; temporary default remains starter branch.
