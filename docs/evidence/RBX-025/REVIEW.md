# First model review and gallery audio

Reviewed 2026-11-08. Runtime implementation: **56e68f849a58c9eb8513b23cd442dd8308c7627d**.
Audio audit: 8ff7cf1; mechanism audit: 069207b. These audit-only commits do not
change runtime behavior. [Source comparison](studio-source.json) verifies all 15
staged runtime sources against the checkout after the same playtest.

## Changes

- Bubble Wand: Y-axis twirl; stem, loop and bubble pop together without ejection.
- Burst Capsule: hollow Blender mouth and rigid removable cap/pin; native cap
  also lifts, tilts and reseats as one assembly.
- Coin Press: independent top crank and bearing spindle, seated flat coin,
  measured die contact, 26% thickness at full compression and full recovery.
- All four chests: 3.4/3.6/3.9/4.2 seconds, long closed rattle, explosive opening,
  held treasure reveal and recovery. Hub waits for real animation completion.
- Every gallery entry has sound; mute, volume, silent scrubbing, cancellation,
  pause/resume and comparison share a single selected-item soundtrack.
- Fixed a navigation/audio-control overlap, disconnected input listeners on
  inspector destruction, and prevented low-frame-rate chest reveal cutoff.

## Studio evidence

Coordinator gallery9f7afcd3, Client1046x524; final fresh file4a95dbcb.
No live Rojo session. Saved experience1f468685 used only for permission checks and
one original model upload; no experience publication or player-data mutations.

| Check | Result |
| --- | --- |
| [Blender motion](studio-blender-motion.json) | 78/78; meshes load,24 repeated cycles/model,14976 sampled poses, restoration/root transform |
| [Native motion](studio-native-motion.json) | 78/78; actual builders, repeated triggers/reduced motion and two card sizes |
| [Mechanisms](studio-mechanisms.json) | 808 poses,10806 assertions; anchored coin/contact, rigid cap, crank support, endpoint restore and handle lifetime |
| [Framing](studio-gallery-framing.json) | First26 IDs include all seven changed models;16320 projected corners, minimum margin .0869 |
| [Audio1](studio-audio-1.json), [audio2](studio-audio-2.json), [audio3](studio-audio-3.json) | 78/78; loaded assets, IsPlaying, advancing playback time, positive gain and observed output loudness; cancellation/disposal pass |
| [Real controls](studio-controls.json) | Trigger/pause/resume: one completed Meadow opening, one start, nine cues, no repeated attacks; pause stopped all voices |
| Fresh file | 78 models/477 meshes, both revised IDs bound to117621047528393; Bubble Wand loaded and triggered its sound |
| Slow-frame hub regression | Actual Panel source wrapped at service boundaries: received reward survives slow animation past9s, reveal completes once, hidden/disposed preview unblocks, timeout/retry and immediate purchase pass |

Reproduce the hub check with `python scripts/models/test_hub_reveal.py --luau .tools/luau.exe`.
It reads the actual module each run (no embedded production copy). Tested source
SHA256:a862028bcbbf2eb561962104e0d8d8979a2a6a87b33c8ca44810418858d6aa7c.

Visual inspection used actual Studio captures: [press rest](press-rest.jpg),
[cap lifted](capsule-open.jpg), [Meadow reveal](meadow-open.jpg). These are static
poses; timing is supported by actual playback/control tests and motion contracts.
The first whole-catalog transfer exceeded the MCP text limit; bounded chunks were
then decoded and hash-checked before replacing the runtime artifact. The failed
truncated transfer was not accepted.

## Build and import identity

Final gallery: `.worktrees/review-pass/build/peg-model-review.rbxlx`.
SHA256: `021b6ae6a81d92c911cc0e89fe950a41c49d9a949f136599371b6764d03d03eb`.
Engine-exported catalog SHA256:
`5388562a14002a7e7aafc963e2f78aeeb1c3a67cea12b093e1a57c9e70affcdb`.
Current catalog:78 models,477 MeshParts,125572 triangles.

One approved model upload117621047528393, owner583716264, operation
`a082d5ba-3a75-4d22-a0e0-5c86a6cd054a`;14 model meshes plus3 calibration meshes.
GLB SHA256 `49d68152f119aa0cf5088fa3cdd4f7188f18937f2d0a87acbaf904c6c321c054`.
Scale measured .280000011; axis correction180-degree yaw; source colors and
anchored/noncolliding flags restored on local clones. Raw package preserved.
No image/audio uploads. Previous source bytes and all original receipts retained.

## Limits

The press die obscures much of the coin at full compression; front/side view and
slow motion help judge its thin gold edge. Audio playback/loudness is measured,
not a recording or subjective listening approval. Samples cannot prove absence
of every intersection between frames. Other-account mesh/audio permissions,
phone inspector layout and the full multiplayer game were not retested here.
The existing unrelated avatar asset203785492 type warning persists; no new game
errors appeared. Build/merge does not publish an experience.
