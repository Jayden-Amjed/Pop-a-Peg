# Current project state

State Version: 14 (accepted RBX-027; RBX-029 proposes 15, not yet accepted).
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Blender gameplay adoption, grounded effects, useful drain growth and readable previews.

Accepted main: 6ef9576dd038ff5f4efa998c4034a559e46d5dcf.
Active task: [RBX-029](tasks/RBX-029-blender-game.md), Codex coordinator.
Branch: task/RBX-029-blender-game; [PR30](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/30).
Implementation: 7eb6c18a971e4f33cb0a2896c23d4ce7fe816897.
Merge: NOT MERGED. Experience publication: NOT RUN.

| Capability | Current evidence |
| --- | --- |
| Blender gameplay | 78 models /477 MeshParts mapped through game adapters; build/source checks pass |
| Physical effects | Quota plate contact; Synth/Relay body pop; all78 placement checks pass (702 Studio poses) |
| Final adapter | All78 Studio lifecycle/loading/framing checks pass:68096 model corners,12884 effect checks |
| Drain growth | Seed Bank/Rain Catcher/Monsoon bank next-shot growth;15 contracts pass in CLI and Studio |
| Owner access | Exact ID583716264 gets40 equipment pools and13 evolution previews; save/isolation checks pass in CLI and Studio |
| UI | Larger shop/choice/hover previews, adaptive perk rows, larger desktop hub; layout checks pass |
| Resume | Completed seeded/restocked board restored after hub resume; CLI and Studio resolver tests pass |
| Native reference | Eight frozen sources match07be76a57335fa3aaa05009c91bd2e36ed05dd0e |

Playtest file: repository-root `build/Pop-a-Peg-PLAYTEST.rbxlx`.
It matches `.worktrees/blender-game/build/dev.rbxlx`, source7eb6c18.
SHA256:A3378DA49F64BA4C9DD481B5E754F56A73B02861C6468E27287C8A83D6D785E6.

Studio c35ab669 opened the correct file; all71 script identities match the build.
Owner badge confirmed; real remote-driven run reached round2 before losing.
Background screen captures show GUI but omit 3D rendering; model geometry/loading
is checked independently. Set3dRenderingEnabled was denied by RobloxScript
capability; no retry or workaround. Final isolated presentation fixture pending.
Gallery9f7afcd3 remains coordinator-owned. No live Rojo. User stopped desktop
Computer Use; subsequent tests use only background Studio MCP.
Older saved Pop a Peggle experience115816779411929 was inspected only.

Checks: required check.ps1 PASS at7eb6c18; catalog/native/mapping/placement and
hub-reveal checks PASS. Final GitHub CI pending.
[Evidence](docs/evidence/RBX-029/REVIEW.md) and [drain rules](docs/DRAIN_ITEM_AUDIT.md).
Next action: finish background presentation fixture, review final changes, push
and merge PR30, then accept State Version15. No additional approval gate.
Repository administration: main unprotected; temporary default remains starter.
