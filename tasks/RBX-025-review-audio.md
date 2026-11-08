# RBX-025 — Model review and gallery audio

- Owner: Codex coordinator, sole Studio operator
- Status: IN PROGRESS
- Reservation: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/25
- Branch: task/RBX-025-review-audio
- Starting main: eafb1dae9a6da8c4caf22edc22cea3feeb7ba918
- Reviewed: 2026-11-08, America/Los_Angeles
- PR: opening draft

## Objective and scope

Apply Bubble Wand, Burst Capsule, all chest and Coin Press feedback. Add sound
preview for every gallery entry. Preserve scoring, progression and approved art
outside the requested edits. No game experience publication.

## Acceptance

- Coherent alternate-axis Bubble Wand pop; removable and reseated capsule cap.
- Long chest anticipation followed by explosive opening and held reveal.
- Blender press crank and under-die coin with squash/recovery.
- Gallery audio covers all 78 entries, aligns with motion and cancels on pause,
  selection, restart and scrubbing; mute/volume controls remain usable.
- Tests, actual Studio visual/audio checks and source/import provenance recorded.

## Ownership and dependencies

Root owns gallery UI/mappings, native geometry, import/runtime archives and docs.
Separate accepted-main worktrees: review_geometry owns two Blender sources and
mechanical builder; review_motion owns choreography/adapters and motion tests;
review_audio owns audio lifecycle/signatures and audio tests. Geometry group and
impact timing contracts coordinated before integration. Existing user galleries
and root starter checkout preserved. Reservation/remote branches inspected.

## Checks

Implementation and runtime checks: NOT RUN. Current baseline accepted version12.

## Handoff

- Owner: Codex coordinator; checkout .worktrees/review-pass, branch above.
- Studio: coordinator QA gallery9f7afcd3; root is sole operator. No Rojo sync.
- User review gallery d9ee27c1 preserved; no unsaved feedback discarded.
- Evidence: starting main above; proposed acceptance version13, not accepted.
- Blockers: none observed. Asset permission/import verification pending.
- Next: integrate disjoint changes, import only revised geometry, test gallery.
- Merge: NOT MERGED. Publication: NOT RUN.
