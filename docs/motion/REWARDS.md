# Reward animation performances

RBX-023 gives each of the eight perks, four chest tiers and four event emblems its
own anticipation, readable action and recovery. `Rewards.luau` supplies pure
normalized-time samples to the shared motion controller. It changes motion only;
the approved Blender geometry, materials, identifiers and motion pivots remain.

Whole-model offsets are fractions of resting bounds. Whole-model scale peaks are
deliberately stronger than idle, generally 13–22% at normal strength. The controller
restores the resting model before resuming the shared figure eight. Completed
rotations are integer turns independent of strength, preventing a fractional-turn
snap on return. Larger strength increases bounce within a capped range. Perk
plinths travel with their whole model; they retain their distinguishing white base.

| ID | Performance | Distinct action and reason |
| --- | --- | --- |
| `first_spark` | Battery crackle kick, 0.92 s | Charge crouch, forward lightning punch and two electrical recoils; short, sharp electricity rather than a spinning appliance. |
| `tailwind` | Fan jet launch, 1.18 s | Three rotor turns, backward thrust, lifted housing and a gradual landing. The fan remains recognizable in its housing. |
| `ricochet` | Pearl three-cushion rally, 1.12 s | Pearl drops toward the pad and follows alternating lateral rebounds within the arch; the body answers the second impact with a smaller bounce. |
| `growth_ring` | Seed orbit bloom, 1.28 s | Inward gathering becomes an enlarged leaf orbit and buoyant bloom. Leaves share the ring pivot and move as an attached assembly. |
| `recovery` | Renewal corkscrew return, 1.24 s | Small reverse windup, two renewal-arrow turns and a compact looping body path make the return motif visible. |
| `last_word` | Quotation double stamp, 1.13 s | Left and right quotation marks punch out sequentially; the larger second stamp produces an emphatic nod from the speech card. |
| `metronome` | Pendulum whip cadence, 1.30 s | A cocked pendulum makes one broad whip and two diminishing counterbeats. The front-mounted pivot carries the weight and stem together. |
| `milestone` | Three-step flag fanfare, 1.34 s | Three stairs rise in ascending order; the final step cues a wide flag wave and proud body lift. |
| `chest_common` | Meadow latch surprise, 1.55 s | Curious rocking, leaf-clasp release, a light hop and one rotating seed bouquet. |
| `chest_uncommon` | Lagoon tidal reveal, 1.70 s | Sweeping lateral tide, rolling coffer, spinning seal and a floating reward wave. |
| `chest_rare` | Aurora vault eruption, 1.84 s | Heavy crouch and tremor, vertical kick, crystal-lid reveal, two reward pulses and a cushioned landing. |
| `chest_legendary` | Celestial coronation, 2.00 s | Full-body coronation turn while levitating, three orbit-ring turns, ascending rewards and a deliberate closure. |
| `event_growth` | Sprout jack-in-the-pot, 1.23 s | Planter gathers down and its rooted sprout scales into a bloom with diminishing leafy sways. The stem stays attached to its soil pivot. |
| `event_repair` | Repair heartbeat defibrillation, 1.03 s | Two distinct heartbeat jolts push the healing cross toward the viewer; the second pulse is stronger. |
| `event_upgrade` | Upgrade chevron launch, 1.17 s | Side arrows launch first, then the gold center arrow rises higher and overtakes them. The stand follows the formation. |
| `event_overtime` | Hourglass somersault reset, 1.40 s | Cock-back, full 360-degree roll in a lift arc, upright settling, then a delayed sand-flow pulse. The lower heap stays fixed. |

## Clearance and return rules

Chest lids keep their existing rear hinges and never exceed the previously
audited 105-degree opening. Rewards begin emerging after the lid reaches its
open pose and return before closure starts. Common treasure finishes returning
at normalized 0.76 before closure at 0.79; uncommon uses 0.77/0.80, rare uses
0.79/0.82, and legendary uses 0.80/0.83. There is no lid overshoot into an untested
angle. Every chest has a separate timing and body performance.

Ricochet travel is bounded inside the arch at normal strength. The metronome
uses the explicit front-mounted pivot and moves its stem forward along the
bearing before the sweep; strength cannot widen its 73-degree whip beyond the
authored maximum. Sprout and hourglass articulation are capped at
normal strength to protect rooted and enclosed geometry. The hourglass starts
its sand pulse after the complete tumble; the lower sand heap never moves.

## Validation and handoff

This contribution owns only `src/client/motion/Rewards.luau` and this document.
The coordinator owns integration, shared controller changes, full-catalog tests
and Studio inspection. Static and sampled-motion checks do not constitute
rendered approval; inspect front and side views at quarter poses and during
repeated triggers, including clipping inside cards and readability at rack size.

Contribution checks run against accepted predecessor
`83a1a611df86f2737179ab9ed54e7ac0f53b9f6b`: StyLua formatting, repository-configured
Selene (zero errors, warnings or parse errors), and a local Luau sweep using the
coordinator's actual `Curves` implementation and the predecessor's `ItemMotion`
part sampler. The sweep evaluated 64,064 body poses and 324,324 articulated poses
across 1,001 normalized times and four strengths. All 16 names and body paths are
distinct; outputs are finite and bounded, endpoints restore geometric identity,
and chest treasure moves only while the lid is fully open. The temporary sweep
is in ignored `scratch/test_rewards.luau`; integrated regression tests and actual
Studio clearance/rendered acceptance remain the coordinator's next action.
