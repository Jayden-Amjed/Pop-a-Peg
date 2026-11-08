local ItemMotion = {}
local Choreography = if script
    then require(script.Parent.ItemChoreography)
    else require("./ItemChoreography")

local profiles = {
    tap_driver = { duration = 0.5, name = "piston-strike" },
    split_prism = { duration = 0.76, name = "prism-aim" },
    wall_meter = { duration = 0.65, name = "bumper-gauge" },
    clockwork = { duration = 1.05, name = "clock-acceleration" },
    burst_capsule = { duration = 0.7, name = "capsule-release" },
    relay = { duration = 0.58, name = "relay-contact" },
    landing_fund = { duration = 0.9, name = "shell-catch" },
    survey_lens = { duration = 0.8, name = "lens-focus" },
    gain_dial = { duration = 0.8, name = "dial-wind" },
    soft_saw = { duration = 0.9, name = "current-curl" },
    balance_scale = { duration = 0.95, name = "pearl-balance" },
    resonator = { duration = 0.75, name = "chime-vibration" },
    echo_plate = { duration = 0.82, name = "shell-echo" },
    growth_array = { duration = 0.95, name = "coral-bloom" },
    quota_bonus = { duration = 0.62, name = "stamp-press" },
    spring_coil = { duration = 0.78, name = "spring-compression" },
    pulse_cell = { duration = 0.8, name = "cell-charge" },
    compass = { duration = 1.05, name = "needle-search" },
    seed_bank = { duration = 1, name = "seed-sprout" },
    encore = { duration = 0.8, name = "horn-response" },
    goldfish = { duration = 1.05, name = "fish-swim" },
    fishbowl = { duration = 1.15, name = "bowl-ripple" },
    rain_catcher = {
        duration = 0.9,
        name = "rain-collection",
        groups = { "RainWater", "RainDrop" },
    },
    bubble_wand = {
        duration = 1.05,
        name = "wand-bubble-release",
        groups = { "WandStem", "WandLoop", "WandBubble" },
    },
    lily_pad = {
        duration = 0.95,
        name = "lily-unfold",
        groups = { "LilyPad", "LilyPetal", "LilyHeart", "LilyDew" },
    },
    solar_leaf = {
        duration = 0.85,
        name = "solar-leaf-harvest",
        groups = { "SolarLeaf", "SolarCell", "SolarVein", "SolarSun" },
    },
    mist_fan = { duration = 0.75, name = "mist-vent", groups = { "MistRotor", "MistPuff" } },
    coral_fork = {
        duration = 0.68,
        name = "coral-tine-ping",
        groups = { "CoralTine", "CoralTip", "CoralCrown" },
    },
    tide_valve = {
        duration = 0.85,
        name = "tide-valve-turn",
        groups = { "ValveWheel", "ValveFlow" },
    },
    dew_lantern = {
        duration = 1.1,
        name = "dew-lantern-shine",
        groups = { "LanternDrop", "LanternMote" },
    },
    moss_capacitor = {
        duration = 0.88,
        name = "moss-capacitor-charge",
        groups = { "MossCharge", "MossBridge" },
    },
    pearl_diver = {
        duration = 0.95,
        name = "diver-pearl-grab",
        groups = { "DiverPearl", "DiverClaw" },
    },
    stream_wheel = {
        duration = 1.08,
        name = "stream-paddle-turn",
        groups = { "StreamPaddle", "StreamSpoke" },
    },
    cloud_mirror = {
        duration = 0.95,
        name = "cloud-reflection",
        groups = { "CloudFrame", "CloudGlass", "CloudGlint", "CloudRain" },
    },
    nectar_pump = {
        duration = 0.78,
        name = "nectar-pump-press",
        groups = { "NectarLiquid", "PumpStem", "PumpHandle", "NectarDrop" },
    },
    lagoon_synth = { duration = 1.12, name = "lagoon-chord", groups = { "SynthKey", "SynthWave" } },
    aurora_kite = {
        duration = 1.16,
        name = "aurora-kite-swoop",
        groups = { "KiteSail", "KiteSpar", "KiteRibbon" },
    },
    biolume_jar = {
        duration = 1.2,
        name = "biolume-firefly-dance",
        groups = { "LumeStem", "LumeCap", "LumeFirefly" },
    },
    ozone_orb = {
        duration = 1.3,
        name = "ozone-orb-ionize",
        groups = { "OzoneShell", "OzoneCore", "OzoneOrbitA", "OzoneOrbitB", "OzoneSatellite" },
    },
    monsoon_loom = {
        duration = 1.15,
        name = "monsoon-weave",
        groups = { "LoomThread", "LoomWeave", "LoomShuttle", "LoomRain" },
    },
    chest_common = {
        duration = 1.4,
        name = "meadow-coffer-open",
        chest = 1,
        groups = { "ChestLid", "ChestClasp", "ChestTreasure" },
    },
    chest_uncommon = {
        duration = 1.55,
        name = "tidal-coffer-open",
        chest = 2,
        groups = { "ChestLid", "ChestClasp", "ChestTreasure" },
    },
    chest_rare = {
        duration = 1.7,
        name = "aurora-vault-open",
        chest = 3,
        groups = { "ChestLid", "ChestClasp", "ChestTreasure" },
    },
    chest_legendary = {
        duration = 1.85,
        name = "celestial-reliquary-open",
        chest = 4,
        groups = { "ChestLid", "ChestClasp", "ChestTreasure", "ChestOrbit" },
    },
    event_growth = { duration = 0.95, name = "growth-emblem-sprout", groups = { "EventSprout" } },
    event_repair = { duration = 0.75, name = "repair-emblem-pulse", groups = { "EventCross" } },
    event_upgrade = { duration = 0.85, name = "upgrade-emblem-rise", groups = { "EventArrow" } },
    event_overtime = {
        duration = 1.1,
        name = "overtime-sand-fall",
        groups = { "EventSand", "EventStream" },
    },
    first_spark = { duration = 0.55, name = "spark-jump" },
    tailwind = { duration = 0.85, name = "turbine-turn" },
    ricochet = { duration = 0.64, name = "rebound-route" },
    growth_ring = { duration = 1, name = "orbit-bloom" },
    recovery = { duration = 0.9, name = "recovery-orbit" },
    last_word = { duration = 0.65, name = "quote-bounce" },
    metronome = { duration = 1.05, name = "pendulum-swing" },
    milestone = { duration = 0.95, name = "step-rise" },
    reserve_pack = { duration = 0.85, name = "reserve-hop" },
    coin_press = { duration = 0.9, name = "coin-mint" },
    tuning_oil = { duration = 0.8, name = "oil-drop" },
    coin = { duration = 0.75, name = "coin-turn" },
    restock = { duration = 0.75, name = "refill-turn" },
    life = { duration = 0.7, name = "ball-hop" },
    score = { duration = 0.7, name = "score-rise" },
    lock = { duration = 0.65, name = "shackle-open" },
    jumble = { duration = 0.8, name = "peg-shuffle" },
}
local evolvedProfiles = {
    aurora_aquarium = { 1.25, "aquarium-aurora", 1.1 },
    spectrum_reef = { 1.0, "reef-refraction", 2.2 },
    tidal_engine = { 0.9, "tidal-compression", -1.6 },
    storm_clock = { 1.2, "storm-clock-charge", 3.5 },
    horizon_observatory = { 1.25, "horizon-focus", -1.1 },
    eden_greenhouse = { 1.3, "eden-flourish", 0.8 },
    pearl_turbine = { 1.1, "pearl-turbine-balance", -2.5 },
    current_nexus = { 0.85, "nexus-transmission", 2.8 },
    ocean_orchestra = { 1.2, "orchestra-crescendo", 1.5 },
    bubble_reactor = { 0.95, "reactor-ignition", -2.1 },
    solar_treasury = { 1.05, "treasury-sunrise", 1.8 },
    sun_koi = { 1.2, "koi-solar-swim", -0.9 },
    tide_gyroscope = { 1.35, "gyroscope-precession", 3.2 },
}
for id, entry in pairs(evolvedProfiles) do
    profiles[id] = { duration = entry[1], name = entry[2], evolved = true, turns = entry[3] }
end
for id, profile in profiles do
    local performance = assert(Choreography.entries[id], "Missing performance: " .. id)
    profile.duration, profile.name = performance.duration, performance.name
    profile.description = performance.description
end
ItemMotion.Profiles = table.freeze(profiles)
ItemMotion.Choreography = Choreography.entries

function ItemMotion.bodySample(id, t, strength)
    if type(t) ~= "number" or t ~= t then
        t = 0
    end
    if type(strength) ~= "number" or strength ~= strength then
        strength = 1
    end
    return Choreography.body(id, math.clamp(t, 0, 1), math.clamp(strength, 0, 2))
end

ItemMotion.Idle = table.freeze({
    period = 4.2,
    resumeDuration = 0.42,
    lateral = 0.024,
    vertical = 0.03,
    pitch = math.rad(5),
    yaw = math.rad(6),
    roll = math.rad(2),
})

function ItemMotion.idleSample(phase)
    local horizontal = -math.cos(phase * 2)
    local vertical = math.cos(phase + math.pi / 4)
    local idle = ItemMotion.Idle
    return {
        x = horizontal * idle.lateral,
        y = vertical * idle.vertical,
        pitch = -vertical * idle.pitch,
        yaw = horizontal * idle.yaw,
        roll = -horizontal * idle.roll,
    }
end

function ItemMotion.newHover(enabled, phase)
    local initial = if type(phase) == "number"
            and phase == phase
            and math.abs(phase) < math.huge
        then phase
        else 0
    return {
        enabled = enabled == true,
        phase = initial % (math.pi * 2),
        paused = false,
        resume = 1,
        handoffs = 0,
    }
end

function ItemMotion.stepHover(state, dt, activating)
    if not state.enabled then
        return { x = 0, y = 0, pitch = 0, yaw = 0, roll = 0 }
    end
    if activating then
        state.paused, state.resume = true, 0
        return ItemMotion.idleSample(state.phase)
    end
    if state.paused then
        -- Start from the exact frozen pose; ramp phase velocity on later frames.
        state.paused = false
        state.handoffs += 1
        return ItemMotion.idleSample(state.phase)
    end
    local delta = if type(dt) == "number" and dt == dt then math.clamp(dt, 0, 0.1) else 0
    local previous = state.resume
    state.resume = math.min(1, previous + delta / ItemMotion.Idle.resumeDuration)
    local function ease(value)
        return value * value * (3 - 2 * value)
    end
    local rate = (ease(previous) + ease(state.resume)) / 2
    state.phase = (state.phase + delta * rate * math.pi * 2 / ItemMotion.Idle.period)
        % (math.pi * 2)
    return ItemMotion.idleSample(state.phase)
end

local function classify(id, object)
    local p, s = object.Position, object.Size
    local x, y, z = p.X, p.Y, p.Z
    if id == "tap_driver" then
        return x > 0.7 and "Piston" or "Fixed"
    elseif id == "split_prism" then
        return y > -0.6 and "Prism" or "Fixed"
    elseif id == "wall_meter" then
        return x < -0.7 and "Bumper" or (object.Name == "Glow" and "Gauge" or "Fixed")
    elseif id == "clockwork" then
        if z >= 0.6 and s.X > 0.2 then
            return y > 0.4 and "MinuteHand" or "HourHand"
        end
        if z > 0.3 and z < 0.58 and (x + 0.34) ^ 2 + (y - 0.12) ^ 2 < 0.27 then
            return "LeftGear"
        end
        if z > 0.3 and z < 0.58 and (x - 0.36) ^ 2 + (y - 0.42) ^ 2 < 0.17 then
            return "RightGear"
        end
    elseif id == "burst_capsule" then
        return y > 1.05 and "Pin" or (object:IsA("WedgePart") and "Fins" or "Fixed")
    elseif id == "relay" then
        return z > 0.3 and y > 0.2 and "Contact"
            or (math.abs(x) < 0.55 and math.abs(y + 0.08) < 0.03 and "Winding" or "Fixed")
    elseif id == "landing_fund" then
        return z > 0.3 and y > -0.1 and "CatchCoin" or "Fixed"
    elseif id == "survey_lens" then
        return y > 0.3 and "Lens" or "Fixed"
    elseif id == "gain_dial" then
        return z > 0.6 and "Knob" or "Fixed"
    elseif id == "balance_scale" then
        return y > 0.75 and "BalanceBeam" or (math.abs(x) > 0.5 and "Pan" or "Fixed")
    elseif id == "resonator" then
        return y > -0.35 and (x < -0.2 and "LeftFork" or (x > 0.2 and "RightFork" or "Chime"))
            or "Fixed"
    elseif id == "quota_bonus" then
        return x > 0 and y > -0.6 and "Stamp" or "Fixed"
    elseif id == "spring_coil" then
        return y > 0.95 and "Weight"
            or (s.Y < 0.16 and s.Z < 0.16 and "Coil" or (y > -0.5 and "Shaft" or "Fixed"))
    elseif id == "pulse_cell" then
        return object.Name == "Glow" and "ChargeBar" or "Fixed"
    elseif id == "compass" then
        return object:IsA("WedgePart") and "Needle" or "Fixed"
    elseif id == "seed_bank" then
        return object.Shape == Enum.PartType.Ball and "Seed" or (y > 0.85 and "Lid" or "Fixed")
    elseif id == "encore" then
        return y > 0.2 and math.abs(x) > 0.35 and "Horn" or "Fixed"
    elseif id == "first_spark" then
        return object.Material == Enum.Material.Neon and "Spark" or "Fixed"
    elseif id == "tailwind" then
        return y > -0.7 and "Turbine" or "Fixed"
    elseif id == "ricochet" then
        return object.Shape == Enum.PartType.Ball and "ReboundBall" or "Fixed"
    elseif id == "growth_ring" then
        return y > -0.75 and "Orbit" or "Fixed"
    elseif id == "recovery" then
        return y > -0.7 and z < 0.2 and "RecoveryArrows" or "Fixed"
    elseif id == "last_word" then
        return z > 0.2 and math.abs(x) < 0.65 and "Quote" or "Fixed"
    elseif id == "metronome" then
        return z > 0.48 and "Pendulum" or "Fixed"
    elseif id == "milestone" then
        return y > 0.5 and "Flag" or (y > -0.8 and "Step" or "Fixed")
    elseif id == "reserve_pack" then
        return y > -0.3 and z > -0.4 and math.abs(x) < 0.8 and "ReserveBall" or "Fixed"
    elseif id == "coin_press" then
        return math.abs(x) < 0.22 and y > -0.6 and "PressScrew"
            or (z > 0.3 and "MintCoin" or "Fixed")
    elseif id == "tuning_oil" then
        return x > 1.4 and y < 0.84 and "Drop" or (x > 0.45 and "Spout" or "Fixed")
    elseif id == "lock" then
        return y > 0.15 and "Shackle" or "Fixed"
    elseif id == "score" then
        return y > -0.7 and "ScoreBar" or "Fixed"
    elseif id == "jumble" then
        return z < 0.12 and "ShufflePeg" or "Fixed"
    elseif id == "coin" then
        return "Coin"
    elseif id == "restock" then
        return z > 0.2 and "RefillArrows" or "Fixed"
    elseif id == "life" then
        return "Ball"
    end
    return "Fixed"
end

function ItemMotion.tag(model, id)
    assert(profiles[id], "Missing item motion: " .. id)
    model:SetAttribute("MotionProfile", profiles[id].name)
    for _, object in ipairs(model:GetChildren()) do
        if object:IsA("BasePart") then
            local group = object:GetAttribute("MotionGroup") or classify(id, object)
            object:SetAttribute("MotionGroup", group)
            object:SetAttribute("AuthoredPosition", object.Position)
        end
    end
end

local pivots = {
    Lens = { 0, 0.62, 0.12 },
    MinuteHand = { 0, 0.15, 0.62 },
    HourHand = { 0, 0.15, 0.65 },
    LeftGear = { -0.34, 0.12, 0.36 },
    RightGear = { 0.36, 0.42, 0.36 },
    LowerGear = { 0.3, -0.46, 0.38 },
    BalanceBeam = { 0, 0.87, 0 },
    ShellLid = { 0, -0.42, -0.49 },
    Knob = { 0, 0, 0.67 },
    Needle = { 0, 0, 0.25 },
    Pendulum = { 0.35, -0.59, 0.53 },
    Turbine = { 0, 0.35, 0 },
    RecoveryArrows = { 0, 0.24, 0 },
    Orbit = { 0, 0.22, 0 },
    FishTail = { -0.56, 0.12, 0 },
    Current = { 0, 0.12, 0 },
    Coin = { 0, 0, 0 },
    RefillArrows = { 0, 0, 0 },
    Ball = { 0, 0, 0 },
    Shackle = { -0.55, 0.15, 0 },
}

-- Samples are plain numbers so motion envelopes can be checked without rendering.
function ItemMotion.sample(id, group, t, strength, x, y, z)
    local v = { x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, scale = 1, glow = 0, axial = 1 }
    if t ~= t or t <= 0 or t >= 1 or group == "Fixed" or strength == 0 then
        return v
    end
    local authoredT = t
    -- Ease the inherited mechanisms into/out of rest without changing the main
    -- action timing. This polynomial meets the interior with unit velocity and
    -- starts with zero velocity/acceleration; completed turns remain completed.
    local function edge(u)
        return u * u * u * (6 - 8 * u + 3 * u * u)
    end
    if t < 0.08 then
        t = 0.08 * edge(t / 0.08)
    elseif t > 0.92 then
        t = 1 - 0.08 * edge((1 - t) / 0.08)
    end
    local a = math.clamp(strength or 1, 0, 2)
    local envelope = math.sin(math.pi * t)
    local damp = (1 - t) ^ 2
    local wobble = math.sin(t * math.pi * 6) * damp
    local turn = t * t * (3 - 2 * t) * math.pi * 2
    v.glow = envelope * 0.25 * a
    if profiles[id] and profiles[id].chest then
        local tier = profiles[id].chest
        if group == "ChestLid" then
            -- Open, hold for the reward reveal, then close smoothly before idle resumes.
            local open = if t < 0.28 then t / 0.28 elseif t <= 0.67 then 1 else (1 - t) / 0.33
            open = open * open * (3 - 2 * open)
            v.rx = -open * math.rad(105)
            v.glow = envelope * 0.2
        elseif group == "ChestTreasure" then
            v.y = envelope * (0.48 + tier * 0.08)
            v.scale = 1 + envelope * 0.35
            v.glow = envelope * 0.85
            v.ry = turn
        elseif group == "ChestClasp" then
            v.z = envelope * 0.16
            v.y = wobble * 0.12
        elseif group == "ChestOrbit" then
            v.ry = turn
            v.rx = envelope * 0.2
        end
    elseif id == "rain_catcher" then
        if group == "RainDrop" then
            v.y = -envelope * (0.42 + x * 0.12)
            v.scale = 1 - envelope * 0.16
        else
            v.y = envelope * 0.16
            v.scale = 1 + envelope * 0.12
        end
    elseif id == "bubble_wand" then
        if group == "WandBubble" then
            v.y, v.x = envelope * 0.42, envelope * 0.17
            v.scale = 1 + envelope * 0.23
        else
            v.rz = -envelope * 0.24
        end
    elseif id == "lily_pad" then
        if group == "LilyPetal" then
            v.rx, v.rz = z * envelope * 0.65, -x * envelope * 0.65
        elseif group == "LilyPad" then
            v.y = wobble * 0.055
        elseif group == "LilyDew" then
            v.y = envelope * 0.24
        else
            v.scale = 1 + envelope * 0.2
            v.glow = envelope * 0.65
        end
    elseif id == "solar_leaf" then
        if group == "SolarSun" then
            v.y = envelope * 0.16
            v.glow = envelope * 0.9
        else
            v.rz = (x < 0 and 1 or -1) * envelope * 0.17
            v.glow = envelope * (group == "SolarCell" and 0.55 or 0.16)
        end
    elseif id == "mist_fan" then
        if group == "MistRotor" then
            v.rz = -turn * 3
        else
            v.z = envelope * (0.3 + x * 0.18)
            v.scale = 1 + envelope * 0.25
        end
    elseif id == "coral_fork" then
        v.x = (x < 0 and -1 or 1) * math.sin(t * math.pi * 26) * damp * 0.075 * a
        v.glow = envelope * (group == "CoralTip" and 0.7 or 0.2)
    elseif id == "tide_valve" then
        if group == "ValveWheel" then
            v.ry = -turn
        else
            v.x = math.sin(t * math.pi * 2) * envelope * 0.22
            v.scale = 1 + envelope * 0.15
        end
    elseif id == "dew_lantern" then
        if group == "LanternMote" then
            v.y = envelope * (0.3 + x * 0.3)
            v.x = math.sin(t * math.pi * 4 + y) * envelope * 0.1
        else
            v.scale = 1 + envelope * 0.2
        end
        v.glow = envelope * 0.8
    elseif id == "moss_capacitor" then
        v.y = math.sin(t * math.pi * 3 - y * 3) * envelope * 0.045
        v.scale = 1 + envelope * (group == "MossCharge" and 0.22 or 0.1)
        v.glow = envelope * 0.6
    elseif id == "pearl_diver" then
        if group == "DiverClaw" then
            v.rz = -x * envelope * 0.28
        else
            v.y = envelope * 0.28
            v.z = envelope * 0.13
            v.glow = envelope * 0.55
        end
    elseif id == "stream_wheel" then
        v.rx = turn * 2
    elseif id == "cloud_mirror" then
        if group == "CloudRain" then
            v.y = -envelope * 0.27
        elseif group == "CloudGlint" then
            v.x = envelope * 0.18
            v.glow = envelope * 0.8
        else
            v.ry = wobble * 0.16
            v.glow = envelope * 0.3
        end
    elseif id == "nectar_pump" then
        if group == "NectarDrop" then
            v.y = -envelope * 0.36
        elseif group == "NectarLiquid" then
            v.y = -envelope * 0.07
        else
            v.y = -math.abs(math.sin(t * math.pi * 2)) * damp * 0.31
        end
    elseif id == "lagoon_synth" then
        if group == "SynthKey" then
            v.y = -math.max(0, math.sin(t * math.pi * 8 + x * 4)) * envelope * 0.075
        else
            v.y = math.sin(t * math.pi * 5 + x * 3) * envelope * 0.11
            v.scale = 1 + envelope * 0.18
            v.glow = envelope * 0.7
        end
    elseif id == "aurora_kite" then
        if group == "KiteRibbon" then
            v.x = math.sin(t * math.pi * 6 + y * 3) * envelope * 0.17
            v.rz = wobble * 0.16
        else
            v.rz = math.sin(t * math.pi * 2) * envelope * 0.19
            v.y = envelope * 0.16
        end
    elseif id == "biolume_jar" then
        if group == "LumeFirefly" then
            v.x = math.sin(t * math.pi * 2 + x * 4) * envelope * 0.16
            v.y = envelope * 0.18
        elseif group == "LumeCap" then
            v.scale = 1 + envelope * 0.19
        else
            v.rz = wobble * 0.08
        end
        v.glow = envelope * (group == "LumeStem" and 0.1 or 0.75)
    elseif id == "ozone_orb" then
        if group == "OzoneOrbitA" then
            v.ry = turn * 2
        elseif group == "OzoneOrbitB" then
            v.rx = -turn
        elseif group == "OzoneSatellite" then
            v.rz = turn
        else
            v.scale = 1 + envelope * (group == "OzoneCore" and 0.3 or 0.08)
            v.glow = envelope * 0.75
        end
    elseif id == "monsoon_loom" then
        if group == "LoomShuttle" then
            v.x = math.sin(t * math.pi * 4) * envelope * 0.5
        elseif group == "LoomRain" then
            v.y = -envelope * 0.35
        elseif group == "LoomThread" then
            v.z = math.sin(t * math.pi * 4 + x * 5) * envelope * 0.07
        else
            v.y = math.sin(t * math.pi * 4 - y * 4) * envelope * 0.08
            v.glow = envelope * 0.5
        end
    elseif id == "event_growth" then
        v.y = envelope * (0.14 + y * 0.07)
        v.rz = -x * envelope * 0.25
    elseif id == "event_repair" then
        v.scale = 1 + math.sin(t * math.pi * 3) * envelope * 0.16
        v.glow = envelope * 0.55
    elseif id == "event_upgrade" then
        v.y = math.max(0, math.sin(t * math.pi * 2 - x)) * envelope * 0.28
    elseif id == "event_overtime" then
        if group == "EventSand" then
            v.y = -envelope * 0.17
        else
            v.scale = 1 + envelope * 0.25
            v.glow = envelope * 0.4
        end
    elseif profiles[id] and profiles[id].evolved then
        local turns = profiles[id].turns
        if group == "EvolvedOrbit" or group == "EvolvedRotor" or group == "EvolvedGyro" then
            -- Finish on whole revolutions so returning to the rest pose never
            -- snaps an asymmetric ring or rotor through a fractional turn.
            local revolutions = math.ceil(math.abs(turns)) * (turns < 0 and -1 or 1)
            local spin = turn * revolutions + envelope * turns * 0.35
            if group == "EvolvedGyro" then
                v.rx, v.ry = spin, -spin
            elseif group == "EvolvedRotor" then
                v.rz = -spin
                v.ry = envelope * 0.35
            else
                v.ry = spin
                v.rx = envelope * 0.4
            end
        elseif group == "EvolvedFastHand" or group == "EvolvedSlowHand" then
            v.rz = -turn * (group == "EvolvedFastHand" and 6 or 2)
        elseif group == "EvolvedSpring" or group == "EvolvedWeight" then
            v.y = -(y + 0.65) * wobble * 0.34 * a
            v.scale = 1 + wobble * 0.08
        elseif group == "EvolvedCrystal" or group == "EvolvedSprout" then
            v.y = envelope * (0.15 + math.max(y, 0) * 0.1) * a
            v.rz = math.sin(t * math.pi * 4 + x * 2) * envelope * 0.11
            v.scale = 1 + envelope * 0.1
        elseif group == "EvolvedLens" then
            v.z = envelope * 0.3 * a
            v.ry = wobble * 0.14
        elseif group == "EvolvedNeedle" then
            v.rz = math.sin(t * math.pi * 7) * damp * 1.8
        elseif group == "EvolvedBalance" then
            v.rz = wobble * 0.18
            v.y = x * wobble * 0.15
        elseif group == "EvolvedHorn" or group == "EvolvedShell" then
            v.z = math.max(0, math.sin(t * math.pi * 10 + x * 2)) * envelope * 0.22 * a
        elseif group == "EvolvedPiston" then
            v.x = -x * math.abs(math.sin(t * math.pi * 4)) * damp * 0.32 * a
        elseif group == "EvolvedCoin" then
            v.y = math.sin(t * math.pi + x) * envelope * 0.4
            v.ry = turn * 2
        elseif group == "FishBody" or group == "FishFin" or group == "FishTail" then
            v.x = math.sin(t * math.pi * 2) * envelope * 0.24 * a
            v.y = envelope * 0.1
            if group == "FishTail" then
                v.ry = math.sin(t * math.pi * 16) * envelope * 0.65
            end
            if group == "FishFin" then
                v.rx = math.sin(t * math.pi * 12) * envelope * 0.42
            end
        elseif group == "Bubbles" then
            v.y = envelope * (0.4 + y * 0.12)
            v.scale = 1 + envelope * 0.18
        elseif group == "Reeds" then
            v.rz = wobble * 0.2
        elseif group == "EvolvedFork" then
            v.x = (x < 0 and -1 or 1) * math.sin(t * math.pi * 24) * damp * 0.11 * a
        else
            v.scale = 1 + envelope * 0.14 * a
            v.y = envelope * 0.055
        end
        v.glow = envelope * (group == "EvolvedCore" and 0.85 or 0.35)
    elseif id == "tap_driver" then
        v.x = -0.35 * math.sin(math.pi * math.min(1, t * 2)) * a
    elseif id == "split_prism" then
        v.z = envelope * 0.1 * a
        v.glow = envelope * 0.85
    elseif id == "wall_meter" then
        if group == "Bumper" then
            v.x = wobble * 0.2 * a
        else
            v.scale = 1 + envelope * (0.12 + x * 0.08) * a
        end
    elseif id == "clockwork" then
        v.rz = turn
            * (
                group == "MinuteHand" and -3
                or (group == "HourHand" and -1 or (group == "LeftGear" and 2 or -2))
            )
    elseif id == "burst_capsule" then
        if group == "Pin" then
            v.y = envelope * 0.23 * a
            v.rz = envelope * 0.25
        else
            v.x = x * envelope * 0.18 * a
            v.ry = wobble * 0.2
        end
    elseif id == "relay" then
        if group == "Contact" then
            v.y = -math.abs(math.sin(t * math.pi * 4)) * damp * 0.25 * a
        else
            v.scale = 1 + envelope * 0.08 * a
        end
    elseif id == "landing_fund" then
        if group == "ShellLid" then
            v.rx = envelope * 0.4 * a
        else
            v.y = envelope * 0.23 * a
            v.ry = turn
        end
    elseif id == "survey_lens" then
        v.z = envelope * (0.1 + math.max(0, z) * 0.15) * a
        v.ry = wobble * 0.07
    elseif id == "gain_dial" then
        v.rz = -envelope * math.pi * 0.65 * a
    elseif id == "soft_saw" then
        if group == "Current" then
            v.rz = envelope * 0.35 * a
        else
            v.y = envelope * 0.17 * a
            v.x = wobble * 0.08
        end
    elseif id == "balance_scale" then
        if group == "BalanceBeam" then
            v.rz = wobble * 0.25 * a
        else
            v.y = x * wobble * 0.25 * a
        end
    elseif id == "resonator" then
        v.x = (group == "LeftFork" and -1 or 1) * math.sin(t * math.pi * 18) * damp * 0.09 * a
    elseif id == "echo_plate" then
        if group == "Pearl" then
            v.z = envelope * 0.34 * a
            v.scale = 1 + envelope * 0.18
        else
            v.z = math.sin(t * math.pi * 8 + math.abs(x) * 2) * envelope * 0.08 * a
        end
    elseif id == "growth_array" then
        v.y = math.max(0, y + 0.54) * envelope * 0.16 * a
        v.rz = math.sin(t * math.pi * 2 + x) * envelope * 0.07
    elseif id == "quota_bonus" then
        v.y = -math.sin(math.pi * math.min(1, t * 1.7)) * 0.42 * a
    elseif id == "spring_coil" then
        v.axial = 1 - wobble * 0.29 * a
        if group == "Weight" then
            v.y = (v.axial - 1) * 2.04
        end
    elseif id == "pulse_cell" then
        v.scale = 1 + math.max(0, math.sin(t * math.pi * 2 - y * 2)) * envelope * 0.2 * a
        v.z = envelope * 0.05
    elseif id == "compass" then
        v.rz = math.sin(t * math.pi * 5) * damp * math.pi * a
    elseif id == "seed_bank" then
        if group == "Lid" then
            v.y = envelope * 0.22 * a
        else
            v.y = envelope * 0.2 * a
            v.scale = 1 + envelope * 0.12 * a
        end
    elseif id == "encore" then
        v.z = math.max(0, math.sin(t * math.pi * 8 + x * 2)) * damp * 0.16 * a
    elseif id == "goldfish" or id == "fishbowl" then
        if group == "FishTail" or group == "FishFin" or group == "FishBody" then
            v.x = math.sin(t * math.pi * 2) * envelope * (id == "fishbowl" and 0.1 or 0.22) * a
            v.y = envelope * 0.06
        end
        if group == "FishTail" then
            v.ry = math.sin(t * math.pi * 12) * envelope * 0.5 * a
        elseif group == "FishFin" then
            v.rx = math.sin(t * math.pi * 14) * envelope * 0.35
        elseif group == "Bubbles" then
            v.y = envelope * (0.2 + y * 0.15) * a
            v.scale = 1 + envelope * 0.15
        elseif group == "Waterline" then
            v.scale = 1 + math.sin(t * math.pi * 6) * envelope * 0.08 * a
        elseif group == "Water" then
            v.ry = envelope * 0.12
            v.y = wobble * 0.035
        elseif group == "Reeds" then
            v.rz = wobble * 0.13 * a
        end
    elseif id == "first_spark" then
        v.x = math.sin(t * math.pi * 20) * damp * 0.09 * a
        v.scale = 1 + envelope * 0.1
    elseif id == "tailwind" then
        v.rz = -turn * 2
    elseif id == "ricochet" then
        v.x = math.sin(t * math.pi * 4 + y * 2) * envelope * 0.21 * a
        v.y = envelope * 0.12
    elseif id == "growth_ring" then
        v.ry = turn
        v.scale = 1 + envelope * 0.08 * a
    elseif id == "recovery" then
        v.rz = -turn
    elseif id == "last_word" then
        v.y = math.abs(math.sin(t * math.pi * 3 + x)) * envelope * 0.2 * a
        v.rz = wobble * 0.08
    elseif id == "metronome" then
        v.rz = math.sin(t * math.pi * 5) * damp * 0.65 * a
    elseif id == "milestone" then
        if group == "Flag" then
            v.rz = wobble * 0.18
        else
            v.y = math.max(0, math.sin(t * math.pi * 2 - x)) * envelope * 0.18 * a
        end
    elseif id == "reserve_pack" then
        v.y = math.abs(math.sin(t * math.pi * 3 + x)) * envelope * 0.28 * a
    elseif id == "coin_press" then
        if group == "PressScrew" then
            v.y = -envelope * 0.3 * a
            v.ry = turn * 2
        else
            v.y = envelope * 0.16
            v.ry = turn
        end
    elseif id == "tuning_oil" then
        if group == "Drop" then
            v.y = -envelope * 0.46 * a
            v.scale = 1 - envelope * 0.25
        else
            v.rz = envelope * -0.1
        end
    elseif id == "coin" then
        v.ry = turn
        v.y = envelope * 0.15 * a
    elseif id == "restock" then
        v.rz = turn
    elseif id == "life" then
        v.y = math.abs(math.sin(t * math.pi * 2)) * envelope * 0.27 * a
        v.scale = 1 + wobble * 0.06
    elseif id == "score" then
        v.y = math.max(0, math.sin(t * math.pi * 2 - x)) * envelope * 0.25 * a
    elseif id == "lock" then
        v.y = envelope * 0.28 * a
        v.ry = envelope * 0.2
    elseif id == "jumble" then
        v.x = math.sin(t * math.pi * 2) * envelope * -y * 0.4
        v.y = math.sin(t * math.pi * 2) * envelope * x * 0.4
    end
    return Choreography.part(id, group, authoredT, a, x, y, z, v)
end

function ItemMotion.new(model, id, options)
    local center = model:GetAttribute("ArtCenter") or Vector3.zero
    local _, restSize = model:GetBoundingBox()
    local reducedMotion = options and options.reducedMotion == true
    local records = {}
    local assemblies = {}
    for _, object in ipairs(model:GetChildren()) do
        if object:IsA("BasePart") then
            local group = object:GetAttribute("MotionGroup") or "Fixed"
            local origin = pivots[group]
            local authoredPivot = object:GetAttribute("MotionPivot")
            table.insert(records, {
                object = object,
                group = group,
                frame = object.CFrame,
                size = object.Size,
                color = object.Color,
                authored = object:GetAttribute("AuthoredPosition"),
                pivot = authoredPivot and authoredPivot - center or (origin and Vector3.new(
                    origin[1],
                    origin[2],
                    origin[3]
                ) - center or object.Position),
                springA = object:GetAttribute("SpringA"),
                springB = object:GetAttribute("SpringB"),
            })
        end
    end
    for _, record in records do
        local pivot = record.pivot
        local key = string.format("%s:%.9g:%.9g:%.9g", record.group, pivot.X, pivot.Y, pivot.Z)
        local assembly = assemblies[key]
        if not assembly then
            assembly = { authored = Vector3.zero, count = 0 }
            assemblies[key] = assembly
        end
        assembly.authored += record.authored
        assembly.count += 1
        record.assembly = assembly
    end
    for _, assembly in assemblies do
        assembly.authored /= assembly.count
    end
    local controller = { duration = profiles[id].duration, profile = profiles[id].name }
    function controller:apply(t, strength, rootPose)
        rootPose = rootPose or CFrame.new()
        local body = ItemMotion.bodySample(id, t, strength)
        if reducedMotion and strength ~= 0 then
            body = Choreography.Curves.body()
            body.scale = 1 + 0.04 * Choreography.Curves.pulse(t, 0, 0.35, 1)
        end
        local bodyRoot = rootPose
            * CFrame.new(body.x * restSize.X, body.y * restSize.Y, body.z * restSize.Z)
            * CFrame.Angles(body.rx, body.ry, body.rz)
        for _, record in ipairs(records) do
            local object, p = record.object, record.authored
            local phasePosition = record.assembly.authored
            if t ~= t or t <= 0 or t >= 1 then
                object.CFrame = rootPose * record.frame
                object.Size = record.size
                object.Color = record.color
                continue
            end
            local state = ItemMotion.sample(
                id,
                record.group,
                if reducedMotion then 0 else t,
                strength,
                phasePosition.X,
                phasePosition.Y,
                phasePosition.Z
            )
            local offset = Vector3.new(state.x, state.y, state.z)
            local transform = CFrame.new(record.pivot + offset)
                * CFrame.Angles(state.rx, state.ry, state.rz)
            local frame, dimensions
            if id == "spring_coil" and record.springA and t > 0 and t < 1 then
                local a, b = record.springA, record.springB
                a = Vector3.new(a.X, -1 + (a.Y + 1) * state.axial, a.Z) - center
                b = Vector3.new(b.X, -1 + (b.Y + 1) * state.axial, b.Z) - center
                frame = CFrame.lookAt((a + b) / 2, b) * CFrame.Angles(0, math.pi / 2, 0)
                dimensions = Vector3.new((b - a).Magnitude, record.size.Y, record.size.Z)
            elseif id == "spring_coil" and record.group == "Shaft" then
                local position = record.frame.Position
                local y = -1 + (p.Y + 1) * state.axial - center.Y
                frame = record.frame + Vector3.new(0, y - position.Y, 0)
                dimensions = Vector3.new(record.size.X * state.axial, record.size.Y, record.size.Z)
            elseif id == "tidal_engine" and record.group == "EvolvedSpring" then
                -- Native coil consists of horizontal rings. Move each complete
                -- ring along the spring axis without inflating its wire gauge.
                local lift = (record.pivot.Y + center.Y + 0.45) * (state.axial - 1)
                frame = record.frame + Vector3.new(0, lift, 0)
                dimensions = record.size
            else
                if id == "tidal_engine" and record.group == "EvolvedWeight" then
                    transform = CFrame.new(
                        record.pivot + Vector3.new(state.x, state.y * 1.47 / 1.46, state.z)
                    ) * CFrame.Angles(state.rx, state.ry, state.rz)
                end
                frame = transform
                    * CFrame.new((record.frame.Position - record.pivot) * state.scale)
                    * record.frame.Rotation
                dimensions = record.size * state.scale
            end
            object.CFrame = bodyRoot * CFrame.new(frame.Position * body.scale) * frame.Rotation
            object.Size = dimensions * body.scale
            object.Color = record.color:Lerp(Color3.new(1, 1, 1), math.clamp(state.glow, 0, 0.22))
        end
    end
    return controller
end

return ItemMotion
