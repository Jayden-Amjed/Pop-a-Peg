-- Gallery-only instrument design. Native/game sound definitions stay frozen.
-- Every partial is the existing C4 sine asset at a different playback rate.
-- Inharmonic bells, odd-harmonic reeds, detuned air, plucks and falling impacts
-- vary the spectrum and envelope, not only the musical transposition.
local Bank = { Profiles = {}, Limits = { voices = 12, pending = 32, mix = 0.32 } }

Bank.Timbres = {
    glass = {
        partials = { { 1, 1, 1 }, { 2.76, 0.24, 0.60 }, { 4.07, 0.10, 0.40 } },
        attack = 0.006,
        decay = 4.6,
    },
    bell = {
        partials = { { 1, 1, 1 }, { 2.40, 0.38, 0.78 }, { 3.86, 0.20, 0.55 } },
        attack = 0.004,
        decay = 3.1,
    },
    reed = {
        partials = { { 1, 1, 1 }, { 3, 0.34, 0.83 }, { 5, 0.16, 0.61 } },
        attack = 0.027,
        decay = 1.7,
        vibrato = 12,
        vibratoRate = 7,
    },
    electric = {
        partials = { { 1, 1, 1 }, { 2, 0.46, 0.75 }, { 3.01, 0.29, 0.55 } },
        attack = 0.005,
        decay = 3.0,
        tremolo = 0.26,
        tremoloRate = 17,
    },
    water = {
        partials = { { 1, 1, 1 }, { 1.51, 0.13, 0.55 } },
        attack = 0.004,
        decay = 5.6,
        bend = 13,
    },
    air = {
        partials = { { 1, 0.75, 1 }, { 1.008, 0.40, 0.97 }, { 2, 0.10, 0.70 } },
        attack = 0.072,
        decay = 1.5,
        vibrato = 18,
        vibratoRate = 4.1,
    },
    wood = {
        partials = { { 1, 1, 1 }, { 2.81, 0.30, 0.36 }, { 4.33, 0.12, 0.20 } },
        attack = 0.003,
        decay = 7.8,
        bend = 2.4,
    },
    bass = {
        partials = { { 1, 1, 1 }, { 2, 0.26, 0.66 }, { 3, 0.12, 0.45 } },
        attack = 0.006,
        decay = 5.0,
        bend = 15,
    },
    organ = {
        partials = { { 1, 0.78, 1 }, { 2, 0.30, 0.92 }, { 3, 0.18, 0.73 } },
        attack = 0.045,
        decay = 1.2,
        tremolo = 0.13,
        tremoloRate = 5.2,
    },
    pluck = {
        partials = { { 1, 1, 1 }, { 2, 0.25, 0.53 }, { 4, 0.11, 0.31 } },
        attack = 0.004,
        decay = 5.4,
        bend = -1.2,
    },
    sonar = {
        partials = { { 1, 0.92, 1 }, { 1.997, 0.17, 0.83 } },
        attack = 0.011,
        decay = 2.1,
        bend = -4.5,
        vibrato = 7,
        vibratoRate = 5.8,
    },
    metal = {
        partials = { { 1, 1, 1 }, { 1.43, 0.31, 0.44 }, { 3.72, 0.18, 0.29 } },
        attack = 0.0025,
        decay = 6.2,
        bend = 3,
    },
}

local function add(id, timbre, notes, rhythm, duration, description, options)
    assert(
        not Bank.Profiles[id] and Bank.Timbres[timbre],
        "Duplicate ID or unknown instrument: " .. id
    )
    assert(#notes == #rhythm and #notes <= 5, "Unbounded or incomplete sound phrase: " .. id)
    local profile = options or {}
    profile.timbre, profile.notes, profile.rhythm = timbre, notes, rhythm
    profile.duration, profile.description = duration, description
    Bank.Profiles[id] = profile
end

-- Mechanisms: short impacts, metallic pips, ratchets and distinctly low motors.
add(
    "tap_driver",
    "wood",
    { -14, -2 },
    { 0, 0.085 },
    0.20,
    "Dry double wooden knock",
    { cue = "pop", cueGain = 0.20 }
)
add("split_prism", "glass", { 5, 12, 9 }, { 0, 0.035, 0.13 }, 0.39, "Three split glass rays")
add("wall_meter", "metal", { -12, -5, -12 }, { 0, 0.10, 0.22 }, 0.15, "Low metal wall counter")
add(
    "clockwork",
    "wood",
    { 7, 7, 2, 14 },
    { 0, 0.055, 0.12, 0.25 },
    0.12,
    "Four dry clock ticks",
    { cue = "click", cueGain = 0.20 }
)
add(
    "burst_capsule",
    "bass",
    { -23, -11 },
    { 0, 0.095 },
    0.31,
    "Falling capsule thump and cap ping",
    { cue = "restock", cueGain = 0.24 }
)
add(
    "relay",
    "electric",
    { -17, -10, -17, -5 },
    { 0, 0.075, 0.16, 0.31 },
    0.32,
    "Low coil buzz with stepped voltage",
    { tremoloRate = 14, bend = 5 }
)
add(
    "landing_fund",
    "bell",
    { 0, 7, 12 },
    { 0, 0.095, 0.23 },
    0.51,
    "Warm shell bell and coin glint",
    { cue = "coin", cueGain = 0.13 }
)
add("survey_lens", "sonar", { 8, -4 }, { 0, 0.19 }, 0.26, "High scan followed by a low return")
add(
    "gain_dial",
    "reed",
    { -12, -8, -5 },
    { 0, 0.07, 0.19 },
    0.25,
    "Rounded three-step dial chirrup"
)
add(
    "soft_saw",
    "air",
    { -7, 0, -2 },
    { 0, 0.10, 0.27 },
    0.42,
    "Soft descending current flutter",
    { bend = -3, tremolo = 0.28, tremoloRate = 9 }
)
add(
    "balance_scale",
    "bell",
    { -9, 3, -9 },
    { 0, 0.16, 0.33 },
    0.28,
    "Alternating bronze scale pans"
)
add("resonator", "glass", { -2, 10 }, { 0, 0.16 }, 0.54, "Clear fork strike and octave answer")
add(
    "echo_plate",
    "sonar",
    { 5, 5, 5 },
    { 0, 0.14, 0.30 },
    0.28,
    "Descending-volume echo pings",
    { fade = 0.58 }
)
add(
    "growth_array",
    "pluck",
    { -7, -3, 2, 5 },
    { 0, 0.05, 0.15, 0.27 },
    0.22,
    "Four springy sprout plucks"
)
add(
    "quota_bonus",
    "metal",
    { -18, 6 },
    { 0, 0.12 },
    0.24,
    "Heavy stamp with bright register ping",
    { cue = "pop", cueGain = 0.19 }
)
add(
    "spring_coil",
    "bass",
    { -20, -8, -15 },
    { 0, 0.10, 0.22 },
    0.25,
    "Elastic low boing and recoil",
    { bend = -12 }
)
add(
    "pulse_cell",
    "electric",
    { -21, -21, -9 },
    { 0, 0.14, 0.29 },
    0.23,
    "Three bass battery pulses",
    { tremoloRate = 10 }
)
add("compass", "bell", { 11, 4 }, { 0, 0.23 }, 0.32, "Small compass chime and needle stop")
add(
    "seed_bank",
    "wood",
    { -5, 2, 9 },
    { 0, 0.09, 0.21 },
    0.20,
    "Hollow seed clicks rising out of the bank"
)
add(
    "encore",
    "organ",
    { -12, -8, -5, -12 },
    { 0, 0, 0, 0.30 },
    0.54,
    "Warm speaker chord with a soft echo",
    { fade = 0.89, tremoloRate = 6.5 }
)
add("goldfish", "water", { 7, 2, 11 }, { 0, 0.11, 0.28 }, 0.19, "Bright fish bubble chatter")
add(
    "fishbowl",
    "water",
    { -12, -5, 0 },
    { 0, 0.15, 0.32 },
    0.28,
    "Deep bowl glugs with a glass rim",
    { bend = 7 }
)

-- Discovery objects: stronger contrasts in texture, register and time shape.
add(
    "rain_catcher",
    "water",
    { 4, -3, 9, 2 },
    { 0, 0.07, 0.18, 0.34 },
    0.16,
    "Uneven falling raindrop taps",
    { fade = 0.94 }
)
add(
    "bubble_wand",
    "water",
    { 12, 5 },
    { 0, 0.065 },
    0.19,
    "One bright joined bubble pop",
    { bend = 19, cue = "pop", cueGain = 0.16 }
)
add(
    "lily_pad",
    "pluck",
    { -10, -3, 4 },
    { 0, 0.14, 0.31 },
    0.28,
    "Round lily pluck and water drop",
    { bend = -4 }
)
add(
    "solar_leaf",
    "glass",
    { 9, 16, 12 },
    { 0, 0.12, 0.30 },
    0.35,
    "Sunlit leaf sparkle with a high fall"
)
add(
    "mist_fan",
    "air",
    { -16, -9, -4, -9 },
    { 0, 0.10, 0.23, 0.39 },
    0.44,
    "Breezy paper rotor flutter",
    { tremolo = 0.40, tremoloRate = 12, bend = 4 }
)
add(
    "coral_fork",
    "electric",
    { 9, -3, 14 },
    { 0, 0.035, 0.13 },
    0.16,
    "Sharp coral arc crackle",
    { tremolo = 0.48, tremoloRate = 21, cue = "trigger", cueGain = 0.18 }
)
add(
    "tide_valve",
    "bass",
    { -24, -17, -12 },
    { 0, 0.12, 0.32 },
    0.33,
    "Pressure valve kick with a wet release",
    { cue = "merge", cueGain = 0.22, bend = 8 }
)
add(
    "dew_lantern",
    "glass",
    { -5, 7 },
    { 0, 0.16 },
    0.62,
    "Lamp switch with a warm glass bloom",
    { attack = 0.065, cue = "click", cueGain = 0.13 }
)
add(
    "moss_capacitor",
    "electric",
    { -19, -7, -12 },
    { 0, 0.18, 0.35 },
    0.35,
    "Spongy low charge and discharge",
    { attack = 0.04, bend = -7, tremoloRate = 8 }
)
add(
    "pearl_diver",
    "sonar",
    { -8, 4, -1, 11 },
    { 0, 0.13, 0.29, 0.46 },
    0.31,
    "Orbiting pearl sonar answers",
    { fade = 0.93, bend = -2 }
)
add(
    "stream_wheel",
    "wood",
    { 2, 5, 9, 14 },
    { 0, 0.07, 0.15, 0.26 },
    0.16,
    "Wooden paddle clacks speeding up"
)
add(
    "cloud_mirror",
    "air",
    { 7, 14, 7 },
    { 0, 0.18, 0.40 },
    0.56,
    "High airy reflection with a delayed return",
    { vibratoRate = 3 }
)
add(
    "nectar_pump",
    "water",
    { -15, -8, -3 },
    { 0, 0.19, 0.33 },
    0.23,
    "Sticky low pump gulps",
    { bend = 4, cue = "pop", cueGain = 0.12 }
)
add(
    "lagoon_synth",
    "reed",
    { -14, -7, -2, -7, 3 },
    { 0, 0.13, 0.26, 0.39, 0.52 },
    0.32,
    "Traveling liquid synth phrase",
    { bend = -5, vibratoRate = 6, tremolo = 0.18, tremoloRate = 8 }
)
add(
    "aurora_kite",
    "air",
    { 0, 7, 12, 19 },
    { 0, 0.10, 0.25, 0.43 },
    0.38,
    "Rising wind ribbon",
    { bend = 3 }
)
add(
    "biolume_jar",
    "glass",
    { -7, 5, 0, 12 },
    { 0, 0.06, 0.25, 0.43 },
    0.37,
    "Tiny glowing glass taps",
    { fade = 0.91 }
)
add(
    "ozone_orb",
    "bass",
    { -24, -12, -5 },
    { 0, 0.09, 0.30 },
    0.46,
    "Sub-bass orb charge with electric shimmer",
    { bend = 18, tremolo = 0.25, tremoloRate = 11 }
)
add(
    "monsoon_loom",
    "reed",
    { -21, -14, -9, -2 },
    { 0, 0.08, 0.24, 0.38 },
    0.33,
    "Low woven reed sweep",
    { cue = "restock", cueGain = 0.16, bend = 6 }
)

add("reserve_pack", "wood", { 0, 4, 9 }, { 0, 0.12, 0.29 }, 0.20, "Three rounded ball-case knocks")
add(
    "coin_press",
    "metal",
    { -20, 12, 7 },
    { 0, 0.08, 0.22 },
    0.25,
    "Press clunk then two metallic coin rings",
    { cue = "coin", cueGain = 0.16 }
)
add(
    "tuning_oil",
    "water",
    { -9, 3, 8 },
    { 0, 0.17, 0.31 },
    0.22,
    "Oil drop with a polished finish",
    { bend = 10 }
)
add(
    "first_spark",
    "electric",
    { 12, 19 },
    { 0, 0.055 },
    0.13,
    "Tiny high spark zip",
    { gain = 0.065 }
)
add(
    "tailwind",
    "air",
    { -5, 2, 9 },
    { 0, 0.12, 0.32 },
    0.46,
    "Gentle accelerating tailwind",
    { bend = -7 }
)
add("ricochet", "wood", { -2, 10, -2 }, { 0, 0.13, 0.25 }, 0.15, "Hollow high-low bounce")
add("growth_ring", "organ", { -17, -10, -5 }, { 0, 0.10, 0.30 }, 0.42, "Warm root chord unfolding")
add(
    "recovery",
    "sonar",
    { -19, -7 },
    { 0, 0.27 },
    0.43,
    "Two rounded restorative pulses",
    { bend = 2 }
)
add("last_word", "bell", { 7, 3, -5 }, { 0, 0.19, 0.38 }, 0.39, "Three deliberate closing bells")
add(
    "metronome",
    "wood",
    { 14, 7, 14, 2 },
    { 0, 0.12, 0.24, 0.36 },
    0.10,
    "Sharp alternating metronome blocks"
)
add(
    "milestone",
    "bell",
    { -5, 2, 7, 14 },
    { 0, 0.09, 0.22, 0.39 },
    0.40,
    "Four bright milestone bells"
)

-- Evolutions combine a new register/rhythm with the material of their mechanism.
add(
    "aurora_aquarium",
    "water",
    { -12, 0, 7, 16 },
    { 0, 0.11, 0.28, 0.46 },
    0.31,
    "Deep-to-bright aquarium cascade",
    { bend = 9 }
)
add(
    "spectrum_reef",
    "glass",
    { 0, 7, 14, 19 },
    { 0, 0.025, 0.15, 0.34 },
    0.41,
    "Prismatic cascading reef glass"
)
add(
    "tidal_engine",
    "bass",
    { -24, -24, -12, -17 },
    { 0, 0.11, 0.26, 0.46 },
    0.29,
    "Four heavy engine strokes",
    { cue = "restock", cueGain = 0.25, bend = 9 }
)
add(
    "storm_clock",
    "electric",
    { -12, 0, -5, 7 },
    { 0, 0.06, 0.22, 0.40 },
    0.24,
    "Thunder-clock ticking voltage",
    { tremoloRate = 19 }
)
add(
    "horizon_observatory",
    "sonar",
    { -5, 7, 14, 2 },
    { 0, 0.18, 0.35, 0.51 },
    0.33,
    "Wide ascending observatory scan"
)
add(
    "eden_greenhouse",
    "organ",
    { -12, -7, 0, 4 },
    { 0, 0, 0.18, 0.37 },
    0.56,
    "Lush greenhouse chord bloom"
)
add(
    "pearl_turbine",
    "metal",
    { -7, 0, 5, 12 },
    { 0, 0.08, 0.18, 0.34 },
    0.26,
    "Turbine metal with pearl overtones",
    { bend = -4 }
)
add(
    "current_nexus",
    "electric",
    { -19, -7, 0, 7 },
    { 0, 0.07, 0.20, 0.39 },
    0.36,
    "Interlocking nexus surge",
    { tremoloRate = 12, bend = 8 }
)
add(
    "ocean_orchestra",
    "organ",
    { -17, -12, -8, -5 },
    { 0, 0, 0.13, 0.30 },
    0.64,
    "Deep ocean chord and brass-like harmonics",
    { vibrato = 10, vibratoRate = 5.5 }
)
add(
    "bubble_reactor",
    "bass",
    { -22, -10, 2, 9 },
    { 0, 0.08, 0.25, 0.41 },
    0.27,
    "Reactor kick climbing into bubble chirps",
    { bend = 20 }
)
add(
    "solar_treasury",
    "bell",
    { -2, 5, 10, 17 },
    { 0, 0.06, 0.23, 0.42 },
    0.46,
    "Gold treasury peal",
    { cue = "coin", cueGain = 0.18 }
)
add(
    "sun_koi",
    "pluck",
    { 4, 9, 16, 11 },
    { 0, 0.09, 0.28, 0.44 },
    0.27,
    "Koi leap with warm sun-string plucks"
)
add(
    "tide_gyroscope",
    "reed",
    { -19, -12, -5, 0 },
    { 0, 0.10, 0.26, 0.43 },
    0.36,
    "Rotating low gyroscope hum",
    { tremolo = 0.31, tremoloRate = 9, bend = -6 }
)

-- Review-only utilities also have distinct instruments rather than borrowed motifs.
add(
    "coin",
    "metal",
    { 12, 19 },
    { 0, 0.07 },
    0.22,
    "Single bright minted coin",
    { cue = "coin", cueGain = 0.20 }
)
add("life", "water", { -2, 10 }, { 0, 0.16 }, 0.24, "Soft ball pop and bright recovery")
add(
    "lock",
    "metal",
    { -9, -21 },
    { 0, 0.10 },
    0.13,
    "Small lock click and low latch",
    { cue = "click", cueGain = 0.22 }
)
add(
    "restock",
    "bass",
    { -17, -10, 2 },
    { 0, 0.095, 0.24 },
    0.28,
    "Restock mechanism thump and fill",
    { cue = "restock", cueGain = 0.23 }
)
add("score", "pluck", { 2, 9, 14 }, { 0, 0.055, 0.17 }, 0.26, "Score counter plucks climbing fast")
add(
    "jumble",
    "wood",
    { -5, 7, 0, 12 },
    { 0, 0.10, 0.23, 0.38 },
    0.17,
    "Irregular shuffling peg knocks"
)
add(
    "event_growth",
    "organ",
    { -15, -8, -3, 4 },
    { 0, 0.08, 0.26, 0.43 },
    0.44,
    "Broad growth event bloom"
)
add(
    "event_overtime",
    "reed",
    { -8, -1, 6, -1 },
    { 0, 0.10, 0.21, 0.37 },
    0.22,
    "Time-stretch winding call",
    { bend = -9 }
)
add(
    "event_repair",
    "sonar",
    { -12, 0, 5 },
    { 0, 0.21, 0.41 },
    0.30,
    "Repair heartbeat and confirmation",
    { bend = 4 }
)
add(
    "event_upgrade",
    "glass",
    { 2, 9, 16, 21 },
    { 0, 0.08, 0.18, 0.34 },
    0.31,
    "Ascending upgrade glass ladder"
)
add(
    "chest_common",
    "wood",
    { -12, 0, 7 },
    { 0, 0.10, 0.27 },
    0.30,
    "Meadow wooden latch and warm reward"
)
add(
    "chest_uncommon",
    "water",
    { -14, -2, 5, 10 },
    { 0, 0.08, 0.23, 0.41 },
    0.32,
    "Lagoon pressure glug and pearl reveal"
)
add(
    "chest_rare",
    "bell",
    { -9, 3, 10, 15 },
    { 0, 0.07, 0.22, 0.40 },
    0.49,
    "Aurora metal blossom and long shimmer"
)
add(
    "chest_legendary",
    "organ",
    { -24, -12, -5, 4 },
    { 0, 0, 0.14, 0.34 },
    0.72,
    "Celestial bass chord opening into light",
    { cue = "restock", cueGain = 0.27 }
)

local function finite(value, fallback)
    return if type(value) == "number"
            and value == value
            and math.abs(value) < math.huge
        then value
        else fallback
end
local function smooth(t)
    t = math.clamp(t, 0, 1)
    return t * t * (3 - 2 * t)
end

function Bank.notes(id, gain)
    local profile = Bank.Profiles[id]
    if not profile then
        return nil
    end
    local instrument = Bank.Timbres[profile.timbre]
    local notes = {}
    gain = math.clamp(finite(gain, 1), 0, 1)
    for index, semitones in profile.notes do
        for _, partial in instrument.partials do
            local duration = profile.duration * partial[3]
            table.insert(notes, {
                wait = profile.rhythm[index],
                duration = duration,
                pitch = math.clamp(2 ^ (semitones / 12) * partial[1], 0.18, 6),
                gain = (profile.gain or 0.071)
                    * partial[2]
                    * (profile.fade or 0.95) ^ (index - 1)
                    * gain,
                attack = profile.attack or instrument.attack,
                decay = profile.decay or instrument.decay,
                bend = profile.bend or instrument.bend or 0,
                vibrato = profile.vibrato or instrument.vibrato or 0,
                vibratoRate = profile.vibratoRate or instrument.vibratoRate or 0,
                tremolo = profile.tremolo or instrument.tremolo or 0,
                tremoloRate = profile.tremoloRate or instrument.tremoloRate or 0,
            })
        end
    end
    return notes
end

function Bank.sample(note, age)
    age = finite(age, 0)
    local t = math.clamp(age / note.duration, 0, 1)
    local attack = smooth(age / note.attack)
    local release = smooth((1 - t) / 0.18)
    local tremolo = 1 - note.tremolo * (0.5 - 0.5 * math.cos(age * note.tremoloRate * math.pi * 2))
    local envelope = attack * release * math.exp(-note.decay * t) * tremolo
    local bend = note.bend * (1 - smooth(t / 0.48))
    local vibrato = note.vibrato * math.sin(age * note.vibratoRate * math.pi * 2) * smooth(t / 0.2)
    local pitch = note.pitch * 2 ^ (bend / 12 + vibrato / 1200)
    return math.max(0, note.gain * envelope), math.clamp(pitch, 0.16, 8)
end

function Bank.mixGain(volume)
    return if volume <= Bank.Limits.mix then 1 else Bank.Limits.mix / volume
end

function Bank.describe(id)
    local profile = Bank.Profiles[id]
    if not profile then
        return nil
    end
    local low, high, duration = math.huge, -math.huge, 0
    for index, note in profile.notes do
        low, high = math.min(low, note), math.max(high, note)
        duration = math.max(duration, profile.rhythm[index] + profile.duration)
    end
    return {
        id = id,
        timbre = profile.timbre,
        description = profile.description,
        notes = #profile.notes,
        partials = #Bank.Timbres[profile.timbre].partials,
        lowSemitone = low,
        highSemitone = high,
        duration = duration,
        attackCue = profile.cue,
    }
end

return Bank
