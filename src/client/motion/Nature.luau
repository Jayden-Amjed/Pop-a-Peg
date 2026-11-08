-- Nature uses readable organic impulses; evolutions combine their actual mechanisms.
-- Whole-body motion carries housings and attached parts together. Part motion is
-- reserved for authored joints, free particles, and contained moving contents.
return function(C)
    local P, R = C.pulse, C.ring

    local function pose(x, y, z, rx, ry, rz, scale)
        return { x = x, y = y, z = z, rx = rx, ry = ry, rz = rz, scale = scale }
    end

    local function spin(t, first, last, turns, a)
        return if a > 0 then C.spin(t, first, last, turns) else 0
    end

    local function clear(v)
        v.x, v.y, v.z, v.rx, v.ry, v.rz = 0, 0, 0, 0, 0, 0
        v.scale, v.axial, v.glow = 1, 1, 0
        return v
    end

    local function side(x)
        return if x < 0 then -1 else 1
    end

    return {
        goldfish = {
            duration = 1.32,
            name = "goldfish-breach-and-barrel-roll",
            description = "Ducks, darts upward through a barrel roll, and lands with a tail-driven rebound.",
            body = function(t, a)
                local crouch = P(t, 0, 0.13, 0.28)
                local leap = P(t, 0.13, 0.40, 0.77)
                local splash = R(t, 0.68, 1, 1)
                return pose(
                    R(t, 0.1, 0.86, 1) * 0.14 * a,
                    (-0.04 * crouch + 0.19 * leap + 0.035 * splash) * a,
                    leap * 0.04 * a,
                    spin(t, 0.19, 0.73, 1, a),
                    R(t, 0.1, 0.87, 1) * 0.24 * a,
                    (-0.22 * crouch + 0.30 * leap) * a,
                    1 + (-0.06 * crouch + 0.19 * leap + 0.04 * splash) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                if group == "FishTail" then
                    v.ry = R(t, 0.02, 0.94, 6) * 0.86 * a
                elseif group == "FishFin" then
                    v.rx = R(t, 0.08, 0.86, 4) * 0.58 * a
                elseif group == "Bubbles" then
                    local burst = P(t, 0.22, 0.48, 0.91)
                    v.y, v.scale = burst * 0.30 * a, 1 + burst * 0.24 * a
                end
                return v
            end,
        },
        fishbowl = {
            duration = 1.22,
            name = "fishbowl-slush-and-hop",
            description = "Winds sideways, makes a buoyant bowl hop, then rocks as its fish and water settle.",
            body = function(t, a)
                local wind = P(t, 0, 0.16, 0.34)
                local hop = P(t, 0.16, 0.35, 0.74)
                local slosh = R(t, 0.28, 1, 1.5)
                return pose(
                    -wind * 0.06 * a,
                    (hop * 0.15 - wind * 0.035) * a,
                    0,
                    hop * 0.08 * a,
                    0,
                    (wind * 0.20 + slosh * 0.13) * a,
                    1 + (-wind * 0.045 + hop * 0.15) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                local slosh = R(t, 0.18, 0.98, 1.5)
                if group == "FishBody" or group == "FishFin" or group == "FishTail" then
                    v.x, v.y = slosh * 0.085 * a, P(t, 0.25, 0.48, 0.85) * 0.035 * a
                    if group == "FishTail" then
                        v.ry = R(t, 0.1, 0.96, 5) * 0.62 * a
                    end
                    if group == "FishFin" then
                        v.rx = R(t, 0.16, 0.93, 4) * 0.36 * a
                    end
                elseif group == "Waterline" then
                    v.rz = slosh * 0.035 * a
                elseif group == "Reeds" then
                    v.rz = slosh * 0.075 * a
                end
                return v
            end,
        },
        rain_catcher = {
            duration = 1.10,
            name = "rain-catcher-heavy-drop-catch",
            description = "Reaches up to catch rain, takes a weighted impact, and springs back with a reservoir surge.",
            body = function(t, a)
                local reach = P(t, 0, 0.19, 0.39)
                local catch = P(t, 0.22, 0.35, 0.56)
                local rebound = P(t, 0.38, 0.54, 0.91)
                return pose(
                    0,
                    (0.07 * reach - 0.055 * catch + 0.13 * rebound) * a,
                    0,
                    R(t, 0.26, 1, 1.5) * 0.12 * a,
                    0,
                    0,
                    1 + (0.07 * reach - 0.06 * catch + 0.20 * rebound) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                if group == "RainDrop" then
                    local drop = P(t, 0.06 + math.abs(x) * 0.08, 0.34, 0.73)
                    v.y, v.scale = -drop * 0.40 * a, 1 - drop * 0.19 * a
                elseif group == "RainWater" then
                    v.y = P(t, 0.30, 0.50, 0.91) * 0.08 * a
                    v.glow = P(t, 0.29, 0.47, 0.89) * 0.30 * a
                end
                return v
            end,
        },
        bubble_wand = {
            duration = 1.46,
            name = "bubble-wand-baton-flourish",
            description = "Cocks back, tosses through a full front-facing baton turn, and exhales bubbles on the catch.",
            body = function(t, a)
                local wind = P(t, 0, 0.14, 0.30)
                local toss = P(t, 0.12, 0.39, 0.82)
                return pose(
                    R(t, 0.13, 0.87, 1) * 0.10 * a,
                    (toss * 0.18 - wind * 0.04) * a,
                    toss * 0.035 * a,
                    R(t, 0.14, 0.88, 1) * 0.16 * a,
                    0,
                    spin(t, 0.17, 0.76, -1, a) + wind * 0.24 * a,
                    1 + (toss * 0.21 - wind * 0.05) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                if group == "WandBubble" then
                    local release = P(t, 0.42, 0.68, 0.98)
                    v.x, v.y = release * (0.08 + math.abs(x) * 0.10) * a, release * 0.34 * a
                    v.scale = 1 + release * 0.34 * a
                end
                return v
            end,
        },
        lily_pad = {
            duration = 1.28,
            name = "lily-pad-flower-pop",
            description = "Dips like a floating trampoline, opens its petals, and tosses a dew bead through a soft rebound.",
            body = function(t, a)
                local dip = P(t, 0, 0.17, 0.33)
                local bloom = P(t, 0.17, 0.40, 0.86)
                return pose(
                    0,
                    (-dip * 0.055 + bloom * 0.17 + R(t, 0.65, 1, 1) * 0.025) * a,
                    0,
                    R(t, 0.15, 1, 1) * 0.11 * a,
                    bloom * 0.13 * a,
                    0,
                    1 + (-dip * 0.06 + bloom * 0.22) * a
                )
            end,
            part = function(group, t, a, x, _y, z, v)
                clear(v)
                local bloom = P(t, 0.15, 0.43, 0.92)
                if group == "LilyPetal" then
                    v.rx, v.rz = z * bloom * 0.80 * a, -x * bloom * 0.80 * a
                elseif group == "LilyHeart" then
                    v.scale, v.glow = 1 + bloom * 0.18 * a, bloom * 0.40 * a
                elseif group == "LilyDew" then
                    v.y = P(t, 0.28, 0.55, 0.95) * 0.42 * a
                    v.x = R(t, 0.28, 0.95, 1) * 0.12 * a
                end
                return v
            end,
        },
        solar_leaf = {
            duration = 1.24,
            name = "solar-leaf-sun-salute",
            description = "Bows toward the sun, springs upright, and fans its paired collectors open before folding home.",
            body = function(t, a)
                local bow = P(t, 0, 0.15, 0.33)
                local salute = P(t, 0.17, 0.36, 0.88)
                return pose(
                    0,
                    (-bow * 0.04 + salute * 0.12) * a,
                    0,
                    (bow * 0.21 - salute * 0.11 + R(t, 0.57, 1, 1) * 0.055) * a,
                    R(t, 0.21, 0.94, 1) * 0.12 * a,
                    0,
                    1 + (-bow * 0.045 + salute * 0.19) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                local fan = P(t, 0.19, 0.41, 0.91)
                if group == "SolarLeaf" or group == "SolarCell" or group == "SolarVein" then
                    -- All three materials share each collector's authored root.
                    v.rz = -side(x) * fan * 0.34 * a
                    v.glow = fan * (if group == "SolarCell" then 0.40 else 0.12) * a
                elseif group == "SolarSun" then
                    v.y, v.scale, v.glow = fan * 0.27 * a, 1 + fan * 0.28 * a, fan * 0.50 * a
                end
                return v
            end,
        },
        mist_fan = {
            duration = 1.16,
            name = "mist-fan-turbo-kick",
            description = "Leans into a turbo burst, recoils from its own air blast, and settles while the rotor coasts down.",
            body = function(t, a)
                local load = P(t, 0, 0.14, 0.29)
                local blast = P(t, 0.16, 0.32, 0.78)
                return pose(
                    0,
                    blast * 0.09 * a,
                    (load * 0.04 - blast * 0.10) * a,
                    (-load * 0.17 + blast * 0.23 + R(t, 0.52, 1, 1.5) * 0.09) * a,
                    0,
                    R(t, 0.22, 0.88, 2) * 0.055 * a,
                    1 + (blast * 0.18 - load * 0.04) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                if group == "MistRotor" then
                    v.rz = spin(t, 0.10, 0.94, -5, a)
                elseif group == "MistPuff" then
                    local blast = P(t, 0.18, 0.46, 0.93)
                    v.z, v.x, v.scale = blast * 0.57 * a, x * blast * 0.25 * a, 1 + blast * 0.45 * a
                end
                return v
            end,
        },
        coral_fork = {
            duration = 0.98,
            name = "coral-fork-struck-chord",
            description = "Cocks diagonally, strikes a bright chord, and answers with an elastic fork vibration.",
            body = function(t, a)
                local cock = P(t, 0, 0.14, 0.29)
                local hit = P(t, 0.16, 0.30, 0.70)
                return pose(
                    R(t, 0.15, 0.95, 2) * 0.045 * a,
                    hit * 0.13 * a,
                    hit * 0.04 * a,
                    0,
                    0,
                    (-cock * 0.27 + R(t, 0.18, 1, 2) * 0.20) * a,
                    1 + (-cock * 0.045 + hit * 0.22) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                if group == "CoralTine" or group == "CoralTip" then
                    -- Tine and attached gold tip use the same joint transform.
                    v.rz = side(x) * R(t, 0.19, 1, 5) * 0.12 * a
                    v.glow = P(t, 0.18, 0.31, 0.90) * 0.38 * a
                elseif group == "CoralCrown" then
                    v.scale = 1 + P(t, 0.22, 0.40, 0.92) * 0.17 * a
                end
                return v
            end,
        },
        tide_valve = {
            duration = 1.30,
            name = "tide-valve-pressure-release",
            description = "Braces against a stuck valve, cranks it open, then shudders as pressure escapes.",
            body = function(t, a)
                local brace = P(t, 0, 0.18, 0.37)
                local release = P(t, 0.22, 0.44, 0.86)
                return pose(
                    R(t, 0.34, 0.98, 2) * 0.045 * a,
                    (release * 0.10 - brace * 0.035) * a,
                    0,
                    0,
                    (-brace * 0.20 + release * 0.14) * a,
                    R(t, 0.23, 1, 1.5) * 0.09 * a,
                    1 + (-brace * 0.04 + release * 0.19) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                if group == "ValveWheel" then
                    v.ry = spin(t, 0.16, 0.85, -2, a) + P(t, 0, 0.13, 0.31) * 0.25 * a
                elseif group == "ValveFlow" then
                    v.glow = P(t, 0.28, 0.49, 0.95) * 0.42 * a
                end
                return v
            end,
        },
        dew_lantern = {
            duration = 1.40,
            name = "dew-lantern-wish-swing",
            description = "Swings like a lifted lantern, floats on a bright wish, and settles through a diminishing arc.",
            body = function(t, a)
                local wind = P(t, 0, 0.16, 0.34)
                local float = P(t, 0.18, 0.43, 0.90)
                return pose(
                    R(t, 0.10, 1, 1) * 0.10 * a,
                    (-wind * 0.025 + float * 0.16) * a,
                    0,
                    0,
                    float * 0.20 * a,
                    (-wind * 0.29 + R(t, 0.23, 1, 1.5) * 0.23) * a,
                    1 + (-wind * 0.035 + float * 0.17) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                local light = P(t, 0.15, 0.43, 0.96)
                if group == "LanternDrop" then
                    v.scale, v.glow = 1 + light * 0.17 * a, light * 0.48 * a
                elseif group == "LanternMote" then
                    v.x, v.y = R(t, 0.22, 0.94, 1) * 0.065 * a, light * (0.15 + x * 0.10) * a
                    v.scale, v.glow = 1 + light * 0.26 * a, light * 0.45 * a
                end
                return v
            end,
        },
        moss_capacitor = {
            duration = 1.12,
            name = "moss-capacitor-charge-discharge",
            description = "Hunkers down to charge, pops upward at discharge, and gives a short grounded electrical shiver.",
            body = function(t, a)
                local charge = P(t, 0, 0.24, 0.40)
                local discharge = P(t, 0.24, 0.37, 0.75)
                return pose(
                    R(t, 0.33, 0.94, 3) * 0.025 * a,
                    (-charge * 0.05 + discharge * 0.12) * a,
                    discharge * 0.05 * a,
                    (-charge * 0.09 + R(t, 0.35, 1, 2) * 0.11) * a,
                    0,
                    0,
                    1 + (-charge * 0.065 + discharge * 0.24) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                -- The windows and conducting bridge remain seated in their housings.
                if group == "MossCharge" then
                    v.glow = (P(t, 0.05, 0.29, 0.52) * 0.30 + P(t, 0.32, 0.43, 0.90) * 0.35) * a
                elseif group == "MossBridge" then
                    v.glow = P(t, 0.27, 0.40, 0.86) * 0.46 * a
                end
                return v
            end,
        },
        pearl_diver = {
            duration = 1.27,
            name = "pearl-diver-prize-catch",
            description = "Dips to scoop, opens its claws to present the pearl, then catches it on a springy landing.",
            body = function(t, a)
                local dive = P(t, 0, 0.17, 0.35)
                local lift = P(t, 0.18, 0.40, 0.82)
                return pose(
                    0,
                    (-dive * 0.065 + lift * 0.15) * a,
                    (dive * 0.04 + lift * 0.03) * a,
                    (dive * 0.22 - lift * 0.13 + R(t, 0.63, 1, 1) * 0.08) * a,
                    0,
                    0,
                    1 + (-dive * 0.05 + lift * 0.19) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                local open = P(t, 0.18, 0.39, 0.85)
                if group == "DiverClaw" then
                    v.rz = -side(x) * open * 0.29 * a
                elseif group == "DiverPearl" then
                    v.y = P(t, 0.25, 0.50, 0.92) * 0.33 * a
                    v.scale, v.glow = 1 + open * 0.16 * a, open * 0.32 * a
                end
                return v
            end,
        },
        stream_wheel = {
            duration = 1.38,
            name = "stream-wheel-water-hammer",
            description = "Loads against the current, lurches into a heavy wheel turn, and rocks backward as it coasts.",
            body = function(t, a)
                local load = P(t, 0, 0.18, 0.36)
                local push = P(t, 0.19, 0.42, 0.85)
                return pose(
                    0,
                    (-load * 0.035 + push * 0.11) * a,
                    R(t, 0.18, 1, 1) * 0.05 * a,
                    (load * 0.15 - push * 0.24 + R(t, 0.54, 1, 1) * 0.07) * a,
                    0,
                    0,
                    1 + (-load * 0.045 + push * 0.20) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                if group == "StreamPaddle" or group == "StreamSpoke" then
                    v.rx = spin(t, 0.16, 0.96, 3, a) - P(t, 0, 0.12, 0.27) * 0.22 * a
                end
                return v
            end,
        },
        cloud_mirror = {
            duration = 1.34,
            name = "cloud-mirror-reflection-reveal",
            description = "Tilts shyly away, swivels its cloud face through a complete reveal, and shakes off rain.",
            body = function(t, a)
                local shy = P(t, 0, 0.14, 0.31)
                local reveal = P(t, 0.19, 0.42, 0.86)
                return pose(
                    0,
                    reveal * 0.12 * a,
                    0,
                    shy * 0.12 * a,
                    R(t, 0.22, 0.98, 1) * 0.10 * a,
                    (-shy * 0.18 + R(t, 0.63, 1, 1) * 0.08) * a,
                    1 + (-shy * 0.035 + reveal * 0.19) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                if group == "CloudFrame" or group == "CloudGlass" or group == "CloudGlint" then
                    -- Mirror, rim and painted glint stay one connected assembly.
                    v.ry = spin(t, 0.16, 0.83, 1, a)
                    v.glow = P(t, 0.48, 0.67, 0.91) * 0.20 * a
                elseif group == "CloudRain" then
                    v.y = -P(t, 0.51, 0.72, 0.97) * 0.31 * a
                end
                return v
            end,
        },
        nectar_pump = {
            duration = 1.08,
            name = "nectar-pump-double-squirt",
            description = "Bounces into two deliberate pump presses, releasing nectar and finishing with a small bottle wobble.",
            body = function(t, a)
                local first = P(t, 0.08, 0.24, 0.44)
                local second = P(t, 0.39, 0.53, 0.78)
                local lift = P(t, 0.16, 0.35, 0.93)
                return pose(
                    0,
                    (lift * 0.11 - first * 0.05 - second * 0.035) * a,
                    0,
                    (first * 0.14 - second * 0.10 + R(t, 0.67, 1, 1) * 0.07) * a,
                    0,
                    0,
                    1 + (lift * 0.19 - first * 0.04) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                local press = P(t, 0.08, 0.24, 0.44) + P(t, 0.39, 0.53, 0.78) * 0.70
                if group == "PumpStem" or group == "PumpHandle" then
                    v.y = -press * 0.23 * a
                elseif group == "NectarDrop" then
                    local drip = P(t, 0.22, 0.40, 0.60) + P(t, 0.53, 0.70, 0.98) * 0.65
                    v.y, v.scale = -drip * 0.33 * a, 1 + drip * 0.18 * a
                elseif group == "NectarLiquid" then
                    v.glow = press * 0.29 * a
                end
                return v
            end,
        },
        lagoon_synth = {
            duration = 1.22,
            name = "lagoon-synth-three-note-riff",
            description = "Plays a left-to-right key riff with three body kicks, then leans back into a final resonant chord.",
            body = function(t, a)
                local riff = P(t, 0.08, 0.21, 0.35) + P(t, 0.27, 0.40, 0.57) * 0.8
                local chord = P(t, 0.46, 0.61, 0.94)
                return pose(
                    R(t, 0.08, 0.91, 1) * 0.045 * a,
                    (riff * 0.09 + chord * 0.14) * a,
                    chord * 0.045 * a,
                    (riff * 0.13 - chord * 0.16) * a,
                    0,
                    R(t, 0.10, 0.95, 1.5) * 0.12 * a,
                    1 + (riff * 0.11 + chord * 0.20) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                if group == "SynthKey" then
                    local start = 0.08 + math.clamp(x + 0.52, 0, 1.04) * 0.30
                    v.rx = P(t, start, start + 0.11, start + 0.30) * 0.18 * a
                elseif group == "SynthWave" then
                    v.y, v.glow = R(t, 0.12, 0.98, 3) * 0.045 * a, P(t, 0.1, 0.61, 0.98) * 0.40 * a
                end
                return v
            end,
        },
        aurora_kite = {
            duration = 1.56,
            name = "aurora-kite-looping-gust",
            description = "Dips into a gust, makes a full soaring twirl, and lets its trailing ribbon settle last.",
            body = function(t, a)
                local dive = P(t, 0, 0.14, 0.31)
                local soar = P(t, 0.16, 0.42, 0.88)
                return pose(
                    R(t, 0.10, 0.92, 1) * 0.16 * a,
                    (-dive * 0.05 + soar * 0.20) * a,
                    soar * 0.04 * a,
                    (-dive * 0.24 + soar * 0.20) * a,
                    spin(t, 0.18, 0.79, 1, a),
                    R(t, 0.08, 1, 1) * 0.30 * a,
                    1 + (-dive * 0.055 + soar * 0.20) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                if group == "KiteRibbon" then
                    v.rz = R(t, 0.18, 1, 2.5) * 0.41 * a
                    v.rx = R(t, 0.24, 1, 2) * 0.22 * a
                end
                return v
            end,
        },
        biolume_jar = {
            duration = 1.36,
            name = "biolume-jar-firefly-awakening",
            description = "Gives a sleepy tilt, pops awake, and lets fireflies spiral inside its softly rocking glass.",
            body = function(t, a)
                local sleepy = P(t, 0, 0.18, 0.36)
                local awake = P(t, 0.20, 0.39, 0.86)
                return pose(
                    0,
                    (-sleepy * 0.03 + awake * 0.13) * a,
                    0,
                    R(t, 0.26, 1, 1) * 0.085 * a,
                    0,
                    (-sleepy * 0.22 + R(t, 0.24, 1, 1.5) * 0.17) * a,
                    1 + (-sleepy * 0.045 + awake * 0.18) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                local light = P(t, 0.20, 0.43, 0.97)
                if group == "LumeFirefly" then
                    v.x = R(t, 0.22, 0.98, 1) * 0.085 * a
                    v.y = R(t, 0.27, 0.98, 1) * 0.065 * side(x) * a
                    v.scale, v.glow = 1 + light * 0.45 * a, light * 0.46 * a
                elseif group == "LumeCap" then
                    -- Stem/cap joints stay assembled; light provides the living pulse.
                    v.glow = (light * 0.25 + P(t, 0.53, 0.67, 0.90) * 0.15) * a
                end
                return v
            end,
        },
        ozone_orb = {
            duration = 1.48,
            name = "ozone-orb-atomic-sling",
            description = "Compresses an electric charge, slings two rings on crossing axes, and lands with a magnetic recoil.",
            body = function(t, a)
                local charge = P(t, 0, 0.20, 0.36)
                local sling = P(t, 0.20, 0.40, 0.88)
                return pose(
                    0,
                    (-charge * 0.045 + sling * 0.17) * a,
                    0,
                    R(t, 0.23, 1, 1) * 0.17 * a,
                    R(t, 0.17, 0.96, 1) * 0.22 * a,
                    0,
                    1 + (-charge * 0.065 + sling * 0.23) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                local release = P(t, 0.20, 0.42, 0.94)
                if group == "OzoneOrbitA" then
                    v.ry = spin(t, 0.17, 0.91, 2, a)
                elseif group == "OzoneOrbitB" then
                    v.rx = spin(t, 0.23, 0.97, -1, a)
                elseif group == "OzoneSatellite" then
                    v.rz = spin(t, 0.17, 0.91, 2, a)
                elseif group == "OzoneCore" then
                    v.scale, v.glow = 1 + release * 0.20 * a, release * 0.48 * a
                end
                return v
            end,
        },
        monsoon_loom = {
            duration = 1.32,
            name = "monsoon-loom-shuttle-storm",
            description = "Braces, snaps the shuttle across twice, and rebounds as the woven rain settles into place.",
            body = function(t, a)
                local brace = P(t, 0, 0.16, 0.34)
                local weave = P(t, 0.19, 0.40, 0.89)
                return pose(
                    R(t, 0.20, 0.93, 2) * 0.065 * a,
                    (weave * 0.10 - brace * 0.035) * a,
                    0,
                    brace * 0.10 * a,
                    0,
                    R(t, 0.21, 1, 2) * 0.09 * a,
                    1 + (-brace * 0.04 + weave * 0.19) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                if group == "LoomShuttle" then
                    v.x = R(t, 0.16, 0.91, 2) * 0.42 * a
                elseif group == "LoomThread" then
                    v.z = R(t, 0.20, 0.94, 2) * 0.025 * a
                elseif group == "LoomWeave" then
                    v.glow = P(t, 0.22, 0.51, 0.97) * 0.31 * a
                elseif group == "LoomRain" then
                    v.y = -P(t, 0.18, 0.46, 0.94) * 0.29 * a
                end
                return v
            end,
        },
        -- Each evolution below has its own rhythm and ingredient choreography.
        aurora_aquarium = {
            duration = 1.60,
            name = "aurora-aquarium-tidal-halo-parade",
            description = "The aquarium makes a grand buoyant rise while its halo parades overhead and its fish rides the returning current.",
            body = function(t, a)
                local sink = P(t, 0, 0.18, 0.36)
                local parade = P(t, 0.20, 0.43, 0.91)
                return pose(
                    R(t, 0.18, 0.98, 1) * 0.06 * a,
                    (-sink * 0.04 + parade * 0.16) * a,
                    0,
                    R(t, 0.20, 1, 1) * 0.08 * a,
                    parade * 0.22 * a,
                    (-sink * 0.12 + R(t, 0.31, 1, 1.5) * 0.11) * a,
                    1 + (-sink * 0.05 + parade * 0.22) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                local current = R(t, 0.18, 0.97, 1)
                local crest = P(t, 0.24, 0.48, 0.94)
                if group == "EvolvedOrbit" then
                    v.ry = spin(t, 0.17, 0.93, 1, a)
                    v.rx, v.y = crest * 0.16 * a, crest * 0.12 * a
                elseif group == "FishBody" or group == "FishFin" or group == "FishTail" then
                    v.x, v.y = current * 0.075 * a, crest * 0.035 * a
                    if group == "FishTail" then
                        v.ry = R(t, 0.12, 0.96, 6) * 0.61 * a
                    end
                    if group == "FishFin" then
                        v.rx = R(t, 0.18, 0.96, 5) * 0.38 * a
                    end
                elseif group == "Reeds" then
                    v.rz = -current * 0.075 * a
                elseif group == "Bubbles" then
                    v.y, v.scale = crest * 0.20 * a, 1 + crest * 0.25 * a
                end
                return v
            end,
        },
        spectrum_reef = {
            duration = 1.38,
            name = "spectrum-reef-prismatic-chord-bloom",
            description = "A fork strike launches a crystal bloom; its prism ring sweeps through the chord and recoils into alignment.",
            body = function(t, a)
                local strike = P(t, 0, 0.15, 0.31)
                local bloom = P(t, 0.17, 0.38, 0.89)
                return pose(
                    0,
                    (-strike * 0.035 + bloom * 0.14) * a,
                    bloom * 0.04 * a,
                    0,
                    R(t, 0.21, 0.98, 1) * 0.20 * a,
                    (-strike * 0.18 + R(t, 0.23, 1, 2) * 0.10) * a,
                    1 + (-strike * 0.045 + bloom * 0.24) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                local bloom = P(t, 0.20, 0.43, 0.93)
                if group == "EvolvedCrystal" then
                    v.scale, v.glow = 1 + bloom * 0.15 * a, bloom * 0.45 * a
                elseif group == "EvolvedFork" then
                    v.rz = side(x) * R(t, 0.16, 0.98, 6) * 0.085 * a
                elseif group == "EvolvedOrbit" then
                    v.ry = spin(t, 0.24, 0.93, 1, a)
                    v.rx = R(t, 0.24, 0.98, 1) * 0.15 * a
                end
                return v
            end,
        },
        tidal_engine = {
            duration = 1.40,
            name = "tidal-engine-hydraulic-launch",
            description = "Loads its coil under a heavy pressure cap, kicks upward on release, and takes a smaller second hydraulic bounce.",
            body = function(t, a)
                local load = P(t, 0, 0.22, 0.38)
                local launch = P(t, 0.24, 0.40, 0.70)
                local catch = P(t, 0.54, 0.68, 0.96)
                return pose(
                    0,
                    (-load * 0.065 + launch * 0.19 + catch * 0.055) * a,
                    -launch * 0.035 * a,
                    (load * 0.10 - launch * 0.16 + catch * 0.09) * a,
                    0,
                    0,
                    1 + (-load * 0.07 + launch * 0.23 + catch * 0.06) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                local load = P(t, 0, 0.22, 0.38)
                local rebound = P(t, 0.24, 0.42, 0.62)
                local settle = R(t, 0.51, 1, 1.5)
                local axial = 1 + (-load * 0.25 + rebound * 0.10 + settle * 0.065) * a
                if group == "EvolvedSpring" then
                    v.axial = axial
                elseif group == "EvolvedWeight" then
                    -- Cap center1.90 minus coil lower socket0.44; no cap scaling.
                    v.y = 1.46 * (axial - 1)
                elseif group == "EvolvedNeedle" then
                    v.rz = (-load * 0.65 + rebound * 0.90 + settle * 0.20) * a
                end
                return v
            end,
        },
        storm_clock = {
            duration = 1.44,
            name = "storm-clock-lightning-overdrive",
            description = "Charges both cells, jolts its clock upward, and sends its hands racing while the storm wheel counter-rotates.",
            body = function(t, a)
                local charge = P(t, 0, 0.20, 0.35)
                local bolt = P(t, 0.21, 0.34, 0.82)
                return pose(
                    R(t, 0.25, 0.92, 3) * 0.025 * a,
                    (-charge * 0.045 + bolt * 0.15) * a,
                    bolt * 0.04 * a,
                    -bolt * 0.12 * a,
                    0,
                    (-charge * 0.16 + R(t, 0.23, 1, 2) * 0.15) * a,
                    1 + (-charge * 0.06 + bolt * 0.24) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                local bolt = P(t, 0.21, 0.36, 0.91)
                if group == "EvolvedFastHand" then
                    v.rz = spin(t, 0.18, 0.95, -8, a)
                elseif group == "EvolvedSlowHand" then
                    v.rz = spin(t, 0.18, 0.95, -2, a)
                elseif group == "EvolvedRotor" then
                    v.rz = spin(t, 0.24, 0.98, 3, a)
                elseif group == "EvolvedCrystal" then
                    v.scale, v.glow = 1 + bolt * 0.18 * a, bolt * 0.50 * a
                elseif group == "EvolvedCore" then
                    v.glow = (P(t, 0.03, 0.21, 0.48) * 0.25 + bolt * 0.22) * a
                end
                return v
            end,
        },
        horizon_observatory = {
            duration = 1.64,
            name = "horizon-observatory-orbital-survey",
            description = "Bows to acquire a target, makes a full azimuth survey, and raises its telescope into a confident sighting.",
            body = function(t, a)
                local acquire = P(t, 0, 0.17, 0.34)
                local survey = P(t, 0.18, 0.42, 0.90)
                return pose(
                    0,
                    (-acquire * 0.035 + survey * 0.14) * a,
                    survey * 0.04 * a,
                    (acquire * 0.13 - survey * 0.08) * a,
                    spin(t, 0.21, 0.83, 1, a),
                    R(t, 0.65, 1, 1) * 0.065 * a,
                    1 + (-acquire * 0.04 + survey * 0.20) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                local sight = P(t, 0.25, 0.55, 0.96)
                if group == "EvolvedLens" then
                    v.rx = -sight * 0.24 * a
                    v.glow = P(t, 0.56, 0.76, 0.96) * 0.23 * a
                elseif group == "EvolvedOrbit" then
                    v.rx = -sight * 0.24 * a
                    v.ry = spin(t, 0.28, 0.92, -1, a)
                elseif group == "EvolvedNeedle" then
                    v.rz = R(t, 0.13, 0.96, 2) * 0.88 * a
                end
                return v
            end,
        },
        eden_greenhouse = {
            duration = 1.52,
            name = "eden-greenhouse-three-stage-sprouting",
            description = "Hunkers down to germinate, opens into a strong growth lift, and rocks gently as the planted sprouts flourish.",
            body = function(t, a)
                local germinate = P(t, 0, 0.21, 0.40)
                local flourish = P(t, 0.23, 0.48, 0.92)
                local leafbeat = P(t, 0.57, 0.69, 0.96)
                return pose(
                    0,
                    (-germinate * 0.045 + flourish * 0.14 + leafbeat * 0.025) * a,
                    0,
                    R(t, 0.33, 1, 1) * 0.08 * a,
                    flourish * 0.14 * a,
                    R(t, 0.28, 0.98, 1) * 0.07 * a,
                    1 + (-germinate * 0.055 + flourish * 0.21 + leafbeat * 0.025) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                if group == "EvolvedCore" then
                    v.glow = P(t, 0.07, 0.30, 0.76) * 0.42 * a
                elseif group == "EvolvedSprout" then
                    local grow = P(t, 0.23, 0.54, 0.96)
                    -- Shared bed pivot preserves stem/leaf joins and roof clearance.
                    v.scale, v.glow = 1 + grow * 0.11 * a, grow * 0.20 * a
                end
                return v
            end,
        },
        pearl_turbine = {
            duration = 1.42,
            name = "pearl-turbine-balance-powered-surge",
            description = "Tips its balance to load one side, spins up the pearl rotor, then catches the scale on the opposite side.",
            body = function(t, a)
                local tip = P(t, 0, 0.18, 0.37)
                local surge = P(t, 0.20, 0.42, 0.88)
                return pose(
                    R(t, 0.15, 0.96, 1) * 0.06 * a,
                    (-tip * 0.035 + surge * 0.13) * a,
                    surge * 0.035 * a,
                    0,
                    surge * 0.14 * a,
                    (-tip * 0.18 + R(t, 0.25, 1, 1.5) * 0.18) * a,
                    1 + (-tip * 0.045 + surge * 0.22) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                if group == "EvolvedRotor" then
                    v.rz = spin(t, 0.16, 0.95, -4, a)
                elseif group == "EvolvedBalance" then
                    -- Beam, hanging pans, and suspension rotate as one authored assembly.
                    v.rz = (P(t, 0, 0.18, 0.36) * 0.19 - R(t, 0.24, 1, 1.5) * 0.16) * a
                end
                return v
            end,
        },
        current_nexus = {
            duration = 1.24,
            name = "current-nexus-contact-snap-broadcast",
            description = "Draws in both contacts, snaps out a signal pulse, and rebounds as the broadcast ring circles its cells.",
            body = function(t, a)
                local draw = P(t, 0, 0.19, 0.35)
                local send = P(t, 0.21, 0.35, 0.81)
                return pose(
                    R(t, 0.30, 0.97, 2) * 0.035 * a,
                    (-draw * 0.04 + send * 0.13) * a,
                    (-draw * 0.035 + send * 0.06) * a,
                    (draw * 0.13 - send * 0.17 + R(t, 0.57, 1, 1) * 0.06) * a,
                    0,
                    0,
                    1 + (-draw * 0.06 + send * 0.25) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                local send = P(t, 0.23, 0.39, 0.93)
                if group == "EvolvedPiston" then
                    v.x = -side(x) * P(t, 0.07, 0.24, 0.55) * 0.12 * a
                elseif group == "EvolvedCore" then
                    v.glow = (P(t, 0.04, 0.22, 0.44) * 0.20 + send * 0.30) * a
                elseif group == "EvolvedOrbit" then
                    v.ry = spin(t, 0.23, 0.92, -2, a)
                    v.rx = send * 0.13 * a
                end
                return v
            end,
        },
        ocean_orchestra = {
            duration = 1.48,
            name = "ocean-orchestra-brass-and-shell-fanfare",
            description = "Takes a conductor's breath, punches out a staggered three-horn fanfare, and lands on a resonating shell chord.",
            body = function(t, a)
                local breath = P(t, 0, 0.17, 0.34)
                local brass = P(t, 0.20, 0.35, 0.58)
                local chord = P(t, 0.49, 0.64, 0.96)
                return pose(
                    0,
                    (-breath * 0.035 + brass * 0.12 + chord * 0.09) * a,
                    (brass * 0.05 + chord * 0.035) * a,
                    (breath * 0.12 - brass * 0.15 + chord * 0.10) * a,
                    0,
                    R(t, 0.21, 1, 1.5) * 0.09 * a,
                    1 + (-breath * 0.045 + brass * 0.22 + chord * 0.16) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                if group == "EvolvedHorn" then
                    local start = 0.19 + math.clamp(x + 0.58, 0, 1.16) * 0.15
                    local note = P(t, start, start + 0.12, start + 0.38)
                    v.rx, v.glow = -note * 0.14 * a, note * 0.30 * a
                elseif group == "EvolvedShell" then
                    local chord = P(t, 0.48, 0.64, 0.96)
                    v.scale, v.glow = 1 + chord * 0.11 * a, chord * 0.32 * a
                elseif group == "EvolvedFork" then
                    v.rz = side(x) * R(t, 0.25, 0.99, 7) * 0.06 * a
                end
                return v
            end,
        },
        bubble_reactor = {
            duration = 1.32,
            name = "bubble-reactor-pressure-cork-pop",
            description = "Squeezes both pistons inward, erupts in a cork-pop hop, and gives two pressure aftershocks as bubbles churn inside.",
            body = function(t, a)
                local squeeze = P(t, 0, 0.23, 0.38)
                local pop = P(t, 0.24, 0.38, 0.74)
                local aftershock = R(t, 0.52, 1, 2)
                return pose(
                    0,
                    (-squeeze * 0.06 + pop * 0.20 + aftershock * 0.035) * a,
                    0,
                    (-pop * 0.13 + aftershock * 0.10) * a,
                    0,
                    aftershock * 0.065 * a,
                    1 + (-squeeze * 0.07 + pop * 0.25 + aftershock * 0.035) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                local squeeze = P(t, 0.05, 0.25, 0.46)
                local churn = P(t, 0.27, 0.50, 0.96)
                if group == "EvolvedPiston" then
                    v.x = -side(x) * squeeze * 0.10 * a
                elseif group == "Bubbles" then
                    -- Small enclosed convection path, not particles through capsule walls.
                    v.x = R(t, 0.27, 0.95, 1) * 0.07 * a
                    v.y = R(t, 0.32, 0.97, 1) * 0.11 * a
                    v.scale = 1 + churn * 0.16 * a
                elseif group == "EvolvedCore" then
                    v.glow = churn * 0.22 * a
                end
                return v
            end,
        },
        solar_treasury = {
            duration = 1.46,
            name = "solar-treasury-mint-and-coin-salute",
            description = "Braces for a quota stamp, thumps down to mint, then throws its coins into a spinning reward salute.",
            body = function(t, a)
                local brace = P(t, 0, 0.17, 0.32)
                local stamp = P(t, 0.19, 0.31, 0.47)
                local payout = P(t, 0.32, 0.52, 0.93)
                return pose(
                    0,
                    (brace * 0.025 - stamp * 0.06 + payout * 0.14) * a,
                    payout * 0.04 * a,
                    (stamp * 0.11 - payout * 0.10) * a,
                    R(t, 0.37, 0.97, 1) * 0.13 * a,
                    R(t, 0.64, 1, 1) * 0.065 * a,
                    1 + (-stamp * 0.055 + payout * 0.23) * a
                )
            end,
            part = function(group, t, a, x, _y, _z, v)
                clear(v)
                if group == "EvolvedWeight" then
                    v.y = -P(t, 0.12, 0.30, 0.52) * 0.22 * a
                elseif group == "EvolvedCoin" then
                    local toss = P(t, 0.32, 0.55, 0.96)
                    v.y, v.x = toss * 0.42 * a, x * toss * 0.11 * a
                    v.ry = spin(t, 0.34, 0.92, 2, a)
                elseif group == "EvolvedNeedle" then
                    v.rz = (-P(t, 0.24, 0.47, 0.85) * 1.12 + R(t, 0.66, 1, 1) * 0.18) * a
                elseif group == "EvolvedCore" then
                    local halo = P(t, 0.32, 0.57, 0.98)
                    v.scale, v.glow = 1 + halo * 0.11 * a, halo * 0.37 * a
                end
                return v
            end,
        },
        sun_koi = {
            duration = 1.62,
            name = "sun-koi-crowned-solar-somersault",
            description = "Dives under its crown, leaps through a complete sun-wheel somersault, and fans its tail on the triumphant landing.",
            body = function(t, a)
                local dive = P(t, 0, 0.16, 0.32)
                local leap = P(t, 0.17, 0.43, 0.88)
                return pose(
                    R(t, 0.15, 0.95, 1) * 0.12 * a,
                    (-dive * 0.05 + leap * 0.20) * a,
                    leap * 0.04 * a,
                    R(t, 0.20, 0.94, 1) * 0.20 * a,
                    leap * 0.15 * a,
                    spin(t, 0.20, 0.80, 1, a) - dive * 0.20 * a,
                    1 + (-dive * 0.06 + leap * 0.24) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                local crown = P(t, 0.27, 0.53, 0.95)
                if group == "FishTail" then
                    v.ry = R(t, 0.06, 1, 7) * 0.78 * a
                elseif group == "FishFin" then
                    v.rx = R(t, 0.12, 0.95, 5) * 0.50 * a
                elseif group == "EvolvedCrystal" then
                    v.scale, v.glow = 1 + crown * 0.14 * a, crown * 0.47 * a
                elseif group == "EvolvedOrbit" then
                    v.ry = spin(t, 0.28, 0.93, -1, a)
                end
                return v
            end,
        },
        tide_gyroscope = {
            duration = 1.66,
            name = "tide-gyroscope-gimbal-cascade",
            description = "Winds its suspension, releases staggered gimbal revolutions, and lets clock hands brake into a controlled final nod.",
            body = function(t, a)
                local wind = P(t, 0, 0.20, 0.37)
                local release = P(t, 0.22, 0.45, 0.90)
                return pose(
                    0,
                    (-wind * 0.04 + release * 0.15) * a,
                    0,
                    (-wind * 0.16 + R(t, 0.28, 1, 1.5) * 0.18) * a,
                    R(t, 0.22, 0.98, 1) * 0.26 * a,
                    R(t, 0.33, 1, 1.5) * 0.12 * a,
                    1 + (-wind * 0.055 + release * 0.23) * a
                )
            end,
            part = function(group, t, a, _x, _y, _z, v)
                clear(v)
                if group == "EvolvedGyro" then
                    v.rx = spin(t, 0.18, 0.90, 2, a)
                elseif group == "EvolvedOrbit" then
                    v.ry = spin(t, 0.29, 0.97, -1, a)
                elseif group == "EvolvedFastHand" then
                    v.rz = spin(t, 0.22, 0.94, -4, a)
                elseif group == "EvolvedSlowHand" then
                    v.rz = spin(t, 0.22, 0.94, -1, a)
                elseif group == "EvolvedSpring" then
                    -- Bracket and clock remain seated; coil stores a small local pulse.
                    v.axial = 1 - P(t, 0.04, 0.21, 0.49) * 0.11 * a
                end
                return v
            end,
        },
    }
end
