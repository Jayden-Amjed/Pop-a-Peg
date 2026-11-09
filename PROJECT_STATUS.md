# Current project state

State Version: 16 (RBX-031 proposal; accepted predecessor remains 15).
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Consistent cartoon UI across gameplay and arcade, ready for desktop/landscape user testing.

Active proposal: [RBX-031](tasks/RBX-031-shop-prototype.md), Codex coordinator,
branch task/RBX-031-shop-prototype, [draft PR32](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/32).
Main re-fetched at 44762e38b5b4e3ad2f89c789ae6a7a6b6f6d4560; accepted State15 unchanged.
Full UI implementation and Studio-tested source: 74f9b0ae0383c34721eda9518b304b2e2162f040.
Pearl/aqua theme covers the run HUD/rack, shop, perks, events, results, inspection,
loading and all arcade/progression panels. Compact choices and chest previews
retain visible models beside their actions. Native geometry and game rules unchanged.
Required checks PASS. Final Studio audits PASS on all15 screens at1920x1080,
844x390 and667x375 presets; actual safe areas1919x1022,749x331,666x316.
Model samples178/171/170 all Blender Ready. Eight action flows include actual
chest animation/reveal and workshop research. Pointer perk choice and chest opening PASS.
Eleven normalized source fingerprints match files. [Evidence](docs/evidence/RBX-031/full-ui-desktop.json).
Physical-device and multiplayer testing NOT RUN. Existing203785492 asset warning remains.
No merge or publication for this task; accepted RBX-029 evidence below is retained.

Normal game: root `build/Pop-a-Peg-FULL-UI.rbxlx`.
Screen selector: root `build/Pop-a-Peg-UI-PREVIEW.rbxlx`; press Play and use **UI PREVIEW**.
Preview session0061e41d-a6ef-42a6-9480-977ce8a50bde; coordinator is sole Studio
operator, no Rojo. Its synthetic account and resources are temporary; both normal
entry scripts are disabled in the delivered preview. See task for normal-entrypoint
smoke-test evidence and exact file hashes. User testing is next; no implementation blocker.

Accepted source: 212c76260a5a6ce44dfd8ba5d10bd3ab77a25c4e.
Latest completed task: [RBX-029](tasks/RBX-029-blender-game.md), Codex coordinator.
Branch: task/RBX-029-blender-game; [PR30](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/30).
Implementation: 8fd0c679e47033970a434afafc6937ea666b26cd.
Studio-tested source: 7eb6c18a971e4f33cb0a2896c23d4ce7fe816897 for gameplay;
the later gallery-description-only update at 8fd0c67 matches all 71 current Edit scripts.
Test helper: ce1a6474dfb6b75dfec248e46e8601033a011cc6.
Merge: GitHub confirmed PR30 merged at 212c76260a5a6ce44dfd8ba5d10bd3ab77a25c4e.
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
native/mapping/placement and hub-reveal checks PASS. GitHub CI run 42549187354
PASS for final task head 673a0500a0502dda1c28c5b005c823a0012e88ad.
[Evidence](docs/evidence/RBX-029/REVIEW.md) and [drain rules](docs/DRAIN_ITEM_AUDIT.md).
Next action: user tests RBX-031 FULL-UI or the UI-PREVIEW screen selector; await feedback.
Repository administration: main unprotected; temporary default remains starter.
