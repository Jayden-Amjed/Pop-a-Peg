-- Authored-space placement contract for every Blender effect. Coordinates are
-- Roblox studs (+Y up, +Z front), before centering, never model-center guesses.
local Anchors = { entries = {} }
local function attach(id, group, face, note, options)
    local entry = options or {}
    entry.mode, entry.group, entry.face, entry.note = "attachment", group, face, note
    Anchors.entries[id] = table.freeze(entry)
end
local function body(id, group, point, note, options)
    local entry = options or {}
    entry.mode, entry.group, entry.point, entry.note = "body", group, point, note
    Anchors.entries[id] = table.freeze(entry)
end
local function special(id, groups, note)
    Anchors.entries[id] = table.freeze({ mode = "special", groups = groups, note = note })
end
local function ambient(id, note)
    Anchors.entries[id] = table.freeze({ mode = "ambient", note = note })
end

ambient(
    "aurora_aquarium",
    "Schooling constellation surrounds the complete aquarium, not its plinth."
)
attach("aurora_kite", "KiteRibbon", nil, "Slipstream follows the trailing ribbon.")
attach("balance_scale", "BalanceBeam", nil, "Counterweight glints follow the balance beam.")
attach(
    "biolume_jar",
    "LumeFirefly",
    nil,
    "Firefly bloom begins among the jar's light motes.",
    { follow = false }
)
attach(
    "bubble_reactor",
    "EvolvedCore",
    nil,
    "Pressure helix surrounds the reactor core.",
    { follow = false }
)
attach(
    "bubble_wand",
    "WandLoop",
    nil,
    "Soap corona stays on the moving loop; no phantom Bubble group."
)
body(
    "burst_capsule",
    "Fixed",
    { 0, 1.765, 0 },
    "Pressure escapes the exposed cap socket.",
    { bias = { 0, 0.18, 0.18 } }
)
attach(
    "chest_common",
    "ChestTreasure",
    nil,
    "Treasure shower originates inside the open chest.",
    { follow = false, bias = { 0, 0.12, 0 } }
)
attach(
    "chest_legendary",
    "ChestTreasure",
    nil,
    "Star shower originates from the treasure cavity.",
    { follow = false, bias = { 0, 0.12, 0 } }
)
attach(
    "chest_rare",
    "ChestTreasure",
    nil,
    "Prismatic shower originates from the treasure cavity.",
    { follow = false, bias = { 0, 0.12, 0 } }
)
attach(
    "chest_uncommon",
    "ChestTreasure",
    nil,
    "Droplet reward fan originates from the treasure cavity.",
    { follow = false, bias = { 0, 0.12, 0 } }
)
body(
    "clockwork",
    "Fixed",
    { 0, 1.24, 0.50 },
    "Minute marks remain concentric with the fixed clock face.",
    { bias = { 0, 0.08, 0.22 } }
)
attach(
    "cloud_mirror",
    "CloudGlass",
    "+Z",
    "Reflected sweep starts on the moving glass face.",
    { bias = { 0, 0, 0.24 } }
)
attach(
    "coin",
    "Coin",
    "+Z",
    "Mint glints remain on the coin face as it flips.",
    { bias = { 0, 0, 0.24 } }
)
body(
    "coin_press",
    "Fixed",
    { 0, 0.575, 0 },
    "Gold flecks radiate from the anvil/coin contact plane."
)
body(
    "compass",
    "Fixed",
    { 0, 1.07, 0.35 },
    "Cardinal marks surround the compass face, not the swinging needle.",
    { bias = { 0, 0.12, 0.22 } }
)
special("coral_fork", { "CoralTip" }, "Lightning bridges the actual posed tips.")
attach(
    "current_nexus",
    "EvolvedCore",
    "+Z",
    "Current grid follows the exposed core faces.",
    { follow = false, bias = { 0, 0, 0.20 } }
)
special("dew_lantern", { "LanternDrop" }, "Localized halo follows the illuminated dew bulb.")
attach(
    "echo_plate",
    "ShellRibs",
    "+Z",
    "Echo rings leave the shell mouth and follow its tilt.",
    { bias = { 0, 0.13, 0.19 } }
)
body(
    "eden_greenhouse",
    "Fixed",
    { 0, 0.46, 0 },
    "Sprout streaks grow out of the soil bed.",
    { bias = { 0, -0.10, 0.12 } }
)
special("encore", { "Horn" }, "Each echo leaves its posed speaker cone along that cone's axis.")
attach("event_growth", "EventSprout", nil, "Leaf accents originate on the growing sprout.")
attach(
    "event_overtime",
    "EventSand",
    nil,
    "Hour ticks travel with the sand chamber during its flip."
)
attach(
    "event_repair",
    "EventCross",
    "+Z",
    "Repair stitches stay on the medical cross face.",
    { bias = { 0, 0, 0.24 } }
)
attach(
    "event_upgrade",
    "EventArrow",
    nil,
    "Upgrade streaks follow the rising arrows.",
    { follow = false }
)
attach(
    "first_spark",
    "Spark",
    nil,
    "Ignition flash comes from the lightning prong.",
    { bias = { 0, 0.20, 0.18 } }
)
attach(
    "fishbowl",
    "Waterline",
    nil,
    "Bubble ladder starts at the bowl's waterline.",
    { follow = false }
)
attach(
    "gain_dial",
    "Knob",
    "+Z",
    "Gauge sweep remains centered on the rotating knob face.",
    { point = { 0, 1.21, 0.56 }, bias = { 0, 0, 0.17 } }
)
attach("goldfish", "FishTail", nil, "Wake follows the swimming tail.")
body(
    "growth_array",
    "Fixed",
    { 0, 0.45, 0 },
    "Pollen stalks grow from the coral bed.",
    { bias = { 0, -0.10, 0.12 } }
)
attach(
    "growth_ring",
    "Orbit",
    nil,
    "Seed satellites share the orbital assembly center.",
    { follow = false }
)
attach(
    "horizon_observatory",
    "EvolvedLens",
    "+Z",
    "Focus beam leaves the objective lens and follows the telescope.",
    { point = { 0, 1.62, 0.84 }, bias = { 0, 0, 0.05 } }
)
ambient("jumble", "Crossing peg tracks intentionally surround the shuffle assembly.")
special("lagoon_synth", { "Fixed" }, "Travelling sine stays on the actual inset display plane.")
attach(
    "landing_fund",
    "ShellLid",
    "+Z",
    "Pearlescent chase follows the shell lid/ribs, not the floating coin.",
    { bias = { 0, 0, 0.12 } }
)
attach(
    "last_word",
    "Quote",
    "+Z",
    "Quotation echoes leave the moving quote glyphs.",
    { bias = { 0, 0, 0.19 } }
)
ambient("life", "Buoyant accent surrounds the complete ball.")
attach(
    "lily_pad",
    "LilyHeart",
    nil,
    "Dew bloom is centered on the flower; horizontal ripples remain below it."
)
attach(
    "lock",
    "Shackle",
    nil,
    "Lock glints track the clasp rather than the icon's foot.",
    { bias = { 0, 0, 0.24 } }
)
attach(
    "metronome",
    "Pendulum",
    nil,
    "Beat marks follow the weighted pendulum.",
    { bias = { 0, 0.10, 0.22 } }
)
attach("milestone", "Step", nil, "Progression lights rise from the steps.", { follow = false })
attach(
    "mist_fan",
    "PaperRotor",
    "+Z",
    "Paper gusts leave the rotor front and follow its orientation.",
    { bias = { 0, 0, 0.12 } }
)
attach(
    "monsoon_loom",
    "LoomWeave",
    "+Z",
    "Rain grid stays on the cloth/front weaving plane.",
    { follow = false, bias = { 0, 0, 0.20 } }
)
attach("moss_capacitor", "MossBridge", nil, "Charge trail surrounds the conducting bridge.")
attach("nectar_pump", "NectarDrop", nil, "Amber spray begins at the delivered nectar drop.")
special(
    "ocean_orchestra",
    { "EvolvedHorn" },
    "Chord rings leave all three upward-facing articulated horn bells."
)
attach("ozone_orb", "OzoneCore", nil, "Ion paths orbit the floating core.", { follow = false })
attach(
    "pearl_diver",
    "DiverPearl",
    nil,
    "Orbital trails center on the pearl, matching the surrounding rings."
)
attach("pearl_turbine", "EvolvedRotor", nil, "Cyclone follows the turbine hub.")
attach(
    "pulse_cell",
    "ChargeBar",
    "+Z",
    "Charge lattice is seated on the battery's front window.",
    { follow = false, bias = { 0, 0, 0.20 } }
)
body(
    "quota_bonus",
    "Fixed",
    { 0.35, 0.46, 0 },
    "Impact spreads across the paper tray at the stamp's contact point."
)
attach("rain_catcher", "RainWater", "+Y", "Rebound droplets start at the water surface.")
ambient("recovery", "Heartbeat glyphs surround the recovery symbol.")
special(
    "relay",
    { "Fixed", "Winding" },
    "Front discharge bridges the seated side terminals and clears the coil."
)
attach(
    "reserve_pack",
    "ReserveBall",
    nil,
    "Ball sparks originate at the raised reserves.",
    { follow = false }
)
attach(
    "resonator",
    "Chime",
    "+Z",
    "Resonance leaves the suspended chime between the forks.",
    { bias = { 0, 0.31, 0.19 } }
)
ambient("restock", "Refill trail deliberately circulates around the complete refill symbol.")
attach(
    "ricochet",
    "ReboundBall",
    nil,
    "Collision streaks follow the rebounding ball.",
    { bias = { 0, 0, 0.18 } }
)
attach(
    "score",
    "ScoreBar",
    "+Z",
    "Score lattice follows the graph's front columns.",
    { follow = false, bias = { 0, 0, 0.20 } }
)
attach(
    "seed_bank",
    "Seed",
    nil,
    "Germination accents begin among the displayed seeds.",
    { follow = false }
)
attach("soft_saw", "Current", nil, "Foam wake follows the rotating water crescent.")
attach(
    "solar_leaf",
    "SolarCell",
    "+Z",
    "Sunlit leaf accents begin on the collector panels.",
    { follow = false }
)
attach(
    "solar_treasury",
    "EvolvedCoin",
    "+Z",
    "Reward spokes originate on the minted coin/sun face.",
    { bias = { 0, 0, 0.18 } }
)
attach(
    "spectrum_reef",
    "EvolvedCrystal",
    nil,
    "Prismatic ladder rises between the crystals.",
    { follow = false }
)
attach(
    "split_prism",
    "Prism",
    "+Z",
    "Incident and split rays meet at the crystal's pearl lens aperture.",
    { point = { 0, 1.18, 0.435 }, bias = { 0, 0.08, 0.10 } }
)
attach(
    "spring_coil",
    "Weight",
    "-Y",
    "Compression shock rings originate beneath the pressing weight.",
    { bias = { 0, -0.20, 0.19 } }
)
body(
    "storm_clock",
    "Fixed",
    { 0, 1.45, 0.36 },
    "Electric ticks remain centered on the clock face.",
    { bias = { 0, 0.17, 0.22 } }
)
attach(
    "stream_wheel",
    "StreamPaddle",
    nil,
    "Tangential water spray follows a moving paddle, not the stand."
)
attach("sun_koi", "FishBody", nil, "Golden scale bloom follows the fish body.")
attach(
    "survey_lens",
    "Lens",
    "+Z",
    "Reticle and beam project from the objective and follow the barrel.",
    { point = { 0, 1.79, 0.61 }, bias = { 0, 0, 0.05 } }
)
attach("tailwind", "Turbine", "+Z", "Aerodynamic ribbons originate on the turbine's front face.")
attach(
    "tap_driver",
    "Piston",
    "+X",
    "Impact teeth start on the moving piston tip.",
    { bias = { 0, 0, 0.18 }, axis = "+X" }
)
attach(
    "tidal_engine",
    "EvolvedSpring",
    nil,
    "Pressure column surrounds the spring chamber.",
    { follow = false }
)
attach(
    "tide_gyroscope",
    "EvolvedGyro",
    nil,
    "Crossing trails center on the gimbal.",
    { follow = false }
)
body(
    "tide_valve",
    "Fixed",
    { 0.87, 0.55, 0 },
    "Water release exits the pipe opening, not the valve wheel.",
    { axis = "+X" }
)
attach(
    "tuning_oil",
    "Spout",
    "+X",
    "Oil droplets begin at the tilted spout lip and fall downward.",
    { point = { 1.29, 1.24, 0 }, axis = "-Y" }
)
attach(
    "wall_meter",
    "Gauge",
    "+Z",
    "Rising marks stay on the screen's gauge plane.",
    { follow = false, bias = { 0, 0, 0.20 } }
)

-- Resolve a source-space origin and the closest material piece of the assembly.
-- Plain numeric records also let offline tests validate every committed manifest.
function Anchors.resolve(id, records)
    local definition = assert(Anchors.entries[id], "Missing effect placement: " .. tostring(id))
    if definition.mode == "ambient" or definition.mode == "special" then
        return definition, nil, nil
    end
    local low, high = { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
    local matches = {}
    for index, record in records do
        if record.group == definition.group then
            table.insert(matches, index)
            for axis = 1, 3 do
                low[axis] = math.min(low[axis], record.low[axis])
                high[axis] = math.max(high[axis], record.high[axis])
            end
        end
    end
    assert(#matches > 0, "Missing physical effect group: " .. id .. "/" .. definition.group)
    local point = if definition.point
        then table.clone(definition.point)
        else { (low[1] + high[1]) / 2, (low[2] + high[2]) / 2, (low[3] + high[3]) / 2 }
    if definition.face and not definition.point then
        local axis = ({ X = 1, Y = 2, Z = 3 })[string.sub(definition.face, 2)]
        point[axis] = if string.sub(definition.face, 1, 1) == "+" then high[axis] else low[axis]
    end
    local nearest, distance = matches[1], math.huge
    for _, index in matches do
        local record, d = records[index], 0
        for axis = 1, 3 do
            local middle = (record.low[axis] + record.high[axis]) / 2
            d += (point[axis] - middle) ^ 2
        end
        if d < distance then
            nearest, distance = index, d
        end
    end
    return definition, point, nearest
end
Anchors.entries = table.freeze(Anchors.entries)
return Anchors
