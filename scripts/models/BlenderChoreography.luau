-- Blender motion. The accepted native ItemMotion is a read-only fallback.
local Native = if script
    then require(script.Parent.ItemMotion)
    else require("../../src/client/ItemMotion")
local C = if script
    then require(script.Parent.motion.Curves)
    else require("../../src/client/motion/Curves")
local Blender = { Profiles = table.clone(Native.Profiles) }
local overrides = {
    coral_fork = { duration = 1.25, name = "coral-spark-conductive-strike" },
    dew_lantern = { duration = 1.60, name = "dew-lantern-warm-switch-on" },
    encore = { duration = 1.55, name = "ocean-chorus-cone-echo" },
    lagoon_synth = { duration = 1.80, name = "lagoon-synth-travelling-phase" },
    landing_fund = { duration = 1.45, name = "landing-shell-pearl-polish" },
    lily_pad = { duration = 1.60, name = "lily-pad-front-bloom" },
    mist_fan = { duration = 1.45, name = "breeze-fan-paper-gust" },
    ozone_orb = { duration = 1.65, name = "ozone-orb-free-charge" },
    pearl_diver = { duration = 1.80, name = "pearl-diver-hex-orbits" },
    relay = { duration = 1.60, name = "current-relay-fixed-coil-surge" },
    soft_saw = { duration = 1.60, name = "soft-current-free-water-roll" },
}
for id, profile in overrides do
    Blender.Profiles[id] = table.freeze(profile)
end
Blender.Profiles = table.freeze(Blender.Profiles)
local function state()
    return { x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, scale = 1, glow = 0, axial = 1, lamp = 0 }
end

function Blender.bodySample(id, t, strength)
    if type(t) ~= "number" or not (t >= -math.huge and t <= math.huge) then
        t = 0
    end
    if type(strength) ~= "number" or not (strength >= -math.huge and strength <= math.huge) then
        strength = 1
    end
    if not overrides[id] then
        return Native.bodySample(id, t, strength)
    end
    local v = C.body()
    if t <= 0 or t >= 1 or strength <= 0 then
        return v
    end
    local a = math.min(strength, 1.5)
    local bloom = C.pulse(t, 0.13, 0.40, 0.92) * a
    if id == "relay" then
        -- Charge compresses the whole assembled device, then the discharge pops
        -- it outward. Mount and winding share this reaction; only the winding
        -- spins in the device's local frame, so its seated supports stay intact.
        local charge = C.pulse(t, 0.02, 0.13, 0.24) * a
        local discharge = C.pulse(t, 0.15, 0.27, 0.47) * a
        local rebound = C.pulse(t, 0.42, 0.55, 0.75) * a
        local settle = C.ring(t, 0.50, 0.98, 2) * a
        v.scale = 1 - charge * 0.12 + discharge * 0.27 + rebound * 0.08 + settle * 0.02
        v.y = -charge * 0.025 + discharge * 0.085 + rebound * 0.025
        v.z, v.rx = -discharge * 0.025, -charge * 0.04 + discharge * 0.065 + settle * 0.025
    elseif id == "lagoon_synth" then
        -- A short downbeat grows into a two-beat musical pop, then a small tail.
        -- The cabinet/display move coherently; key travel and the sine phase
        -- remain local to their actual keys and screen throughout the bounce.
        local downbeat = C.pulse(t, 0.02, 0.12, 0.23) * a
        local chord = C.pulse(t, 0.15, 0.27, 0.44) * a
        local reply = C.pulse(t, 0.38, 0.50, 0.73) * a
        local tail = C.pulse(t, 0.65, 0.76, 0.98) * a
        v.scale = 1 - downbeat * 0.10 + chord * 0.24 + reply * 0.13 + tail * 0.035
        v.y = -downbeat * 0.025 + chord * 0.095 + reply * 0.045 + tail * 0.012
        v.rx = downbeat * 0.055 - chord * 0.075 + reply * 0.035
        v.rz = C.ring(t, 0.20, 0.96, 1) * a * 0.035
    elseif id == "coral_fork" then
        v.y, v.rz, v.scale = bloom * 0.04, C.ring(t, 0.17, 0.95, 3) * a * 0.045, 1 + bloom * 0.07
    elseif id == "dew_lantern" then
        v.y, v.rz, v.scale = bloom * 0.07, C.ring(t, 0.06, 0.98, 1) * a * 0.10, 1 + bloom * 0.06
    elseif id == "encore" then
        local recoil = (C.pulse(t, 0.18, 0.26, 0.40) + C.pulse(t, 0.36, 0.44, 0.57) * 0.65) * a
        v.z, v.rx, v.scale = -recoil * 0.055, recoil * 0.06, 1 + recoil * 0.09
    elseif id == "landing_fund" then
        v.y, v.rx, v.scale = bloom * 0.09, C.ring(t, 0.10, 0.98, 1) * a * 0.08, 1 + bloom * 0.11
    elseif id == "lily_pad" then
        v.y = -C.pulse(t, 0.02, 0.17, 0.31) * a * 0.04 + bloom * 0.09
        v.rz, v.scale = C.ring(t, 0.24, 0.98, 1) * a * 0.045, 1 + bloom * 0.08
    elseif id == "mist_fan" then
        v.rx, v.scale = bloom * -0.055, 1 + bloom * 0.04
    elseif id == "ozone_orb" then
        v.y, v.scale = bloom * 0.12, 1 - C.pulse(t, 0.04, 0.19, 0.32) * a * 0.07 + bloom * 0.13
    elseif id == "pearl_diver" then
        v.y, v.rz, v.scale = bloom * 0.08, C.ring(t, 0.12, 0.95, 1) * a * 0.06, 1 + bloom * 0.07
    elseif id == "soft_saw" then
        v.x, v.y, v.rz, v.scale =
            C.ring(t, 0.08, 0.97, 1) * a * 0.06,
            bloom * 0.09,
            C.spin(t, 0.12, 0.90, -1),
            1 + bloom * 0.08
    end
    return v
end

function Blender.sample(id, group, t, strength, x, y, z)
    if type(t) ~= "number" or not (t >= -math.huge and t <= math.huge) then
        t = 0
    end
    if type(strength) ~= "number" or not (strength >= -math.huge and strength <= math.huge) then
        strength = 1
    end
    if not overrides[id] then
        -- Preserve the accepted mechanism and add object-specific secondary
        -- action in this gallery layer. Never mutate a native-returned table.
        local value = table.clone(Native.sample(id, group, t, strength, x, y, z))
        if t <= 0 or t >= 1 or strength <= 0 or group == "Fixed" then
            return value
        end
        local force = math.min(strength, 1.5)
        local accent = C.pulse(t, 0.17, 0.38, 0.90) * force
        if id == "quota_bonus" and group == "Stamp" then
            -- Contact is geometric: reducing the expressive strength must not
            -- leave the die hovering above the tray while its impact fires.
            -- The source pad bottom is Y=.89 and printed tray surface Y=.457.
            -- Hold that contact from .25 to .29; body recoil still uses strength.
            local strike = C.phase(t, 0.18, 0.25) - C.phase(t, 0.29, 0.48)
            value.y = 0.16 * C.pulse(t, 0, 0.13, 0.23)
                - 0.433 * strike
                + 0.07 * C.pulse(t, 0.48, 0.62, 0.86)
        elseif id == "survey_lens" and group == "Lens" then
            value.scale *= 1 + accent * 0.06 -- iris visibly focuses
        elseif id == "split_prism" and group == "Prism" then
            value.glow += accent * 0.5
        elseif id == "growth_array" and group == "Coral" then
            value.scale *= 1 + C.pulse(t, 0.12 + (x + 1) * 0.035, 0.42, 0.92) * force * 0.09
        elseif id == "goldfish" and group == "FishFin" then
            value.rz += C.ring(t, 0.18, 0.94, 6) * force * 0.18
        elseif id == "fishbowl" and group == "Reeds" then
            value.rz += C.ring(t, 0.15, 0.95, 2) * force * 0.11
        elseif id == "biolume_jar" and group == "LumeFirefly" then
            value.glow += C.pulse(t, 0.15 + math.abs(x) * 0.1, 0.44, 0.95) * 0.65
        elseif id == "cloud_mirror" and group == "CloudGlint" then
            value.scale *= 1 + accent * 0.28
        elseif id == "echo_plate" and group == "Pearl" then
            value.scale *= 1 + C.ring(t, 0.20, 0.94, 3) * force * 0.09
        elseif id == "nectar_pump" and group == "NectarLiquid" then
            value.y += C.ring(t, 0.20, 0.95, 2) * force * 0.035
        elseif id == "rain_catcher" and group == "RainWater" then
            value.rz += C.ring(t, 0.24, 0.96, 2) * force * 0.06
        elseif id == "pulse_cell" and group == "ChargeBar" then
            value.glow += C.pulse(t, 0.10 + math.abs(x) * 0.12, 0.42, 0.94) * 0.55
        elseif id == "solar_leaf" and group == "SolarVein" then
            value.glow += accent * 0.65
        elseif id == "tide_valve" and group == "ValveFlow" then
            value.scale *= 1 + C.ring(t, 0.25, 0.96, 3) * force * 0.09
        elseif id == "monsoon_loom" and group == "LoomThread" then
            value.rz += C.ring(t, 0.19, 0.93, 4) * force * 0.04
        elseif id == "reserve_pack" and group == "ReserveBall" then
            value.scale *= 1 + C.pulse(t, 0.12 + math.abs(x) * 0.06, 0.36, 0.87) * force * 0.08
        elseif id == "aurora_kite" and group == "KiteRibbon" then
            value.rz += C.ring(t, 0.12, 0.98, 4) * force * 0.12
        end
        return value
    end
    local v = state()
    if t <= 0 or t >= 1 or strength <= 0 or group == "Fixed" then
        return v
    end
    local a = math.min(strength, 1.5)
    local glow = C.pulse(t, 0.15, 0.36, 0.90)
    if id == "relay" then
        if group == "Winding" or group == "WindingX" then
            v.rx = C.spin(t, 0.10, 0.90, 4)
            v.glow = glow * 0.32
        end
    elseif id == "coral_fork" then
        if group == "CoralTine" or group == "CoralTip" then
            v.rz = (x < 0 and -1 or 1) * C.ring(t, 0.16, 0.94, 7) * a * 0.05
            v.glow = glow * 0.6
        elseif group == "CoralCrown" then
            v.ry, v.scale = C.spin(t, 0.20, 0.87, 1), 1 + glow * a * 0.08
        end
    elseif id == "dew_lantern" then
        local light = C.phase(t, 0.14, 0.24) * (1 - C.phase(t, 0.82, 0.98))
        if group == "LanternDrop" or group == "LanternMote" then
            v.lamp, v.glow = light, light
            v.scale = 1 + light * a * (group == "LanternDrop" and 0.14 or 0.30)
        end
    elseif id == "encore" then
        if group == "Horn" or group == "Pan" then
            local delay = x < 0 and 0 or 0.045
            v.z = (
                C.pulse(t, 0.17 + delay, 0.26 + delay, 0.38 + delay) * 0.14
                + C.pulse(t, 0.36 + delay, 0.44 + delay, 0.62 + delay) * 0.09
            ) * a
        end
    elseif id == "lagoon_synth" then
        if group == "SynthKey" then
            local delay = 0.10 + math.clamp(x + 0.52, 0, 1.04) * 0.27
            v.rx = (
                C.pulse(t, delay, delay + 0.09, delay + 0.21)
                + C.pulse(t, delay + 0.36, delay + 0.44, math.min(0.96, delay + 0.56))
            )
                * a
                * 0.14
        end
    elseif id == "landing_fund" then
        if group == "ShellLid" then
            v.rx = -C.pulse(t, 0.11, 0.38, 0.93) * a * 0.28
        elseif group == "CatchCoin" then
            v.y, v.ry = C.pulse(t, 0.23, 0.47, 0.88) * a * 0.35, C.spin(t, 0.24, 0.88, 1)
        end
    elseif id == "lily_pad" then
        if group == "LilyPad" then
            v.rx, v.rz = -glow * a * 0.10, (x < 0 and -1 or 1) * C.ring(t, 0.18, 0.95, 1) * a * 0.05
        elseif group == "LilyPetal" then
            v.rx, v.scale = -glow * a * 0.14, 1 + glow * a * 0.08
        elseif group == "LilyHeart" then
            v.scale, v.glow = 1 + glow * a * 0.15, glow * 0.45
        elseif group == "LilyDew" then
            v.y = C.pulse(t, 0.30, 0.59, 0.95) * a * 0.26
        end
    elseif id == "mist_fan" then
        if group == "PaperRotor" or group == "BreezeBlade" then
            v.rz = C.spin(t, 0.08, 0.94, -4)
        end
    elseif id == "ozone_orb" then
        if group == "OzoneOrbitA" then
            v.ry = C.spin(t, 0.12, 0.92, 2)
        elseif group == "OzoneOrbitB" then
            v.rx = C.spin(t, 0.18, 0.94, -2)
        elseif group == "OzoneShell" then
            v.scale, v.glow = 1 + glow * a * 0.09, glow * 0.33
        end
    elseif id == "pearl_diver" then
        if group == "HexRing" then
            v.rz = C.spin(t, 0.10, 0.92, 1)
        elseif group == "OrbitBlue" then
            v.ry, v.rz = C.spin(t, 0.12, 0.91, 2), C.ring(t, 0.12, 0.91, 1) * 0.35
        elseif group == "OrbitGold" then
            v.rx, v.rz = C.spin(t, 0.19, 0.95, -2), C.ring(t, 0.19, 0.95, 1) * -0.35
        elseif group == "DiverPearl" then
            v.scale, v.glow = 1 + glow * a * 0.17, glow * 0.35
        end
    elseif id == "soft_saw" then
        if group == "Foam" then
            v.y, v.scale = C.pulse(t, 0.25, 0.59, 0.93) * a * 0.16, 1 + glow * a * 0.10
        end
    end
    return v
end
return Blender
