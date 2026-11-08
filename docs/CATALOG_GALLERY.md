# Full catalog model inspector

The catalog gallery is a separate Studio place for reviewing each model and its
activation animation. It covers all **78 registered renderable IDs**: 40 equipment
items, 13 evolutions, 8 perks, 3 Supplies and 14 utilities, chests and event props.
Search by display name or ID, inspect one model closely, and export feedback tied
to a particular pose. Only the selected model and its optional native comparison
are mounted in the preview.

The normal game retains its native geometry. The gallery evaluates the Blender
catalog; it does not adopt that geometry into gameplay or publish an experience.
Shared preview lighting and UI depth/contrast styling are separate changes.
Use [PROJECT_STATUS](../PROJECT_STATUS.md) for current accepted state and
[RBX-021](../tasks/RBX-021-catalog-lab.md) for exact checks, source SHAs, Studio
evidence and remaining work. A registered entry is not proof that its remote
meshes loaded successfully.

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
| PAUSE / RESUME | Holds playback, resumes it, or resumes from a scrubbed pose. |
| LOOP | Repeats the activation with a short idle interval. |
| 0.25x / 0.5x / 1x / 2x | Changes playback speed without changing the animation's normalized pose. |
| STRENGTH 1x / 2x | Compares normal and exaggerated activation movement. |
| REST | Holds the authored rest pose without idle movement. |
| Pose slider | Scrubs and holds any normalized activation pose from `0` to `1`; endpoints restore rest. |
| Front / 3/4 / Side / Rear | Changes camera direction; framing includes sampled activation bounds. |
| COMPARE NATIVE | Adds the current native L1 model beside the Blender model with a shared camera fit and lighting. |
| LIGHT: BALANCED / ORIGINAL | Compares the shared deeper lighting rig with the previous brighter rig. |
| TAG POSE | Appends the selected ID, pose, speed, strength, camera and lighting to that item's notes. |
| COPY NOTES | Opens selectable text containing all nonempty notes from this Play session. |

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
| `scripts/models/CatalogMotion.luau` | Imported-model adapter using shared `ItemMotion` activation profiles. |
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
This is rigid-piece animation, not a physics simulation or a skinned mesh rig.
Wave Spring compresses its mesh along the spring axis, which also changes the
wire's vertical cross-section; constant-thickness skinned coil deformation remains
a future improvement.

Geometry audits, offline motion checks, Studio loading, visual review, Git merge
and Roblox publication are separate facts. Sampled bounds and poses cannot prove
every possible intersection or device layout. Record actual runtime results in
the task evidence; use this guide for the repeatable workflow rather than as a
claim that every check has passed.
