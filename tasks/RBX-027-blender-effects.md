# RBX-027 — Blender detail, transient effects and varied sound

- Owner: Codex coordinator; sole Studio operator
- Status: READY FOR REVIEW
- Reservation: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/27
- Starting main: 07be76a57335fa3aaa05009c91bd2e36ed05dd0e, accepted State Version13
- Branch: task/RBX-027-blender-effects
- PR: https://github.com/Jayden-Amjed/Pop-a-Peg/pull/28
- Reviewed: 2026-11-08, America/Los_Angeles

## Objective and scope

Apply the eleven named notes and extend distinctive effects and sound across the
78-entry Blender gallery. Native geometry, animation and all gameplay src/ remain
unchanged. No monetization, balance changes or experience publication.

## Acceptance and implementation

- Eight rebuilt/refined Blender sources: Landing Shell, Lily Pad, Breeze Fan,
  Ozone Orb, Pearl Diver, Current Relay, Soft Current and Lagoon Synth.
- Coral Spark and Breeze Fan are presentation labels; stable IDs and historical
  manifest names preserved.
- Eleven requested plus16 additional mechanism refinements in BlenderChoreography.
  All78 IDs receive distinct pose-addressable transient effects with 40-part pools.
  Gallery comparison uses the unchanged native reference.
- 78 authored sounds across12 timbres/45 semitones, using existing licensed
  tone/cue assets. Mute, volume, scrub silence and pause/resume preserved.
- Gallery FX toggle, bounds-aware camera fit and per-item treatment reference.
- Native freeze encoded in AGENTS and eight-file hash manifest/CI guard.
- Original revision asset107372484175276 Approved; eight old sources, current
  sources, GLB, raw observations and binding receipts retained immutably.
- Full implementation, visual evidence and limitations:
  [Studio review](../docs/evidence/RBX-027/REVIEW.md).

## Ownership and source identity

Root owns integration, Studio, import archives and final QA. Contributors used
separate accepted-main worktrees: effects_geometry, effects_motion, effects_audio.
No contributor operated Studio or changed native sources.

Initial complete source:9f0a5b9e7984fbca1cca75d22d65b6f1c22832ed.
Final runtime source:7f7339bd3bacb427a840ed43bb2295fd6eae32f3.
Final delta fixes relay electricity previously occluded inside the opaque winding.
28 built script byte counts/hashes match the tested Studio source.

## Checks

- Required local checks pass: StyLua, Selene, 23 gameplay suites, 78 motion
  profiles, 12,792 deterministic effect samples, gallery lifecycle/instrument
  tests, three Rojo builds,45 source mappings, docs links/status fields.
- Native hash guard passes; src/ and default.project.json unchanged from07be76a.
- Catalog validation:78 models/477MeshParts/127664triangles/12archived uploads;
  eight archive corruption-regression tests pass.
- Studio all78 imported motion, all78 effects (3,276 final samples), all78 camera
  fit at strength2 (121,056 initial corners plus3,360 corrected-relay corners).
- Studio all78 sound loading, playback, time progression and nonzero output
  loudness pass; gain/voice limits and disposal pass.
- Four press/cap assemblies:808poses/10,806assertions pass.
- Actual GUI trigger, pause/resume and FX OFF behavior verified.
- All78 rendered activation poses reviewed in13contact sheets; named items and
  late chest openings additionally inspected. Static images are not video.
- Existing avatar203785492 type warning remains; no new script errors.
- Subjective listening approval not claimed. CI pending final published head.

## Handoff

- Owner/next owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/blender-effects.
- Branch/PR: published above; no unrelated checkout switched.
- Studio: coordinatorQA9f7afcd3 stopped in Edit with exact final modules/models;
  previous user gallery4a95dbcb and saved experiencef9c95fd9 preserved.
- Sync: no Rojo server/connection. Asset host place105048204331261 was used only
  for the approved upload; import workbench c719dd9a retains raw package.
- Deliverable: build/peg-blender-effects.rbxlx,
  SHA25612366dd766e60bc83fbd659ace0895d15367babfa48f53957072e3ecbc90f5de.
  Another Studio launch hit its instance-count warning; the final build was
  compared with the tested existing session instead.
- Main:07be76a, accepted13; proposed14 not accepted. No concurrent main advance.
- Blockers:none. Next action: final CI, authorized merge, bounded acceptance receipt.
- Merge:NOT MERGED. Experience publication:NOT RUN.
