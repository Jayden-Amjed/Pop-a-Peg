# Current project state

State Version: 14 (accepted RBX-027; RBX-029 proposes 15).
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Blender gameplay adoption, grounded effects, useful drain growth and readable previews.

Accepted source: 6ef9576dd038ff5f4efa998c4034a559e46d5dcf.
Active task: [RBX-029](tasks/RBX-029-blender-game.md), Codex coordinator.
Branch: task/RBX-029-blender-game; [PR30](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/30).
Implementation: 8fd0c679e47033970a434afafc6937ea666b26cd.
Studio-tested source: 7eb6c18a971e4f33cb0a2896c23d4ce7fe816897 for gameplay;
the later gallery-description-only update at 8fd0c67 matches all 71 current Edit scripts.
Test helper: ce1a6474dfb6b75dfec248e46e8601033a011cc6.
Merge: NOT MERGED.
Published: no experience update.

| Capability | Current evidence |
| --- | --- |
| Blender gameplay | 78 models / 477 MeshParts mapped through game adapters; source checks pass |
| Physical effects | Quota plate contact; Synth/Relay body pop; all 78 placement checks pass (702 Studio poses) |
| Final adapter | All 78 Studio lifecycle/loading/framing checks pass: 68,096 model corners, 12,884 effect checks |
| Drain growth | Seed Bank/Rain Catcher/Monsoon bank next-shot growth; 15 contracts pass in CLI and Studio |
| Owner access | ID 583716264 gets 40 equipment pools and 13 evolution previews; save/isolation checks pass |
| UI | Larger previews and adaptive perk rows; actual compact Studio containment and flow checks pass |
| Full rack upgrade | Studio fixture buys Seed Bank level 2 to 3 with seven occupied slots; other shop previews persist |
| Resume | Completed seeded/restocked board restores after hub resume; CLI and Studio tests pass |
| Native reference | Eight frozen sources match 07be76a57335fa3aaa05009c91bd2e36ed05dd0e |

Playtest file: repository-root `build/Pop-a-Peg-PLAYTEST.rbxlx`.
Exact copy of the task's generated `build/dev.rbxlx`.
SHA256: 0ECD30A1FACDC87A27C70A83BB372E91FB2821289A4A661241CB98CAF683E1F0.

Studio c35ab669 is in Edit mode with all 71 scripts verified against this build.
Owner badge confirmed; real remote-driven run reached round 2 before losing.
The isolated presentation fixture passes natural drain, eight seeded pegs,
automatic retry, seven-slot rack, four perks, six shop offers, full-rack upgrade,
and perk choice back to aim. Existing GUI/camera restored; no live profile writes.
Actual viewport: 1046×524, safe area 1046×466; compact layout, not desktop visual proof.

Background game captures omit 3D rendering; model geometry/loading is independently
checked. Roblox denied Set3dRenderingEnabled; no retry/workaround.
Gallery QA and game play are stopped. No live Rojo. All final checks used background
Studio MCP; no desktop control. Older saved experience 115816779411929 was inspected only.

Checks: required check.ps1 PASS at ce1a647; catalog, eight archive regressions,
native/mapping/placement and hub-reveal checks PASS. Final GitHub CI pending.
[Evidence](docs/evidence/RBX-029/REVIEW.md) and [drain rules](docs/DRAIN_ITEM_AUDIT.md).
Next action: push, confirm final CI, merge PR30, accept State Version 15.
Repository administration: main unprotected; temporary default remains starter.
