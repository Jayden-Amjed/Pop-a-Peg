# Blender pilot model lab

Wave Spring, Seed Bank and Meadow Chest now have original Blender models and a
separate Studio comparison gallery. The normal game still uses its native models.
This pilot tests mesh quality, restoration and animation before catalog adoption.
Use the [style guide](MODEL_STYLE_GUIDE.md) for art decisions and
[RBX-019](../tasks/RBX-019-blender-pilots.md) for exact verification evidence.

## Open the Studio gallery

From the repository checkout that contains this pilot:

```powershell
.\scripts\setup.ps1
New-Item -ItemType Directory -Path build -Force | Out-Null
& .\.tools\rojo.exe build blender-pilots.project.json --output build\peg-blender-pilots.rbxlx
```

Open `build/peg-blender-pilots.rbxlx` in Roblox Studio and press **Play**. This is an
isolated model lab; opening it does not replace or publish the game. The imported
mesh assets require Roblox access. A visible mesh-load failure in the gallery is
an access/load problem, not a successful visual test.

| Control | What it does |
| --- | --- |
| ACTIVATE ALL | Plays each model's activation, restores its pose, then resumes the shared figure-eight idle. |
| REST POSE | Holds all models at rest for close inspection. |
| OPEN / TRIGGER | Holds the middle of the activation; the chest stays open. |
| 48 / 96 / 192 px | Switches to thumbnail checks at those explicit viewport sizes. |
| BLENDER / NATIVE | Toggles the large previews between Blender and current native models using the same viewport dimensions, lighting and camera direction. Each model is fitted to its activation bounds. |
| Click a model | Triggers that individual preview. |

The small native examples remain useful for orientation, but use **BLENDER /
NATIVE** for the equal-size comparison. **ACTIVATE ALL** resumes animation after
either held-pose control. Inspect the full motion as well as the still poses.

## Models and ownership

| Model / catalog ID | Triangles | Mesh pieces | Main improvement |
| --- | ---: | ---: | --- |
| Wave Spring / `spring_coil` | 3,184 | 7 | Continuous helix with connected ends and a moving pressure cap. |
| Seed Bank / `seed_bank` | 2,040 | 8 | Pearl frame, readable golden pods and green sprouts behind a restrained glass panel. |
| Meadow Chest / `chest_common` | 3,168 | 10 | Hollow rounded shell, leaf clasp and a rear-hinged lid with an arched handle. |

The original pilot bundle was uploaded as Roblox Model asset
`112890615474684`, owned by user `583716264`, with approved moderation recorded
in [studio-import.json](../art/models/studio-import.json). It contained 26 raw
MeshParts: 25 pilot pieces and one calibration cube. These are original project
meshes, with no imported third-party models or textures.

The engine-exported runtime copy is
[BlenderPilots.rbxm](../art/models/BlenderPilots.rbxm). Only
[blender-pilots.project.json](../blender-pilots.project.json) maps it into
`ReplicatedStorage.BlenderPilots`; the default game project does not load it.
Git stores the runtime container and editable sources, but cannot grant access
to the Roblox mesh assets. Loading under another account or another owner's
experience remains unverified. Uploading this model asset did not publish the game.

## Blender setup and ordinary exports

The project uses portable **Blender 4.5.9 LTS** inside `.tools/`, with no global
installation required:

```powershell
.\scripts\setup-blender.ps1
.\scripts\build-models.ps1 -Render
```

Setup downloads the Windows x64 ZIP from the
[official Blender release directory](https://download.blender.org/release/Blender4.5/)
and verifies SHA256
`41da973b9bf95bb312cbeff4d1982feb13259b43c821686b9bafea4dfe5477cf`
before extraction or execution. It also checks the executable's reported version.

Open any editable source with the portable executable, for example:

```powershell
& .\.tools\blender-4.5.9-windows-x64\blender.exe art\models\chest_common\chest_common.blend
```

Each `art/models/<catalog-id>/<catalog-id>.blend` is the editable geometry source.
An ordinary build opens those files, audits and exports them without saving changes
back into them. It emits individual GLBs, a combined calibration bundle, candidate
manifests, an audit summary and motion-audit JSON under ignored
`build/model-exports/`. `-Render` also creates individual PNG previews there.
The committed `art/models/<catalog-id>/manifest.json` files describe the uploaded
revision; an ordinary export deliberately does not overwrite those records.

The Python builders are useful for regenerating a procedural starting point:

```powershell
.\scripts\build-models.ps1 -Regenerate -Render
```

**`-Regenerate` overwrites the `.blend` sources from Python.** Use an ordinary build
after editing in Blender; use regeneration when deliberately replacing those edits
with the scripted construction. If a source `.blend` is missing, the build creates
it from its builder. Preserve source edits in Git before intentional regeneration.

## Coordinate and import contract

Author in studs with Blender X right, Y back and Z up; the front is -Y. The source
uses unit system `None`. The exporter creates temporary copies at 0.28 meters per
stud, exports GLB with Y-up, then discards the copies. Source objects remain in
authoring units. Meshes carry explicit `motion_group` and, where needed,
`motion_pivot` custom properties; keep independently moving pieces separate.

This particular Studio import produced a **0.28-stud calibration cube**, not the
intended one-stud cube. Its local pilot copies were repaired with scale `1/0.28`,
a measured 180-degree yaw correction, and restored source sRGB colors after the
import arrived gray. The normalizer also restores glass transparency, articulation
metadata and direct MeshPart children, and disables collision, touch and query.
These are observed corrections for this upload, not universal importer settings.
The raw uploaded package stays separate; the local repairs do not update it.

## Edit, reimport and verify a new revision

1. Edit the appropriate `.blend`, following the style guide. Preserve stable
   catalog IDs, deliberate moving groups, coherent pivots and one material per
   render piece. Keep preview geometry nonphysical.
2. Run `build-models.ps1 -Render`. Review the candidate manifests and images, mesh
   counts, manifold/degenerate-face checks and motion audit. Inspect front, rear,
   side and activated poses. Automated geometry checks do not establish appearance.
3. Import the new exported bundle into an isolated Studio target using the
   [Studio workflow](WORKFLOW.md#agent-workflow-through-mcp). Use the intended
   creator's existing asset permissions and approved upload folder. Record the new
   upload operation, moderation result, model/mesh IDs and the actual hierarchy.
4. Recheck calibration, orientation, materials and moving pivots from that observed
   import. Capture the new uploaded bytes, manifests and observed identity evidence;
   normalize only after those records agree. Export the reviewed runtime model
   through Studio and rebuild the gallery from that saved artifact.
5. Play the rebuilt gallery. Check the equal-size native comparison, 48/96/192px
   silhouettes, glass, full activation, return to rest, repeated triggers and idle
   handoff. Run `scripts/models/StudioPilotAudit.luau` in the gallery's **Client**
   DataModel after it reports Ready. It checks expected MeshPart counts, provenance
   metadata, physics flags, bounded motion, 12 activation cycles and exact return
   of transforms, sizes and colors, plus paused/resumed idle.
6. Save actual Studio captures and the exact tested source SHA in the task record.
   Review source, manifest, asset identity and runtime-export changes together.
   Catalog adoption is a separate implementation step; this gallery alone does not
   change normal item rendering.

`scripts/models/capture_import.py` is an evidence replay for the **recorded upload**,
not a generic importer. It pins the archived GLB, three uploaded manifests and raw
Studio observations before associating the 25 MeshIds. It refuses changed evidence.
Do not edit its hashes merely to make a new export pass: a new geometry revision
needs its own observed upload record. The replay does not download and independently
rehash Roblox's mesh bytes.

The current Wave Spring animation axially scales a rigid MeshPart, so its wire
cross-section changes during compression. A skinned coil preserving constant wire
thickness is a future improvement. Offline motion tests sample selected interfaces
and poses; they are not exhaustive swept-volume or visual proofs. Inspect Studio
renders separately from geometry audits, repository checks, merge and publication.

Reference documentation: [Roblox Blender guidance](https://create.roblox.com/docs/art/blender),
[Studio importer](https://create.roblox.com/docs/studio/importer),
[Roblox modeling specifications](https://create.roblox.com/docs/art/modeling/specifications),
[Blender glTF export](https://docs.blender.org/manual/en/latest/addons/scene_gltf2.html)
and [applying transforms](https://docs.blender.org/manual/en/latest/scene_layout/object/editing/apply.html).
