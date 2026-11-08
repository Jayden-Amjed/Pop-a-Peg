# Current project state

State Version: 8 (proposal: earned hub progression and mobile polish)
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Connect runs to tiered hub chests and equipment discoveries, add arcade rankings, and make phone play usable.

Accepted predecessor: 9d516120dc4c925061c444f713fb3b40719e1688, State Version 7.
Implementation: b8329c800762f3d238f5d535261ab09cbdb18312.
Active task: [RBX-015](tasks/RBX-015-hub-progression.md), Codex coordinator.
Branch: task/RBX-015-hub-progression; [PR #16](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/16).
Main: fetched again and unchanged; acceptance awaits PR CI and merge.

| Capability | Verified state |
| --- | --- |
| Hub | 1,038-part aquarium arcade, modeled four-tier chest pavilion, three physical ranking screens and six-action dock |
| Rankings | Time played, highest Endless round, and experience Robux spent; global/session/offline and stale-data labels |
| Earned progression | Qualifying defeats and milestones award tiered chests; hub opening grants an unowned blueprint; exhausted tiers grant research |
| Ownership | Eight starter items; only owned equipment can roll; new runs freeze their pool; legacy discoveries migrate |
| Content | 40 base equipment including 18 new multi-effect items, four tiers, 13 existing evolutions, eight perks |
| Persistence | Versioned profiles, renewable exclusive leases, serialized spending, newest 64 persisted retry receipts; failure/retry adapter tests |
| Models and motion | 78 distinct geometry signatures; dedicated chest/event/perk models; chest opening and choice figure-eight motion |
| Phone UI | Portrait/landscape support, notch-aware camera/input/FX, visible 4+2 shop, compact recipe inspector, Stats/Perks/Rack panels |
| Local checks | 22 suites, clean StyLua/Selene, Rojo build, 38 exact mappings, documentation checks |
| Native checks | Ordinary earned-chest-to-new-run loop, phone controls/layouts, 78-model audit, eight-player progression/isolation harness |

Studio-tested source: b8329c800762f3d238f5d535261ab09cbdb18312.
Studio 0.746.0.7461269, isolated peg-mobile-qa.rbxlx, target 0f901236-a3db-4178-890f-d0cb4929d1e1.
Root sole operator; Rojo disconnected. Stopped in Edit. All 41 normal sources
match repository checksums, both Main scripts enabled, and both temporary multiplayer
scripts removed. Local PlaceId/GameId are 0.
Playable output: build/peg-progression.rbxlx in the progression-hub worktree.
Build SHA256: B800D286088FA0F0AB70FD9EDD039D963A7702E5C139853FC6BA647D8F80E036.

Blockers: none. Final PR CI/merge pending.
Unrun: physical touch/gamepad, production DataStore/OrderedDataStore, live plugin sync, publication.
Limits: native emulator and eight Studio clients do not establish physical-device
performance. New content still needs human long-run tuning. MCP captures sometimes
omit peg labels or model previews; native window captures verified them. Unrelated
203785492 asset warning remains.
Monetization: no products, prompts, paid chests or receipt processor; Robux board is honestly empty.
Published: NOT PUBLISHED; no production experience/place selected.
Next action: pass PR CI, merge the authorized task, record acceptance once, then human playtest the generated build.
Repository administration: main unprotected; temporary default remains starter branch.
