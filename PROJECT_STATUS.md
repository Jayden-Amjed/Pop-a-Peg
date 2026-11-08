# Current project state

State Version: 9 (accepted restock market, sound and model cleanup)
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Save extra restocks for hub chest purchases, bound reward playback, improve item sound and remove model artifacts.

Accepted source: fa7f6e36662dad86f145ec8133390c1a3c2987d5 (PR 18 merged into main).
Implementation: 21ac14748710be87635fb7e0d40ec9f65d6bc683.
Completed task: [RBX-017](tasks/RBX-017-restock-market.md), Codex coordinator.
Branch: task/RBX-017-restock-market; [PR18](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/18).
Main: GitHub confirmed merge; fetched checkout matches. State advanced once from accepted version 8.

| Capability | Verified state |
| --- | --- |
| Hub | Eight-player aquarium arcade, visible saved Restocks wallet, market and separate Buy/Open controls |
| Chest market | Common 100 / Uncommon 250 / Rare 500 / Legendary 1,000; hub-only, server priced, retry-safe |
| Progression | Each settled shot banks all restocks beyond the first; original board rewards and milestone/defeat chests retained |
| Reward presentation | At most five full refill/merge cycles; gaps retain every reward and final board |
| Sound | 64 unique motifs across 32 light / 17 rounded / 15 heavy profiles; short bass impacts; bounded voices/mix |
| Models | 78 unique single-pass models; generic floating upgrade trim removed; safe remount cleanup |
| Art workflow | [Style guide](docs/MODEL_STYLE_GUIDE.md) and [Blender pilots](docs/MODELING_WORKFLOW.md); no mesh conversion performed |
| Content/persistence | 40 base items, 13 evolutions, 8 perks; leased profiles and newest 64 purchase/open/research receipts |
| Checks | 23 local suites, clean formatting/lint, build, 38 mappings and docs |
| Native evidence | Two natural runs, two earned-chest loops, eight-client market/isolation, real market buttons, phone layout, audio and 78-model audit |

Studio-tested source: 21ac14748710be87635fb7e0d40ec9f65d6bc683 (final model revision; unchanged market/audio modules checked at their recorded earlier SHAs).
Studio 0.746.0.7461269; isolated peg-restock-qa.rbxlx; fcaa7ed5-f945-4708-abd8-d081f39a8ee2.
Root sole operator; Rojo disconnected; Play stopped in Edit. All 41 normal sources
match repository checksums; both Main scripts enabled; temporary fixtures removed.
User's peg-progression.rbxlx was preserved.
Playable output: build/peg-restock-market.rbxlx in the restock-market worktree.
Build SHA256: E4611D91B7F2D0682EFA1D6C64E9CC109E826CC9977940FD4366238E80E32FF7.

Balance: 24 simulated runs and two natural native runs measured. Beginner bots
earned 0 extras; future-best-shot upper-bound runs earned 0–540. The wallet is optional
long-term targeting alongside free early chests; human earning pace needs tuning.
Yellow monitor border: resolved by closing our capture runtime; user confirmed.
Blockers: none. PR CI 42510936404 passed at 1bc9eca322290c5b82af1890d86260414b8f0864.
Unrun: physical touch/gamepad, production storage/rankings, live plugin sync, publication.
Limits: native/simulated tests do not prove human pacing or physical-device performance;
native audio checks do not establish subjective listening quality. Existing unrelated
203785492 asset warning remains. Detailed evidence and resolved test failure are in the task.
Monetization: no paid products/prompts/receipt processing.
Published: NOT PUBLISHED; no production target selected.
Next action: human playtest build/peg-restock-market.rbxlx for savings pace; use the documented three-pilot workflow for the next modeling pass.
Repository administration: main unprotected; temporary default remains starter branch.
