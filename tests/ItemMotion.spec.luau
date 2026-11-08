local Motion = if script
    then require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ItemMotion)
    else require("../src/client/ItemMotion")

local function samePose(a, b, tolerance)
    for key, value in pairs(a) do
        assert(math.abs(value - b[key]) <= tolerance, "Hover pose changed at " .. key)
    end
end

return function()
    local quarterSigns = { { -1, 1 }, { 1, -1 }, { -1, -1 }, { 1, 1 } }
    for index, signs in ipairs(quarterSigns) do
        local pose = Motion.idleSample((index - 1) * math.pi / 2)
        assert(
            pose.x * signs[1] > 0 and pose.y * signs[2] > 0,
            "Figure eight quadrant order changed"
        )
    end
    samePose(Motion.idleSample(0), Motion.idleSample(math.pi * 2), 0.000000000001)
    for index = 0, 512 do
        local pose = Motion.idleSample(index * math.pi * 2 / 512)
        for _, value in pairs(pose) do
            assert(value == value and math.abs(value) < math.huge, "Nonfinite idle pose")
        end
        assert(
            math.abs(pose.x) <= Motion.Idle.lateral + 0.000000001,
            "Horizontal hover exceeded bound"
        )
        assert(
            math.abs(pose.y) <= Motion.Idle.vertical + 0.000000001,
            "Vertical hover exceeded bound"
        )
        assert(math.abs(pose.pitch) <= math.rad(5.001), "Idle pitch turned too far")
        assert(math.abs(pose.yaw) <= math.rad(6.001), "Idle yaw turned too far")
        assert(math.abs(pose.roll) <= math.rad(2.001), "Idle roll turned too far")
        assert(math.cos(pose.pitch) * math.cos(pose.yaw) > 0.98, "Idle turned model away")
    end

    local continuous = Motion.newHover(true)
    assert(Motion.Idle.period == 4.2, "Idle loop must complete twice as fast as the original")
    for _ = 1, 42 do
        Motion.stepHover(continuous, 0.1, false)
    end
    samePose(Motion.idleSample(continuous.phase), Motion.idleSample(0), 0.000000000001)

    local hover = Motion.newHover(true, 0.73)
    for _ = 1, 15 do
        Motion.stepHover(hover, 1 / 60, false)
    end
    local phase = hover.phase
    local frozen = Motion.idleSample(phase)
    -- A current activation and its coalesced follow-up keep the same pause.
    for _ = 1, 120 do
        samePose(Motion.stepHover(hover, 1 / 60, true), frozen, 0)
        assert(hover.phase == phase and hover.handoffs == 0, "Activation advanced idle phase")
    end
    samePose(Motion.stepHover(hover, 1 / 60, false), frozen, 0)
    assert(
        hover.handoffs == 1 and hover.resume == 0,
        "Idle must resume exactly once at frozen pose"
    )
    Motion.stepHover(hover, 1 / 60, false)
    local normalStep = math.pi * 2 / (Motion.Idle.period * 60)
    assert(
        hover.phase > phase and hover.phase - phase < normalStep * 0.02,
        "Idle resumed at full speed"
    )
    for _ = 1, 180 do
        Motion.stepHover(hover, 1 / 60, false)
    end
    assert(
        hover.resume == 1 and hover.handoffs == 1 and not hover.paused,
        "Idle kept requeuing handoffs"
    )

    local disabled = Motion.newHover(false)
    local neutral = { x = 0, y = 0, pitch = 0, yaw = 0, roll = 0 }
    for _, active in ipairs({ false, true, true, false }) do
        samePose(Motion.stepHover(disabled, 1, active), neutral, 0)
    end
    assert(disabled.phase == 0 and disabled.handoffs == 0, "Static or reduced-motion preview moved")
    Motion.stepHover(hover, 0 / 0, false)
    Motion.stepHover(hover, math.huge, false)
    Motion.stepHover(hover, -1, false)
    assert(hover.phase == hover.phase and hover.resume <= 1, "Invalid frame time corrupted hover")
    local evolved, uniqueNames = 0, {}
    local groups = {
        "EvolvedOrbit",
        "EvolvedRotor",
        "EvolvedGyro",
        "EvolvedFastHand",
        "EvolvedSlowHand",
        "EvolvedSpring",
        "EvolvedWeight",
        "EvolvedCrystal",
        "EvolvedSprout",
        "EvolvedLens",
        "EvolvedNeedle",
        "EvolvedBalance",
        "EvolvedHorn",
        "EvolvedShell",
        "EvolvedPiston",
        "EvolvedCoin",
        "FishBody",
        "FishFin",
        "FishTail",
        "Bubbles",
        "Reeds",
        "EvolvedFork",
        "EvolvedCore",
    }
    for id, profile in pairs(Motion.Profiles) do
        assert(not uniqueNames[profile.name], "Duplicate motion identity: " .. id)
        uniqueNames[profile.name] = true
        if profile.evolved then
            evolved += 1
            for _, group in ipairs(groups) do
                samePose(
                    Motion.sample(id, group, 0, 2, 1, 1, 1),
                    Motion.sample(id, group, 1, 2, 1, 1, 1),
                    0
                )
                for index = 0, 80 do
                    local pose = Motion.sample(id, group, index / 80, 2, 1, 1, 1)
                    for _, value in pairs(pose) do
                        assert(
                            value == value and math.abs(value) < 50,
                            "Nonfinite or excessive evolution motion: " .. id
                        )
                    end
                    assert(
                        pose.scale >= 0.8 and pose.scale <= 1.4,
                        "Evolution scale escaped model envelope"
                    )
                end
                local nearRest = Motion.sample(id, group, 0.999999, 1, 1, 1, 1)
                for _, axis in ipairs({ "rx", "ry", "rz" }) do
                    assert(
                        math.abs(math.sin(nearRest[axis])) < 0.0001
                            and math.cos(nearRest[axis]) > 0.9999,
                        "Evolution rotor snaps at the end: " .. id
                    )
                end
            end
        end
    end
    assert(evolved == 13, "Expected thirteen distinct evolution motion profiles")
    print(
        "PASS item motion: figure eight, frozen activation, smooth handoff, static opt-out and thirteen bounded evolution profiles"
    )
end
