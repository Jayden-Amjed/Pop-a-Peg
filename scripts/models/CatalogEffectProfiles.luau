-- Pure, pose-addressable visual notes. Coordinates are fractions of rest bounds.
-- Explicit per-ID direction keeps a model's accent tied to its mechanism/theme.
local Effects = { MaxParts = 40, entries = {} }
local TAU = math.pi * 2
local palette = {
    aqua = { 0.26, 0.91, 1 },
    blue = { 0.22, 0.57, 1 },
    pearl = { 0.96, 1, 1 },
    gold = { 1, 0.76, 0.20 },
    lime = { 0.57, 1, 0.38 },
    coral = { 1, 0.48, 0.29 },
    ice = { 0.64, 0.91, 1 },
    violet = { 0.69, 0.57, 1 },
}
local function add(id, kind, name, peak, count, spread, lift, turns, color, accent)
    Effects.entries[id] = table.freeze({
        kind = kind,
        name = name,
        peak = peak,
        count = count,
        spread = spread,
        lift = lift,
        turns = turns,
        color = color,
        accent = accent,
    })
end
add(
    "aurora_aquarium",
    "orbit",
    "aquarium schooling constellation",
    0.40,
    9,
    0.54,
    0.17,
    1.1,
    "aqua",
    "gold"
)
add("aurora_kite", "ribbon", "kite streaming diamond tail", 0.38, 7, 0.48, 0.29, 0.7, "ice", "gold")
add(
    "balance_scale",
    "glyph",
    "pearl balance counterweight sparks",
    0.36,
    4,
    0.45,
    0.11,
    0.5,
    "pearl",
    "gold"
)
add("biolume_jar", "bubble", "jar firefly rising swarm", 0.43, 9, 0.26, 0.68, 1.2, "lime", "aqua")
add(
    "bubble_reactor",
    "helix",
    "reactor double bubble helix",
    0.40,
    12,
    0.41,
    0.58,
    2.2,
    "aqua",
    "gold"
)
add("bubble_wand", "bubble", "wand coherent soap corona", 0.68, 7, 0.56, 0.22, 0.4, "aqua", "pearl")
add(
    "burst_capsule",
    "radial",
    "capsule pressure shrapnel glints",
    0.30,
    9,
    0.56,
    0.18,
    0.12,
    "coral",
    "gold"
)
add("chest_common", "chest", "meadow golden seed shower", 0.62, 8, 0.46, 0.52, 0.18, "gold", "lime")
add(
    "chest_legendary",
    "chest",
    "celestial crown star supernova",
    0.64,
    12,
    0.69,
    0.66,
    0.63,
    "gold",
    "ice"
)
add(
    "chest_rare",
    "chest",
    "aurora prismatic treasure spokes",
    0.63,
    10,
    0.59,
    0.58,
    0.42,
    "ice",
    "violet"
)
add(
    "chest_uncommon",
    "chest",
    "lagoon treasure droplet fan",
    0.62,
    9,
    0.51,
    0.55,
    0.30,
    "aqua",
    "gold"
)
add(
    "clockwork",
    "clock",
    "clock accelerating minute marks",
    0.35,
    12,
    0.43,
    0.08,
    1.8,
    "gold",
    "blue"
)
add(
    "cloud_mirror",
    "scan",
    "mirror reflected horizon sweep",
    0.42,
    5,
    0.54,
    0.13,
    0.7,
    "ice",
    "pearl"
)
add("coin", "glyph", "coin four corner mint shine", 0.30, 4, 0.49, 0.08, 0.33, "gold", "pearl")
add("coin_press", "radial", "press struck gold flecks", 0.40, 7, 0.39, -0.15, 0.15, "gold", "ice")
add("compass", "clock", "compass four cardinal pulses", 0.36, 4, 0.53, 0.12, 1.1, "aqua", "gold")
add("coral_fork", "coral", "coral twin tine live lightning", 0.24, 2, 0.44, 0.21, 5, "ice", "gold")
add(
    "current_nexus",
    "lattice",
    "nexus crossing current grid",
    0.44,
    6,
    0.55,
    0.12,
    1.2,
    "aqua",
    "gold"
)
add(
    "dew_lantern",
    "lantern",
    "lantern warm switch and halo",
    0.22,
    8,
    0.34,
    0.18,
    0.4,
    "gold",
    "pearl"
)
add("echo_plate", "echo", "shell concentric pearl echo", 0.34, 3, 0.61, 0.13, 0.8, "ice", "gold")
add(
    "eden_greenhouse",
    "petal",
    "greenhouse ascending leaf canopy",
    0.45,
    10,
    0.52,
    0.51,
    0.65,
    "lime",
    "gold"
)
add(
    "encore",
    "chorus",
    "chorus alternating cone sound waves",
    0.26,
    3,
    0.58,
    0.09,
    0.6,
    "aqua",
    "ice"
)
add("event_growth", "petal", "growth sprout scatter", 0.38, 7, 0.41, 0.49, 0.42, "lime", "gold")
add(
    "event_overtime",
    "clock",
    "overtime falling hour ticks",
    0.36,
    8,
    0.44,
    0.31,
    -0.8,
    "ice",
    "gold"
)
add(
    "event_repair",
    "glyph",
    "repair four stitch crosses",
    0.38,
    4,
    0.37,
    0.28,
    0.12,
    "lime",
    "pearl"
)
add("event_upgrade", "lattice", "upgrade rising chevrons", 0.38, 4, 0.34, 0.53, 0.3, "gold", "aqua")
add(
    "first_spark",
    "radial",
    "first spark sharp ignition",
    0.29,
    5,
    0.61,
    0.20,
    0.08,
    "gold",
    "coral"
)
add("fishbowl", "bubble", "fishbowl rim bubble ladder", 0.40, 6, 0.31, 0.57, 0.95, "aqua", "pearl")
add("gain_dial", "clock", "dial rewarding gauge sweep", 0.33, 9, 0.48, 0.14, 1.35, "lime", "gold")
add("goldfish", "ribbon", "goldfish leaping golden wake", 0.38, 8, 0.42, 0.28, 0.42, "gold", "aqua")
add(
    "growth_array",
    "petal",
    "coral garden staggered pollen",
    0.42,
    11,
    0.61,
    0.45,
    0.32,
    "lime",
    "pearl"
)
add("growth_ring", "orbit", "growth ring seed satellites", 0.46, 6, 0.51, 0.21, 1.6, "lime", "gold")
add(
    "horizon_observatory",
    "scan",
    "observatory long focus beam",
    0.39,
    6,
    0.67,
    0.18,
    0.25,
    "ice",
    "gold"
)
add("jumble", "orbit", "jumble crossing peg tracks", 0.38, 5, 0.49, 0.19, -1.4, "blue", "gold")
add(
    "lagoon_synth",
    "synth",
    "synth stationary travelling sine",
    0.16,
    28,
    0.54,
    0.10,
    3,
    "gold",
    "aqua"
)
add(
    "landing_fund",
    "glyph",
    "landing shell pearlescent rib glints",
    0.38,
    7,
    0.48,
    0.22,
    0.6,
    "pearl",
    "gold"
)
add(
    "last_word",
    "echo",
    "last word final quotation echoes",
    0.50,
    2,
    0.68,
    0.19,
    0.45,
    "gold",
    "ice"
)
add("life", "bubble", "life buoyant blue launch", 0.28, 5, 0.30, 0.72, 0.6, "blue", "pearl")
add("lily_pad", "petal", "lily dew crowned water bloom", 0.34, 8, 0.57, 0.18, 0.72, "lime", "aqua")
add("lock", "glyph", "lock seal and tiny key spark", 0.36, 3, 0.32, 0.15, 0.9, "gold", "blue")
add(
    "metronome",
    "clock",
    "metronome alternating beat marks",
    0.31,
    6,
    0.46,
    0.10,
    -0.65,
    "gold",
    "ice"
)
add(
    "milestone",
    "lattice",
    "milestone ascending stair lights",
    0.40,
    3,
    0.43,
    0.58,
    0.5,
    "gold",
    "lime"
)
add(
    "mist_fan",
    "ribbon",
    "breeze folded paper slipstream",
    0.38,
    10,
    0.61,
    0.07,
    1.4,
    "pearl",
    "aqua"
)
add(
    "monsoon_loom",
    "lattice",
    "monsoon woven falling rain",
    0.41,
    9,
    0.60,
    -0.38,
    0.8,
    "blue",
    "ice"
)
add(
    "moss_capacitor",
    "helix",
    "moss green charging circuit",
    0.36,
    8,
    0.32,
    0.49,
    2.8,
    "lime",
    "aqua"
)
add("nectar_pump", "bubble", "nectar amber pump spray", 0.34, 7, 0.33, 0.52, 0.34, "gold", "lime")
add(
    "ocean_orchestra",
    "echo",
    "orchestra overlapping chord rings",
    0.44,
    4,
    0.72,
    0.16,
    1.15,
    "aqua",
    "gold"
)
add("ozone_orb", "orbit", "ozone ion crossing electrons", 0.42, 11, 0.62, 0.03, 2.3, "blue", "ice")
add(
    "pearl_diver",
    "orbit",
    "diver blue gold orbital trails",
    0.54,
    10,
    0.64,
    0.09,
    -1.8,
    "aqua",
    "gold"
)
add("pearl_turbine", "helix", "turbine pearl cyclone", 0.36, 10, 0.47, 0.52, -2.4, "pearl", "aqua")
add(
    "pulse_cell",
    "lattice",
    "pulse battery charging bars",
    0.32,
    5,
    0.36,
    0.48,
    0.2,
    "aqua",
    "lime"
)
add("quota_bonus", "radial", "quota stamped point rays", 0.32, 6, 0.53, 0.28, 0.22, "gold", "lime")
add(
    "rain_catcher",
    "bubble",
    "rain catcher collected droplet rebound",
    0.38,
    8,
    0.40,
    0.39,
    0.55,
    "blue",
    "aqua"
)
add(
    "recovery",
    "glyph",
    "recovery soft double heartbeat",
    0.40,
    5,
    0.42,
    0.24,
    0.27,
    "lime",
    "pearl"
)
add("relay", "relay", "relay live helical electricity", 0.20, 2, 0.57, 0.10, 4, "blue", "gold")
add(
    "reserve_pack",
    "bubble",
    "reserve pack juggling bubble sparks",
    0.33,
    6,
    0.48,
    0.42,
    1.55,
    "blue",
    "gold"
)
add("resonator", "echo", "reef chime thin resonant rings", 0.32, 3, 0.48, 0.31, 0.32, "ice", "aqua")
add(
    "restock",
    "orbit",
    "restock circulating refill arrows",
    0.32,
    8,
    0.51,
    0.05,
    -1.1,
    "aqua",
    "gold"
)
add(
    "ricochet",
    "radial",
    "ricochet two sided collision streaks",
    0.22,
    4,
    0.70,
    0.09,
    0.55,
    "pearl",
    "gold"
)
add("score", "lattice", "score three rising columns", 0.36, 3, 0.38, 0.66, 0.15, "gold", "lime")
add(
    "seed_bank",
    "petal",
    "seed bank three seed germination",
    0.38,
    6,
    0.48,
    0.57,
    0.23,
    "lime",
    "gold"
)
add(
    "soft_saw",
    "ribbon",
    "soft current curling foam wake",
    0.30,
    9,
    0.56,
    0.21,
    -1.2,
    "aqua",
    "pearl"
)
add("solar_leaf", "petal", "solar leaf sunlit veins", 0.40, 5, 0.62, 0.35, 0.93, "lime", "gold")
add(
    "solar_treasury",
    "radial",
    "solar treasury sun coin spokes",
    0.43,
    12,
    0.66,
    0.25,
    0.47,
    "gold",
    "lime"
)
add(
    "spectrum_reef",
    "helix",
    "spectrum reef prismatic ladder",
    0.45,
    11,
    0.55,
    0.64,
    1.7,
    "aqua",
    "violet"
)
add("split_prism", "scan", "prism three split light rays", 0.35, 3, 0.72, -0.24, 0.4, "ice", "gold")
add(
    "spring_coil",
    "echo",
    "spring heavy impact compression rings",
    0.30,
    2,
    0.57,
    -0.20,
    0.2,
    "blue",
    "gold"
)
add(
    "storm_clock",
    "clock",
    "storm clock electric hour orbit",
    0.37,
    12,
    0.57,
    0.17,
    -2.6,
    "blue",
    "gold"
)
add(
    "stream_wheel",
    "ribbon",
    "stream wheel tangential spray",
    0.35,
    11,
    0.50,
    0.19,
    1.9,
    "aqua",
    "ice"
)
add("sun_koi", "petal", "sun koi golden scale bloom", 0.43, 9, 0.63, 0.27, 1.12, "gold", "coral")
add(
    "survey_lens",
    "scan",
    "survey focused telescope reticle",
    0.32,
    4,
    0.63,
    0.14,
    1.05,
    "aqua",
    "gold"
)
add(
    "tailwind",
    "ribbon",
    "tailwind paired aerodynamic ribbons",
    0.36,
    6,
    0.67,
    0.05,
    0.9,
    "pearl",
    "aqua"
)
add(
    "tap_driver",
    "radial",
    "tap driver compact impact teeth",
    0.28,
    8,
    0.44,
    -0.02,
    0.3,
    "gold",
    "blue"
)
add(
    "tidal_engine",
    "helix",
    "tidal engine heavy pressure column",
    0.37,
    12,
    0.58,
    0.42,
    -1.65,
    "aqua",
    "gold"
)
add(
    "tide_gyroscope",
    "orbit",
    "gyroscope three axis crossing trail",
    0.41,
    12,
    0.66,
    0.12,
    2.7,
    "ice",
    "gold"
)
add(
    "tide_valve",
    "ribbon",
    "tide valve lateral water release",
    0.34,
    7,
    0.68,
    -0.04,
    0.52,
    "blue",
    "aqua"
)
add(
    "tuning_oil",
    "bubble",
    "tuning oil amber three drop drip",
    0.37,
    3,
    0.29,
    -0.46,
    0.17,
    "gold",
    "ice"
)
add(
    "wall_meter",
    "lattice",
    "shore meter rising measuring marks",
    0.32,
    7,
    0.31,
    0.58,
    0.12,
    "aqua",
    "gold"
)

local function smooth(a, b, t)
    local u = math.clamp((t - a) / (b - a), 0, 1)
    return u * u * (3 - 2 * u)
end
local function envelope(t, peak)
    return smooth(math.max(0.015, peak - 0.16), peak, t)
        * (1 - smooth(math.min(0.84, peak + 0.13), 0.98, t))
end
local function point(x, y, z)
    return { x, y, z }
end
local function mix(a, b, t)
    return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end
function Effects.sample(id, t, strength, context)
    local p = assert(Effects.entries[id], "Missing Blender effect: " .. tostring(id))
    local out = {}
    if t <= 0 or t >= 1 or strength <= 0 then
        return out
    end
    context = context or {}
    local gain = envelope(t, p.peak)
    if gain < 0.002 then
        return out
    end
    local a = math.min(strength, 1.5)
    local travel = smooth(math.max(0.01, p.peak - 0.12), 0.96, t)
    local function line(first, last, width, color, alpha)
        if #out < Effects.MaxParts then
            table.insert(out, {
                kind = "line",
                a = first,
                b = last,
                radius = width,
                color = palette[color],
                alpha = math.clamp(alpha * gain, 0, 0.96),
            })
        end
    end
    local function ball(position, radius, color, alpha)
        if #out < Effects.MaxParts then
            table.insert(out, {
                kind = "ball",
                a = position,
                radius = radius,
                color = palette[color],
                alpha = math.clamp(alpha * gain, 0, 0.96),
            })
        end
    end
    local function ring(center, radius, color, alpha, axis, segments, phase)
        segments = segments or 10
        for n = 0, segments - 1 do
            local function at(angle)
                local x, y = math.cos(angle) * radius, math.sin(angle) * radius
                if axis == "Y" then
                    return point(center[1] + x, center[2], center[3] + y)
                end
                return point(center[1] + x, center[2] + y, center[3])
            end
            line(
                at((n / segments) * TAU + (phase or 0)),
                at(((n + 1) / segments) * TAU + (phase or 0)),
                0.009,
                color,
                alpha
            )
        end
    end
    local function bolt(first, last, offset, color, segments)
        local previous = first
        for n = 1, segments do
            local u = n / segments
            local q = mix(first, last, u)
            local jag = math.sin(u * math.pi)
                * math.sin(n * 2.13 + math.floor(t * 36) * 1.7 + offset)
            q[2] += jag * 0.055 * a
            q[3] += math.sin(n * 1.9 + offset) * math.sin(u * math.pi) * 0.025
            line(previous, q, 0.011, color, 0.95)
            previous = q
        end
    end
    if id == "split_prism" then
        -- One incident ray resolves into three spatially separated colours.
        line(point(-0.36, 0.08, 0.10), point(0, 0.08, 0.10), 0.016, "pearl", 0.9)
        for i, color in { "gold", "aqua", "coral" } do
            local endPoint =
                point(0.25 + travel * 0.45, 0.08 + (i - 2) * (0.14 + travel * 0.18), 0.10)
            line(point(0, 0.08, 0.10), endPoint, 0.012, color, 0.9)
            ball(endPoint, 0.027, color, 0.9)
        end
    elseif id == "survey_lens" or id == "horizon_observatory" then
        local reach = id == "survey_lens" and 0.45 or 0.70
        local target = point(0, 0.03, 0.20 + travel * reach)
        ring(target, 0.10 + travel * 0.12, "aqua", 0.85, "Z", 12)
        for i = 0, 3 do
            local angle = i * TAU / 4
            line(
                point(math.cos(angle) * 0.18, math.sin(angle) * 0.18 + 0.03, target[3]),
                point(math.cos(angle) * 0.24, math.sin(angle) * 0.24 + 0.03, target[3]),
                0.008,
                "gold",
                0.85
            )
        end
        line(point(0, 0, 0.05), target, 0.005, "ice", 0.3)
    elseif id == "landing_fund" then
        -- Pearlescent light chases the shell ribs rather than orbiting its base.
        for i = 1, 7 do
            local angle = (i / 8 - 0.5) * math.pi
            local r = 0.15 + 0.29 * travel
            local q = point(math.sin(angle) * r, math.cos(angle) * r, 0.12)
            local twinkle = 0.02 + 0.015 * math.sin(t * 18 + i * 2) ^ 2
            line(
                point(q[1] - twinkle, q[2], q[3]),
                point(q[1] + twinkle, q[2], q[3]),
                0.007,
                "pearl",
                0.9
            )
            line(
                point(q[1], q[2] - twinkle, q[3]),
                point(q[1], q[2] + twinkle, q[3]),
                0.007,
                "gold",
                0.8
            )
        end
    elseif id == "mist_fan" then
        -- Three folded chevrons travel in the rotor's outflow with twin wakes.
        for i = 1, 3 do
            local flight = (travel * 1.8 + i / 3) % 1
            local angle = i * TAU / 3 + travel * TAU
            local q = point(math.cos(angle) * 0.16, math.sin(angle) * 0.12, 0.12 + flight * 0.58)
            line(point(q[1] - 0.045, q[2] - 0.04, q[3]), q, 0.015, "pearl", 0.88)
            line(q, point(q[1] + 0.045, q[2] - 0.04, q[3]), 0.015, "ice", 0.88)
            line(
                point(q[1] - 0.03, q[2] - 0.05, q[3] - 0.13),
                point(q[1] - 0.03, q[2] - 0.05, q[3] - 0.03),
                0.006,
                "aqua",
                0.65
            )
            line(
                point(q[1] + 0.03, q[2] - 0.05, q[3] - 0.13),
                point(q[1] + 0.03, q[2] - 0.05, q[3] - 0.03),
                0.006,
                "aqua",
                0.65
            )
        end
    elseif id == "seed_bank" or id == "growth_array" or id == "eden_greenhouse" then
        for i = 1, math.min(p.count, 10) do
            local phase = math.clamp(travel * 1.8 - i * 0.065, 0, 1)
            local x = (i / (math.min(p.count, 10) + 1) - 0.5) * p.spread * 1.5
            local height = phase * p.lift + 0.08
            line(point(x, -0.10, 0.12), point(x, height, 0.12), 0.007, "lime", 0.65)
            local branch = 0.035 + 0.025 * phase
            line(
                point(x, height - 0.025, 0.12),
                point(x - branch, height + 0.025, 0.12),
                0.012,
                "lime",
                0.85
            )
            line(
                point(x, height - 0.025, 0.12),
                point(x + branch, height + 0.025, 0.12),
                0.012,
                p.accent,
                0.85
            )
            ball(point(x, height + 0.06, 0.12), 0.017, "gold", 0.8)
        end
    elseif id == "coin_press" then
        local struck = smooth(0.32, 0.42, t)
        for i = 1, 7 do
            local angle = i * TAU / 7
            local r = 0.05 + struck * travel * 0.39
            local q =
                point(math.cos(angle) * r, 0.025 + math.sin(angle) * r * 0.18, math.sin(angle) * r)
            ball(q, 0.022, "gold", 0.92)
            line(q, point(q[1] * 0.78, q[2] + 0.018, q[3] * 0.78), 0.008, "pearl", 0.75)
        end
    elseif id == "gain_dial" then
        local last
        for i = 0, math.floor(18 * smooth(0.13, 0.74, t)) do
            local angle = -math.pi * 0.8 + i / 18 * math.pi * 1.6
            local q = point(math.sin(angle) * 0.43, math.cos(angle) * 0.28, 0.17)
            if last then
                line(last, q, 0.014, i > 12 and "gold" or "lime", 0.9)
            end
            last = q
        end
        if last then
            ball(last, 0.025, "pearl", 0.95)
        end
    elseif id == "lily_pad" then
        ring(point(0, -0.14, 0), 0.18 + travel * 0.47, "aqua", 0.65, "Y", 14)
        ring(point(0, -0.135, 0), 0.08 + travel * 0.29, "ice", 0.55, "Y", 10)
        for i = 1, 6 do
            local angle = i * TAU / 6
            local flight = smooth(0.42, 0.85, t)
            ball(
                point(
                    math.cos(angle) * 0.39 * flight,
                    math.sin(flight * math.pi) * 0.30,
                    math.sin(angle) * 0.30 * flight
                ),
                0.025,
                "aqua",
                0.85
            )
        end
    elseif p.kind == "coral" then
        local left, right =
            context.left or point(-0.42, 0.38, 0.02), context.right or point(0.42, 0.38, 0.02)
        bolt(left, right, 0, p.color, 9)
        local lowerA, lowerB = mix(left, right, 0.10), mix(left, right, 0.90)
        lowerA[2] -= 0.11
        lowerB[2] -= 0.11
        bolt(lowerA, lowerB, 2, p.accent, 7)
        for _, q in { left, right } do
            ball(q, 0.025 + gain * 0.014, "pearl", 0.9)
        end
    elseif p.kind == "relay" then
        local left, right =
            context.left or point(-0.36, 0.04, 0), context.right or point(0.36, 0.04, 0)
        local last
        for n = 0, 20 do
            local u = n / 20
            local q = mix(left, right, u)
            local angle = u * TAU * 2.5 - t * TAU * 5
            q[2] += math.cos(angle) * 0.14
            q[3] += math.sin(angle) * 0.14
            if last then
                line(last, q, 0.011, n % 3 == 0 and p.accent or p.color, 0.92)
            end
            last = q
        end
        bolt(left, right, 1, "ice", 9)
    elseif p.kind == "lantern" then
        local origin = context.origin or point(0, 0, 0)
        ball(origin, 0.11 * (1 + 0.12 * math.sin(t * TAU * 2)), "gold", 0.20)
        ring(origin, 0.25 + 0.06 * travel, "gold", 0.50, "Z", 12)
        for n = 1, 8 do
            local angle = n * TAU / 8
            local length = 0.08 + 0.05 * math.sin(n + t * 8) ^ 2
            line(
                point(
                    origin[1] + math.cos(angle) * 0.29,
                    origin[2] + math.sin(angle) * 0.29,
                    origin[3]
                ),
                point(
                    origin[1] + math.cos(angle) * (0.29 + length),
                    origin[2] + math.sin(angle) * (0.29 + length),
                    origin[3]
                ),
                0.009,
                "pearl",
                0.7
            )
        end
    elseif p.kind == "synth" then
        local low, high =
            context.low or point(-0.40, 0.10, 0.25), context.high or point(0.40, 0.10, 0.25)
        local amplitude = context.amplitude or 0.08
        local previous
        for n = 0, 28 do
            local u = n / 28
            local q = mix(low, high, u)
            q[2] += math.sin(u * TAU * 2 - smooth(0.14, 0.88, t) * TAU * 3) * amplitude * gain
            if previous then
                line(previous, q, 0.008, p.color, 0.96)
            end
            previous = q
        end
        local cursor = (smooth(0.14, 0.88, t) * 3) % 1
        local head = mix(low, high, cursor)
        head[2] += math.sin(cursor * TAU * 2 - smooth(0.14, 0.88, t) * TAU * 3) * amplitude * gain
        ball(head, 0.015, "pearl", 0.9)
    elseif p.kind == "chorus" then
        local left, right =
            context.left or point(-0.27, 0.18, 0.25), context.right or point(0.27, 0.18, 0.25)
        for i = 0, 2 do
            local start = 0.19 + i * 0.17
            local progress = math.clamp((t - start) / 0.42, 0, 1)
            if t > start and progress < 1 then
                local origin = i % 2 == 0 and left or right
                ring(
                    point(origin[1], origin[2], origin[3] + progress * 0.42),
                    0.10 + progress * 0.28,
                    i % 2 == 0 and p.color or p.accent,
                    (1 - progress) * 0.88,
                    "Z",
                    10
                )
            end
        end
    elseif p.kind == "echo" then
        for i = 1, p.count do
            local progress = math.clamp((t - p.peak + 0.08 - (i - 1) * 0.07) / 0.46, 0, 1)
            if progress > 0 and progress < 1 then
                ring(
                    point(0, p.lift, 0.19 + progress * 0.29),
                    0.12 + progress * p.spread,
                    i % 2 == 0 and p.accent or p.color,
                    (1 - progress) * 0.85,
                    id == "spring_coil" and "Y" or "Z",
                    8,
                    i * 0.09
                )
            end
        end
    elseif p.kind == "orbit" or p.kind == "helix" then
        for i = 1, p.count do
            local u = (i - 1) / p.count
            local angle = u * TAU + travel * TAU * p.turns
            local radius = p.spread * (0.60 + 0.30 * gain)
            local x, y, z =
                math.cos(angle) * radius,
                math.sin(angle) * radius * 0.65,
                math.sin(angle + u * 2) * 0.22
            if p.kind == "helix" then
                y = (u - 0.5) * p.lift * 1.4 + p.lift * travel * 0.20
            end
            local q = point(x, y + p.lift * 0.35, z)
            ball(
                q,
                0.017 + 0.009 * math.sin(u * math.pi) ^ 2,
                i % 3 == 0 and p.accent or p.color,
                0.9
            )
            line(
                q,
                point(
                    x - math.sin(angle) * 0.07,
                    y + p.lift * 0.35 + math.cos(angle) * 0.04,
                    z - 0.025
                ),
                0.006,
                p.color,
                0.60
            )
        end
    elseif p.kind == "bubble" then
        for i = 1, p.count do
            local u = (i - 1) / math.max(1, p.count - 1)
            local rise = math.clamp(travel * 1.3 - u * 0.22, 0, 1)
            local angle = u * TAU * p.turns + t * 2.5
            local q = point(
                math.cos(angle) * p.spread * (0.25 + rise * 0.65),
                -0.08 + p.lift * rise + math.sin(u * 7) * 0.12,
                0.10 + math.sin(angle) * p.spread * 0.3
            )
            local radius = (0.025 + u * 0.028) * (1 - rise * 0.35)
            ball(q, radius, i % 3 == 0 and p.accent or p.color, 0.58)
            ball(
                point(q[1] - radius * 0.28, q[2] + radius * 0.36, q[3] + radius * 0.65),
                radius * 0.25,
                "pearl",
                0.9
            )
        end
    elseif p.kind == "ribbon" then
        for i = 1, p.count do
            local u = (i - 1) / p.count
            local angle = (u - travel * 0.7) * TAU * p.turns
            local q = point(
                (u - 0.5) * p.spread * 1.6,
                math.sin(angle) * 0.10 + p.lift * travel,
                0.18 + math.cos(angle) * 0.08
            )
            local q2 = point(q[1] + 0.08, q[2] + math.cos(angle) * 0.065, q[3] - 0.02)
            line(
                q,
                q2,
                0.011 + 0.003 * math.sin(u * math.pi),
                i % 3 == 0 and p.accent or p.color,
                0.82
            )
            if i % 2 == 0 then
                ball(point(q[1], q[2] + 0.10, q[3]), 0.018, p.accent, 0.67)
            end
        end
    elseif p.kind == "petal" then
        for i = 1, p.count do
            local angle = i * TAU / p.count + p.turns * travel
            local r = (0.13 + travel * p.spread) * (0.82 + 0.16 * math.sin(i * 2))
            local q = point(
                math.cos(angle) * r,
                math.sin(angle) * r * 0.43 + p.lift * travel,
                0.14 + math.cos(i * 3) * 0.12
            )
            local leaf = 0.04 + 0.03 * (1 - travel)
            line(
                point(q[1] - leaf, q[2] - leaf * 0.35, q[3]),
                point(q[1], q[2] + leaf, q[3]),
                0.013,
                p.color,
                0.9
            )
            line(
                point(q[1], q[2] + leaf, q[3]),
                point(q[1] + leaf, q[2] - leaf * 0.35, q[3]),
                0.010,
                i % 3 == 0 and p.accent or p.color,
                0.85
            )
        end
    elseif p.kind == "scan" then
        local sweep = math.sin(travel * math.pi)
        for i = 1, p.count do
            local u = (i - 1) / math.max(1, p.count - 1)
            local y = p.lift + (u - 0.5) * 0.28
            line(
                point(-0.12, y, 0.24),
                point(p.spread * sweep, y + (u - 0.5) * p.turns * 0.24, 0.42 + sweep * 0.17),
                0.007,
                i % 2 == 0 and p.accent or p.color,
                0.8
            )
            ball(
                point(p.spread * sweep, y + (u - 0.5) * p.turns * 0.24, 0.42 + sweep * 0.17),
                0.019,
                "pearl",
                0.9
            )
        end
    elseif p.kind == "lattice" then
        for i = 1, p.count do
            local u = (i - 1) / math.max(1, p.count - 1)
            local x = (u - 0.5) * p.spread * 1.6
            local y = -0.18 + p.lift * (0.3 + 0.7 * math.sin(travel * math.pi + u * p.turns) ^ 2)
            line(point(x, -0.18, 0.20), point(x, y, 0.20), 0.012, p.color, 0.72)
            line(point(x - 0.035, y - 0.04, 0.20), point(x, y, 0.20), 0.010, p.accent, 0.9)
            line(point(x, y, 0.20), point(x + 0.035, y - 0.04, 0.20), 0.010, p.accent, 0.9)
        end
    elseif p.kind == "clock" then
        for i = 1, p.count do
            local angle = i * TAU / p.count + smooth(0.04, 0.94, t) * TAU * p.turns
            local radius = p.spread * (0.83 + 0.15 * gain)
            line(
                point(math.cos(angle) * radius, math.sin(angle) * radius + p.lift, 0.22),
                point(
                    math.cos(angle) * (radius + 0.06),
                    math.sin(angle) * (radius + 0.06) + p.lift,
                    0.22
                ),
                0.010,
                i % 3 == 0 and p.accent or p.color,
                0.9
            )
        end
        line(
            point(0, p.lift, 0.23),
            point(
                math.cos(t * TAU * p.turns) * p.spread * 0.67,
                math.sin(t * TAU * p.turns) * p.spread * 0.67 + p.lift,
                0.23
            ),
            0.007,
            p.accent,
            0.55
        )
    elseif p.kind == "glyph" then
        for i = 1, p.count do
            local angle = i * TAU / p.count + p.turns * travel
            local x, y =
                math.cos(angle) * p.spread, math.sin(angle) * p.spread * 0.55 + p.lift * travel
            local radius = 0.025
                + 0.04 * math.sin(math.pi * math.clamp(t * 1.4 - i * 0.035, 0, 1)) ^ 2
            line(point(x - radius, y, 0.24), point(x + radius, y, 0.24), 0.008, p.color, 0.85)
            line(point(x, y - radius, 0.24), point(x, y + radius, 0.24), 0.008, p.accent, 0.9)
        end
    elseif p.kind == "chest" then
        for i = 1, p.count do
            local angle = (i / (p.count + 1) - 0.5) * math.pi * 1.3
            local flight = smooth(0.56, 0.84, t)
            local x = math.sin(angle) * flight * p.spread
            local y = 0.12 + math.sin(flight * math.pi) * p.lift + math.cos(angle) * flight * 0.10
            local z = math.cos(i * 1.8) * flight * 0.26
            ball(point(x, y, z), 0.022 + (i % 3) * 0.005, i % 3 == 0 and p.accent or p.color, 0.95)
            line(
                point(x, y, z),
                point(x - math.sin(angle) * 0.05, y - 0.08, z),
                0.006,
                p.color,
                0.5
            )
        end
    else
        for i = 1, p.count do
            local angle = i * TAU / p.count + p.turns * math.pi
            local inner = 0.12 + travel * p.spread * 0.6
            local outer = inner + 0.08 + (1 - travel) * 0.12
            line(
                point(math.cos(angle) * inner, math.sin(angle) * inner * 0.65 + p.lift, 0.18),
                point(math.cos(angle) * outer, math.sin(angle) * outer * 0.65 + p.lift, 0.18),
                0.013,
                i % 3 == 0 and p.accent or p.color,
                0.9
            )
        end
    end
    if context.offset then
        for _, accent in out do
            local function shifted(q)
                return if q
                    then point(
                        q[1] + context.offset[1],
                        q[2] + context.offset[2],
                        q[3] + context.offset[3]
                    )
                    else nil
            end
            accent.a, accent.b = shifted(accent.a), shifted(accent.b)
        end
    end
    return out
end
Effects.entries = table.freeze(Effects.entries)
return Effects
