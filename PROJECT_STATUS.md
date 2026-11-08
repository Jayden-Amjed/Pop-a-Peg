# Current project state

State Version: 4 (proposed evolution revision; acceptance pending)
Reviewed: 2026-11-07, America/Los_Angeles
Objective: Five-level equipment, unique shop evolutions, continuous round goals and richer activation feedback.

Accepted source: fef03bb55a07b1cf4a5e0d68a6ac4635f9805acc (previous accepted main).
Implementation: 5047ee70100b7e2b154f795d024cf25726222584.
Active task: [RBX-007](tasks/RBX-007-evolution-stages.md), Codex coordinator.
Branch: task/RBX-007-evolution-stages; [PR #8](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/8).

| Capability | Verified state |
| --- | --- |
| Equipment upgrades | Levels 1–5, one level per purchase/Supply/event; full racks supported |
| Evolutions | 13 distinct recipes covering all 22 base items; two L5 ingredients combine atomically for no additional coins |
| Evolved abilities | Both original L5 trigger channels and ordered operations preserved in one slot |
| Shop | Four equipment + at most two Supplies; eligible offers refresh; hidden recipes cycle without spending; expected-ID stale guard |
| UI | Modeled equations and readiness labels; evolved/perk/Supply cards omit recipes; six responsive layouts, stable preview objects |
| Stages | Clear 15, 40, 65, 100, then every 50; bosses at campaign goals; success-only completion and full goal indicators |
| Models and motion | 52 native models, 13 unique evolved devices, five tiers; 260 variants tested with exact rest restoration |
| Board | 235 original native parts; decorated attached monitor, unchanged collision/projection anchors |
| Feedback | 46 motifs; dense bursts/beams/ribbons; 184 decorative / 240 total FX cap; reward delivery preserved |
| Extreme builds | 4,096 activations per shot; huge-score meter and boss quota bounds; stress run advanced 41→42 at 5.46e107 score |
| Local / Studio checks | Thirteen suites pass; 20 evolution cases + 28 progression cases; 21 exact mapping/source checks |
| Production play | 167 seconds, round 41, 47 shots, eight shops, seven upgrades, four Supplies, three perks; no notices/project errors |

Studio-tested source: 5047ee70100b7e2b154f795d024cf25726222584.
Published: NOT PUBLISHED; no production experience/place selected.
Playable output: build/peg-evolutions.rbxlx in the evolution worktree.
Studio target: isolated peg-aero-qa.rbxlx stopped in Edit; all 26 normal sources
restored exactly, Rojo disconnected. User-owned Studio windows are untouched.

Blockers: none; push/PR CI and merge receipt pending.
Unrun: physical touch/gamepad, two clients, cloud persistence, live plugin sync, publication.
Limits: device-specific FX performance and long-run balance need human playtesting.
MCP captures can omit peg numbers; the unrelated 203785492 asset-type warning remains.
Detailed tests, corrected QA observations and resolved failures are in the task.
Next action: verify CI, merge under existing authorization, then record the actual receipt.
Repository administration: main unprotected; temporary default remains starter branch.
