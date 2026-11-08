# Current project state

State Version: 5 (accepted full-rack shop revision)
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Guarantee two useful upgrades in full-rack shops while preserving holds, random offers and evolution access.

Accepted source: a896e56a91041d6f8aaea9c7cefa19439a0897b5 (PR #10 merged into main).
Implementation: a34b8e57c1a0648294de72d07a42496d37f75daa.
Completed task: [RBX-009](tasks/RBX-009-full-rack-shop.md), Codex coordinator.
Branch: task/RBX-009-full-rack-shop; [PR #10](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/10).

| Capability | Verified state |
| --- | --- |
| Equipment upgrades | Levels 1–5, one level per purchase/Supply/event; full racks supported |
| Evolutions | 13 distinct recipes covering all 22 base items; two L5 ingredients combine atomically for no additional coins |
| Evolved abilities | Both original L5 trigger channels and ordered operations preserved in one slot |
| Shop | Full racks reserve two useful upgrades on opening/reroll; remaining offers roll normally; held prices and evolution access preserved; four equipment + at most two Supplies |
| UI | Modeled equations and readiness labels; evolved/perk/Supply cards omit recipes; six responsive layouts, stable preview objects |
| Stages | Clear 15, 40, 65, 100, then every 50; bosses at campaign goals; success-only completion and full goal indicators |
| Models and motion | 52 native models, 13 unique evolved devices, five tiers; 260 variants tested with exact rest restoration |
| Board | 235 original native parts; decorated attached monitor, unchanged collision/projection anchors |
| Feedback | 46 motifs; dense bursts/beams/ribbons; 184 decorative / 240 total FX cap; reward delivery preserved |
| Extreme builds | 4,096 activations per shot; huge-score meter and boss quota bounds; stress run advanced 41→42 at 5.46e107 score |
| Local / Studio checks | Fourteen suites pass locally and in Studio; 13 new shop contracts covering 800 seeded rolls; server-runtime shop suite also passes; 21 exact source mappings |
| Shop UI verification | Two native clicks upgrade a full seven-slot rack, levels 4→5 and 1→2, coins 90→81; reroll, one-upgrade-left and all-capped cases pass |
| Production play | Normal restored client launches a server-owned shot with 34 state snapshots and no project errors; longer evolution playtest remains recorded in RBX-007 |

Studio-tested source: a34b8e57c1a0648294de72d07a42496d37f75daa.
Published: NOT PUBLISHED; no production experience/place selected.
Playable output: build/peg-full-rack.rbxlx in the full-rack worktree.
Studio target: isolated peg-aero-qa.rbxlx stopped in Edit; all 26 normal sources
restored exactly, Rojo disconnected. User-owned Studio windows are untouched.

Blockers: none. Push CI 42460978053 and PR CI 42460982630 passed at 78246be728692fd57fc2eb0a245a5a21b24d7487; GitHub returned the merge receipt above and fetched main confirms it.
Unrun: physical touch/gamepad, two clients, cloud persistence, live plugin sync, publication.
Limits: device-specific FX performance and long-run balance need human playtesting.
MCP captures can omit peg numbers; the unrelated 203785492 asset-type warning remains.
Detailed tests, corrected QA observations and resolved failures are in the task.
Next action: human playtest build/peg-full-rack.rbxlx; choose a hub concept before reserving a hub implementation task.
Hub and monetization: researched proposals only; neither a lobby nor payments are implemented.
Repository administration: main unprotected; temporary default remains starter branch.
