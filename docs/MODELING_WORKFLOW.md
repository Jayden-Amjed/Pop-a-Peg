# Modeling workflow: Blender catalog and frozen native reference

RBX-029 explicitly adopts the [Blender catalog](CATALOG_GALLERY.md) into game
previews through `GameItemModels`. The game and separate inspector consume the
same imported catalog and Blender motion/effect sources. **Original native
builders and choreography remain frozen** as fallback/reference; keep new
integration separate from those files. Game adoption does not publish an experience.
Follow the [style guide](MODEL_STYLE_GUIDE.md), [ownership policy](SYSTEM_OVERVIEW.md#ownership-and-restoration)
and [Studio workflow](WORKFLOW.md#agent-workflow-through-mcp).

## Tool availability and scope

RBX-019 installed checksum-verified portable Blender **4.5.9 LTS** in the task's
ignored `.tools` directory and implemented the three pilots below. It uses the
Blender CLI/Python API and Roblox Studio MCP; no Blender MCP is required.
Follow the [catalog guide](CATALOG_GALLERY.md) for all 78 models, preserved-source
exports, import receipts and individual animation feedback. The earlier
[pilot guide](BLENDER_PILOTS.md) retains the three-model comparison workflow.
The game and separate gallery use imported meshes. Earlier tasks retain their own Studio
evidence; each new revision needs its own loading and visual checks. Model upload
does not publish an experience, and a successful Blender render does not establish
that the current Studio revision has passed review.

## Original pipeline pilots

| Pilot | What it must demonstrate |
| --- | --- |
| Wave Spring (`spring_coil`) | A continuous clean helix, stable end connections and compression without self-intersection |
| Seed Bank (`seed_bank`) | Pearl frame, readable seeds behind a restrained glass window, crisp small-scale silhouette |
| Meadow Chest (`chest_common`) | Distinct body/lid, a correct rear hinge, readable opening and return to rest |

These pilots established the original comparison workflow. Compare lighting,
camera, size and rest pose with the frozen native reference where useful, while
reviewing Blender-only motion on its own merits. Keep revisions within the
agreed runtime budget. Check updated Blender behavior in the gallery and actual
game cards while keeping the native comparison unchanged.

## Author, export and inspect

1. **Block out the object.** Use the stable catalog ID as the root name, with
   explicit fixed and moving groups. Review silhouette thumbnails before detail.
   Use scriptable Blender primitives, curves, bevels and repeated structures for
   quick variants, then inspect and refine their proportions and joins by eye.
   Automation produces candidates; it does not establish visual acceptance.
   For an accepted model, inspect its existing source and tagged feedback first.
   Preserve unrelated geometry; rebuild a whole object only when that matches the
   requested change. Give each mechanism its own proportions and moving groups.
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
6. **Adapt, then test.** Normalize imported render parts into the catalog adapter's
   direct-child structure, preserving their world transforms.
   Reconstruct `MotionGroup` and authored-space `MotionPivot` from a reviewed
   manifest; then let the existing adapter tag positions, calculate `ArtCenter`
   and center the model. Its current motion code enumerates direct `BasePart`
   children, so glTF wrapper Models cannot simply be dropped into it unchanged.
   Put new articulation in `scripts/models/BlenderChoreography.luau` and
   `CatalogMotion.luau`; native motion stays read-only. Keep transient
   effects in `CatalogEffectProfiles.luau` and `CatalogEffects.luau`, separate from
   the authored mesh. `CatalogEffectAnchors` records physical origins, directions
   and attachment groups: inspect the modeled plate, nozzle, cone, lens or contact
   before assigning the effect. Transform that attachment through the posed
   assembly, including its rotation and scale. Gate impacts to actual contact,
   and verify the contact at reduced strength as well as normal strength.
   A functional light may brighten locally and briefly while
   the object keeps contrasting mass; verify exact material/color restoration.
   Keep Luau-driven idle and activation for these rigid models. Bone animation is
   a separate future path, not an automatic part of mesh import.

Decorative preview meshes need no physical interaction. Keep `CanCollide`,
`CanTouch` and `CanQuery` false and select inexpensive Box/Hull collision fidelity.
For future hub props, use simple separate collision shapes where practical.
Precise convex decomposition remains an approximation and costs more; it is not a
way to fix visible model intersections. See [Roblox collisions](https://create.roblox.com/docs/workspace/collisions)
and [performance guidance](https://create.roblox.com/docs/performance-optimization/improve).

## Repeatable source and delivery

Current catalog layout, with the original pilot sources retained:

| Path | Authority / purpose |
| --- | --- |
| `art/catalog/<id>/<id>.blend` and `manifest.json` | Current editable catalog source, hash, geometry audit, groups and pivots |
| `art/models/<id>/<id>.blend` and `manifest.json` | Accepted Wave Spring, Seed Bank and Meadow Chest pilot sources; ordinary catalog builds preserve them |
| `scripts/models/` | Targeted revision recipes, non-destructive export, Blender motion/effects shared by game and gallery, and inspection tools |
| `build/model-exports/` / `build/catalog-exports/` | Regenerable export candidates and inspection images; not import receipts |
| `art/catalog/CatalogAssets.rbxm` | Engine-serialized imported runtime folder mapped into game and gallery |
| `src/client/GameItemModels.luau` | Game lifecycle/viewport adapter consuming the imported catalog and shared Blender behavior |
| `src/client/GameSoundEffects.luau` | Game wrapper for the authored sound bank/engine; preserves the original SoundEffects implementation |
| `art/catalog/revisions/index.json` | Active receipt selection plus predecessor source/manifest archive mappings |
| `art/catalog/uploaded/` and `art/models/uploaded/` | Immutable uploaded GLB bytes and observed import evidence |

Keep `.blend` authoring files outside the Rojo-mapped `assets` subtree. The `.rbxm`
is the runtime import result, not a competing editable geometry source. The catalog
adapter uses stable IDs in the gallery and game. Native sources remain unchanged
and available for reference/fallback.
Restoration is documented in `ASSETS.md`. A local GLB is not automatically a deployable Roblox
mesh: asset ownership, access, moderation and observed IDs must be recorded after
the actual import. A fresh clone must be able to identify every dependency.

The batch script loads the editable blend without overwriting it, exports its
tagged meshes, validates geometry/group names, emits candidate manifests and can
render fixed-camera previews. `build_catalog.py --regenerate` recreates selected
catalog blends from their original Python builders and can erase accepted manual
or targeted revisions. It is not the ordinary review/export path. Use Blender
background execution and an explicit
Python error exit code so a failed export fails the job. The official
[command-line reference](https://docs.blender.org/manual/en/4.2/advanced/command_line/arguments.html)
documents those controls; match flags to the pinned installed version. Keep
machine-generated candidates separate from accepted sources, and inspect the
Studio result before accepting the revised catalog entry.

For the RBX-027 feedback, `scripts/models/revise_effect_models.py -- --apply`
is a bounded recipe for eight named sources. It checks pinned predecessor hashes,
preserves unselected files, and refuses unrecognized source edits. A second run
on its matching revision exports without rebuilding it. Use `--ids` to narrow
the requested set, `--render` for inspection images and `--upload-dir` for a
task-specific candidate folder. The earlier `revise_review_models.py` similarly
records the cap/crank pass. These recipes document particular revisions; they
are not a general license to regenerate the catalog. After later hand edits,
use the preserving catalog export path instead of forcing a recipe's hash guard.

Before replacing an accepted source, retain its exact bytes and manifest under
the predecessor archive mapping in `art/catalog/revisions/index.json`. Keep every
uploaded GLB, receipt and observed import snapshot immutable. Changed geometry
requires a new export/import receipt; never rewrite an old receipt to point at
new source bytes or asset IDs. Bind the new observations, normalize the imported
clones, then select the new active receipt for only the revised IDs. Preserve
superseded receipt/source pairs so both old and new uploads remain verifiable.
The archive validator must agree with the sources, active selection and exported
runtime artifact; a new local source alone does not complete that chain.

Pilot evidence includes source/export versions, hashes, actual triangle and
render-piece counts, the imported hierarchy, motion checks and the style-guide
checklist. Run the catalog archive and motion checks for imported MeshPart
identity/metadata; the frozen native primitive signature does not compare imported
mesh topology. Record visual QA independently from scripts,
Git integration and Roblox publication. See [RBX-019](../tasks/RBX-019-blender-pilots.md)
and its linked Studio images/audit for the first executed pass.
