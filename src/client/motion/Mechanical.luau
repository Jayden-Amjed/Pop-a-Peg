-- Expressive trigger choreography; idle motion remains owned by the renderer.
-- Body offsets are fractions of rest bounds. Part offsets retain stud units.
return function(C)
    local P, R = C.pulse, C.ring
    local function spin(t, a, first, last, turns)
        return if a > 0 then C.spin(t, first, last, turns) else 0
    end
    local function clean(v)
        v.x, v.y, v.z = 0, 0, 0
        v.rx, v.ry, v.rz = 0, 0, 0
        v.scale, v.axial, v.glow = 1, 1, 0
        return v
    end
    local entries = {}
    local function add(id, duration, name, description, body, part)
        entries[id] = {
            duration = duration,
            name = name,
            description = description,
            body = body,
            part = part,
        }
    end

    add(
        "tap_driver",
        0.84,
        "cock-punch-double-tap",
        "Cocks back, punches twice, then rebounds through its handle.",
        function(t, a)
            local v = C.body()
            v.x = a * (-0.09 * P(t, 0, 0.13, 0.25) + 0.07 * P(t, 0.17, 0.25, 0.45))
            v.y = a * (0.10 * P(t, 0.24, 0.36, 0.66) + 0.035 * P(t, 0.62, 0.71, 0.9))
            v.rz = a * (-0.19 * P(t, 0.04, 0.17, 0.32) + 0.13 * R(t, 0.27, 0.92, 1))
            v.scale = 1 + a * (-0.04 * P(t, 0, 0.13, 0.24) + 0.22 * P(t, 0.20, 0.29, 0.58))
            return v
        end,
        function(_, t, a, _, _, _, v)
            clean(v)
            -- The sleeve stays inside the collar even at boosted trigger strength.
            v.x = math.min(a, 1)
                * (
                    -0.25 * P(t, 0, 0.14, 0.23)
                    + 0.10 * P(t, 0.18, 0.25, 0.40)
                    + 0.07 * P(t, 0.42, 0.49, 0.65)
                )
            return v
        end
    )

    add(
        "split_prism",
        1.14,
        "prism-refract-fan",
        "Tilts to aim, fans through a complete turn, and snaps its focus forward.",
        function(t, a)
            local v = C.body()
            v.rx = a * (-0.20 * P(t, 0, 0.15, 0.34) + 0.16 * P(t, 0.47, 0.62, 0.91))
            v.ry = spin(t, a, 0.16, 0.79, 1)
            v.y = a * 0.16 * P(t, 0.12, 0.42, 0.88)
            v.z = a * 0.065 * P(t, 0.59, 0.72, 0.93)
            v.scale = 1 + a * 0.19 * P(t, 0.14, 0.38, 0.9)
            return v
        end,
        function(_, t, a, _, _, _, v)
            clean(v)
            v.z = a * 0.21 * P(t, 0.54, 0.69, 0.9)
            v.glow = 0.9 * P(t, 0.16, 0.49, 0.9)
            return v
        end
    )

    add(
        "wall_meter",
        0.92,
        "shore-sidekick-surge",
        "A lateral bumper kick sends a rising surge through the gauge.",
        function(t, a)
            local v = C.body()
            v.x = a * (-0.055 * P(t, 0, 0.13, 0.23) + 0.12 * P(t, 0.18, 0.28, 0.58))
            v.y = a * (0.09 * P(t, 0.26, 0.39, 0.64) + 0.035 * P(t, 0.64, 0.72, 0.9))
            v.rz = a * (-0.24 * P(t, 0.17, 0.30, 0.57) + 0.09 * R(t, 0.5, 0.94, 1))
            v.scale = 1 + a * 0.19 * P(t, 0.19, 0.31, 0.66)
            return v
        end,
        function(group, t, a, x, _, _, v)
            clean(v)
            if group == "Bumper" then
                v.x = -a * 0.30 * P(t, 0.12, 0.22, 0.43)
            else
                local delay = math.clamp((x + 1) * 0.045, 0, 0.09)
                v.scale = 1 + a * 0.25 * P(t, 0.22 + delay, 0.39 + delay, 0.8 + delay)
                v.glow = 0.45 * P(t, 0.22 + delay, 0.39 + delay, 0.8 + delay)
            end
            return v
        end
    )

    add(
        "clockwork",
        1.38,
        "tide-clock-overdrive",
        "Loads torsion, accelerates hands and gears, then settles with a weighted tick.",
        function(t, a)
            local v = C.body()
            v.rz = a
                * (
                    -0.21 * P(t, 0, 0.15, 0.34)
                    + 0.16 * P(t, 0.23, 0.46, 0.74)
                    + 0.06 * R(t, 0.67, 0.97, 1)
                )
            v.y = a * (0.11 * P(t, 0.16, 0.43, 0.76) - 0.025 * P(t, 0.75, 0.82, 0.94))
            v.scale = 1 + a * 0.18 * P(t, 0.17, 0.42, 0.84)
            return v
        end,
        function(group, t, a, _, _, _, v)
            clean(v)
            local turns = if group == "MinuteHand"
                then -5
                elseif group == "HourHand" then -2
                elseif group == "LeftGear" then 4
                else -3
            v.rz = spin(t, a, 0.13, 0.87, turns)
            return v
        end
    )

    add(
        "burst_capsule",
        1.50,
        "capsule-lift-off-reseal",
        "Builds pressure, blows its complete top clear of the capsule, then catches and reseats the cap with a springy landing.",
        function(t, a)
            local v = C.body()
            v.y = a * (-0.045 * P(t, 0, 0.18, 0.27) + 0.16 * P(t, 0.23, 0.32, 0.67))
            v.rz = a * (0.05 * R(t, 0, 0.23, 3) + 0.10 * R(t, 0.70, 0.98, 1))
            v.scale = 1 + a * (-0.055 * P(t, 0, 0.18, 0.26) + 0.23 * P(t, 0.23, 0.30, 0.69))
            return v
        end,
        function(group, t, a, x, _, _, v)
            clean(v)
            if group == "BurstCap" or group == "Pin" then
                local lift = C.phase(t, 0.22, 0.32) - C.phase(t, 0.52, 0.76)
                v.y = math.min(a, 1.3) * 1.15 * lift
                v.rz = math.min(a, 1.3) * 0.24 * P(t, 0.30, 0.44, 0.60)
            else
                v.x = x * a * 0.21 * P(t, 0.18, 0.33, 0.73)
                v.ry = a * 0.30 * R(t, 0.29, 0.94, 2)
            end
            return v
        end
    )

    add(
        "relay",
        1.17,
        "relay-barrel-charge",
        "Winds the coil, rolls over its long axis, and closes the contact with a double snap.",
        function(t, a)
            local v = C.body()
            v.rz = a * -0.18 * P(t, 0, 0.16, 0.34)
            v.rx = spin(t, a, 0.20, 0.80, 1)
            v.y = a * 0.15 * P(t, 0.15, 0.43, 0.9)
            v.z = a * 0.045 * R(t, 0.40, 0.94, 1)
            v.scale = 1 + a * 0.20 * P(t, 0.14, 0.36, 0.88)
            return v
        end,
        function(group, t, a, _, _, _, v)
            clean(v)
            if group == "Contact" then
                v.y = a
                    * (
                        0.10 * P(t, 0, 0.14, 0.23)
                        - 0.28 * P(t, 0.19, 0.27, 0.42)
                        - 0.20 * P(t, 0.48, 0.56, 0.73)
                    )
            else
                v.scale = 1 + a * 0.15 * P(t, 0.12, 0.35, 0.81)
                v.glow = 0.7 * P(t, 0.14, 0.37, 0.84)
            end
            return v
        end
    )

    add(
        "landing_fund",
        1.08,
        "shell-catch-and-toss",
        "Dips to catch the reward, opens its shell, and tosses the coin with a cheerful bounce.",
        function(t, a)
            local v = C.body()
            v.y = a * (-0.07 * P(t, 0, 0.15, 0.27) + 0.16 * P(t, 0.23, 0.42, 0.81))
            v.rx = a * (-0.16 * P(t, 0.04, 0.18, 0.37) + 0.23 * P(t, 0.29, 0.48, 0.85))
            v.ry = a * 0.19 * R(t, 0.40, 0.96, 1)
            v.scale = 1 + a * 0.21 * P(t, 0.21, 0.38, 0.84)
            return v
        end,
        function(group, t, a, _, _, _, v)
            clean(v)
            if group == "ShellLid" then
                v.rx = a * 0.58 * P(t, 0.13, 0.29, 0.82)
            else
                v.y = a * 0.55 * P(t, 0.23, 0.48, 0.86)
                v.ry = spin(t, a, 0.25, 0.85, 2)
            end
            return v
        end
    )

    add(
        "survey_lens",
        1.20,
        "lens-flip-focus",
        "Draws back, performs a full presentation roll, and extends the lens for a sharp focus beat.",
        function(t, a)
            local v = C.body()
            v.z = a * (-0.06 * P(t, 0, 0.13, 0.28) + 0.09 * P(t, 0.66, 0.76, 0.93))
            v.rz = spin(t, a, 0.14, 0.77, 1)
            v.rx = a * -0.14 * P(t, 0.63, 0.76, 0.94)
            v.y = a * 0.15 * P(t, 0.12, 0.41, 0.85)
            v.scale = 1 + a * 0.18 * P(t, 0.12, 0.35, 0.92)
            return v
        end,
        function(_, t, a, _, _, z, v)
            clean(v)
            v.z = a * (0.16 + math.max(0, z) * 0.16) * P(t, 0.60, 0.74, 0.94)
            v.ry = a * 0.10 * R(t, 0.71, 0.97, 1)
            return v
        end
    )

    add(
        "gain_dial",
        1.02,
        "gain-crank-kick",
        "Braces backward, cranks through a full turn, and kicks forward as the gain catches.",
        function(t, a)
            local v = C.body()
            v.rx = a * (-0.20 * P(t, 0, 0.15, 0.30) + 0.21 * P(t, 0.23, 0.37, 0.72))
            v.y = a * 0.11 * P(t, 0.20, 0.39, 0.8)
            v.z = a * 0.07 * P(t, 0.24, 0.40, 0.76)
            v.rz = a * 0.08 * R(t, 0.57, 0.96, 1)
            v.scale = 1 + a * 0.23 * P(t, 0.19, 0.35, 0.81)
            return v
        end,
        function(_, t, a, _, _, _, v)
            clean(v)
            v.rz = spin(t, a, 0.13, 0.72, -1) - a * 0.60 * P(t, 0.64, 0.76, 0.95)
            return v
        end
    )

    add(
        "soft_saw",
        1.23,
        "current-cartwheel",
        "Curls sideways, cartwheels with the current, and unfurls a trailing foam wake.",
        function(t, a)
            local v = C.body()
            v.x = a * 0.12 * R(t, 0.07, 0.92, 1)
            v.rz = spin(t, a, 0.14, 0.81, -1)
            v.y = a * 0.16 * P(t, 0.12, 0.43, 0.9)
            v.ry = a * 0.18 * P(t, 0.57, 0.73, 0.95)
            v.scale = 1 + a * 0.19 * P(t, 0.14, 0.38, 0.91)
            return v
        end,
        function(group, t, a, x, _, _, v)
            clean(v)
            if group == "Current" then
                v.rz = a * 0.60 * P(t, 0.10, 0.38, 0.92)
            else
                local delay = math.clamp((x + 0.7) * 0.1, 0, 0.14)
                v.y = a * 0.33 * P(t, 0.24 + delay, 0.46 + delay, 0.83 + delay)
                v.x = a * 0.11 * R(t, 0.27, 0.96, 1)
            end
            return v
        end
    )

    add(
        "balance_scale",
        1.28,
        "pearl-tipping-point",
        "Loads one side, tips decisively, and rocks through a damped balance recovery.",
        function(t, a)
            local v = C.body()
            v.rz = a * (-0.13 * P(t, 0, 0.16, 0.31) + 0.17 * R(t, 0.21, 0.96, 1.5))
            v.y = a * (-0.045 * P(t, 0.08, 0.19, 0.32) + 0.11 * P(t, 0.29, 0.46, 0.85))
            v.scale = 1 + a * 0.17 * P(t, 0.18, 0.36, 0.87)
            return v
        end,
        function(group, t, a, x, _, _, v)
            clean(v)
            local angle = a * 0.35 * R(t, 0.08, 0.96, 1.5)
            if group == "BalanceBeam" then
                v.rz = angle
            else
                v.y = x * math.sin(angle)
                v.x = x * (math.cos(angle) - 1)
            end
            return v
        end
    )

    add(
        "resonator",
        0.94,
        "reef-ringing-recoil",
        "Tenses the fork, rings with a visible rapid shiver, and releases one bright chime bounce.",
        function(t, a)
            local v = C.body()
            v.x = a * 0.065 * R(t, 0.17, 0.88, 5)
            v.y = a * 0.12 * P(t, 0.17, 0.31, 0.77)
            v.rz = a * 0.08 * R(t, 0.16, 0.94, 3)
            v.scale = 1 + a * (-0.035 * P(t, 0, 0.13, 0.22) + 0.21 * P(t, 0.17, 0.28, 0.78))
            return v
        end,
        function(group, t, a, _, _, _, v)
            clean(v)
            if group == "Chime" then
                v.y = a * 0.20 * P(t, 0.21, 0.36, 0.81)
                v.z = a * 0.10 * R(t, 0.2, 0.94, 2)
            else
                v.x = (if group == "LeftFork" then -1 else 1) * a * 0.12 * R(t, 0.12, 0.93, 6)
            end
            return v
        end
    )

    add(
        "echo_plate",
        1.12,
        "echo-shell-sonic-bloom",
        "Leans open, projects its pearl, then answers with a smaller echo ripple.",
        function(t, a)
            local v = C.body()
            v.rx = a * (-0.25 * P(t, 0, 0.16, 0.35) + 0.14 * P(t, 0.26, 0.43, 0.83))
            v.z = a * (0.10 * P(t, 0.21, 0.34, 0.61) + 0.04 * P(t, 0.61, 0.72, 0.93))
            v.y = a * 0.13 * P(t, 0.17, 0.38, 0.86)
            v.scale = 1 + a * 0.22 * P(t, 0.17, 0.32, 0.85)
            return v
        end,
        function(group, t, a, _, _, _, v)
            clean(v)
            if group == "Pearl" then
                v.z = a * 0.45 * P(t, 0.18, 0.36, 0.85)
                v.y = a * 0.18 * P(t, 0.21, 0.43, 0.88)
                v.scale = 1 + a * 0.22 * P(t, 0.18, 0.34, 0.84)
            else
                v.z = a * 0.12 * R(t, 0.21, 0.95, 2)
            end
            return v
        end
    )

    add(
        "growth_array",
        1.34,
        "coral-wave-bloom",
        "Bends into a growing wave, blooms from planted stems, and sways back into its bed.",
        function(t, a)
            local v = C.body()
            v.y = a * 0.15 * P(t, 0.16, 0.44, 0.90)
            v.rz = a * 0.16 * R(t, 0.04, 0.96, 1)
            v.rx = a * -0.12 * P(t, 0.16, 0.40, 0.85)
            v.scale = 1 + a * 0.18 * P(t, 0.14, 0.40, 0.91)
            return v
        end,
        function(_, t, a, x, _, _, v)
            clean(v)
            local delay = math.clamp((x + 0.8) * 0.075, 0, 0.12)
            v.scale = 1 + a * 0.25 * P(t, 0.12 + delay, 0.36 + delay, 0.83 + delay)
            v.rz = a * 0.12 * R(t, 0.15 + delay, 0.97, 1)
            return v
        end
    )

    add(
        "quota_bonus",
        0.88,
        "quota-heavy-stamp",
        "Lifts the stamp, slams once with weight, then kicks the whole press into a recoil hop.",
        function(t, a)
            local v = C.body()
            v.y = a * (-0.07 * P(t, 0.18, 0.28, 0.41) + 0.15 * P(t, 0.30, 0.47, 0.87))
            v.rx = a * (0.10 * P(t, 0, 0.14, 0.27) - 0.18 * P(t, 0.20, 0.32, 0.60))
            v.rz = a * 0.07 * R(t, 0.40, 0.95, 1)
            v.scale = 1 + a * (-0.045 * P(t, 0.17, 0.27, 0.36) + 0.24 * P(t, 0.29, 0.40, 0.81))
            return v
        end,
        function(_, t, a, _, _, _, v)
            clean(v)
            -- The ink pad meets the tray at the default stroke; extra strength
            -- is expressed by body recoil, not by penetrating the paper tray.
            v.y = math.min(a, 1)
                * (
                    0.16 * P(t, 0, 0.13, 0.23)
                    - 0.43 * P(t, 0.18, 0.27, 0.48)
                    + 0.07 * P(t, 0.48, 0.62, 0.86)
                )
            return v
        end
    )

    add(
        "spring_coil",
        1.02,
        "wave-spring-launch",
        "Loads into the socket, launches the complete spring frame, and absorbs the landing in a second bounce.",
        function(t, a)
            local v = C.body()
            v.y = a
                * (
                    -0.045 * P(t, 0, 0.12, 0.23)
                    + 0.18 * P(t, 0.18, 0.38, 0.69)
                    + 0.055 * P(t, 0.67, 0.77, 0.94)
                )
            v.rx = a * 0.13 * R(t, 0.22, 0.95, 1)
            v.scale = 1 + a * (-0.045 * P(t, 0, 0.12, 0.22) + 0.20 * P(t, 0.18, 0.32, 0.76))
            return v
        end,
        function(_, _, _, _, _, _, v)
            -- Preserve the renderer's proven axial-only spring/cap/guide relationship.
            return v
        end
    )

    add(
        "pulse_cell",
        1.08,
        "dew-charge-release",
        "Charges bottom to top, swells under pressure, and releases a short forward kick.",
        function(t, a)
            local v = C.body()
            v.z = a * (-0.045 * P(t, 0, 0.17, 0.32) + 0.10 * P(t, 0.38, 0.49, 0.80))
            v.y = a * 0.12 * P(t, 0.26, 0.47, 0.86)
            v.rx = a * 0.16 * R(t, 0.32, 0.94, 1)
            v.scale = 1 + a * (0.13 * P(t, 0.05, 0.25, 0.42) + 0.23 * P(t, 0.31, 0.45, 0.87))
            return v
        end,
        function(_, t, a, _, y, _, v)
            clean(v)
            local delay = math.clamp((y + 1) * 0.075, 0, 0.15)
            v.scale = 1 + a * 0.24 * P(t, 0.10 + delay, 0.29 + delay, 0.69 + delay)
            v.z = a * 0.11 * P(t, 0.31, 0.46, 0.85)
            v.glow = 0.65 * P(t, 0.1 + delay, 0.29 + delay, 0.75 + delay)
            return v
        end
    )

    add(
        "compass",
        1.30,
        "compass-north-flourish",
        "Tosses into a full yaw turn as the needle searches, then confidently points home.",
        function(t, a)
            local v = C.body()
            v.rz = a * -0.18 * P(t, 0, 0.15, 0.31)
            v.ry = spin(t, a, 0.18, 0.79, -1)
            v.rx = a * 0.17 * P(t, 0.68, 0.79, 0.95)
            v.y = a * 0.17 * P(t, 0.14, 0.42, 0.9)
            v.scale = 1 + a * 0.19 * P(t, 0.13, 0.36, 0.9)
            return v
        end,
        function(_, t, a, _, _, _, v)
            clean(v)
            v.rz = spin(t, a, 0.10, 0.70, 3) + a * 0.42 * R(t, 0.65, 0.97, 1)
            return v
        end
    )

    add(
        "seed_bank",
        1.20,
        "seedbank-greenhouse-pop",
        "Builds pressure beneath its canopy, bounces into a rooted sprout bloom, then gently settles.",
        function(t, a)
            local v = C.body()
            v.y = a
                * (
                    -0.035 * P(t, 0, 0.14, 0.25)
                    + 0.15 * P(t, 0.20, 0.39, 0.77)
                    + 0.04 * P(t, 0.72, 0.81, 0.95)
                )
            v.ry = a * 0.16 * R(t, 0.20, 0.96, 1)
            v.scale = 1 + a * (-0.035 * P(t, 0, 0.14, 0.24) + 0.21 * P(t, 0.19, 0.36, 0.89))
            return v
        end,
        function(group, t, a, x, _, _, v)
            clean(v)
            if group == "Lid" then
                v.y = a * 0.29 * P(t, 0.13, 0.31, 0.83)
            else
                local delay = math.clamp((x + 0.7) * 0.08, 0, 0.11)
                -- Root-relative scaling keeps the stem seated; no detached upward translation.
                v.scale = 1 + a * 0.22 * P(t, 0.18 + delay, 0.39 + delay, 0.84 + delay)
            end
            return v
        end
    )

    add(
        "encore",
        1.16,
        "ocean-chorus-call-response",
        "Takes a breath, blasts forward, then answers with a smaller paired horn bounce.",
        function(t, a)
            local v = C.body()
            v.z = a
                * (
                    -0.055 * P(t, 0, 0.15, 0.27)
                    + 0.12 * P(t, 0.20, 0.31, 0.53)
                    + 0.07 * P(t, 0.51, 0.63, 0.87)
                )
            v.rx = a * (-0.16 * P(t, 0.02, 0.15, 0.29) + 0.19 * P(t, 0.22, 0.35, 0.67))
            v.y = a * 0.10 * P(t, 0.22, 0.40, 0.86)
            v.scale = 1 + a * (0.21 * P(t, 0.18, 0.30, 0.54) + 0.13 * P(t, 0.51, 0.64, 0.90))
            return v
        end,
        function(_, t, a, x, _, _, v)
            clean(v)
            local delay = if x < 0 then 0 else 0.07
            v.z = a
                * (
                    0.25 * P(t, 0.17 + delay, 0.29 + delay, 0.47 + delay)
                    + 0.15 * P(t, 0.50 + delay, 0.62 + delay, 0.86 + delay)
                )
            return v
        end
    )

    add(
        "reserve_pack",
        1.13,
        "reserve-jackpot-juggle",
        "Dips like a loaded basket, then tosses its reserve balls in a staggered juggling burst.",
        function(t, a)
            local v = C.body()
            v.y = a * (-0.045 * P(t, 0, 0.13, 0.24) + 0.13 * P(t, 0.19, 0.36, 0.79))
            v.rz = a * 0.18 * R(t, 0.16, 0.95, 1.5)
            v.rx = a * -0.12 * P(t, 0.20, 0.38, 0.85)
            v.scale = 1 + a * 0.19 * P(t, 0.17, 0.32, 0.84)
            return v
        end,
        function(_, t, a, x, _, z, v)
            clean(v)
            local delay = math.clamp((x + 0.8) * 0.08 + math.max(0, z) * 0.04, 0, 0.16)
            v.y = a * 0.53 * P(t, 0.12 + delay, 0.37 + delay, 0.79 + delay)
            v.ry = spin(t, a, 0.16 + delay, 0.82 + delay, 1)
            return v
        end
    )

    add(
        "coin_press",
        1.65,
        "mint-crank-contact-squash",
        "Turns its top crank, presses the coin flat against the anvil, then releases the die as the coin springs back to its minted shape.",
        function(t, a)
            local v = C.body()
            v.ry = a * -0.22 * P(t, 0, 0.17, 0.38)
            v.y = a * (-0.055 * P(t, 0.29, 0.40, 0.51) + 0.13 * P(t, 0.48, 0.64, 0.93))
            v.rx = a * 0.11 * R(t, 0.40, 0.97, 1)
            v.scale = 1 + a * 0.19 * P(t, 0.34, 0.46, 0.89)
            return v
        end,
        function(group, t, a, _, _, _, v)
            clean(v)
            -- Contact geometry caps the stroke even at 2x strength; stronger
            -- triggers add body recoil, never drive the die through the anvil.
            local stroke = (C.phase(t, 0.12, 0.40) - C.phase(t, 0.48, 0.74)) * math.min(a, 1)
            v.press = stroke
            if group == "PressScrew" then
                v.y = -0.4299 * stroke
                v.ry = spin(t, a, 0.12, 0.74, 2)
            elseif group == "Crank" then
                v.ry = spin(t, a, 0.12, 0.74, 2)
            elseif group == "MintCoin" then
                v.axial = 1 - math.max(0, 0.4299 * stroke - 0.33) / 0.135
            end
            return v
        end
    )

    add(
        "tuning_oil",
        1.32,
        "oil-flair-pour",
        "Flips like a bartender's can, pauses into a clear pouring tilt, then snaps upright.",
        function(t, a)
            local v = C.body()
            v.rz = spin(t, a, 0.11, 0.60, -1) + a * 0.38 * P(t, 0.55, 0.70, 0.94)
            v.y = a * 0.17 * P(t, 0.10, 0.32, 0.76)
            v.x = a * 0.075 * P(t, 0.55, 0.72, 0.95)
            v.scale = 1 + a * 0.18 * P(t, 0.13, 0.33, 0.91)
            return v
        end,
        function(group, t, a, _, _, _, v)
            clean(v)
            if group == "Drop" then
                v.y = -a * 0.54 * P(t, 0.57, 0.77, 0.96)
                v.x = a * 0.14 * P(t, 0.56, 0.72, 0.95)
                v.scale = 1 - a * 0.20 * P(t, 0.61, 0.79, 0.97)
            else
                v.rz = -a * 0.12 * P(t, 0.53, 0.68, 0.94)
            end
            return v
        end
    )

    add(
        "coin",
        1.10,
        "coin-double-flip-catch",
        "Dips edge-first, tosses through two clean face turns, then lands with a small reward bounce.",
        function(t, a)
            local v = C.body()
            v.ry = spin(t, a, 0.13, 0.77, 2)
            v.rz = a * -0.19 * P(t, 0, 0.13, 0.31)
            v.y = a * (0.20 * P(t, 0.11, 0.38, 0.80) + 0.045 * P(t, 0.78, 0.86, 0.97))
            v.scale = 1 + a * 0.24 * P(t, 0.14, 0.34, 0.90)
            return v
        end,
        function(_, _, _, _, _, _, v)
            return clean(v)
        end
    )

    add(
        "restock",
        1.08,
        "restock-turbine-spool",
        "Spools up its refill arrows, expands into a generous reward pop, then brakes with a small rock.",
        function(t, a)
            local v = C.body()
            v.rz = a * (-0.20 * P(t, 0, 0.15, 0.31) + 0.13 * R(t, 0.61, 0.97, 1))
            v.y = a * 0.14 * P(t, 0.17, 0.39, 0.88)
            v.rx = a * 0.15 * P(t, 0.23, 0.42, 0.87)
            v.scale = 1 + a * 0.24 * P(t, 0.16, 0.35, 0.91)
            return v
        end,
        function(_, t, a, _, _, _, v)
            clean(v)
            v.rz = spin(t, a, 0.10, 0.88, 2)
            return v
        end
    )

    add(
        "life",
        0.98,
        "ball-superbounce",
        "Loads a squash, springs high, and returns through a smaller second bounce.",
        function(t, a)
            local v = C.body()
            v.y = a
                * (
                    -0.05 * P(t, 0, 0.12, 0.21)
                    + 0.20 * P(t, 0.17, 0.34, 0.65)
                    + 0.075 * P(t, 0.63, 0.76, 0.95)
                )
            v.x = a * 0.04 * R(t, 0.18, 0.97, 1)
            v.scale = 1
                + a
                    * (-0.06 * P(t, 0, 0.12, 0.21) + 0.23 * P(t, 0.18, 0.30, 0.61) + 0.08 * P(
                        t,
                        0.65,
                        0.77,
                        0.95
                    ))
            return v
        end,
        function(_, _, _, _, _, _, v)
            return clean(v)
        end
    )

    add(
        "score",
        1.03,
        "score-staircase-surge",
        "Leans into an ascending score wave, sends each column upward, then lands on the final beat.",
        function(t, a)
            local v = C.body()
            v.rz = a * (-0.17 * P(t, 0, 0.14, 0.30) + 0.13 * P(t, 0.24, 0.43, 0.82))
            v.y = a * 0.16 * P(t, 0.16, 0.38, 0.86)
            v.scale = 1 + a * 0.22 * P(t, 0.18, 0.37, 0.89)
            return v
        end,
        function(_, t, a, x, _, _, v)
            clean(v)
            local delay = math.clamp((x + 0.6) * 0.14, 0, 0.17)
            v.y = a * 0.31 * P(t, 0.1 + delay, 0.31 + delay, 0.77 + delay)
            v.scale = 1 + a * 0.12 * P(t, 0.10 + delay, 0.31 + delay, 0.77 + delay)
            return v
        end
    )

    add(
        "lock",
        1.16,
        "lock-click-flourish",
        "Braces, opens the shackle with a clear swing, then snaps shut in a satisfying body hop.",
        function(t, a)
            local v = C.body()
            v.ry = a * (-0.24 * P(t, 0, 0.16, 0.33) + 0.31 * P(t, 0.24, 0.43, 0.80))
            v.y = a * (0.10 * P(t, 0.18, 0.36, 0.69) + 0.065 * P(t, 0.67, 0.77, 0.94))
            v.rz = a * 0.10 * R(t, 0.55, 0.96, 1)
            v.scale = 1 + a * 0.18 * P(t, 0.16, 0.33, 0.89)
            return v
        end,
        function(_, t, a, _, _, _, v)
            clean(v)
            v.y = a * 0.24 * P(t, 0.11, 0.26, 0.76)
            v.ry = a * 0.66 * P(t, 0.23, 0.42, 0.81)
            return v
        end
    )

    add(
        "jumble",
        1.26,
        "shuffle-orbital-mix",
        "Winds backward, rolls its whole frame, and sends the three pegs through a small orbital mix.",
        function(t, a)
            local v = C.body()
            v.rz = spin(t, a, 0.17, 0.84, 1) - a * 0.17 * P(t, 0, 0.15, 0.32)
            v.x = a * 0.09 * R(t, 0.18, 0.94, 1)
            v.y = a * 0.15 * P(t, 0.13, 0.40, 0.90)
            v.scale = 1 + a * 0.20 * P(t, 0.14, 0.36, 0.91)
            return v
        end,
        function(_, t, a, x, y, _, v)
            clean(v)
            local wave = a * 0.52 * R(t, 0.15, 0.94, 1)
            v.x = -y * wave
            v.y = x * wave
            v.scale = 1 + a * 0.12 * P(t, 0.20, 0.44, 0.88)
            return v
        end
    )

    return entries
end
