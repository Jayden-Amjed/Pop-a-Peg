-- Distinct, short musical signatures and visual accents for every catalog entry.
-- Notes are semitone offsets from the public C4 sine-wave sample.
local Feedback = { Profiles = {} }

local function add(id, notes, rhythm, color, style)
    Feedback.Profiles[id] = {
        notes = notes,
        rhythm = rhythm,
        color = color,
        style = style,
        duration = 0.16,
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

return Feedback
