# RBX-023 visual and runtime review

Tested 2026-11-08 by the coordinator through Roblox Studio MCP, Studio
0.746.0.7461269. No desktop capture helper was used.

## Source and targets

- Animation implementation: `1533ae542ed948396070f0186e819fb79599a8a4`.
- Final inspector label: `aeb64c252ef4e3d29a7cd9d63a1aee9e8ed78360`.
- Gallery QA: `9f7afcd3-3f7d-45ea-8f2d-9769db7f8564`.
- Normal game QA: `db4acb6d-7162-40f1-9d16-7a42008a07a1`.
- Source comparison: nine motion modules matched disk in normalized UTF-8 byte
  length and rolling checksum. See [verification](source-verification.json).
- The user-open gallery `70205aa0-19f5-408c-a218-f3334e58bc66` and saved
  experience `105048204331261` were not modified.

A new Studio launch did not connect while numerous Studio windows were already
open. Existing coordinator-owned, disconnected QA sessions were used in Edit,
with explicit source-only patches and change-history waypoints. Imported models
were retained. Both sessions ended in Edit, with no live sync server.

## Executed checks

| Check | Observed result |
| --- | --- |
| Local suite | Formatting/lint, 23 suites, native/Blender adapter contracts, three builds, 45 exact source mappings and doc validation passed. |
| All-model mesh audit | 78/78 loaded; 477 MeshParts; 24 cycles/model; 14976 sampled poses; restoration, shared body transform and deterministic replay passed. |
| Native audit | 78/78; three cycles at each of strengths 1/2; root transforms, connected body pieces, reduced motion and two queued triggers passed. |
| Native framing | 2575232 real part-corner checks at 160×112 and 300×260; no clipping, including perk plinths. |
| Gallery framing | 45792 corner checks across 12 held poses/model at strength 2 and default Fit; no clipping; smallest margin 0.09868. |
| Geometry archive | All source/export/import/runtime hashes still match;78 unique geometry signatures;124332 triangles; no asset uploads or geometry edits. |
| Actual playback | Six representative models played on RenderStepped for 3 seconds; transformations changed through the live interval. |
| Normal game | Real mouse input entered the hub/run and completed6shots, clearing rounds 1/2;36 mounted viewports; no new game errors. |

Reports: [Blender audit](studio-catalog-audit.json),
[native audit](studio-native-audit.json), [gallery fit](studio-gallery-fit.json),
[archive](catalog-integrity.json), [playback/game](playback-and-game.json).

The fresh game run did not reach the round 5 shop, so equipped-item procs in that
particular run were not observed. Actual item controllers, queued procs, both
preview sizes and reduced motion were instead exercised for all 78 IDs by the
native Studio audit. This distinction is intentional.

## Visual review

[Animated study](expressive-motion.gif) uses 25 captured Studio poses at synchronized
normalized phases, with a shared palette and held endpoints. It is a pose-study GIF,
not a recording of the different real-time durations. The normal inspector plays
each model at its own authored duration.

[Final inspector](final-inspector.jpg) shows Wave Spring loaded at pose 0.320,
125% zoom, with the current choreography label. The full-catalog contact sheets
below show the actual Blender assemblies at pose 0.36, normal strength:

- [Page 1](contact-01.jpg)
- [Page 2](contact-02.jpg)
- [Page 3](contact-03.jpg)
- [Page 4](contact-04.jpg)
- [Page 5](contact-05.jpg)
- [Page 6](contact-06.jpg)
- [Page 7](contact-07.jpg)
- [Page 8](contact-08.jpg)
- [Page 9](contact-09.jpg)
- [Page 10](contact-10.jpg)
- [Page 11](contact-11.jpg)
- [Page 12](contact-12.jpg)
- [Page 13](contact-13.jpg)

Reviewed visible silhouettes, connected material pieces, closed/open lid poses,
plants remaining rooted, spring socket/cap alignment, and the different object
headings during completed spins. Representative beginning/middle/end captures
cover spring, seed bank, kite, stamp, hourglass and legendary chest.

## Remaining limits

- A single contact pose is not an exhaustive geometric-intersection proof.
  All-pose automation checks bounds/restoration, not artistic appeal.
- Inspector high manual zoom can intentionally crop. Mobile inspector layout
  and access from a different Roblox account remain unverified.
- Existing unrelated avatar asset 203785492 type warnings remain.
- Approved Blender models remain in the gallery; gameplay retains native shapes.
  Both use the same new motion definitions. No game experience was published.

