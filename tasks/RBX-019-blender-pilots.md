# RBX-019 — Blender model pilots

- Owner: Codex coordinator; sole Studio operator.
- Status: VERIFIED, awaiting merge
- Reservation: [issue 19](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/19)
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: 098b7b6fa24e423703db6e9ceb68eb020010d3aa; accepted State Version 9.
- Branch: task/RBX-019-blender-pilots
- Worktree: `.worktrees/blender-pilots`
- PR: [20](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/20)
- Implementation evidence SHA: 0a0e40c9861b10ef35ee07226f8e2abe453f0e93
- Confirmed merge SHA: NOT MERGED

## Objective and delivered scope

Installed checksum-verified portable Blender 4.5.9 LTS and authored original Wave
Spring, Seed Bank and Meadow Chest pilots from the style guide. Editable blends,
Python recipes, export manifests, exact uploaded GLB, observed MeshIds and an
engine-serialized model are retained. A separate Studio model lab compares native
and Blender models, previews 48/96/192-pixel sizes and plays real activation/idle.
Production model defaults remain native. No monetization or experience update.

## Acceptance criteria

- [x] Verified portable Blender installation and repeatable build command.
- [x] Three editable .blend sources, clean exported geometry and audit reports.
- [x] Studio scale, orientation, materials, collision flags and activation verified.
- [x] Actual Studio images captured with clear native/pilot labels.
- [x] Modeling workflow, provenance and current dashboard updated.

## Dependencies and ownership

Root owns setup/common geometry/export, Wave Spring, integration and docs.
Contributors authored Seed Bank, Meadow Chest, import-proof guard and motion audit
in separate worktrees. Root alone operated Studio. No overlapping open work was
found before reservation. Existing checkouts and Studio sessions were preserved.

## Implementation evidence

- 126407807f52026cd217f9fb93f7c94f2e3e4dbc: initial source/imported-model gallery.
- 994a4ea102bc23e45b40fb194c9b889c85379717: preserve manual Blender edits, explicit
  regeneration, pinned import proof, equal-size comparison and preload failure UI.
- 0a0e40c9861b10ef35ee07226f8e2abe453f0e93: full activation-envelope framing.
- Uploaded Model 112890615474684, revision 1, owner 583716264; Approved.
  The exact upload SHA256 is
  AAAC1D192CA6BDF394FBD02E5DD6958F82416525BF6ACAD77EB6FAA73D084BE1.
- The raw import contained 26 meshes, including a 0.28-stud calibration cube.
  Normalized copies retain 25 pilot MeshIds and correct scale 1/0.28, yaw 180
  degrees, gray materials, glass, motion tags and physics flags.
- The saved permission-host experience was observed as universe 10775417591,
  place 105048204331261. Only asset upload used its credentials; no scene or
  experience update was published there.

## Checks actually run

| Check | Exact source / environment | Result and limitation |
| --- | --- | --- |
| Portable setup | Official ZIP SHA256 41da973b9bf95bb312cbeff4d1982feb13259b43c821686b9bafea4dfe5477cf | PASS; Blender 4.5.9 LTS, no system install/PATH changes |
| Geometry export | 0a0e40c; Blender 4.5.9 | PASS; Spring 3184 tris/7 pieces, Seed 2040/8, Chest 3168/10; all meshes manifold, no degenerate faces |
| Normal export preservation | 0a0e40c; build-models.ps1 | PASS; reads existing blends; Git confirmed no blend changes after exports |
| Offline motion | 0a0e40c; audit_motion.py reads actual blends | PASS; spring minimum turn gap .066151 studs; seed 40 interface checks, .329460-stud roof clearance; chest 132 BVH checks across 22 poses, 0–105 degrees |
| Import replay | 994a4ea; capture_import.py | PASS; exact bundle/manifests/import pins match all 25 MeshIds; contributor negative controls reject changed inputs before writing |
| Isolated asset restoration | 994a4ea; Rojo rebuild/reopen | PASS; 3 models/25 meshes restored, raw package absent, local place 0 |
| Native runtime | 0a0e40c; Studio 0.746.0.7461269 | PASS; 12 cycles × 8 poses per model at strength 2; full CFrame/size/color restoration, frozen/resumed idle |
| Viewport framing | 0a0e40c; actual gallery Client | PASS; 10800 corner projections across 5 poses; max frame fraction .932278, no clipping |
| UI and asset loading | 0a0e40c; MCP mouse and capture | PASS; Activate/Rest/Open/Size/Native controls; actual meshes loaded, Ready true, no preload failures |
| Pilot formatting/lint | 0a0e40c; pinned StyLua/Selene | PASS; 0 errors/warnings |
| Repository checks | d2c167f0557c11350a55403c780564e05a01ba7d; check.ps1 | PASS; 23 suites, build, 38 source mappings and docs; final docs recheck recorded below |
| Publication | This task | NOT RUN; no experience update published |

Evidence: [motion audit](../docs/evidence/RBX-019/motion-audit.json),
[Studio audit](../docs/evidence/RBX-019/studio-audit.json),
[rest image](../docs/evidence/RBX-019/studio-rest.jpg),
[open image](../docs/evidence/RBX-019/studio-open.jpg),
[size image](../docs/evidence/RBX-019/studio-sizes.jpg),
[native image](../docs/evidence/RBX-019/studio-native.jpg).

## Resolved failures and remaining limits

Initial missing asset scopes blocked upload; the user saved an experience and
enabled permissions/folder access. Asset upload and owner-account loading then
succeeded. Initial gallery lint warnings, a missing Rojo Folder class and Windows
wildcard invocation were corrected. Non-destructive export initially tried to
append the current blend into itself; a fresh bundle scene fixed it. The audit's
original quad/end-cap assumption was revised for the triangulated editable source.
An open lid initially clipped its viewport; fitting the full activation envelope
fixed it and numerical projection checks passed.

The unrelated existing avatar ContentId 203785492 warning remains in Output.
No pilot script errors or failed mesh loads were observed. The rigid spring mesh
scales wire thickness during compression; constant-thickness skinning is future
work. Sampled surface checks do not prove exhaustive swept-volume clearance.
No claim of production-device performance, cross-account asset access or
production-catalog adoption is made.

## Handoff

- Root owns task/RBX-019-blender-pilots / PR20; proposal advances accepted version 9 to 10.
- Tested implementation: 0a0e40c9861b10ef35ee07226f8e2abe453f0e93.
- Studio target: peg-blender-pilots.rbxlx, 466c063b-5d2e-4435-8c22-ad2394ef1d77;
  Studio 0.746.0.7461269, local place 0, Play stopped in Edit.
- Rojo disconnected; no sync server. Final gallery source exactly matched disk.
- Playable output: build/peg-blender-pilots.rbxlx in the pilot worktree.
  SHA256 3394E5363B89CB0F4BD36565CC420E32BCA3618DDA0D93DC7D760E7D9C7B628E.
- Production remains the accepted native model path. User's other places preserved.
- Next action: final docs checks/CI and merge review branch; user can open gallery
  and press Play to evaluate the three pilots before production replacement.
