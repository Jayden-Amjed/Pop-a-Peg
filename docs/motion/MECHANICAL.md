# Mechanical trigger choreography

RBX-023 replaces restrained mechanical trigger movement with readable anticipation,
an emphatic action, and a deliberate recovery. This covers 27 mechanical catalog
models plus the original Wave Spring and Seed Bank pilots. It changes animation,
not model geometry, scoring, proc rates, idle motion, or sound assets.

Implementation: `src/client/motion/Mechanical.luau`. Each entry exposes a duration,
name, description, complete-body pose and mechanism pose through the helpers
injected by the shared motion sampler. There are no service or asset dependencies.

## Per-model direction

Body enlargement at ordinary strength is approximately 17–24%; most hops reach
10–20% of the resting model height. The whole model moves as one assembly before
its individual mechanism motion is applied. Timing and movement differ by model.

| Model ID | Duration | Anticipation, action and recovery |
| --- | --- | --- |
| `tap_driver` | 0.84 s | Cock the handle and retract its sleeve; punch twice with a sideways body kick; rebound through a short second hop. Sleeve travel remains inside its collar. |
| `split_prism` | 1.14 s | Tilt to aim; lift through a complete yaw turn; project the crystal forward for the final focus beat and ease back. |
| `wall_meter` | 0.92 s | Brace away from impact; kick sideways as the bumper compresses; send a rising scale/glow wave through the gauge and bounce once. |
| `clockwork` | 1.38 s | Load torsion in the body; accelerate the minute hand through five turns, hour hand through two and gears through opposing four/three turns; stop with a weighted tick. |
| `burst_capsule` | 1.50 s | Rattle under pressure; blow the complete cap, neck and pin clear as one assembly; briefly tilt it above the shoulder, catch and reseat it, then settle. |
| `relay` | 1.17 s | Wind the coil and cock the housing; barrel-roll over its long axis while the contact snaps twice; settle with a forward/back rock. |
| `landing_fund` | 1.08 s | Dip to catch the reward; hinge the shell open and toss its coin through two turns; recover with a cheerful leaning bounce. |
| `survey_lens` | 1.20 s | Pull back; roll the complete tool through 360 degrees; extend the lens into a sharp late focus beat and damp its tiny final shimmy. |
| `gain_dial` | 1.02 s | Brace backward; crank the knob through one turn with a visible overshoot; kick the housing forward and rock gently to rest. |
| `soft_saw` | 1.23 s | Curl sideways; cartwheel with its current while foam pearls trail upward; unfurl and return without a second generic impact. |
| `balance_scale` | 1.28 s | Load one side; tip decisively into one and a half damped rocking cycles; keep the pans following the rotating beam endpoints as the body steadies. |
| `resonator` | 0.94 s | Tense and compress; ring with six fork oscillations and a visible complete-body shiver; let the suspended chime give a separate upward answer. |
| `echo_plate` | 1.12 s | Lean open; project and enlarge the pearl with the main sonic beat; send a smaller follow-up ripple through the shell before closing the motion. |
| `growth_array` | 1.34 s | Bend into a growing wave; bloom the coral stems in a staggered sequence from their planted pivots; sway back into the bed. |
| `quota_bonus` | 0.88 s | Lift the stamp; slam once with a weighted body dip; spring the complete press upward and lift the pad off the tray. Stroke strength is capped at physical contact. |
| `spring_coil` | 1.02 s | Load into the socket; launch the complete frame; absorb the landing in a smaller second hop. Existing axial compression, top weight, guide and cap relationships remain unchanged. |
| `pulse_cell` | 1.08 s | Charge from low to high; swell under pressure; release a distinct forward kick and pitch recovery while the charge bars settle. |
| `compass` | 1.30 s | Cock diagonally; toss through a full yaw turn while the needle searches through three turns; tip toward the viewer as the needle damps confidently home. |
| `seed_bank` | 1.20 s | Build pressure beneath the canopy; pop the lid and bounce into a rooted sprout bloom; settle with a small second hop. Seeds and stems scale together from the shared seated pivot. |
| `encore` | 1.16 s | Take a backward breath; blast forward; answer with a smaller paired horn beat offset left/right, then ease out. |
| `reserve_pack` | 1.13 s | Dip like a loaded basket; toss the reserve balls in a staggered juggling burst; rock the basket underneath their return. |
| `coin_press` | 1.65 s | Turn the separate top crank through two revolutions; lower the die onto a flat coin; compress its thickness to 26%, hold, then release and restore. The coin stays seated on its anvil. |
| `tuning_oil` | 1.32 s | Flip the complete can through a full roll; pause into a clear pouring tilt and moving droplet; snap smoothly upright. |
| `coin` | 1.10 s | Dip edge-first; toss through two face turns with a large reward pop; catch and make one smaller final bounce. No duplicate per-part rotation. |
| `restock` | 1.08 s | Wind backward; spool its arrows through two turns while the body enlarges generously; brake with a small opposing rock. |
| `life` | 0.98 s | Load a small uniform squash; spring high with a strong enlargement; recover through a second lower bounce. Ball part motion is cleared to avoid double translation. |
| `score` | 1.03 s | Lean into an ascending wave; launch each chart column in sequence; land the complete chart on the final beat. |
| `lock` | 1.16 s | Brace with a yaw; lift and swing the shackle clearly open; snap it shut as the body answers with a short second hop. |
| `jumble` | 1.26 s | Wind backward; roll the complete frame once; send its three pegs through a small orbital mixing wave, then collect them into the resting arrangement. |

## Continuity and fit

RBX-025 refines the capsule and press from the first model-review notes. The
capsule's new `BurstCap` carries its complete top with a shared pivot. Coin Press
uses separate `Crank`, `PressScrew` and `MintCoin` groups. The imported coin has
0.135-stud total thickness, anvil Y=0.57, and a 0.33-stud gap to the die. Its
0.4299-stud stroke reaches contact before compressing the coin; the native adapter
reads its own `PressContact` and `CoinThickness` to maintain the same relationship.
Both adapters squash height and layer spacing about the anvil pivot, preserving
the diameter. A stronger trigger does not push the die through the anvil.

- Full turns use the shared quintic phase and integer turn counts. Strength scales
  the expressive offsets but never multiplies the turn count; partial-strength
  procs therefore finish facing the same direction as ordinary procs.
- The shared sampler owns exact rest endpoints, trigger scheduling and bounds.
  Every authored envelope has zero endpoint velocity. Complete turns hold their
  equivalent rest orientation until the shared sampler returns the identity pose.
- Seated seeds receive no local upward translation or rotation. Seed pods and
  stems retain the same root-relative scale. Coral also grows around its authored
  planted pivots instead of translating an entire stem away from the bed.
- Wave Spring's mechanism callback preserves the supplied legacy sample exactly.
  Its extra expression comes from complete-model motion so axial spring fitting
  remains the responsibility of the established native and mesh adapters.
- Tap Driver, Quota Stamp and Coin Press limit mechanism travel independently of
  overall trigger strength. Bigger procs can still move the complete assembly
  farther without requiring a deeper mechanical stroke.
- Repeated triggers must queue at the shared renderer level. Restarting a full
  turn halfway through would produce a snap even with continuous pose curves.

## Checks and review boundary

The contributor worktree passed Luau execution of 29 distinct profile signatures,
11,716 body samples and 527,220 part samples at strengths 0, 0.25, 1 and 2. Checks
cover finite values, positive scales, bounded complete-body translation/scale,
rest-orientation endpoints, zero-strength body identity, spring sample
preservation and rooted seed movement. StyLua formatting also passed.

These numerical checks are not rendered model or gameplay acceptance. The main
RBX-023 task owns integrated native/Blender adapter tests, gallery inspection,
viewport framing and repeated-trigger verification in Studio. Its task record
and current dashboard hold the accepted validation result. No art assets were
regenerated or uploaded by this choreography change.
