# Item activation direction

Activation should be expressive enough to read at rack size: a preparation,
a decisive action, then a smaller recovery.
Every registered model has its own authored performance, including utilities,
Supplies, perks, chests, events and all thirteen evolutions.

RBX-027 established the separate Blender review layer. RBX-029 explicitly adopts
that catalog and behavior into the game through `GameItemModels`; the game and
inspector now consume the same Blender choreography and effect sources.
The user's native-model freeze still includes native geometry and animation; its
accepted source `07be76a` is recorded in `art/catalog/native-reference.json`.
Do not implement new review notes in `src/client/ItemModels`, `ItemMotion`,
`NativeAssemblies`, `ItemChoreography` or the native `motion/` families.
`GameSoundEffects` wraps the authored bank/engine for game use without rewriting
the original `SoundEffects` implementation. Geometry revisions belong in Blender
sources and their import evidence.

## Motion language

- Make the silhouette react, not just a tiny internal part. Whole-object growth
  and a short lift or recoil communicate impact; keep connected materials together.
- Match the action to the object. A spring compresses then rebounds, a pump draws
  then ejects, a fish breaches, a kite twirls, and a chest holds open to reveal treasure.
- Complete full rotations when the shape benefits: wands, elongated tools,
  hourglasses, rotors and selected devices. Other mechanisms use weighted strikes,
  sways or blooms. Do not put the same spin on every housing.
- Stage a main beat and follow-through instead of continuous random vibration.
  Normal strength must already read clearly; 2x is a clearance stress case.
- Finish every turn on an integer revolution, including fractional strengths.
  Restore exact frames, sizes and colors before smoothly resuming the frozen
  figure-eight phase. Idle itself remains restrained and front-facing.
- Keep established materials readable. Brightness accents stay capped; motion
  should not turn the pearl, blue and metal surfaces into a white flash.

## Individual performances

The per-model tables preserve the accepted baseline action and its purpose:

- [Mechanical equipment, Supplies and utilities](motion/MECHANICAL.md): 29 models.
- [Nature equipment and evolutions](motion/NATURE.md): 33 models.
- [Perks, chests and event emblems](motion/REWARDS.md): 16 models.

`ItemChoreography` combines these frozen native families. `body` supplies
translation as fractions of resting dimensions, radian rotations and uniform scale. `part`
supplies articulation in authored model units. Shared quintic pulses and completed
turns provide smooth timing; each item chooses its own timing, axes and mechanism.
`BlenderChoreography` reads that baseline without changing it and adds Blender
articulation, body reactions and durations through `CatalogMotion` in both consumers.
Articulation precedes coherent whole-object movement; scaling changes positions
and dimensions together. The baseline tables are historical direction, not a
complete inventory of later Blender overrides.

## Brief effects and sound

`CatalogEffectProfiles.entries` is the explicit design registry for all 78
renderable IDs. Each entry names its object-specific accent and specifies its
timing, shape, count, spread, movement and colors. Related effects can share a
renderer while keeping distinct composition and timing. Avoid assigning the
same rotating sparkle halo to every object.

The eleven focused RBX-027 treatments establish the level of detail to use:

| Model | Gallery action and transient accent |
| --- | --- |
| Coral Spark (`coral_fork`) | A conductive strike with lightning joining the two rods. |
| Dew Lantern | A switch-on beat, warmer illuminated core and halo. |
| Ocean Chorus (`encore`) | Cone recoil followed by expanding speaker echoes. |
| Lagoon Synth | A traveling sine phase within its display, with a coherent contraction, main chord pop and smaller reply across the assembled cabinet. |
| Landing Shell (`landing_fund`) | Pearl and shell-detail glints with its treasure reveal. |
| Lily Pad | Camera-readable leaves, an opening bloom and dew accents. |
| Breeze Fan (`mist_fan`) | A paper-plane rotor with a streaming wake. |
| Ozone Orb | A free-floating charge and crossing ion trails. |
| Pearl Diver | A hexagonal frame, central pearl and orbiting colored arms/trails. |
| Current Relay (`relay`) | An energized spinning coil inside a locally fixed mount; the whole assembly contracts, pops on discharge and rebounds. |
| Soft Current (`soft_saw`) | A free water roll with a curling foam wake. |

The catalog also gives mechanisms, nature items, evolutions, perks, Supplies and
utility props their own brief accents. `CatalogEffects` uses a pool of at most
40 non-colliding parts, sampled directly from normalized pose. It does not rely
on accumulated particle simulation, clocks or per-frame object creation. Effects
must disappear at both endpoints, hold during pause/scrub and clean up when the
model changes. Include their bounds when fitting the stationary preview camera.

`CatalogEffectAnchors` attaches each emission to its modeled source surface and
direction. Check both position and orientation through articulation: cone echoes
point out of a moving speaker, nozzle spray follows its outlet, and a press impact
spreads from the plate it strikes. Keep a short contact clearance from opaque
surfaces. Quota Bonus completes its .433-stud stroke at every positive strength,
holding the printed tray surface during phases .25–.29; the impact belongs to
that contact interval. Strength changes the expressive body reaction, not whether
the die reaches the plate. A zero-strength pose stays at rest.

For Relay, charge contracts at phase .13, discharge enlarges at .27 and a smaller
rebound peaks at .55. Synth contracts at .12, pops on its main chord at .27 and
answers with a smaller .50 beat. Their fixed parts stay fixed within each reacting
assembly; the whole device's size and spacing change together. Review the wave's
screen bounds and electrical contacts during those body reactions.

`GallerySoundBank` authors one distinct phrase per ID across 12 timbre families:
glass, bell, reed, electric, water, air, wood, bass, organ, pluck, sonar and metal.
Use spectrum, attack, decay, rhythm, pitch movement and register to suggest the
object's action. A low coil buzz, a dry clock tick, a bell-like shell reward and
an airy rotor should differ in more than note transposition. The bank layers
partials from the existing sine asset and, where appropriate, quiet existing
physical cues. The gallery and `GameSoundEffects` use this bank through the
instance-local engine; the original native bank/source and asset identities stay
unchanged, and no new audio upload is needed.

`GallerySoundTimeline` places the attack on the mechanism's meaningful beat.
Changing preview speed moves that attack with the pose without transposing the
phrase. Only one soundtrack plays in native comparison. `describe(id)` on the
bank exposes the sound design for review; measured signal bounds and unique
descriptors do not substitute for listening.

## Playback and review

Use the [catalog inspector](CATALOG_GALLERY.md) at 1x speed first, then 0.25x and
pose scrub for attachments and recovery. Compare the frozen native reference and
Blender views; **FX OFF** isolates the underlying geometry and articulation. Use
Front and Side views for lids, fish, telescopes and nested assemblies. Record ID,
pose, strength, camera and the exact tested source commit with feedback.

Previews fit a sampled full-motion envelope once and retain a stationary camera.
Do not resize the camera every frame to follow a bounce. In game previews,
retriggers coalesce into a following activation so a new proc cannot rewind a half-finished
spin. The inspector's explicit TRIGGER remains a deliberate playback restart.
Reduced-motion native previews use a small uniform 4% pulse without spins or
articulation; the model still returns to its original pose.

The earlier shared review pass (RBX-025) used a whole-wand pop instead of
ejecting its bubble, a rigid removable capsule cap, and an independently cranked
press that flattens its seated coin to 26% thickness. The die and coin remain in
contact during compression. Chests keep their lids shut until pose .52, open
quickly by .60, hold through .88 and return to rest; tier durations are 3.4–4.2s.
Its chest timing uses accelerating rattles, an impact at .56 and reveal at .64.
That pass made hub reward replacement wait on `handle:isAnimating()` so slow
frames cannot skip the opening. The game adapter must preserve that completion
contract when using Blender models. These earlier mechanisms remain part of the
read-only baseline sampled by the Blender layer. See
[RBX-025 review](evidence/RBX-025/REVIEW.md).

Automated checks cover all IDs, distinct sampled trajectories, finite transforms,
completed turns, attachments, repeated restoration and actual camera projection.
Gallery effect checks also cover per-ID registry coverage, finite samples,
endpoint cleanup and the part budget. Audio checks cover all phrases and the
bounded engine; Studio loading/playback checks and listening are separate.
These contracts do not replace visual review of shape, rhythm, intended
intersections or audible differences. Record executed checks and observations
against the exact source revision in the task record; this guide asserts no
new Studio or subjective review result.
