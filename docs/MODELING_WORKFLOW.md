# Modeling workflow: native builders and Blender pilots

The game currently builds its models in `src/client/ItemModels.luau`; it does not
load a Blender asset library. Keep that reproducible path while testing a small
Blender pipeline for cleaner curved surfaces and more deliberate silhouettes.
Follow the [style guide](MODEL_STYLE_GUIDE.md), [ownership policy](SYSTEM_OVERVIEW.md#ownership-and-restoration)
and [Studio workflow](WORKFLOW.md#agent-workflow-through-mcp).

## Tool availability and scope

On 2026-11-08, a read-only check found no `blender` command on PATH and no standard
`C:\Program Files\Blender Foundation` folder. No Blender MCP tool was advertised.
A portable installation elsewhere is unknown. No Blender installation, mesh
conversion, import, upload or publication was performed by this documentation task.
Record the actual Blender/exporter version before a pilot; do not describe the
proposed scripts below as existing tools.

## Three pilots before a catalog conversion

| Pilot | What it must demonstrate |
| --- | --- |
| Wave Spring (`spring_coil`) | A continuous clean helix, stable end connections and compression without self-intersection |
| Seed Bank (`seed_bank`) | Pearl frame, readable seeds behind a restrained glass window, crisp small-scale silhouette |
| Meadow Chest (`chest_common`) | Distinct body/lid, a correct rear hinge, readable opening and return to rest |

Compare each with its native model in the same UI lighting, camera, size and
animation. Adopt a mesh only when it improves that comparison and stays inside
the agreed runtime budget. A failed pilot stays on the native builder. Expand
to other items after the import, restoration and animation steps are repeatable.

## Author, export and inspect

1. **Block out the object.** Use the stable catalog ID as the root name, with
   explicit fixed and moving groups. Review silhouette thumbnails before detail.
   Use scriptable Blender primitives, curves, bevels and repeated structures for
   quick variants, then inspect and refine their proportions and joins by eye.
   Automation produces candidates; it does not establish visual acceptance.
2. **Set the frame and dimensions.** Use a 1-unit calibration cube and compare it
   with a 1-stud Studio part. Establish a single preset with Blender unit system
   `None`, rotation in degrees and matching Studio import units. Verify the final
   Roblox +Y-up/+Z-front frame instead of stacking speculative axis corrections.
   For FBX, Roblox recommends `Apply Scaling: FBX Unit Scale` with other scale
   values at 1; glTF avoids those extra FBX scaling settings. Follow the current
   [Roblox Blender guidance](https://create.roblox.com/docs/art/blender).
3. **Prepare clean export geometry.** Save the editable source first. Apply
   rotation/scale on export copies, inspect modifier results, and preserve hinge
   origins rather than blindly applying Location. Blender documents that applying
   Location moves the origin, while rotation/scale application can affect parent
   and modifier behavior. See [Apply transforms](https://docs.blender.org/manual/en/latest/scene_layout/object/editing/apply.html).
   Check face orientation, recalculate outward normals where appropriate and
   inspect custom shading separately; recalculation does not repair every custom
   normal issue. See [Editing normals](https://docs.blender.org/manual/en/latest/modeling/meshes/editing/mesh/normals.html).
4. **Export a selected collection.** Prefer a `.glb` pilot; use `.fbx` as the
   compatibility fallback. Export evaluated geometry with normals and needed UVs,
   omit scene lights/cameras, and keep moving objects separate. glTF's modifier
   export evaluates the resulting mesh; Y-up and custom-property export are
   explicit settings. Record the chosen options and verify the result rather than
   assuming Blender procedural materials, drivers or custom properties become
   equivalent Roblox behavior. See [Blender glTF export](https://docs.blender.org/manual/en/latest/addons/scene_gltf2.html).
   Inspect triangulated output, thickness and closed surfaces against
   [Roblox mesh specifications](https://create.roblox.com/docs/art/modeling/specifications).
5. **Import into an isolated development target.** Review the preview and warnings,
   calibration, materials and object pivots. Keep mesh merging disabled when it
   would combine independently moving parts. `Use Imported Pivot` preserves an
   authored object pivot, but does not automatically configure our motion adapter.
   GLB/glTF may create nested Models and multiple MeshParts per mesh, unlike FBX;
   node names can receive suffixes. Capture the actual hierarchy, not a guessed
   name mapping. See [Studio Importer](https://create.roblox.com/docs/studio/importer).
6. **Adapt, then test.** Normalize imported render parts into the structure expected
   by `ItemModels.create` and `ItemMotion`, preserving their world transforms.
   Reconstruct `MotionGroup` and authored-space `MotionPivot` from a reviewed
   manifest; then let the existing adapter tag positions, calculate `ArtCenter`
   and center the model. Its current motion code enumerates direct `BasePart`
   children, so glTF wrapper Models cannot simply be dropped into it unchanged.
   Keep Luau-driven idle and activation for these rigid pilots. Bone animation is
   a separate future path, not an automatic part of mesh import.

Decorative preview meshes need no physical interaction. Keep `CanCollide`,
`CanTouch` and `CanQuery` false and select inexpensive Box/Hull collision fidelity.
For future hub props, use simple separate collision shapes where practical.
Precise convex decomposition remains an approximation and costs more; it is not a
way to fix visible model intersections. See [Roblox collisions](https://create.roblox.com/docs/workspace/collisions)
and [performance guidance](https://create.roblox.com/docs/performance-optimization/improve).

## Repeatable source and delivery

Proposed layout for the first pilot:

| Path | Authority / purpose |
| --- | --- |
| `art/models/<id>/<id>.blend` | Editable authoring source; one approved version |
| `art/models/<id>/manifest.json` | Source revision, dimensions, group/pivot mapping, export preset, asset IDs, ownership and license |
| `scripts/models/` | Future deterministic build/export/audit scripts with a pinned Blender version |
| `build/model-exports/` | Regenerable GLB/FBX files and inspection images |
| `assets/models/<id>.rbxmx` | Reviewed Studio runtime export referencing approved mesh/texture assets |

These are planned paths, not an implemented loader. Keep `.blend` authoring files
outside the Rojo-mapped `assets` subtree. The `.rbxmx` is the runtime import result,
not a competing editable geometry source. Introduce a narrow catalog-ID adapter
for adopted pilots, retain the native fallback during evaluation and document
restoration in `ASSETS.md`. A local GLB is not automatically a deployable Roblox
mesh: asset ownership, access, moderation and observed IDs must be recorded after
the actual import. A fresh clone must be able to identify every dependency.

A future batch script should load the approved blend, export only its named
collection, validate counts/normals/group names, emit the manifest and generate
fixed-camera contact sheets. Use Blender background execution and an explicit
Python error exit code so a failed export fails the job. The official
[command-line reference](https://docs.blender.org/manual/en/4.2/advanced/command_line/arguments.html)
documents those controls; match flags to the pinned installed version. Keep
machine-generated candidates separate from accepted sources, and inspect the
Studio result before replacing a native model.

Pilot evidence must include source/export versions, hashes, actual triangle and
render-piece counts, the imported hierarchy, motion checks and the style-guide
checklist. Run the repository checks and extend the native model audit to cover
MeshPart identity/metadata; its current primitive geometry signature does not
compare imported mesh topology. Record visual QA independently from scripts,
Git integration and Roblox publication.
