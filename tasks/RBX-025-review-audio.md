# RBX-025 — Model review and gallery audio

- Owner: Codex coordinator, sole Studio operator
- Status: MERGED; accepted State Version13
- Reservation: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/25
- Branch: task/RBX-025-review-audio
- Starting main: eafb1dae9a6da8c4caf22edc22cea3feeb7ba918
- Reviewed: 2026-11-08, America/Los_Angeles
- PR: https://github.com/Jayden-Amjed/Pop-a-Peg/pull/26
- Runtime evidence:56e68f849a58c9eb8513b23cd442dd8308c7627d
- Confirmed merge:84d10556eff93c98f64250e94e36a26414dc6c17
- CI:42529919325 PASS at2fc77bf63e2713a6bcb991cdfb7bcd1db8297343

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

PASS project formatting/lint,23 gameplay suites, catalog motion and gallery audio
contracts, three builds and45 mappings. PASS archive identity for all78 active
models and11 original/revision uploads; eight corruption regression tests.
PASS actual-source hub reveal harness (slow frames, cleanup, timeout/retry).
Studio at runtime SHA above:78 Blender+78 native motion,808 targetedmechanism
poses/10806assertions,26model framing/16320corners,all78 real audio playback.
Real GUI Trigger/Pause/Resume produced exactly nine Meadow cues in one cycle.
Fresh generated gallery4a95dbcb loaded and played Bubble Wand with sound.
Audit sources:8ff7cf1 and069207b; [full evidence](../docs/evidence/RBX-025/REVIEW.md).
No experience publication or live player profile mutation. Full multiplayer game
and other-account permissions NOT RUN. Existing avatar asset203785492 warning.

Implementation contributions: geometry30fd4f2, motion3fa5b95, audio cba03ab,
revision validator956e952, hub completion fix b652aee integrated into56e68f8.
Initial asset permission denial resolved after user reopened saved experience;
subsequent scope probe200 and one asset upload Approved. Full-catalog export
truncation discarded; bounded capture/hash verification succeeded.

## Handoff

- Owner: Codex coordinator; checkout .worktrees/review-pass, branch above.
- Studio: fresh gallery4a95dbcb and QA9f7afcd3 in Edit; root sole operator. No Rojo sync.
- Absolute checkout:C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/review-pass.
- User review/saved experience content preserved; no feedback discarded.
- Main fetched:84d10556eff93c98f64250e94e36a26414dc6c17, accepted13 once from12.
- Evidence: runtime56e68f8 plus linked bounded audits and archive hashes.
- Blockers:none. Limits: subjective audio listening/phone/fullmultiplayer not retested;
  coin largely covered by die at full compression.
- Next: user Play/Trigger review in peg-model-review.rbxlx; tag/copy new notes.
- Merge: MERGED. Model asset117621047528393 uploaded; experience NOT PUBLISHED.
