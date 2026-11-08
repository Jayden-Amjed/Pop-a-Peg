-- Distinct, short musical signatures and visual accents for every catalog entry.
-- Notes are semitone offsets from the public C4 sine-wave sample.
local Feedback = {
    Profiles = {},
    Limits = table.freeze({ total = 240, decoration = 184, burst = 18, reducedBurst = 3 }),
}

local function add(id, notes, rhythm, color, style)
    Feedback.Profiles[id] = {
        notes = notes,
        rhythm = rhythm,
        color = color,
        style = style,
        duration = 0.16,
        particles = 12,
        reach = 78,
        shape = "orb",
        spin = 1,
    }
end

local aqua = { 71, 211, 237 }
local blue = { 91, 161, 248 }
local lime = { 161, 222, 94 }
local gold = { 255, 205, 92 }
local violet = { 181, 161, 250 }
local coral = { 255, 151, 105 }

add("tap_driver", { 0, 12 }, { 0, 0.07 }, aqua, "tap")
add("split_prism", { 7, 12, 19 }, { 0, 0.065, 0.13 }, violet, "prism")
add("wall_meter", { -5, 7 }, { 0, 0.10 }, blue, "meter")
add("clockwork", { 0, 4, 7, 12 }, { 0, 0.045, 0.08, 0.105 }, gold, "clock")
add("burst_capsule", { -12, 0, 7 }, { 0, 0.025, 0.05 }, coral, "burst")
add("relay", { 0, 7, 14 }, { 0, 0.09, 0.18 }, aqua, "relay")
add("landing_fund", { -7, 0, 4 }, { 0, 0.055, 0.11 }, gold, "landing")
add("survey_lens", { 12, 7 }, { 0, 0.12 }, blue, "scan")
add("gain_dial", { 0, 7, 12 }, { 0, 0.065, 0.13 }, violet, "dial")
add("soft_saw", { 7, 2, -3 }, { 0, 0.055, 0.11 }, aqua, "trim")
add("balance_scale", { -5, 0, -5 }, { 0, 0.085, 0.17 }, gold, "balance")
add("resonator", { 2, 9, 14 }, { 0, 0.035, 0.07 }, aqua, "resonance")
add("echo_plate", { 12, 7, 0 }, { 0, 0.075, 0.15 }, violet, "echo")
add("growth_array", { 0, 5, 9, 12 }, { 0, 0.055, 0.11, 0.165 }, lime, "grow")
add("quota_bonus", { 7, 11, 14 }, { 0, 0.055, 0.11 }, gold, "quota")
add("spring_coil", { -12, 12, 0 }, { 0, 0.06, 0.15 }, aqua, "spring")
add("pulse_cell", { 0, 0, 12 }, { 0, 0.055, 0.16 }, blue, "pulse")
add("compass", { 9, 4, 16 }, { 0, 0.06, 0.12 }, gold, "compass")
add("seed_bank", { -5, 2, 7 }, { 0, 0.065, 0.13 }, lime, "seed")
add("encore", { 0, 4, 7, 16 }, { 0, 0.035, 0.07, 0.14 }, violet, "chorus")
add("goldfish", { 4, 11, 16 }, { 0, 0.09, 0.15 }, coral, "fish")
add("fishbowl", { -7, 5, 12 }, { 0, 0.07, 0.19 }, aqua, "bubbles")

add("reserve_pack", { -5, 4, 12 }, { 0, 0.08, 0.16 }, blue, "reserve")
add("coin_press", { 7, 14, 19 }, { 0, 0.05, 0.10 }, gold, "coins")
add("tuning_oil", { 2, 7, 16 }, { 0, 0.07, 0.14 }, aqua, "polish")
add("first_spark", { 12, 16, 19 }, { 0, 0.04, 0.08 }, gold, "spark")
add("tailwind", { -5, 7, 14 }, { 0, 0.075, 0.15 }, aqua, "wind")
add("ricochet", { 0, 12, 7 }, { 0, 0.05, 0.14 }, blue, "bounce")
add("growth_ring", { -7, 0, 9 }, { 0, 0.07, 0.14 }, lime, "bloom")
add("recovery", { -12, -5, 4 }, { 0, 0.08, 0.16 }, lime, "recover")
add("last_word", { 7, 4, 0 }, { 0, 0.09, 0.18 }, violet, "last")
add("metronome", { 5, 5, 12 }, { 0, 0.065, 0.13 }, blue, "tempo")
add("milestone", { 0, 9, 16 }, { 0, 0.055, 0.11 }, gold, "milestone")

-- Evolved motifs retain the bright, short electronic register while adding a
-- fourth note. Their larger bursts celebrate two fully upgraded abilities.
local evolved = {
    { "aurora_aquarium", { 4, 12, 19, 16 }, aqua, "aquarium", "bubble", 1.7 },
    { "spectrum_reef", { 7, 14, 19, 24 }, violet, "spectrum", "diamond", 2.4 },
    { "tidal_engine", { -7, 0, 12, 7 }, blue, "tidal", "streak", -2 },
    { "storm_clock", { 0, 7, 16, 19 }, gold, "storm", "spark", 3 },
    { "horizon_observatory", { 9, 16, 12, 21 }, blue, "horizon", "diamond", -1.3 },
    { "eden_greenhouse", { 0, 5, 12, 17 }, lime, "eden", "leaf", 1.1 },
    { "pearl_turbine", { -5, 2, 9, 14 }, aqua, "pearl", "orb", -2.6 },
    { "current_nexus", { 0, 7, 14, 21 }, violet, "nexus", "spark", 2.8 },
    { "ocean_orchestra", { 4, 7, 12, 16 }, gold, "orchestra", "note", -1.8 },
    { "bubble_reactor", { -12, 0, 12, 19 }, coral, "reactor", "bubble", 2.2 },
    { "solar_treasury", { 7, 11, 19, 23 }, gold, "treasury", "diamond", 1.5 },
    { "sun_koi", { 4, 9, 16, 21 }, coral, "koi", "leaf", -1.6 },
    { "tide_gyroscope", { -5, 7, 12, 24 }, aqua, "gyroscope", "streak", 3.2 },
}
for _, entry in ipairs(evolved) do
    add(entry[1], entry[2], { 0, 0.045, 0.10, 0.18 }, entry[3], entry[4])
    local profile = Feedback.Profiles[entry[1]]
    profile.evolved = true
    profile.particles, profile.reach, profile.shape, profile.spin = 18, 115, entry[5], entry[6]
end

local looks = {
    tap = { "streak", 1.0 },
    prism = { "diamond", 1.8 },
    meter = { "streak", -0.8 },
    clock = { "spark", 2.6 },
    burst = { "spark", -1.7 },
    relay = { "streak", 1.4 },
    landing = { "diamond", -0.5 },
    scan = { "diamond", 0.7 },
    dial = { "spark", -2.4 },
    trim = { "leaf", -1.1 },
    balance = { "orb", 0.8 },
    resonance = { "note", 2.1 },
    echo = { "note", -1.3 },
    grow = { "leaf", 1.6 },
    quota = { "diamond", 2.2 },
    spring = { "streak", -2.0 },
    pulse = { "spark", 1.9 },
    compass = { "diamond", -2.7 },
    seed = { "leaf", 0.9 },
    chorus = { "note", -1.9 },
    fish = { "leaf", 1.3 },
    bubbles = { "bubble", -0.9 },
    reserve = { "bubble", 1.2 },
    coins = { "diamond", 1.7 },
    polish = { "spark", -1.6 },
    spark = { "spark", 2.0 },
    wind = { "streak", -1.2 },
    bounce = { "orb", 1.8 },
    bloom = { "leaf", 0.6 },
    recover = { "bubble", -0.7 },
    last = { "note", 1.5 },
    tempo = { "spark", -2.3 },
    milestone = { "diamond", 0.5 },
}
for _, profile in pairs(Feedback.Profiles) do
    local look = looks[profile.style]
    if look then
        profile.shape, profile.spin = look[1], look[2]
    end
end

function Feedback.burst(id, reducedMotion, impact)
    local profile = Feedback.Profiles[id]
    if not profile then
        return nil
    end
    return {
        count = if reducedMotion
            then Feedback.Limits.reducedBurst
            elseif impact then math.min(8, profile.particles)
            else profile.particles,
        reach = if reducedMotion then 18 elseif impact then profile.reach * 0.55 else profile.reach,
        duration = if reducedMotion then 0.3 elseif impact then 0.42 else 0.62,
        shape = profile.shape,
        spin = if reducedMotion then 0 else profile.spin,
        orbit = not reducedMotion and not impact,
    }
end

return Feedback
