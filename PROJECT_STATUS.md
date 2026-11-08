# Current project state

State Version: 2 (gameplay proposal over accepted starter version 1)
Reviewed: 2026-11-07, America/Los_Angeles
Objective: Independent peg-bounce runs with clear rewards, varied hybrid builds, and an aquatic glass presentation.

Accepted source: `18f2b17c2e3daf00ee2edd30f7b0db4d5b88e17c` (starter PR #2 merged).
Implementation / Studio-tested source: `c1f524c321d7ebdeb8c6d9f9f2fbb2c21c264037`.
Integration reconciles main at `644ba6327ce3a6dc84a2081883fa23e874e1a9be` without source changes.
Gameplay [PR #4](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/4) now targets main.
The user authorized this integration after playtesting; final CI and merge are pending.

| Capability | Verified state |
| --- | --- |
| Board, quotas, restocks, run/shop/perk/event/reset rules | PASS standalone and Studio; 28 progression cases |
| Hybrid effects and themed synergies | PASS ordered operations, costs, fish-pair scoring, bounded relay chains |
| Full rack and capped upgrades | PASS actual L1 Seed Bank upgrade with seven occupied slots, 33 to 28 coins; L2 remains MAX LEVEL |
| Grouped shop | PASS four equipment plus at most two Supplies, separate white enclosures, larger centered price/coin groups; 30 inspection cases across five sizes |
| Stable shop selection | PASS actual clicks preserve all 12 preview/model instances, with zero model additions/removals |
| Item/perk interaction | PASS stronger selection, separate perk inspection, all eight perks plus duplicate counts, short-desktop detail bounds |
| Idle and activation motion | PASS 39 figure-eight models, paused activation and smooth resume; 78 static level variants return exactly to rest |
| Counter feedback | PASS score/coins/restocks bounce and reset, guarded reward arrivals, perk cue, no reserve-to-ball launch flight |
| Scenery stability | PASS all 24 clouds opaque/shadowless; 147 mouse-sweep frames with zero camera/cloud transform changes |
| Repository checks | PASS eight suites, pinned format/lint, build, 15 exact mappings, documentation checks |
| Production Studio play | PASS all 20 normal sources restored exactly; 134-second ordinary-action run, four shops, two perk choices, highest round 15, no project errors |

Studio-tested source: `c1f524c321d7ebdeb8c6d9f9f2fbb2c21c264037`.
Visual checks use controlled fixtures; production play was checked separately.
Detailed evidence and limits: [RBX-003](tasks/RBX-003-peg-run-loop.md).
Published: NOT PUBLISHED; no production experience/place selected.

Active task: RBX-003, owner Codex gameplay coordinator, branch `task/RBX-003-peg-run-loop`.
Current playable file: generated `build/peg-polished.rbxlx` in the game worktree.
Studio: isolated `peg-aero-qa.rbxlx` stopped in Edit; all normal sources restored; Rojo disconnected.
The user's separate existing place/play windows were not modified.
Blockers / dependencies: none; starter PR #2 is accepted.
Unrun: physical mobile/touch, two clients in one server, cloud persistence, live plugin sync, publication.
Limits: other compact choice menus may scroll. Automated aiming is not human balance testing.
The play driver counts attempted actions and restarts directly after gameover;
terminal menu timing is covered by controlled feedback tests, not that driver.
Human playtesting remains useful for balance, visual preference, and the sound mix.
Observed limitation: unrelated Studio asset-type warning for 203785492; no project source reference.
Next action: verify final GitHub CI, merge PR #4, and record the observed merge receipt.
Repository administration: main remains unprotected; temporary default branch remains the starter branch.
