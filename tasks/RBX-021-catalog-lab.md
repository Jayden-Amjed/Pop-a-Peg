# RBX-021 — Full Blender catalog and animation inspector

- Owner: Codex coordinator; sole Studio operator.
- Status: READY FOR REVIEW
- Reservation: [issue 21](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/21)
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: dfe5c4a8c8d82185a640cd7a029f6bb90d1014fd; accepted State Version 10.
- Branch: task/RBX-021-catalog-lab
- Worktree: `.worktrees/catalog-lab`
- PR: [22](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/22)
- Implementation evidence SHA: 23f4615c4231114af6cf72e271739a8858459e3c (final inspector);
  92c4578d72548a61e0bc810f22b105fb65d1e812 (uploaded catalog and motion).
- Confirmed merge SHA: NOT MERGED

## Objective and outcome

Create a Blender model for every registered catalog entry and a precise individual
animation inspector. All 78 entries now have editable geometry and imported
runtime copies: 40 equipment, 13 evolutions, 8 perks, 3 Supplies and 14 utilities.
They total 477 MeshParts / 124332 triangles. Original silhouettes, continuous
curves, beveled edges, dark inset faces and explicit moving pivots replace ad-hoc
primitive assemblies in the review gallery. Existing three pilots are reused.

Search/filter and previous/next navigation lead to individual trigger/loop,
four playback speeds, held pose scrubbing, strength 1/2, four views, 60–250% zoom
and Fit. Native comparison uses the same lighting/camera/framing. Pose tags and
copyable notes capture ID, pose, speed, strength, view, zoom and lighting. Notes
are session-only and must be copied before stopping Play.

Balanced directional lighting and pearl/aqua panel depth also reach the normal
game. Production geometry remains native during user review. No gameplay balance,
paid products, player profiles or experience publication changed.

## Acceptance criteria

- [x] All 78 registered IDs have editable Blender geometry and imported models.
- [x] Individual animation, camera, slow playback, pose, zoom and feedback controls work.
- [x] Shared lighting/UI contrast adds depth without duplicate outline geometry.
- [x] Geometry, mesh loading, motion, restoration, framing and controls checked in Studio.
- [x] Editable source, upload identity, commands, limitations and dashboard recorded.

## Ownership and integration

Root owns catalog-lab integration and all Studio sessions. Independent mechanical,
nature and inspector contributors used separate worktrees from accepted main.
Their bounded commits were cherry-picked; no contributor touched Studio.
Original root checkout and unrelated prior places were preserved. No open PR
overlap existed at reservation. Main was fetched again and remained dfe5c4a.
Version 11 is proposed from accepted 10 until merge; no earlier failure is hidden.

## Checks actually run

| Check | Environment / evidence | Result |
| --- | --- | --- |
| Blender build and export | Portable 4.5.9 LTS, 75 new sources + 3 accepted pilots | PASS; 78 unique model signatures, zero nonmanifold/degenerate faces |
| Source preservation | Contributor isolated rebuild, exact .blend hashes | PASS; ordinary export retained edits |
| Chest lid geometry | Five sampled opening poses on new reward builders | Body/rim clearance passed; intended hinge bearing overlaps remain |
| Upload/import | Ten owner583716264 assets; 452 new pieces + 30 calibration cubes | All Approved; measured0.28 scale and yaw correction; raw packages preserved |
| Archive validator | `catalog-integrity.json`; original sources, GLBs, raw captures, receipts, runtime hash | PASS; modified source/raw/metadata fixture cases rejected |
| Runtime motion/loading | 92c4578; Studio gallery97fe17b2; `studio-catalog-audit.json` | 78/78; 24 cycles/model, 14976 sampled poses, exact reset and real mesh loading |
| Final gallery restore/frame | 23f4615; rebuilt artifact in gallery9f7afcd3 | 78/78 mounted; 22896 corners, six strength2 poses, no default-fit clipping |
| Actual controls | Studio mouse/keyboard actions in final gallery | Search spring→Wave Spring, trigger, loop, slow speed, native comparison, wheel156%, Fit100%, library-wheel isolation, pose tag/export |
| Normal game | UI implementation769403d; isolated db4acb6d target | Hub→run; three completed shot rounds, populated viewports use Balanced; UI readable |
| Local contracts | check.ps1; adapter test; source/archive validator | Formatting/lint, 23 gameplay suites, motion contracts, main build/39 source mappings passed |
| Final expanded checks | Both gallery builds, 39 source mappings, scripts lint/motion, archive validator | PASS; PR CI pending |

Runtime audit checks sampled transforms, dimensions and mesh status; it does not
prove exhaustive swept-volume clearance. Visual sheets cover all 78 models;
individual screenshots show the inspector and native comparison. Contact sheets
are QA fixtures, not additional game UI. All evidence is under
`docs/evidence/RBX-021/`.

## Assets and reproducibility

Sources: `art/catalog/<id>/<id>.blend`, plus accepted `art/models/` pilots.
Runtime: `art/catalog/CatalogAssets.rbxm`, engine-exported and mapped only by
`catalog-gallery.project.json`. SHA256
`f56fdf27a0efa6b4bf13067b543ca3cb449b50ae39787811ad42f02420f28a7a`.
Ten uploads and their operation/approval records are in
`art/catalog/uploaded/receipts.json`; each has GLB, manifest, raw capture and bound
receipt. Exact source hashes are checked before binding existing MeshIds. Source
identity and remote identity are recorded; remote mesh bytes are not rehashed.
No paid or third-party model assets used. Another account's access is unverified.

The first attempted multi-model serialization exceeded MCP's100000-character
response limit; it was rejected as truncated JSON and never used. The complete
folder was exported in eleven bounded Base64 chunks, decoded and hash-pinned,
then restored through Rojo for final Studio checks. Temporary export chunks were
removed from the final development place.

Guide: [Catalog gallery](../docs/CATALOG_GALLERY.md).
Existing native gallery and game builds remain supported. Old pilot project now
maps the new shared PreviewLighting dependency explicitly. Required checks include
catalog Luau scripts/motion contracts and both gallery builds; CI also validates
the source/import archive.

## Limitations

Rigid Wave Spring compression changes wire thickness. Tidal Engine retains its
inherited whole-coil activation rather than a skinned spring simulation. Glass
uses simple transparent meshes, and ViewportFrames do not render cast shadows.
Default framing is checked; deliberate high zoom may crop. Inspector tested at
1046x524, not narrow/mobile hardware. Feedback persists only within the Play
session. Production adoption of the Blender shapes remains for user review.
Existing unrelated avatar asset203785492 warnings persist; no catalog errors.
No Windows capture helper used; prior yellow border remains resolved.

## Handoff

Root owns `C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\catalog-lab`.
Studio version: 0.746.0.7461269. Final target: peg-catalog-gallery-final.rbxlx,
9f7afcd3-3f7d-45ea-8f2d-9769db7f8564. Play stopped; Rojo disconnected.
Import workbench c719dd9a and prior gallery97fe17b2 are isolated Edit sessions.
User's saved permission-host place105048204331261 and earlier sessions preserved.
Build SHA256: `0EB94AA776AEA48CB71C4138406367EF79C523191E8BE8D3F2312CF678548DF3`.
Next action: final checks and PR CI, merge under existing user authorization,
then open gallery and press Play to collect item-by-item modeling feedback.
Published: model assets uploaded; no experience update published.
