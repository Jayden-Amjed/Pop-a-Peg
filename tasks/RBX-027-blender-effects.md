# RBX-027 — Blender detail, transient effects and varied sound

- Owner: Codex coordinator; sole Studio operator
- Status: IN PROGRESS
- Reservation: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/27
- Starting main:07be76a57335fa3aaa05009c91bd2e36ed05dd0e, accepted State Version13
- Branch:task/RBX-027-blender-effects
- PR:https://github.com/Jayden-Amjed/Pop-a-Peg/pull/28
- Reviewed:2026-11-08, America/Los_Angeles

## Objective and scope

Apply the user's eleven named item notes and extend distinctive brief effects and
sound variety across the 78-entry Blender gallery. Rename gallery labels Coral
Spark and Breeze Fan while retaining stable IDs. Explicitly freeze native models,
native choreography and gameplay sources. No balance or experience publication.

## Acceptance

- Named models meet the requested silhouette, articulation and VFX notes.
- All78 gallery entries have deliberate distinct transient effects and sound.
- Rest/endpoints, scrubbing, pause/resume, loop, cleanup and framing work.
- Native rendering/animation and the game source tree remain byte-identical.
- Revised assets retain exact source/export/import provenance; Studio visual and
  actual audio checks accompany tests and builds.

## Ownership and dependencies

Root owns gallery integration, labels, imports, archives, documentation and QA.
effects_geometry owns eight targeted Blender source revisions/helper/builders;
effects_motion owns Blender-only choreography/FX/adapters and tests;
effects_audio owns gallery-only sound bank/playback and tests. Each contributor
has its own accepted-main worktree. They coordinate pivots and impact phases.
No contributor may edit src/ or operate Studio. Root/native review checkout and
user's current gallery content remain preserved.

## Checks

Local required check.ps1 passes: formatting, lint, 23 gameplay suites, 78 motion
contracts, 12,792 effect samples, gallery audio lifecycle and 78 instrument phrases,
three builds, 45 game source mappings and documentation checks. Revision validator
passes 78 models / 477 MeshParts / 127664 triangles / 12 archived uploads; eight
archive regression tests pass. Native hash guard and unchanged src/ proof pass.
Studio normalization of asset107372484175276 succeeded for eight models; actual
new animation/effect/audio runtime verification is pending.

## Handoff

- Owner/next owner:Codex coordinator; root is sole Studio/import operator.
- Checkout:C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/blender-effects.
- Branch/PR:published above.
- Studio target:coordinatorQA9f7afcd3; current user gallery4a95dbcb preserved.
- Sync:no live Rojo. Saved experiencef9c95fd9/place105048204331261 verified;
  asset read/write scope probe200. Known approved export folder unchanged.
- Main:07be76a, accepted13. Proposed14 not accepted.
- Blockers:none. Geometry, all78 effects and audio integrated. User reinforced that
  the specific treatment style applies across all items. Eight-model revision
  uploaded and normalized; original sources and receipts archived immutably.
  Native source hash guard passes; src/ and default game mapping are unchanged.
  Next:open the fresh built gallery and verify all78 effects/framing/audio in Studio.
- Merge:NOT MERGED. Experience publication:NOT RUN.
