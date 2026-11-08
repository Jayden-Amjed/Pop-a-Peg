# RBX-021 — Full Blender catalog and animation inspector

- Owner: Codex coordinator; sole Studio operator.
- Status: IN PROGRESS
- Reservation: [issue 21](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/21)
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: dfe5c4a8c8d82185a640cd7a029f6bb90d1014fd; accepted State Version 10.
- Branch: task/RBX-021-catalog-lab
- Worktree: `.worktrees/catalog-lab`
- PR: pending creation
- Implementation evidence SHA: pending
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Create a Blender model for every registered catalog entry and an individual
animation inspector for precise user feedback. Preserve editable sources and
upload provenance. Add directional depth to item previews and restrained UI
shadow/contrast while retaining the bright Frutiger Aero palette. Evaluate models
in an isolated gallery; production geometry adoption remains distinct. No paid
products, gameplay balance changes or experience publication.

## Acceptance criteria

- [ ] All 78 registered IDs have editable Blender geometry and imported models.
- [ ] Search/category navigation, individual trigger, slow playback, pause/scrub,
      camera inspection and copyable per-item feedback are usable.
- [ ] Shared preview lighting and UI contrast improve depth without hiding content.
- [ ] Geometry, loading, bounds, animations, restoration and gallery controls are
      checked in Studio; actual captures retained.
- [ ] Source/asset identity, commands, limitations and current dashboard updated.

## Dependencies and ownership

Root owns integration, Blender/export/import pipeline, 15 new perk/chest/event
builders, existing three pilots, motion adapter, task/status/docs and all Studio.
Mechanical contributor owns catalog_mechanical.py (27 IDs). Nature contributor
owns catalog_nature.py (33 IDs). Inspector contributor owns CatalogGallery,
PreviewLighting, UiTheme and the narrow ItemModels viewport-lighting change.
Contributors use separate worktrees from accepted main; no shared Studio access.
No open PR overlaps were found. Issue19 remains open despite its confirmed merged
task; its implementation is already accepted and does not reserve new paths.

## Checks actually run

| Check | Source/environment | Result |
| --- | --- | --- |
| Accepted state, dirty files, remotes and reservations | dfe5c4a | PASS; clean isolated worktree, issue21 reserved |
| Studio connection / permissions | permission host universe10775417591, owner583716264 | PASS; asset read/write probe returned200 |
| Existing pilot target | 466c063b-5d2e-4435-8c22-ad2394ef1d77 | Edit; preserved, disconnected |
| Full catalog and runtime checks | pending | NOT RUN |

## Handoff

Root owns the catalog-lab worktree and Studio integration. Accepted main remains
version10. New builders and inspector are being authored independently. Exports
will be written directly to the existing approved model-export folder for upload;
new filenames preserve the original pilot upload. New isolated Studio target will
be created for testing. Next action: build/audit batches, inspect renders, import
and verify all IDs. No experience publication.
