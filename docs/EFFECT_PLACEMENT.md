# Effect placement audit

The RBX-029 audit checks every Blender item against its actual committed source
manifest and mechanism. Effects should originate at the contact surface or emitter,
then follow that assembly's posed translation, rotation and scale. A decorative
halo can surround the full object when that is its explicit purpose. Native
models and animation remain frozen; these contracts apply to the Blender layer
used by the gallery and game integration.

`CatalogEffectAnchors.luau` is the placement authority. Source coordinates are
Roblox studs, before centering: +Y up, +Z front. The renderer resolves real groups
and rejects missing anchors. Rebuilding a mesh requires checking this contract
alongside its pivot metadata. Do not silently substitute the model center.

## Concrete corrections

- Quota Bonus now strikes at source `(0.35, 0.46, 0)`, just above the printed tray
  surface at Y=0.457. Its horizontal shock begins on contact, not anticipation.
- Lens and horn effects inherit the moving assembly's rotation. Ocean Chorus uses
  both cone mouths; Ocean Orchestra uses all three upward-facing bells.
- Coin Press flecks come from the anvil/coin plane. Tap Driver's impact leaves its
  piston tip. Tuning Oil drips from its spout; Tide Valve releases at the pipe end.
- Clock marks stay centered on fixed dials, while gauge/battery effects stay on
  the screen face. Shell glints follow the lid, not the separate reward coin.
- Plant streaks start in their beds/seeds, chest rewards in the cavity, and the
  Bubble Wand uses its real `WandLoop` group instead of a nonexistent `Bubble`.

## Verification boundary

All78 source manifests resolve:67 attachment/body placements,6 multi-anchor or
special placements, and5 deliberate whole-object accents. The standalone test
checks actual group existence, declared faces, source-space silhouettes,468 affine
endpoint mappings, the tray plane/contact beat and mandatory failures for missing
anchors. The separate Studio audit exercises actual rotated/transformed models
and plate-planarity. This document records static geometry/intent review; it does
not claim the Studio audit or visual acceptance was performed by this contributor.
See the task's runtime evidence for that separate result.

| Item | Placement | Physical target | Rationale |
| --- | --- | --- | --- |
| Aurora Aquarium (`aurora_aquarium`) | ambient | whole-object accent | Schooling constellation surrounds the complete aquarium, not its plinth. |
| Aurora Kite (`aurora_kite`) | attachment | KiteRibbon | Slipstream follows the trailing ribbon. |
| Pearl Scale (`balance_scale`) | attachment | BalanceBeam | Counterweight glints follow the balance beam. |
| Biolume Jar (`biolume_jar`) | attachment | LumeFirefly | Firefly bloom begins among the jar's light motes. |
| Bubble Reactor (`bubble_reactor`) | attachment | EvolvedCore | Pressure helix surrounds the reactor core. |
| Bubble Wand (`bubble_wand`) | attachment | WandLoop | Soap corona stays on the moving loop; no phantom Bubble group. |
| Burst Capsule (`burst_capsule`) | body | Fixed (0, 1.76, 0) | Pressure escapes the exposed cap socket. |
| Meadow Chest (`chest_common`) | attachment | ChestTreasure | Treasure shower originates inside the open chest. |
| Celestial Chest (`chest_legendary`) | attachment | ChestTreasure | Star shower originates from the treasure cavity. |
| Aurora Chest (`chest_rare`) | attachment | ChestTreasure | Prismatic shower originates from the treasure cavity. |
| Lagoon Chest (`chest_uncommon`) | attachment | ChestTreasure | Droplet reward fan originates from the treasure cavity. |
| Tide Clock (`clockwork`) | body | Fixed (0, 1.24, 0.5) | Minute marks remain concentric with the fixed clock face. |
| Cloud Mirror (`cloud_mirror`) | attachment | CloudGlass +Z | Reflected sweep starts on the moving glass face. |
| Coin (`coin`) | attachment | Coin +Z | Mint glints remain on the coin face as it flips. |
| Coin Press (`coin_press`) | body | Fixed (0, 0.575, 0) | Gold flecks radiate from the anvil/coin contact plane. |
| Compass (`compass`) | body | Fixed (0, 1.07, 0.35) | Cardinal marks surround the compass face, not the swinging needle. |
| Coral Spark (`coral_fork`) | special | CoralTip | Lightning bridges the actual posed tips. |
| Current Nexus (`current_nexus`) | attachment | EvolvedCore +Z | Current grid follows the exposed core faces. |
| Dew Lantern (`dew_lantern`) | special | LanternDrop | Localized halo follows the illuminated dew bulb. |
| Echo Shell (`echo_plate`) | attachment | ShellRibs +Z | Echo rings leave the shell mouth and follow its tilt. |
| Eden Greenhouse (`eden_greenhouse`) | body | Fixed (0, 0.46, 0) | Sprout streaks grow out of the soil bed. |
| Ocean Chorus (`encore`) | special | Horn | Each echo leaves its posed speaker cone along that cone's axis. |
| Growth (`event_growth`) | attachment | EventSprout | Leaf accents originate on the growing sprout. |
| Overtime (`event_overtime`) | attachment | EventSand | Hour ticks travel with the sand chamber during its flip. |
| Repair (`event_repair`) | attachment | EventCross +Z | Repair stitches stay on the medical cross face. |
| Upgrade (`event_upgrade`) | attachment | EventArrow | Upgrade streaks follow the rising arrows. |
| First Spark (`first_spark`) | attachment | Spark | Ignition flash comes from the lightning prong. |
| Fishbowl (`fishbowl`) | attachment | Waterline | Bubble ladder starts at the bowl's waterline. |
| Gain Dial (`gain_dial`) | attachment | Knob +Z (0, 1.21, 0.56) | Gauge sweep remains centered on the rotating knob face. |
| Goldfish (`goldfish`) | attachment | FishTail | Wake follows the swimming tail. |
| Coral Garden (`growth_array`) | body | Fixed (0, 0.45, 0) | Pollen stalks grow from the coral bed. |
| Growth Ring (`growth_ring`) | attachment | Orbit | Seed satellites share the orbital assembly center. |
| Horizon Observatory (`horizon_observatory`) | attachment | EvolvedLens +Z (0, 1.62, 0.84) | Focus beam leaves the objective lens and follows the telescope. |
| Shuffle (`jumble`) | ambient | whole-object accent | Crossing peg tracks intentionally surround the shuffle assembly. |
| Lagoon Synth (`lagoon_synth`) | special | Fixed | Travelling sine stays on the actual inset display plane. |
| Landing Shell (`landing_fund`) | attachment | ShellLid +Z | Pearlescent chase follows the shell lid/ribs, not the floating coin. |
| Last Word (`last_word`) | attachment | Quote +Z | Quotation echoes leave the moving quote glyphs. |
| Ball (`life`) | ambient | whole-object accent | Buoyant accent surrounds the complete ball. |
| Lily Pad (`lily_pad`) | attachment | LilyHeart | Dew bloom is centered on the flower; horizontal ripples remain below it. |
| Held Offer (`lock`) | attachment | Shackle | Lock glints track the clasp rather than the icon's foot. |
| Metronome (`metronome`) | attachment | Pendulum | Beat marks follow the weighted pendulum. |
| Milestone (`milestone`) | attachment | Step | Progression lights rise from the steps. |
| Breeze Fan (`mist_fan`) | attachment | PaperRotor +Z | Paper gusts leave the rotor front and follow its orientation. |
| Monsoon Loom (`monsoon_loom`) | attachment | LoomWeave +Z | Rain grid stays on the cloth/front weaving plane. |
| Moss Capacitor (`moss_capacitor`) | attachment | MossBridge | Charge trail surrounds the conducting bridge. |
| Nectar Pump (`nectar_pump`) | attachment | NectarDrop | Amber spray begins at the delivered nectar drop. |
| Ocean Orchestra (`ocean_orchestra`) | special | EvolvedHorn | Chord rings leave all three upward-facing articulated horn bells. |
| Ozone Orb (`ozone_orb`) | attachment | OzoneCore | Ion paths orbit the floating core. |
| Pearl Diver (`pearl_diver`) | attachment | DiverPearl | Orbital trails center on the pearl, matching the surrounding rings. |
| Pearl Turbine (`pearl_turbine`) | attachment | EvolvedRotor | Cyclone follows the turbine hub. |
| Dew Cell (`pulse_cell`) | attachment | ChargeBar +Z | Charge lattice is seated on the battery's front window. |
| Quota Bonus (`quota_bonus`) | body | Fixed (0.35, 0.46, 0) | Impact spreads across the paper tray at the stamp's contact point. |
| Rain Catcher (`rain_catcher`) | attachment | RainWater +Y | Rebound droplets start at the water surface. |
| Recovery (`recovery`) | ambient | whole-object accent | Heartbeat glyphs surround the recovery symbol. |
| Current Relay (`relay`) | special | Fixed, Winding | Front discharge bridges the seated side terminals and clears the coil. |
| Reserve Pack (`reserve_pack`) | attachment | ReserveBall | Ball sparks originate at the raised reserves. |
| Reef Chime (`resonator`) | attachment | Chime +Z | Resonance leaves the suspended chime between the forks. |
| Restock (`restock`) | ambient | whole-object accent | Refill trail deliberately circulates around the complete refill symbol. |
| Ricochet (`ricochet`) | attachment | ReboundBall | Collision streaks follow the rebounding ball. |
| Shot Score (`score`) | attachment | ScoreBar +Z | Score lattice follows the graph's front columns. |
| Seed Bank (`seed_bank`) | attachment | Seed | Germination accents begin among the displayed seeds. |
| Soft Current (`soft_saw`) | attachment | Current | Foam wake follows the rotating water crescent. |
| Solar Leaf (`solar_leaf`) | attachment | SolarCell +Z | Sunlit leaf accents begin on the collector panels. |
| Solar Treasury (`solar_treasury`) | attachment | EvolvedCoin +Z | Reward spokes originate on the minted coin/sun face. |
| Spectrum Reef (`spectrum_reef`) | attachment | EvolvedCrystal | Prismatic ladder rises between the crystals. |
| Sun Prism (`split_prism`) | attachment | Prism +Z (0, 1.18, 0.435) | Incident and split rays meet at the crystal's pearl lens aperture. |
| Wave Spring (`spring_coil`) | attachment | Weight -Y | Compression shock rings originate beneath the pressing weight. |
| Storm Clock (`storm_clock`) | body | Fixed (0, 1.45, 0.36) | Electric ticks remain centered on the clock face. |
| Stream Wheel (`stream_wheel`) | attachment | StreamPaddle | Tangential water spray follows a moving paddle, not the stand. |
| Sun Koi (`sun_koi`) | attachment | FishBody | Golden scale bloom follows the fish body. |
| Survey Lens (`survey_lens`) | attachment | Lens +Z (0, 1.79, 0.61) | Reticle and beam project from the objective and follow the barrel. |
| Tailwind (`tailwind`) | attachment | Turbine +Z | Aerodynamic ribbons originate on the turbine's front face. |
| Tap Driver (`tap_driver`) | attachment | Piston +X | Impact teeth start on the moving piston tip. |
| Tidal Engine (`tidal_engine`) | attachment | EvolvedSpring | Pressure column surrounds the spring chamber. |
| Tide Gyroscope (`tide_gyroscope`) | attachment | EvolvedGyro | Crossing trails center on the gimbal. |
| Tide Valve (`tide_valve`) | body | Fixed (0.87, 0.55, 0) | Water release exits the pipe opening, not the valve wheel. |
| Tuning Oil (`tuning_oil`) | attachment | Spout +X (1.29, 1.24, 0) | Oil droplets begin at the tilted spout lip and fall downward. |
| Shore Meter (`wall_meter`) | attachment | Gauge +Z | Rising marks stay on the screen's gauge plane. |
