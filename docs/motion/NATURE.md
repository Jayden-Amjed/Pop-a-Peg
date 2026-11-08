# Nature and evolution activation direction

RBX-023 contribution: 20 nature equipment models and all 13 evolutions in
`src/client/motion/Nature.luau`. Based on accepted source
`83a1a611df86f2737179ab9ed54e7ac0f53b9f6b`. Geometry, names, gameplay effects,
palette and the shared figure-eight idle are unchanged by this contribution.

Each activation has an anticipation, a forceful release and an eased recovery.
Body translations are fractions of the model's rest dimensions. Default-strength
whole-model growth peaks between 10% and 25%; vertical travel reaches at least
8% of model height, with a maximum 20% upward hop. Uniform body scaling moves the
housing and its contents together. Selective complete turns use whole revolutions
independent of fractional effect strength, so their final orientation matches rest.
Zero strength produces no movement. Durations range from 0.98 to 1.66 seconds.

## Nature equipment

| ID | Activation | Why this movement belongs to the object |
| --- | --- | --- |
| `goldfish` | Breach and barrel roll, 1.32s | A backward dip precedes a swimming leap and one roll around the fish's long axis. Tail and fins paddle; bubbles trail the landing. |
| `fishbowl` | Slush and hop, 1.22s | A heavy bowl leans and hops without overturning. The enclosed fish and water move less than the housing; reeds answer the returning current. |
| `rain_catcher` | Heavy-drop catch, 1.10s | The funnel reaches up, takes the falling rain's impact, and rebounds as water rises slightly inside the reservoir. |
| `bubble_wand` | Long-axis twirl and shared pop, 1.46s | The complete wand twirls around Y, then its handle, loop and bubbles swell and pop together on the catch. Bubbles never detach or spit outward. RBX-025 model-review revision. |
| `lily_pad` | Flower pop, 1.28s | A floating trampoline dip opens the flower at release; the dew bead continues upward after the petals, then returns. |
| `solar_leaf` | Sun salute, 1.24s | A forward bow becomes a proud upward lift. The paired collectors fan open at their roots, keeping the inset cells and gold veins attached. |
| `mist_fan` | Turbo kick, 1.16s | An accelerating five-turn rotor drives a mist burst toward the viewer; the fan housing recoils from its own airflow. |
| `coral_fork` | Struck chord, 0.98s | A diagonal cock-and-strike produces a short bright body hop followed by fast opposing tine vibration. Gold tips stay fixed to their tines. |
| `tide_valve` | Pressure release, 1.30s | The body braces against a stuck valve, the wheel unwinds through two turns, and the pipe shudders as pressure releases. |
| `dew_lantern` | Wish swing, 1.40s | A hanging-lantern swing opens into a buoyant lift. The dew core brightens and small motes drift inside the cage. |
| `moss_capacitor` | Charge and discharge, 1.12s | A compressed charging stance becomes a sharp upward electrical discharge, followed by a grounded shiver. Charge windows and bridge remain seated. |
| `pearl_diver` | Prize catch, 1.27s | A scoop-and-lift opens the articulated claws to present the pearl, which follows a slightly delayed arc back into its cradle. |
| `stream_wheel` | Water hammer, 1.38s | The complete paddle-and-spoke assembly winds back, then turns three times. The frame reacts like a heavy mechanism pushed by water. |
| `cloud_mirror` | Reflection reveal, 1.34s | A shy body tilt leads into one full swivel of the cloud face. Frame, glass and glint remain one assembly; droplets fall after the reveal. |
| `nectar_pump` | Double squirt, 1.08s | Two distinct presses move the pump stem and handle together. Nectar follows each press, with a smaller second body bounce. |
| `lagoon_synth` | Three-note riff, 1.22s | Three keys depress in order, the cabinet kicks to the beat, and the waveform answers a larger final chord. |
| `aurora_kite` | Looping gust, 1.56s | A dip catches a gust, then the whole kite rises through a complete twirl. The articulated ribbon lags behind and settles last. |
| `biolume_jar` | Firefly awakening, 1.36s | A sleepy jar tilt pops awake into a gentle rock. Fireflies make a small enclosed spiral while attached mushrooms pulse through light. |
| `ozone_orb` | Atomic sling, 1.48s | A charging crouch releases a buoyant magnetic hop. Rings turn on crossing axes, with a contained core pulse and orbiting satellites. |
| `monsoon_loom` | Shuttle storm, 1.32s | The loom braces while its shuttle crosses twice. The frame reacts laterally, threads flex slightly, and the woven rain glows before settling. |

## Evolutions

Evolutions use their actual ingredient mechanisms instead of sharing one generic
evolved-item spin. No evolution shares its complete body trajectory with another.

| ID | Activation | Combined mechanism and distinctive finish |
| --- | --- | --- |
| `aurora_aquarium` | Tidal halo parade, 1.60s | A grand, heavy buoyant rise combines the enclosed fish's swim with an elevated rotating halo; reeds move in the returning current. |
| `spectrum_reef` | Prismatic chord bloom, 1.38s | The coral fork strike launches a crystal bloom while the prism ring sweeps across it. Fast tine vibration contrasts with a slower crystal recovery. |
| `tidal_engine` | Hydraulic launch, 1.40s | A heavily loaded pressure cap compresses the coil, launches upward and lands through a smaller second bounce. The pressure needle answers the load and release. |
| `storm_clock` | Lightning overdrive, 1.44s | Cells charge before the body jolts. Fast/slow hands race through eight/two turns while the surrounding storm wheel counter-rotates three times and the crown flashes. |
| `horizon_observatory` | Orbital survey, 1.64s | The whole observatory makes a complete azimuth survey; its telescope raises for a sighting, the meridian turns, and the compass needle searches then settles. |
| `eden_greenhouse` | Three-stage sprouting, 1.52s | Germination, upward growth and a small final leaf beat form a deliberate slower rhythm. Seeds light first; connected sprouts expand from their shared bed pivot within the roof. |
| `pearl_turbine` | Balance-powered surge, 1.42s | The balance tips to load the mechanism, the pearl rotor accelerates through four turns, and the intact hanging balance catches on the opposite side. |
| `current_nexus` | Contact-snap broadcast, 1.24s | Both contacts pull inward before a sharp signal pulse. The body recoils and its broadcast ring makes two revolutions around seated, glowing cells. |
| `ocean_orchestra` | Brass-and-shell fanfare, 1.48s | A conductor-like breath precedes three staggered horn strikes; the shell supplies the delayed final chord while the forks vibrate. |
| `bubble_reactor` | Pressure cork-pop, 1.32s | Inward piston compression releases a tall body hop and two aftershocks. Small internal bubbles churn within the unchanged containment shell. |
| `solar_treasury` | Mint-and-coin salute, 1.46s | A quota stamp thumps before the larger payout hop. Coins launch through two axial spins, the gain needle sweeps, and the sun halo expands slightly. |
| `sun_koi` | Crowned solar somersault, 1.62s | A crown-bearing fish dives, then performs one complete front-facing somersault. The circlet counter-turns while fins and tail finish the landing. |
| `tide_gyroscope` | Gimbal cascade, 1.66s | A winding suspension releases staggered outer/inner gimbal revolutions. The clock hands brake at a different cadence, ending in a controlled body nod. |

## Attachment and recovery rules

- The adapter must apply body translation, rotation and uniform scale to every
  part, including fixed structure. `part` overrides clear legacy motion before
  setting the intended local joints, particles and glow.
- `SolarLeaf`, `SolarCell` and `SolarVein` use the same side-dependent angle;
  `CoralTine` and `CoralTip` share their angular displacement. Mirror materials,
  wheel spokes/paddles, pump stem/handle and hanging balance materials stay
  connected through their authored assembly pivots.
- A Tidal Engine coil uses `EvolvedSpring.axial` around its lower socket. Its
  rigid `EvolvedWeight` cap moves by `1.46 * (axial - 1)`, matching the imported
  socket-to-cap-center span (0.44 to 1.90 authored studs). The adapter must preserve
  the coil's X/Z dimensions and handle the native coil's corresponding span.
- Bowl, jar, greenhouse and reactor shells do not independently expand away from
  their rims or supports. Enclosed contents receive bounded local motion; their
  stronger visible bounce comes from the whole model.
- All transition curves ease to zero velocity. Completed spins remain exact
  whole turns; the controller restores original transforms, dimensions and colors
  at completion before resuming figure-eight idle.

## Contribution checks

Executed in the `task/RBX-023-motion-nature` worktree:

- StyLua format and `--check`: passed for `Nature.luau`.
- Standalone Luau audit using the integration worktree's actual `Curves` module
  and all 33 catalog manifests: passed 26,532 body samples and 169,644 part samples
  at strengths 0, 0.5, 1 and 2 over 201 poses per activation. Checked exact catalog
  coverage, unique names/body trajectories, finite transforms, positive bounded
  scales, rest endpoints, whole-turn endpoint equivalence and zero-strength rest.
- Default-strength maxima: 1.25 whole-model scale and 0.20 model-height upward
  travel. Every profile has at least 1.10 peak scale and 0.08 upward travel.
- A direct Selene invocation could not retrieve the Roblox standard library in
  this worktree. Integration lint and Studio visual/runtime evidence are owned
  by the RBX-023 coordinator; this contribution does not claim either result.

These numerical checks establish bounded choreography and restoration contracts.
Actual card framing, attachment clearance and animation appeal still require the
coordinator's complete native/Blender gallery runtime review.
