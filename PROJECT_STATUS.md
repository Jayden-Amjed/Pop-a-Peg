# Current project state

State Version: 10 (proposed Blender pilot workflow; predecessor accepted version 9)
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Evaluate three original Blender models in a separate Studio gallery.

Accepted main inspected: 098b7b6fa24e423703db6e9ceb68eb020010d3aa.
Production gameplay implementation remains 21ac14748710be87635fb7e0d40ec9f65d6bc683.
Active task: [RBX-019](tasks/RBX-019-blender-pilots.md), Codex coordinator.
Branch: task/RBX-019-blender-pilots; [PR20](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/20).
Pilot implementation / Studio evidence: 0a0e40c9861b10ef35ee07226f8e2abe453f0e93.
Merge: NOT MERGED. Main still represents accepted version 9.

| Capability | Verified state |
| --- | --- |
| Blender | Portable 4.5.9 LTS installed with official SHA256 verification; repeatable setup/export |
| Pilot models | Wave Spring 3184 tris/7 meshes; Seed Bank 2040/8; Meadow Chest 3168/10 |
| Editable source | Three .blend files; normal exports preserve edits; explicit -Regenerate uses Python recipes |
| Studio gallery | Separate local place, equal-size native toggle, activation controls, 48/96/192-pixel previews |
| Import / access | Model112890615474684, owner583716264, Approved; 25 meshes restored and loaded under owner account |
| Native verification | 12 activation cycles per model, full transforms restored; 10800 framing-corner checks; actual GUI and images |
| Art workflow | [Pilot guide](docs/BLENDER_PILOTS.md), [style guide](docs/MODEL_STYLE_GUIDE.md), [provenance](docs/ASSETS.md) |
| Production models | All 78 native models remain the default; no catalog replacement in this pilot |
| Existing game | Eight-player arcade, saved extra-Restocks wallet, hub chest market, bounded five-cycle restocks and 64 sound motifs retained |
| Chest prices | Common100 / Uncommon250 / Rare500 / Legendary1000; server-authoritative and retry-safe |
| Checks | Pilot lint/export/audits passed; 23 repository suites, build, 38 mappings and docs passed before final docs update |

Studio: 0.746.0.7461269; peg-blender-pilots.rbxlx;
466c063b-5d2e-4435-8c22-ad2394ef1d77. Root sole operator; Rojo disconnected;
Play stopped in Edit. Normalized models restored from engine-serialized .rbxm.
Other Studio sessions and the user's saved permission-host experience were preserved.

Playable output: build/peg-blender-pilots.rbxlx in .worktrees/blender-pilots.
SHA256: 3394E5363B89CB0F4BD36565CC420E32BCA3618DDA0D93DC7D760E7D9C7B628E.
[Actual Studio preview](docs/evidence/RBX-019/studio-rest.jpg).

Blockers: none. Final docs checks/CI and merge are pending.
Limitations: rigid coil compression changes wire thickness; another account's mesh
access, production adoption and physical-device performance are unverified.
Existing unrelated avatar asset203785492 warning persists. No pilot runtime errors.
Yellow monitor border remains resolved; this task used Studio capture only.
Published: model asset uploaded; no experience update published by this task.
Next action: complete checks/merge, then evaluate the gallery before adopting pilots.
Repository administration: main unprotected; temporary default remains starter branch.
