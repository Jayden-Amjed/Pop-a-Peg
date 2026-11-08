# Full catalog model inspector

The catalog gallery is a separate Studio place for reviewing each model and its
activation animation. It covers all **78 registered renderable IDs**: 40 equipment
items, 13 evolutions, 8 perks, 3 Supplies and 14 utilities, chests and event props.
Search by display name or ID, inspect one model closely, and export feedback tied
to a particular pose. Only the selected model and its optional native comparison
are mounted in the preview.

The normal game retains its native geometry. The gallery evaluates the Blender
catalog; it does not adopt that geometry into gameplay or publish an experience.
The [animation direction](ITEM_ANIMATION_GUIDE.md) gives all 78 models individual
whole-object reactions, articulation and brief effects. From RBX-027 onward,
new motion, effects and sound live in gallery-only modules. Native geometry and
animation are a frozen reference at source `07be76a`; the hash manifest
`art/catalog/native-reference.json` records that boundary. The Blender adapter
can reuse those read-only baseline samples, then add its own behavior. Changing
the gallery does not update the normal game's models, motion or sound.
Use [PROJECT_STATUS](../PROJECT_STATUS.md) for current accepted state and
[RBX-021](../tasks/RBX-021-catalog-lab.md) for exact checks, source SHAs, Studio
evidence. See [RBX-023](../tasks/RBX-023-expressive-motion.md) for the expressive
animation pass, and [RBX-025](../tasks/RBX-025-review-audio.md) for the subsequent
review notes and sound pass. [RBX-027](../tasks/RBX-027-blender-effects.md) records
the subsequent Blender-only detail, effects and sound work. A registered entry
is not proof that its remote meshes loaded successfully.

## Open the inspector

From the checkout containing the catalog sources and imported runtime models:

```powershell
.\scripts\setup.ps1
New-Item -ItemType Directory -Path build -Force | Out-Null
& .\.tools\rojo.exe build catalog-gallery.project.json --output build\peg-catalog-gallery.rbxlx
```

Open `build/peg-catalog-gallery.rbxlx` in Roblox Studio and press **Play**. The
project maps `art/catalog/CatalogAssets.rbxm` to `ReplicatedStorage.CatalogAssets`; it loads
the inspector instead of the normal game. Follow the repository's
[Studio ownership and sync workflow](WORKFLOW.md) when changing target places.

Imported MeshParts still require access to their Roblox mesh assets. A missing
model, mount failure or mesh-load error is shown in the preview. Check Studio
Output and asset access, then select the model again. Opening a local `.rbxlx`
does not grant another account permission to the remote meshes.

## Controls and useful review passes

| Control | Behavior |
| --- | --- |
| Search / category button | Filters names and IDs; cycles equipment, evolutions, perks, Supplies and utilities/chests. |
| PREV / NEXT | Moves through the filtered list. |
| TRIGGER | Restarts the selected activation from its beginning. |
| SOUND ON / OFF | Enables the selected model's sound; switching off clears live and scheduled voices. |
| VOLUME | Cycles 25%, 50%, 75%, 100%; starts at 50%. |
| FX ON / OFF | Shows or hides the Blender model's transient accents without changing its articulation or the native reference. |
| PAUSE / RESUME | Holds playback, resumes it, or resumes from a scrubbed pose. |
| LOOP | Repeats the activation with a short idle interval. |
| 0.25x / 0.5x / 1x / 2x | Changes playback speed without changing the animation's normalized pose. |
| STRENGTH 1x / 2x | Compares normal and exaggerated activation movement. |
| REST | Holds the authored rest pose without idle movement. |
| Pose slider | Scrubs and holds any normalized activation pose from `0` to `1`; endpoints restore rest. |
| Front / 3/4 / Side / Rear | Changes camera direction; framing includes sampled activation bounds. |
| COMPARE NATIVE | Adds the frozen native L1 reference beside the Blender model with a shared camera fit and lighting. New Blender effects are absent from the reference. |
| LIGHT: BALANCED / ORIGINAL | Compares the shared deeper lighting rig with the previous brighter rig. |
| TAG POSE | Appends the selected ID, pose, speed, strength, camera and lighting to that item's notes. |
| COPY NOTES | Opens selectable text containing all nonempty notes from this Play session. |

All 78 entries have an explicit effect design in `CatalogEffectProfiles` and an
authored sound phrase in `GallerySoundBank`. Effects match the object's function:
lightning bridges Coral Spark's rods, Ocean Chorus emits cone echoes, Lagoon Synth
shows a traveling phase through a stationary wave, and seeds, water, clocks and
chests use their own accents. These are deterministic pose samples, so pause and
scrub hold the effect at the same pose as the mechanism. The renderer reuses at
most 40 effect parts for the selected Blender model and removes them on disposal.
Use **FX OFF** to inspect the underlying mesh and its movement separately.

Gallery sound varies spectrum, register, timing and envelope as well as melody.
Each ID has a distinct phrase; it does not simply transpose one shared beep.
`GallerySoundBank.describe(id)` exposes its design description, timbre, note and
partial counts, register, phrase duration and optional attack cue for review.

| Timbre family | Authored character |
| --- | --- |
| Glass | Bright, short inharmonic glints. |
| Bell | Longer inharmonic ringing. |
| Reed | Odd-harmonic body with vibrato. |
| Electric | Harmonic buzz and rapid amplitude modulation. |
| Water | Droplet-like downward pitch movement. |
| Air | Detuned partials, slower attack and flutter. |
| Wood | Dry, fast-decaying knocks. |
| Bass | Low impacts with a falling pitch envelope. |
| Organ | Sustained chord body and slower modulation. |
| Pluck | Sharp attack with rapidly fading upper partials. |
| Sonar | Rounded pings and upward glide. |
| Metal | Short, inharmonic strikes. |

These are additive approximations made from the existing licensed C4 sine asset,
with selected established cue assets adding quiet physical attacks. They require
no new audio upload. Gallery playback uses a separate bank and an instance-local
adapter around the unchanged game sound pool; it does not rewrite game motifs.
It caps tone voices at 12, pending partials at 32 and summed tone gain at 0.32.
The authored phrases span 45 semitones and last at most 1.06 seconds before any
separate sampled cue tail. These bounds describe the implementation, not a claim
about perceived loudness or successful playback on every account.

Cue attacks follow animation pose when speed changes; phrase pitch remains
stable. Chests retain accelerating rattles before their tier-specific opening
phrase and reward cue. Comparison plays one Blender soundtrack. Scrubbing is
silent; pausing, changing model or restarting clears previous voices. Resume
does not replay skipped cues. Volume and mute apply to that whole soundtrack.

The earlier RBX-025 pass gave Bubble Wand a vertical-axis twirl and coordinated
pop, opened and reseated the capsule cap, and added a crank plus seated squashable
coin to the Blender press. Chest performances last 3.4/3.6/3.9/4.2 seconds by tier, with
closed anticipation through pose .52, fast opening, held reveal and recovery.
That pass also made the hub wait for actual model playback completion before
replacing the chest. These are historical baseline changes; RBX-027 does not
propagate its gallery revisions back into the hub or native renderer.

Start with **REST** and inspect all four camera views for silhouette, seams,
unintended intersections and floating connections. Play **TRIGGER** at normal
speed, then use **0.25x**, **PAUSE** and the slider to locate a problem precisely.
Try strength 2x to expose clearance issues, return to 1x, and watch a repeated
activation restore its original pose. Compare lighting at the same camera and
pose so a changed shadowed face is not confused with a changed material.

The inspector displays triangle count, render-piece count and motion profile.
Its individual model view supports detailed review; passing it does not replace
checking the busiest shop, small recipe icons, rack sizing or mobile performance
before production adoption.

## Give feedback that can be reproduced

1. Select the model and camera. Scrub or pause where the issue is clearest.
2. Click **TAG POSE**, then describe what looks wrong and what you expected.
   Keep separate issues on separate lines; tag another pose when needed.
3. Include a screenshot with the model ID/frame tag visible when the shape or
   overlap is hard to describe. Add the tested commit/build and viewport size to
   the exported notes when recording formal review evidence.
4. Click **COPY NOTES**, press **Ctrl+C** on the selected export text, and paste
   it into the review conversation or a task evidence file **before stopping Play**.

Example feedback format; the observation fields are for the reviewer to fill:

```text
[spring_coil | pose 0.420 | 0.25x | strength 1 | Side | Balanced]
Observed: <the specific part, shape, overlap or movement that looks wrong>
Expected: <how that part should look or move>
Build / viewport: <commit or artifact revision; width x height>
```

Notes follow each item while navigating within the same Play session. They are
held in client memory and **do not persist when Play stops**. The export opens a
copyable text box; it does not automatically write a file, copy to the operating
system clipboard, save to a DataStore or send feedback anywhere.

## Sources, generated files and runtime models

The viewer supports mouse-wheel zoom from 60% to 250%; click **ZOOM / FIT** to
restore the full-animation framing. Zoom applies only over the model viewer,
so scrolling the library does not resize the model. Pose tags record the precise
zoom along with item, pose, speed, strength, camera and lighting. High zoom can
intentionally crop a moving part; use Fit before checking the full activation.

These are original project models built from the project's
[model style guide](MODEL_STYLE_GUIDE.md). No third-party mesh or texture pack is
required by these builders. See [asset provenance](ASSETS.md) for the project's
source policy and upload records.

| Path | Role |
| --- | --- |
| `art/catalog/<id>/<id>.blend` | Editable source for each of the 75 new catalog models. |
| `art/catalog/<id>/manifest.json` | Current source hash, geometry audit, bounds, materials, motion groups and pivots. |
| `art/catalog/index.json` | Generated index of all 78 IDs, source paths and build metadata. |
| `art/catalog/CatalogAssets.rbxm` | Engine-exported folder of all imported runtime models; includes mesh references and normalized motion metadata. |
| `art/models/<id>/<id>.blend` | Existing accepted Wave Spring (`spring_coil`), Seed Bank (`seed_bank`) and Meadow Chest (`chest_common`) pilot sources. |
| `scripts/models/catalog_mechanical.py` | 27 equipment, Supply and utility builders. |
| `scripts/models/catalog_nature.py` | 20 nature item and 13 evolution builders. |
| `scripts/models/catalog_rewards.py` | 8 perk, 3 chest and 4 event builders. |
| `scripts/models/CatalogInfo.luau` | Generated gallery names, categories, source paths and counts. |
| `scripts/models/CatalogGallery.client.luau` | Searchable inspector, playback controls and session feedback export. |
| `scripts/models/CatalogMotion.luau` | Imported-model adapter using gallery-only `BlenderChoreography`. |
| `scripts/models/BlenderChoreography.luau` | Blender articulation and whole-object overrides; reads frozen native samples as a baseline without modifying them. |
| `scripts/models/CatalogEffectProfiles.luau` | Explicit pose-addressable effect designs for all 78 IDs. |
| `scripts/models/CatalogEffects.luau` | Bounded transient-effect renderer attached only to the Blender preview. |
| `scripts/models/GallerySoundBank.luau` | Per-ID sound phrases, additive timbres, envelopes and review descriptors. |
| `scripts/models/GallerySoundEngine.luau` | Gallery-local tone scheduling over the unchanged game voice pools. |
| `scripts/models/GallerySoundTimeline.luau` | Animation-pose timing for gallery sound attacks. |
| `art/catalog/native-reference.json` | Frozen native source hashes and predecessor SHA. |
| `src/client/PreviewLighting.luau` | Shared Balanced/Original preview-lighting presets. |

The three [Blender pilots](BLENDER_PILOTS.md) are reused rather than regenerated
by the catalog builder. Their existing source hashes must match the accepted
pilot manifests. Catalog exports exclude those three from new upload batches.

## Build and export the Blender catalog

The portable toolchain uses Blender 4.5.9 LTS. Run these commands from the repository
root; Blender is needed for source editing/export, not merely opening the gallery.

```powershell
.\scripts\setup.ps1
.\scripts\setup-blender.ps1
New-Item -ItemType Directory -Path build -Force | Out-Null
$catalogMetadata = & .\.tools\luau.exe scripts\models\catalog_metadata.luau
if ($LASTEXITCODE -ne 0) { throw 'Catalog metadata evaluation failed' }
$catalogMetadata | Set-Content -Encoding utf8 build\catalog-metadata.json
& .\.tools\blender-4.5.9-windows-x64\blender.exe --background --factory-startup --python-exit-code 1 --python scripts\models\build_catalog.py -- --export
```

`build_catalog.py` evaluates coverage against the registered IDs, audits geometry
and budgets, writes the catalog index and gallery metadata, and optionally exports
GLB batches of at most eight new models. Exports, their object/calibration
manifests and `batches.json` go under ignored `build/catalog-exports/` by default.
This command does not upload assets or refresh the `.rbxm` runtime copies.

Validate the archived, uploaded revision without rebuilding geometry:

```powershell
& .\.tools\blender-4.5.9-windows-x64\4.5\python\bin\python.exe scripts\models\validate_catalog.py --expected-owner 583716264 --runtime-manifest art\catalog\runtime-artifacts.json
```

This verifies sources, manifests, exported bytes, observed mesh identities and
the engine-exported runtime artifact. Changed source geometry intentionally fails
until its new import evidence is recorded. CI runs the same pure-Python archive
check, alongside Luau motion contracts and both gallery builds.

An ordinary build loads and preserves each existing `.blend` source, including
manual Blender edits. It refreshes the source manifest and export from that file.
A missing new source is created from its Python builder. To work on just selected
models and keep a review export separate:

```powershell
& .\.tools\blender-4.5.9-windows-x64\blender.exe --background --factory-startup --python-exit-code 1 --python scripts\models\build_catalog.py -- --ids relay compass --export --upload-dir build\catalog-exports\relay-compass-review
```

**`--regenerate` overwrites selected new `.blend` sources from Python.** Without
`--ids`, it applies to all 75 new sources. Preserve intended Blender edits in Git
before deliberately using this flag; use an ordinary build after hand editing.
The three accepted pilot sources remain read-only even with `--regenerate`.

Other CLI options are `--metadata` for the evaluated catalog JSON,
`--builders-dir` for builder modules and `--output-root` for isolated artifact
generation. An alternate output root still reads accepted pilot sources from the
repository. The generated index includes the entire registry even when `--ids`
selects only a subset for building.

For a changed model, retain the exact GLB, source hashes and observed import data
for its new upload. `bind_catalog_import.py` binds those observations into a new
receipt; `NormalizeCatalogImport.luau` normalizes local clones using the imported
calibration geometry. Preserve the raw package and previous receipt, then export
the normalized catalog folder to `art/catalog/CatalogAssets.rbxm` and rebuild the gallery.
Do not point an old upload receipt at changed geometry. These tools associate
observed MeshIds with source/export bytes; they do not independently download and
rehash Roblox's remote mesh bytes. Follow [MODELING_WORKFLOW](MODELING_WORKFLOW.md)
for the surrounding source, import and review process.

Revisions use `art/catalog/revisions/index.json`: all 78 IDs explicitly select an
active receipt, and every superseded receipt/model pair retains the previous
source and manifest under `historical_sources`. Both old and new uploads remain
hash-checked; active geometry counts exclude superseded pieces. New partial
batches use exact `batchName` values in upload operation/receipt records.
`test_catalog_revisions.py` checks corruption and invalid selection failures.

## Lighting, motion and validation limits

Balanced lowers the shared ambient fill and uses a cooler directional light so
recesses and turned faces have more contrast while pearl surfaces remain readable.
Original restores the prior brighter preset for comparison. The UI's panel depth
is drawn with interface styling; the model view uses directional shading.
Roblox documents the `Ambient`, `LightDirection` and `LightColor` controls in its
[ViewportFrame lighting guide](https://create.roblox.com/docs/ui/viewport-frames#lighting-and-appearance).
ViewportFrames do not render cast shadows or post-processing effects, and glass
and neon have reduced rendering quality; see Roblox's
[ViewportFrame reference source](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/classes/ViewportFrame.yaml).
Blender render shadows are therefore not a promise of identical Studio previews.

Source coordinates use Blender X right, Y back and Z up, with front at -Y;
normalization maps them to Roblox `(X, Z, -Y)`. Shared pivots keep connected
material pieces together; separate pivots preserve individual moving mechanisms.
The runtime adapter restores frame, size and color at activation endpoints.
Transient gallery accents disappear at rest and at the activation endpoint;
they are not additional imported mesh pieces. Viewport accents simulate light,
arcs and waves with geometry and color rather than promising scene illumination
or cast shadows. Sampled preview framing includes their bounds.
This is rigid-piece animation, not a physics simulation or a skinned mesh rig.
Wave Spring compresses its mesh along the spring axis, which also changes the
wire's vertical cross-section; constant-thickness skinned coil deformation remains
a future improvement.

The pure gallery audio checks cover all 78 phrases, finite envelopes, voice and
queue bounds, mute, pause/resume, seek, loop and disposal behavior. The Studio
audio audit separately checks actual asset loading, advancing playback and
nonzero gain through complete phrase tails. Neither proves subjective quality;
listening comparisons must be recorded as observations in task evidence.

Geometry audits, offline motion checks, Studio loading, visual review, Git merge
and Roblox publication are separate facts. Sampled bounds and poses cannot prove
every possible intersection or device layout. Record actual runtime results in
the task evidence; use this guide for the repeatable workflow rather than as a
claim that every check has passed.
