-- Review-only sound placement. Phases follow the motion clock, so changing
-- preview speed moves the attack with the mechanism without transposing it.
local Bank = if script
    then require(script.Parent.GallerySoundBank)
    else require("./GallerySoundBank")

local Timeline = {}

local impacts = {
    bubble_wand = 0.68,
    burst_capsule = 0.30,
    coin_press = 0.40,
    spring_coil = 0.30,
    quota_bonus = 0.32,
    gain_dial = 0.33,
    survey_lens = 0.32,
    compass = 0.36,
    clockwork = 0.30,
    seed_bank = 0.38,
    growth_array = 0.42,
    goldfish = 0.38,
    fishbowl = 0.40,
    first_spark = 0.29,
    tailwind = 0.36,
    ricochet = 0.22,
    growth_ring = 0.46,
    recovery = 0.40,
    last_word = 0.50,
    metronome = 0.31,
    milestone = 0.40,
    coral_fork = 0.24,
    dew_lantern = 0.18,
    encore = 0.26,
    lagoon_synth = 0.16,
    landing_fund = 0.38,
    lily_pad = 0.34,
    mist_fan = 0.16,
    ozone_orb = 0.18,
    pearl_diver = 0.22,
    relay = 0.20,
    soft_saw = 0.30,
    coin = 0.30,
    life = 0.28,
    lock = 0.36,
    restock = 0.32,
    score = 0.36,
    jumble = 0.20,
    event_growth = 0.38,
    event_overtime = 0.36,
    event_repair = 0.38,
    event_upgrade = 0.38,
}

local function item(id, phase, gain)
    return { kind = "item", id = id, phase = phase, gain = gain or 1 }
end

local function cue(id, phase, pitch, gain)
    return { kind = "cue", id = id, phase = phase, pitch = pitch or 1, gain = gain or 1 }
end

local chestTier = {
    chest_common = 1,
    chest_uncommon = 2,
    chest_rare = 3,
    chest_legendary = 4,
}

function Timeline.forId(id)
    local tier = chestTier[id]
    if tier then
        -- Increasingly close rattles leave nearly two seconds of anticipation
        -- before the cap/lid attack. The low burst lands on the .56 BOOM pose.
        local events = {}
        for index, phase in { 0.08, 0.20, 0.30, 0.38, 0.44, 0.49 } do
            table.insert(events, cue("click", phase, 0.76 + index * 0.025, 0.18 + index * 0.065))
        end
        table.insert(events, cue("restock", 0.56, 0.88 + tier * 0.035, 0.8))
        table.insert(events, item(id, 0.56, 0.65 + tier * 0.07))
        table.insert(events, cue("clear", 0.64, 0.84 + tier * 0.09, 0.55 + tier * 0.08))
        return events
    end
    if Bank.Profiles[id] then
        return { item(id, impacts[id] or 0.28) }
    end
    return nil
end

return Timeline
