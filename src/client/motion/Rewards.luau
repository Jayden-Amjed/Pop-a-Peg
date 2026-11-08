-- Original reward performances. Times are normalized; body offsets are fractions
-- of the resting bounds. Articulated offsets retain ItemMotion's authored units.
return function(C)
    local rad = math.rad
    local function gain(a)
        return math.min(a, 1.25)
    end
    local function lid(t, start, finish)
        -- The imported lids have clearance through 105 degrees. Treasure must
        -- return below the rim before this held-open interval starts closing.
        return -rad(105) * (C.phase(t, start, start + 0.14) - C.phase(t, finish, 0.96))
    end

    return {
        first_spark = {
            duration = 0.92,
            name = "battery-crackle-kick",
            description = "Charge crouch, lightning kick toward the viewer, two electrical recoils and a soft landing.",
            body = function(t, a)
                local k = gain(a)
                local charge = C.pulse(t, 0, 0.13, 0.23)
                local kick = C.pulse(t, 0.13, 0.29, 0.73)
                local b = C.body()
                b.y = (-0.04 * charge + 0.12 * kick) * k
                b.z = 0.07 * kick * k
                b.rz = (-0.19 * charge + 0.24 * C.ring(t, 0.19, 0.87, 2)) * k
                b.rx = -0.21 * kick * k
                b.scale = 1 + (-0.07 * charge + 0.19 * kick) * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "Spark" then
                    local kick = C.pulse(t, 0.14, 0.28, 0.70)
                    v.x = 0.09 * C.ring(t, 0.18, 0.65, 4) * gain(a)
                    v.z = 0.22 * kick * gain(a)
                    v.rz = 0.48 * C.ring(t, 0.12, 0.83, 2)
                    v.scale = 1 + 0.24 * kick * gain(a)
                    v.glow = 0.8 * kick
                end
                return v
            end,
        },
        tailwind = {
            duration = 1.18,
            name = "fan-jet-launch",
            description = "Fan leans into its windup, rotor races three turns, thrust lifts the housing and eases to a hover landing.",
            body = function(t, a)
                local k = gain(a)
                local thrust = C.pulse(t, 0.12, 0.36, 0.88)
                local b = C.body()
                b.y = 0.13 * thrust * k
                b.z = -0.10 * thrust * k
                b.rx = (0.24 * C.pulse(t, 0, 0.13, 0.26) - 0.25 * thrust) * k
                b.ry = 0.18 * C.ring(t, 0.25, 0.90, 1) * k
                b.scale = 1 + 0.14 * thrust * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "Turbine" then
                    v.rz = -C.spin(t, 0.09, 0.88, 3)
                    v.z = 0.055 * C.pulse(t, 0.14, 0.32, 0.84) * gain(a)
                    v.glow = 0.45 * C.pulse(t, 0.13, 0.39, 0.88)
                end
                return v
            end,
        },
        ricochet = {
            duration = 1.12,
            name = "pearl-three-cushion-rally",
            description = "Pearl drops toward its pad, ricochets left and right inside the arch, then lands with a smaller body rebound.",
            body = function(t, a)
                local k = gain(a)
                local hit = C.pulse(t, 0.10, 0.22, 0.51)
                local rebound = C.pulse(t, 0.47, 0.61, 0.91)
                local b = C.body()
                b.y = (0.12 * hit + 0.06 * rebound) * k
                b.rz = 0.22 * C.ring(t, 0.12, 0.88, 1.5) * k
                b.scale = 1 + (0.17 * hit + 0.07 * rebound) * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "ReboundBall" then
                    local k = math.min(a, 1)
                    v.x = 0.23 * C.ring(t, 0.13, 0.85, 1.5) * k
                    v.y = (
                        -0.22 * C.pulse(t, 0, 0.13, 0.23)
                        + 0.22 * C.pulse(t, 0.18, 0.37, 0.59)
                        + 0.12 * C.pulse(t, 0.57, 0.69, 0.90)
                    ) * k
                    v.rz = -C.spin(t, 0.14, 0.85, 1)
                    v.scale = 1 - 0.08 * C.pulse(t, 0.07, 0.14, 0.23)
                    v.glow = 0.55 * C.pulse(t, 0.18, 0.37, 0.82)
                end
                return v
            end,
        },
        growth_ring = {
            duration = 1.28,
            name = "seed-orbit-bloom",
            description = "Seed gathers inward, its leaf ring unfurls through a complete orbit and the whole plant rises into a buoyant bloom.",
            body = function(t, a)
                local k = gain(a)
                local bloom = C.pulse(t, 0.15, 0.46, 0.91)
                local b = C.body()
                b.y = (-0.025 * C.pulse(t, 0, 0.12, 0.24) + 0.15 * bloom) * k
                b.ry = 0.30 * C.ring(t, 0.15, 0.94, 1) * k
                b.rz = 0.14 * C.ring(t, 0.32, 0.96, 1.5) * k
                b.scale = 1 + (-0.08 * C.pulse(t, 0, 0.14, 0.28) + 0.20 * bloom) * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "Orbit" then
                    v.ry = C.spin(t, 0.13, 0.90, 1)
                    v.rx = 0.39 * C.pulse(t, 0.13, 0.44, 0.90) * gain(a)
                    v.scale = 1 + 0.15 * C.pulse(t, 0.12, 0.42, 0.87) * gain(a)
                    v.glow = 0.5 * C.pulse(t, 0.24, 0.48, 0.88)
                end
                return v
            end,
        },
        recovery = {
            duration = 1.24,
            name = "renewal-corkscrew-return",
            description = "Arrows gather in reverse, sweep a double renewal spiral while the body follows a small loop, then spring back into alignment.",
            body = function(t, a)
                local k = gain(a)
                local lift = C.pulse(t, 0.13, 0.40, 0.91)
                local b = C.body()
                b.x = 0.085 * C.ring(t, 0.12, 0.88, 1) * k
                b.y = 0.14 * lift * k
                b.z = 0.055 * C.ring(t, 0.20, 0.92, 1) * k
                b.rz = 0.36 * C.ring(t, 0.09, 0.93, 1) * k
                b.scale = 1 + 0.17 * lift * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "RecoveryArrows" then
                    v.rz = 0.28 * C.pulse(t, 0, 0.12, 0.23) - C.spin(t, 0.13, 0.88, 2)
                    v.scale = 1 + 0.16 * C.pulse(t, 0.18, 0.46, 0.90) * gain(a)
                    v.z = 0.10 * C.pulse(t, 0.17, 0.43, 0.87) * gain(a)
                    v.glow = 0.55 * C.pulse(t, 0.18, 0.45, 0.89)
                end
                return v
            end,
        },
        last_word = {
            duration = 1.13,
            name = "quotation-double-stamp",
            description = "Speech card draws back, its two punctuation marks punch forward in sequence and the second word lands with a decisive nod.",
            body = function(t, a)
                local k = gain(a)
                local first = C.pulse(t, 0.12, 0.24, 0.47)
                local final = C.pulse(t, 0.37, 0.50, 0.87)
                local b = C.body()
                b.z = (-0.045 * C.pulse(t, 0, 0.11, 0.21) + 0.075 * first + 0.10 * final) * k
                b.y = (0.06 * first + 0.10 * final) * k
                b.rx = (0.17 * first - 0.24 * final) * k
                b.scale = 1 + (0.10 * first + 0.20 * final) * k
                return b
            end,
            part = function(group, t, a, x, _y, _z, v)
                if group == "Quote" then
                    local delay = if x < 0 then 0 else 0.24
                    local stamp = C.pulse(t, 0.11 + delay, 0.24 + delay, 0.60 + delay)
                    v.y = 0.20 * stamp * gain(a)
                    v.z = 0.22 * stamp * gain(a)
                    v.rz = (if x < 0 then -1 else 1) * 0.35 * stamp
                    v.scale = 1 + 0.18 * stamp * gain(a)
                    v.glow = 0.5 * stamp
                end
                return v
            end,
        },
        metronome = {
            duration = 1.30,
            name = "pendulum-whip-cadence",
            description = "Metronome cocks to one side, whips its pendulum across a wide beat and answers with two diminishing counterbeats.",
            body = function(t, a)
                local k = gain(a)
                local beat = C.pulse(t, 0.13, 0.31, 0.66)
                local b = C.body()
                b.rz = (-0.18 * C.pulse(t, 0, 0.13, 0.26) - 0.19 * C.ring(t, 0.17, 0.95, 2)) * k
                b.y = 0.10 * beat * k
                b.scale = 1 + 0.16 * beat * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "Pendulum" then
                    -- The stem slides a little forward along its bearing before
                    -- the broad whip, clearing the pearl A-frame during crossing.
                    v.z = 0.085 * (C.phase(t, 0, 0.10) - C.phase(t, 0.85, 0.98))
                    v.rz = (
                        0.45 * C.pulse(t, 0, 0.15, 0.28)
                        - 1.28 * C.pulse(t, 0.15, 0.31, 0.51)
                        + 0.65 * C.pulse(t, 0.43, 0.56, 0.73)
                        - 0.25 * C.pulse(t, 0.66, 0.77, 0.94)
                    ) * math.min(a, 1)
                    v.glow = 0.45 * C.pulse(t, 0.17, 0.32, 0.80)
                end
                return v
            end,
        },
        milestone = {
            duration = 1.34,
            name = "three-step-flag-fanfare",
            description = "Stairs rise in an ascending three-beat procession, followed by a broad flag celebration and a small proud landing.",
            body = function(t, a)
                local k = gain(a)
                local summit = C.pulse(t, 0.30, 0.55, 0.93)
                local b = C.body()
                b.x = 0.04 * C.ring(t, 0.05, 0.79, 1) * k
                b.y = 0.15 * summit * k
                b.ry = -0.19 * summit * k
                b.scale = 1 + 0.18 * summit * k
                return b
            end,
            part = function(group, t, a, x, _y, _z, v)
                if group == "Step" then
                    local order = math.clamp((x + 0.45) / 0.42, 0, 2)
                    local start = 0.05 + order * 0.13
                    v.y = 0.22 * C.pulse(t, start, start + 0.13, start + 0.43) * gain(a)
                    v.glow = 0.3 * C.pulse(t, start, start + 0.14, start + 0.45)
                elseif group == "Flag" then
                    v.rz = 0.46 * C.ring(t, 0.30, 0.95, 2) * math.min(a, 1)
                    v.ry = 0.30 * C.ring(t, 0.38, 0.95, 1.5) * gain(a)
                    v.y = 0.10 * C.pulse(t, 0.32, 0.56, 0.90) * gain(a)
                end
                return v
            end,
        },
        chest_common = {
            duration = 1.55,
            name = "meadow-latch-surprise",
            description = "Chest gives a curious rocking windup, pops its leaf clasp, hops open with a seed bouquet and gently closes after the seeds return.",
            body = function(t, a)
                local k = gain(a)
                local reveal = C.pulse(t, 0.18, 0.35, 0.70)
                local b = C.body()
                b.rz = (0.13 * C.ring(t, 0, 0.25, 1) + 0.07 * C.ring(t, 0.40, 0.89, 1)) * k
                b.y = (-0.035 * C.pulse(t, 0.02, 0.14, 0.24) + 0.105 * reveal) * k
                b.scale = 1 + 0.13 * reveal * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "ChestLid" then
                    v.rx = lid(t, 0.20, 0.79)
                elseif group == "ChestClasp" then
                    v.z = 0.22 * C.pulse(t, 0.10, 0.20, 0.39) * gain(a)
                    v.rz = 0.30 * C.ring(t, 0.12, 0.43, 1)
                elseif group == "ChestTreasure" then
                    local reveal = C.pulse(t, 0.34, 0.49, 0.76)
                    v.y = 0.82 * reveal * gain(a)
                    v.ry = C.spin(t, 0.34, 0.75, 1)
                    v.scale = 1 + 0.22 * reveal
                    v.glow = 0.85 * reveal
                end
                return v
            end,
        },
        chest_uncommon = {
            duration = 1.70,
            name = "lagoon-tidal-reveal",
            description = "Lagoon coffer rolls with an incoming wave, releases its seal and floats its reward on a sweeping tide before a soft ebb and closure.",
            body = function(t, a)
                local k = gain(a)
                local tide = C.pulse(t, 0.14, 0.39, 0.87)
                local b = C.body()
                b.x = 0.07 * C.ring(t, 0.03, 0.90, 1) * k
                b.y = 0.14 * tide * k
                b.rz = 0.23 * C.ring(t, 0.02, 0.93, 1.5) * k
                b.rx = -0.10 * tide * k
                b.scale = 1 + 0.16 * tide * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "ChestLid" then
                    v.rx = lid(t, 0.21, 0.80)
                elseif group == "ChestClasp" then
                    v.z = 0.24 * C.pulse(t, 0.12, 0.22, 0.40) * gain(a)
                    v.rz = C.spin(t, 0.15, 0.53, 1)
                elseif group == "ChestTreasure" then
                    local tide = C.pulse(t, 0.35, 0.53, 0.77)
                    v.y = 0.92 * tide * gain(a)
                    v.x = 0.09 * C.ring(t, 0.38, 0.73, 1) * gain(a)
                    v.ry = C.spin(t, 0.36, 0.75, 1)
                    v.scale = 1 + 0.28 * tide
                    v.glow = 0.9 * tide
                end
                return v
            end,
        },
        chest_rare = {
            duration = 1.84,
            name = "aurora-vault-eruption",
            description = "Heavy vault compresses and trembles, kicks upward as its crystal lid opens, ejects rewards in two pulses and settles with a cushioned thud.",
            body = function(t, a)
                local k = gain(a)
                local load = C.pulse(t, 0, 0.19, 0.29)
                local leap = C.pulse(t, 0.20, 0.35, 0.68)
                local b = C.body()
                b.y = (-0.05 * load + 0.18 * leap + 0.035 * C.pulse(t, 0.65, 0.73, 0.89)) * k
                b.rz = 0.06 * C.ring(t, 0.02, 0.24, 3) * k
                b.rx = -0.16 * leap * k
                b.scale = 1 + (-0.08 * load + 0.19 * leap) * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "ChestLid" then
                    v.rx = lid(t, 0.23, 0.82)
                elseif group == "ChestClasp" then
                    local release = C.pulse(t, 0.16, 0.25, 0.43)
                    v.z = 0.29 * release * gain(a)
                    v.y = 0.10 * release * gain(a)
                    v.rz = 0.48 * C.ring(t, 0.18, 0.47, 1)
                elseif group == "ChestTreasure" then
                    local reveal = C.pulse(t, 0.37, 0.50, 0.79)
                    v.y = (1.02 * reveal + 0.12 * C.pulse(t, 0.54, 0.61, 0.71)) * gain(a)
                    v.ry = -C.spin(t, 0.38, 0.77, 2)
                    v.scale = 1 + 0.32 * reveal
                    v.glow = 0.95 * reveal
                end
                return v
            end,
        },
        chest_legendary = {
            duration = 2.0,
            name = "celestial-coronation",
            description = "Celestial chest levitates into a full coronation turn, orbit ring races around the crown, then rewards ascend before a deliberate royal closure.",
            body = function(t, a)
                local k = gain(a)
                local coronation = C.pulse(t, 0.13, 0.43, 0.91)
                local b = C.body()
                b.y = (-0.035 * C.pulse(t, 0, 0.12, 0.24) + 0.19 * coronation) * k
                b.ry = C.spin(t, 0.13, 0.63, 1)
                b.rx = -0.11 * coronation * k
                b.rz = 0.08 * C.ring(t, 0.60, 0.95, 1) * k
                b.scale = 1 + 0.22 * coronation * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "ChestLid" then
                    v.rx = lid(t, 0.28, 0.83)
                elseif group == "ChestClasp" then
                    local release = C.pulse(t, 0.18, 0.29, 0.46)
                    v.z = 0.30 * release * gain(a)
                    v.rz = C.spin(t, 0.22, 0.53, 1)
                elseif group == "ChestTreasure" then
                    local reveal = C.pulse(t, 0.42, 0.60, 0.80)
                    v.y = 1.12 * reveal * gain(a)
                    v.ry = C.spin(t, 0.43, 0.78, 2)
                    v.scale = 1 + 0.37 * reveal
                    v.glow = reveal
                elseif group == "ChestOrbit" then
                    v.ry = C.spin(t, 0.12, 0.89, 3)
                    v.rx = 0.19 * C.pulse(t, 0.15, 0.46, 0.88)
                    v.scale = 1 + 0.12 * C.pulse(t, 0.14, 0.42, 0.88)
                    v.glow = 0.70 * C.pulse(t, 0.23, 0.49, 0.88)
                end
                return v
            end,
        },
        event_growth = {
            duration = 1.23,
            name = "sprout-jack-in-the-pot",
            description = "Planter gathers down, springing its sprout into an oversized bloom with a leafy side-to-side celebration and gentle return to soil.",
            body = function(t, a)
                local k = gain(a)
                local bloom = C.pulse(t, 0.14, 0.32, 0.88)
                local b = C.body()
                b.y = (-0.045 * C.pulse(t, 0, 0.14, 0.25) + 0.14 * bloom) * k
                b.rz = 0.20 * C.ring(t, 0.25, 0.93, 2) * k
                b.scale = 1 + 0.18 * bloom * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "EventSprout" then
                    local bloom = C.pulse(t, 0.12, 0.34, 0.91)
                    v.y = 0
                    v.scale = 1
                        + (-0.14 * C.pulse(t, 0, 0.12, 0.22) + 0.24 * bloom) * math.min(a, 1)
                    v.rz = 0.30 * C.ring(t, 0.24, 0.93, 2) * math.min(a, 1)
                    v.ry = 0.40 * C.ring(t, 0.19, 0.93, 1)
                    v.glow = 0.55 * bloom
                end
                return v
            end,
        },
        event_repair = {
            duration = 1.03,
            name = "repair-heartbeat-defibrillation",
            description = "Repair kit jolts through two strong heartbeat pulses, pushes its healing cross toward the viewer and exhales back to rest.",
            body = function(t, a)
                local k = gain(a)
                local beat = C.pulse(t, 0.08, 0.21, 0.40)
                local answer = C.pulse(t, 0.35, 0.48, 0.90)
                local b = C.body()
                b.y = (0.08 * beat + 0.12 * answer) * k
                b.z = (0.05 * beat + 0.08 * answer) * k
                b.rz = (0.11 * beat - 0.11 * answer) * k
                b.scale = 1 + (0.14 * beat + 0.20 * answer) * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                if group == "EventCross" then
                    local heartbeat = C.pulse(t, 0.08, 0.21, 0.40) + C.pulse(t, 0.35, 0.48, 0.88)
                    v.z = 0.18 * heartbeat * gain(a)
                    v.scale = 1 + 0.28 * heartbeat * gain(a)
                    v.rz = 0.19 * C.ring(t, 0.43, 0.93, 1)
                    v.glow = 0.8 * heartbeat
                end
                return v
            end,
        },
        event_upgrade = {
            duration = 1.17,
            name = "upgrade-chevron-launch",
            description = "Three arrows crouch, side arrows launch first, the gold leader overtakes them and the stand rises after the accelerating formation.",
            body = function(t, a)
                local k = gain(a)
                local launch = C.pulse(t, 0.20, 0.44, 0.93)
                local b = C.body()
                b.y = (-0.04 * C.pulse(t, 0.01, 0.15, 0.28) + 0.17 * launch) * k
                b.rx = -0.17 * launch * k
                b.scale = 1 + 0.17 * launch * k
                return b
            end,
            part = function(group, t, a, x, _y, _z, v)
                if group == "EventArrow" then
                    local central = math.abs(x) < 0.20
                    local start = if central then 0.23 else 0.13
                    local launch = C.pulse(t, start, start + 0.16, 0.91)
                    v.y = (
                        (if central then 0.49 else 0.31) * launch
                        - 0.08 * C.pulse(t, 0.01, 0.12, 0.24)
                    ) * gain(a)
                    v.rz = (if central then 0 else -math.sign(x) * 0.10) * launch
                    v.scale = 1 + (if central then 0.20 else 0.10) * launch * gain(a)
                    v.glow = (if central then 0.8 else 0.5) * launch
                end
                return v
            end,
        },
        event_overtime = {
            duration = 1.40,
            name = "hourglass-somersault-reset",
            description = "Hourglass cocks back, tumbles a complete turn in a buoyant arc, then restarts its sand stream only once the glass is upright again.",
            body = function(t, a)
                local k = gain(a)
                local arc = C.pulse(t, 0.12, 0.36, 0.79)
                local b = C.body()
                b.rz = -0.22 * C.pulse(t, 0, 0.13, 0.26) + C.spin(t, 0.15, 0.66, 1)
                b.y = 0.18 * arc * k
                b.x = 0.045 * C.ring(t, 0.15, 0.78, 1) * k
                b.scale = 1 + 0.18 * arc * k
                return b
            end,
            part = function(group, t, a, _x, _y, _z, v)
                local flow = C.pulse(t, 0.65, 0.78, 0.97)
                if group == "EventSand" then
                    v.y = -0.10 * flow * math.min(a, 1)
                    v.scale = 1 - 0.09 * flow
                    v.glow = 0.25 * flow
                elseif group == "EventStream" then
                    v.scale = 1 + 0.28 * flow * math.min(a, 1)
                    v.glow = 0.7 * flow
                end
                return v
            end,
        },
    }
end
