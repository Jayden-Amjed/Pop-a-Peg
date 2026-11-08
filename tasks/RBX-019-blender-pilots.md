# RBX-019 — Blender model pilots

- Owner: Codex coordinator; sole Studio operator.
- Status: IN PROGRESS
- Reservation: [issue 19](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/19)
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: 098b7b6fa24e423703db6e9ceb68eb020010d3aa; accepted State Version 9.
- Branch: task/RBX-019-blender-pilots
- Worktree: `.worktrees/blender-pilots`
- PR: pending creation
- Implementation evidence SHA: pending
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Set up pinned portable Blender and create original Wave Spring, Seed Bank and
Meadow Chest pilots using the accepted model style guide. Preserve editable
sources, deterministic builders, export manifests and Studio import evidence.
Compare the pilots with current native models before replacing production defaults.
No experience publication, monetization or wholesale catalog conversion.

## Acceptance criteria

- [ ] Verified portable Blender installation and repeatable build command.
- [ ] Three editable .blend sources, clean exported geometry and audit reports.
- [ ] Studio scale, orientation, materials, collision flags and activation verified.
- [ ] Actual Studio images shown to the user with clear native/pilot labels.
- [ ] Modeling workflow, provenance and current dashboard updated honestly.

## Dependencies and ownership

Root owns setup/common geometry/export/validation, Wave Spring, integration and docs.
Seed Bank and Meadow Chest contributors own only their respective Python builders
in separate worktrees. Read-only reviewer owns no paths. Root alone owns Studio.
No overlapping open PRs/issues were found before reservation. Existing checkouts
and disconnected Studio sessions are preserved.

## Checks actually run

| Check | Source/environment | Result |
| --- | --- | --- |
| Checkout/remotes/reservations | main 098b7b6 | PASS; clean new worktree, issue reserved |
| Studio availability | fcaa7ed5-f945-4708-abd8-d081f39a8ee2 | PASS; Edit, local game/place 0, user 583716264 |
| Asset scope probes | Studio MCP | BLOCKED: asset:read and asset:write not granted |
| Blender / models / runtime | pending | NOT RUN |

## Handoff

- Root owns task/RBX-019-blender-pilots; main remains accepted version 9.
- Downloading verified Blender 4.5.9 portable; model authoring can proceed independently.
- Studio/Rojo disconnected; existing peg-restock-qa remains stopped and unchanged.
- Awaiting user to enable asset read/write and approve build/model-exports folder.
- Next action: build and audit three pilots, then import to a dedicated Studio gallery.
- Published experience: NOT PUBLISHED.
