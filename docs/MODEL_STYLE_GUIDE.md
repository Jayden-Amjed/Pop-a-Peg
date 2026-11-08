# Pop a Peg model style guide

Use this guide for every new or revised item, Supply, perk, chest and board prop.
It defines the intended art quality; passing a geometry script alone does not
establish that a model looks good. See [modeling workflow](MODELING_WORKFLOW.md)
for the proposed Blender pipeline and [asset provenance](ASSETS.md) for sources.

## Visual direction

Build friendly Frutiger Aero objects: pearl housings, aqua glass or water cues,
rounded blue mechanisms, fresh plant accents and small gold reward details.
Choose one recognizable object and one visible action for each item. Start with
three large masses, then add only details that help identify the item or explain
its movement. A readable silhouette matters more than many tiny components.

Use the existing `ItemModels` palette as the starting point:

| Role | RGB / hex | Treatment |
| --- | --- | --- |
| Pearl shell | 249, 253, 255 / `#F9FDFF` | Broad clean surfaces; leave visible white area |
| Aqua mechanism | 39, 189, 220 / `#27BDDC` | Main accent and water identity |
| Blue mechanism | 48, 153, 239 / `#3099EF` | Secondary depth and moving parts |
| Dark structure | 44, 88, 126 / `#2C587E` | Recesses, supports and readable separation |
| Pale glass | 145, 244, 255 / `#91F4FF` | Restrained transparent windows or opaque reflections |
| Growth | 142, 220, 103 / `#8EDC67` | Leaves, seeds and growth devices |
| Reward | 249, 189, 63 / `#F9BD3F` | Coins, tier accents and small focal points |

Give each object two dominant colors and one main accent. Materials should read
as smooth ceramic/plastic, selective metal and glass. Keep neon to small active
elements. Avoid covering a whole model in reflective or transparent layers.
Prefer one glass shell with deliberate contents and a simple reflection shape;
test that its contents remain readable under actual ViewportFrame lighting.

Each catalog ID needs its own geometry. Sharing a housing, hinge or material is
fine; a recolor or extra bolt does not create a new item. Evolutions should visibly
combine their ingredients around a new central mechanism. Level accents support
the same identity at L1–L5. Perks may retain their white display circles; equipment,
coins and Supplies must not gain a generic display pedestal. Structural feet
that belong to a device are fine.

## Shape and construction

- Use clean continuous contours and consistent edge rounding. Replace a chain of
  visibly intersecting blocks with a connected surface when it is meant to be a
  smooth ring, coil, leaf or shell.
- Join, trim or hide intentional structural connections. Do not leave accidental
  penetrations through visible faces, duplicated shells, floating joints,
  coincident faces, z-fighting or random gaps. A shaft entering a bearing is an
  intentional joint; a gear cutting through its outer housing is a defect.
- Use real thickness for visible sheets and correct face directions. Inspect
  front, side, rear and moving poses even when the UI mainly shows the front.
- Author a clear front facing Roblox +Z and upright +Y after import. The current
  preview looks from `(0.72, 0.43, 1)` toward the centered model. Check that the
  important mechanism is visible from that three-quarter angle.
- Keep the whole silhouette inside the card throughout idle and activation.
  Inspect at actual rack, shop, recipe and hub sizes; also compare 48, 96 and
  192-pixel thumbnails. Tiny recipes may simplify detail, but must keep identity.
- A black outer contour, when supported cleanly, should read as one boundary.
  It must not create a displaced second object, dark interior seams, halos or a
  visible clone through glass. Fix the render method before adding geometry to
  compensate. Outline quality is a separate visual check from model construction.

## Motion and runtime contract

Idle follows the shared bounded figure eight in `ItemMotion`; do not add a full
spin or a second competing hover loop. Activation freezes that idle pose, performs
the item's action, returns every articulated part to rest and resumes smoothly.
Check rest, quarter, half, three-quarter and end poses plus repeated activations.
Coils compress along their axis; clock hands rotate about their hub; lids open
around a hinge. Pivots and clearance must support these movements without clipping.

Retain catalog IDs and explicit `MotionGroup` names. Define `MotionPivot` for
articulated parts in the model's authored coordinate space. The current adapter
sets `AuthoredPosition`, `ArtCenter` and `MotionProfile`, centers the model at the
origin and animates its direct `BasePart` children. Nested imported objects must
be normalized deliberately; see the workflow before changing this contract.
Preview parts remain anchored, noncolliding, non-touchable and non-queryable.
Reduced motion must keep the object readable and restore its rest pose.

## Working budgets

These are project targets for new work, not Roblox platform limits or claims that
all existing models already meet them. Exceed a target only with a recorded visual
reason and a measured comparison in the busiest shop/rack view.

| Asset | Native parts target | Imported triangles target | Imported render pieces target |
| --- | --- | --- | --- |
| Base item / perk / Supply | 20–60 | 1,000–4,000 | 1–8 |
| Evolution / detailed chest | 40–100 | 2,000–6,000 | 1–12 |
| Small currency / recipe utility | 8–30 | 300–1,500 | 1–4 |

Keep separate pieces for actual articulation or material needs. Start with flat
colors and no textures; when a texture materially improves readability, target
one 512px set per item or a shared atlas and document the decision. Count active
preview copies, any contour pass and effect bursts together when profiling.
The existing native audit's `<256` parts and bounds checks are regression guards,
not quality targets. Imported triangle counts need an additional export audit.

## Acceptance checklist

- [ ] Recognizable, unique silhouette at rack and recipe sizes; L1 and L5 checked.
- [ ] Palette and material hierarchy are coherent; visible pearl/white remains.
- [ ] No unintended intersections, duplicate geometry, reversed visible faces,
  open seams, z-fighting, floating joints or clipped framing.
- [ ] Glass and any contour pass show no ghost shape or displaced duplicate.
- [ ] Named moving groups have correct pivots and clearance through all poses;
  repeated triggers restore frame, size and color without drift.
- [ ] Physics flags, bounds, catalog ID and motion contract pass runtime checks.
- [ ] Model/texture/preview-copy counts recorded; busy UI checked in Studio at
  desktop and phone sizes, with reduced motion and normal motion.
- [ ] Save a contact sheet and an activation capture with exact tested source SHA,
  viewport sizes and remaining issues in the task evidence. Build/lint is separate
  from visual acceptance; a capture that omits geometry is inconclusive.
- [ ] Original work or documented permitted asset use. Record creator, original
  URL, license and modifications for external models/textures in `ASSETS.md`.

Reference images guide shape, lighting and material choices; they do not confer
reuse rights. Maintain a small reference board with source links and notes about
what each reference teaches. Do not import another game's meshes or textures just
because an image search found them. Procedural or generated results receive the
same geometry and visual review as hand-authored work.
