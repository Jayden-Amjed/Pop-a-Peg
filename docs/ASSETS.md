# Model and sound sources

The board and arcade architecture use original native Roblox geometry. Equipment,
perks, Supplies, chests and currency previews now use the original Blender catalog
through GameItemModels. They depend on the owner-account MeshIds documented below.
The frozen native catalog remains available for explicit load failure fallback
and review comparison. Source art and import receipts are shared by game/gallery.

## Complete Blender catalog (RBX-021)

The [catalog inspector](CATALOG_GALLERY.md) adds 75 original Blender models and
reuses the three accepted pilots. At RBX-021 its 78 models contained 477 MeshParts and 124,332
triangles in total; only the selected preview and optional native comparison are
mounted for rendering. No downloaded models, third-party textures or AI images
were used. Sources, individual audit manifests and exact uploaded bytes are in
`art/catalog/`; the original three sources remain under `art/models/`.

Ten Model assets, revision 1, were uploaded to user **583716264** on 2026-11-08:

| Batch | Model asset ID |
| --- | --- |
| 001 | 121823491792990 |
| 002 | 82869341823394 |
| 003 | 76963303869520 |
| 004 | 93776112267831 |
| 005 | 134876655398379 |
| 006 | 120222779256970 |
| 007 | 80156916896305 |
| 008 | 136647282144366 |
| 009 | 127932056297541 |
| 010 | 134841234052716 |

[Observed upload responses](../art/catalog/uploaded/receipts.json) record Approved
for every batch. Each batch retains its GLB, manifest, raw Studio observation and
bound receipt. Three calibration cubes measure scale/orientation; normalized local
clones restore colors, transparency, explicit pivots and nonphysical flags. The raw
packages stay unchanged. The aggregate
[runtime folder](../art/catalog/CatalogAssets.rbxm) is engine-serialized and mapped
by both the game and gallery projects. `validate_catalog.py` verifies the archived chain;
these receipts do not independently download and rehash Roblox's mesh bytes.
Owner-account Studio loading passed for all 477 meshes. Another account's access
remains unverified. Asset upload did not publish or update the game experience.

## Blender pilot assets (RBX-019)

Wave Spring, Seed Bank and Meadow Chest are original meshes authored for this
repository with Blender 4.5.9 LTS and the project style guide. No downloaded model,
texture or generated raster was used. Editable `.blend` sources, Python generators,
the exact uploaded GLB and import evidence are retained under `art/models/`.

Model asset **112890615474684**, revision 1, is owned by user **583716264**;
Roblox returned Approved on 2026-11-08. Its 26 meshes are 25 pilot render pieces
plus a calibration cube. [studio-import.json](../art/models/studio-import.json)
records every observed MeshId, geometry signature, source mapping and upload proof.
The engine-serialized [BlenderPilots.rbxm](../art/models/BlenderPilots.rbxm)
contains normalized local copies of the 25 pilot pieces. It preserves those MeshIds
and is mapped only by `blender-pilots.project.json`. The same three designs are
included in the complete `CatalogAssets.rbxm` used by the game from RBX-029.

Import correction was observed, not assumed: the 1-stud cube arrived at 0.28 studs,
all materials were gray, and front-facing geometry was reversed. The local copies
restore source dimensions (scale 1/0.28), yaw 180 degrees, sRGB colors, glass and
motion metadata. The raw uploaded package is not changed by those local repairs.
No textures were uploaded. Mesh loading was verified under the owner's account;
another account/experience must verify asset access before adoption. A failed mesh
preload marks the gallery unavailable instead of reporting Ready.

See [Blender pilot workflow](BLENDER_PILOTS.md) for restoration and revision steps.
Asset upload is separate from publishing an experience; no experience update was
published by this task.

## Native environment and preserved reference assets

`HubWorld` builds an original aquarium arcade: eight detailed cabinets,
walkable pearl/aqua atrium, safety glazing, paths, plants, seating, arches, gallery,
records kiosk, chest pavilion, leaderboard gallery and a central modeled fish tank.
`HubAmbience` animates fish/bubble groups locally while the hub is visible, restores their
rest poses on exit, and respects reduced motion. No external hub model, texture,
mesh, music or paid asset is required. Player avatars use Roblox's normal character
loading rather than an imported character asset.
Seafoam floor fields, pearl walking routes, dark teal borders and approach
chevrons separate the arcade's areas. Large cabinet numbers, a reef arch, coral,
pearls, a layered lagoon base and glass canopy add depth without changing station
positions, collision geometry or the existing ambient animation groups.
The local cabinet guide uses native BillboardGui and Highlight objects, not
uploaded textures or a replicated effect.

`BoardArt` builds the pearl/aqua enclosure and attached status monitor from original
native parts. Rounded shell layers, water-depth bands, curved side channels, leaf
accents and bubble glints are original geometry. The monitor adds a pearl crown,
layered aqua seal, cheek vents, leaves, cable collars and hinge, bubble antenna,
inset progress channel, and four campaign indicator lights. Its text is projected
by the interface; the decorative structure and lights are physical parts. All
board decorations are opaque, anchored, noncolliding and shadowless, and do not
participate in simulated collisions.

`ItemModels` registers **78 distinct original native models**: 40 base equipment,
13 evolutions, eight perks, three Supplies and 14 utility/reward objects. Evolved items include
Aurora Aquarium, Spectrum Reef, Tidal Engine, Storm Clock, Horizon Observatory,
Eden Greenhouse, Pearl Turbine, Current Nexus, Ocean Orchestra, Bubble Reactor,
Solar Treasury, Sun Koi and Tide Gyroscope. Equipment has accents for five upgrade
tiers; evolved items use the maximum tier. Recipes compose existing source models
inside square ViewportFrames and require no separate image assets.

The expanded equipment set adds 18 original silhouettes and moving mechanisms.
Perk builders have their own geometry rather than reusing equipment. Meadow,
Lagoon, Aurora and Celestial chest models each have a different body/lid design and
hinged opening animation. Growth, repair, upgrade and overtime event prompts use
their own emblems. The model audit checks geometry independent of colors, names
and motion tags, so a recolor cannot pass as a distinct model. It also checks
noncolliding preview parts, bounded geometry, required moving groups and restoration
after activation; exact observed audit results are recorded with task evidence.

`ItemModels` removes the generic white display circle from equipment, currencies
and Supplies while retaining it on perks. Previews now render a single model.
The enlarged black clone layer was removed because it showed a displaced copy
and dark interior shapes through glass. Generic bounds-derived upgrade rails,
nodes and bars were removed because they floated around several device shapes.
Authored builder details and UI level badges remain. Remounting disposes the
previous owned model/camera; stale handles cannot clear the replacement camera.
The [model guide](MODEL_STYLE_GUIDE.md) and [workflow](MODELING_WORKFLOW.md) define
clean joins, readable silhouettes, motion clearance and future mesh pilots.
The 4.2-second figure-eight cycle is defined in `ItemMotion` and
is shared by equipment, perk-choice, event and hub previews. A trigger or chest
opening pauses that idle pose, runs the appropriate activation and resumes idle
motion; reduced-motion/static mounts can disable the idle cycle.

Dense trigger bursts, swirls, beams, impact rings, ribbons and the evolution
celebration use native GUI geometry. Decorative effects are capped at 184 entries
within a 240-entry total, leaving capacity for 56 counter/reward arrivals. Reduced
motion uses three particles per burst and removes orbiting motion. These effects
add no external textures, meshes or uploaded effect assets.

The short feedback sounds use public Creator Store audio:

| Asset | Creator | Use |
| --- | --- | --- |
| [CoinTransfer_01 — 127645268874265](https://create.roblox.com/store/asset/127645268874265) | Roblox | Coin delivery and purchases |
| [Suction Pop 5 — 9119669074](https://create.roblox.com/store/asset/9119669074) | ProSoundEffects | Button clicks |
| [Soccer Ball Bounces Hits On Grass 4 — 9119319842](https://create.roblox.com/store/asset/9119319842) | ProSoundEffects | Soft, short peg impact and launch thump |
| [Sine Wave (C4) — 77129402344871](https://create.roblox.com/store/asset/77129402344871) | orxnl | Base oscillator sample for distinct item/perk/consumable note motifs |
| [Store Entry Bell 1 — 9119642864](https://create.roblox.com/store/asset/9119642864) | ProSoundEffects | Quota crossings and board clear |
| [DVD Disc Drops 6 — 9114210044](https://create.roblox.com/store/asset/9114210044) | ProSoundEffects | Mechanical refill and merge impacts |
| [Tone Clusters 26 — 9126132550](https://create.roblox.com/store/asset/9126132550) | ProSoundEffects | Optional generic trigger cue |

Roblox's [2D audio tutorial](https://create.roblox.com/docs/tutorials/use-case-tutorials/audio/add-2D-audio)
uses the coin asset for currency feedback. The [audio assets documentation](https://create.roblox.com/docs/audio/assets)
describes the Creator Store's free licensed sound library. These IDs are used in
Roblox; raw third-party audio files are not redistributed by this repository.

On 2026-11-07, Creator Store metadata identified the creators above and all seven IDs loaded
successfully in the local Studio target using ContentProvider. Source-defined
pitch, volume, short playback windows, bounded voice pools, and per-cue rate
limits keep large trigger chains from overwhelming the mix. A visible sound
toggle mutes the group. Missing audio never blocks gameplay.

`ItemFeedback` defines distinct short pitch/rhythm signatures for catalog
entries, including four-note motifs for all 13 evolutions. They reuse the existing
C4 sample; evolutions introduce no new audio IDs. That sample is a public Creator
Store sine wave described by its creator
as generated in Audacity. Its pitches follow semitone ratios; a short attack/decay
envelope shapes each note. Twelve shared tone voices, 32 pending notes, and motif
rate limits bound dense chains. No item needs an individual uploaded sound file.

Item timbres now have three weights. Light glass/water items keep the bright
register; rounded mechanisms move down five semitones; heavy mechanisms move down
an octave and add a short falling sine impact. Burst Capsule, Wave Spring and Dew
Cell are heavier original items. Tide Valve, Moss Capacitor, Nectar Pump, Lagoon
Synth, Ozone Orb and Monsoon Loom add heavy discovery sounds; six mechanical
evolutions carry that weight forward. Reef Chime, Goldfish, Bubble Wand and Spectrum
Reef remain light. Every item retains its distinct pitch/rhythm motif.

The bass impact drops to approximately 65–98 Hz in 55 ms and fades within
180–280 ms. Smooth attack/release envelopes avoid abrupt amplitude edges. Bass
uses the same C4 asset through native
[Sound.PlaybackSpeed](https://create.roblox.com/docs/reference/engine/classes/Sound#PlaybackSpeed),
so it adds no external asset dependency or DSP instance. All melody and bass
notes share the existing 12-voice/32-note limits. Their summed volume is capped
at 0.34 before the 0.7 feedback-group gain, reserving mix space for coins and goals.
Restock and merge mechanical cues have lower pitches and slightly softer volume.
These bounds and envelope/pitch behavior have automated coverage; actual asset
loading, playback and subjective listening are separate Studio checks.

Availability can change: recheck preloading and playback in the target experience
before publishing. Studio loading does not establish publication or future access.

## RBX-025 model revision and gallery audio

One new original Model upload, asset **117621047528393**, belongs to user
**583716264**. Operation `a082d5ba-3a75-4d22-a0e0-5c86a6cd054a` returned Approved.
It contains the revised Burst Capsule and Coin Press (14 model meshes plus three
calibration meshes); no textures or audio assets were uploaded. Exact bytes and
observed identities are retained under `art/catalog/revisions/RBX-025/`.
The raw package remains unchanged. The gallery uses normalized local copies with
measured .28 scale correction, orientation, restored colors and physics flags;
reinserting/updating the raw package does not apply those local repairs.

At RBX-025, gallery audio reused the documented game assets and 64 item motifs, adding
explicit utility mappings and chest cue timing. All 78 entries passed Studio
asset loading, active playback and advancing time checks; output loudness was
observed. This establishes runtime playback, not subjective listening approval.

## RBX-027 Blender-only refinement

Original Model asset **107372484175276**, owned by **583716264**, contains eight
revised models (48 model meshes and three calibration meshes). Operation
`a1daa18e-9157-4506-8a3c-0c45f69ccfa4` returned Approved. Sources, previous sources,
GLB, observation and binding receipt are retained under
`art/catalog/revisions/RBX-027/`; the active revision index resolves each model.
The raw upload is preserved. Runtime copies have the measured .28 scale correction,
orientation, colors, articulation metadata and inert physics flags restored.

The gallery now uses 78 authored sound phrases across 12 additive timbre families.
It reuses the existing licensed tone/cue assets: no new audio or textures were
uploaded. Transient visual effects use local primitive pools, not external assets.
Native models, animation and gameplay audio remain unchanged. The task record
distinguishes offline checks, Studio verification and subjective review.
