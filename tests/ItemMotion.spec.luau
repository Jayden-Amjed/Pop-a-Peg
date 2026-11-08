local Motion = if script
    then require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.ItemMotion)
    else require("../src/client/ItemMotion")

local function samePose(a, b, tolerance)
    for key, value in pairs(a) do
        assert(math.abs(value - b[key]) <= tolerance, "Hover pose changed at " .. key)
    end
end

return function()
    local signatures, count, wholeTurns = {}, 0, 0
    for id, profile in Motion.Profiles do
        count += 1
        assert(
            profile.duration >= 0.65 and profile.duration <= (if profile.chest then 4.5 else 2.5),
            "Unreadable performance timing: " .. id
        )
        assert(#profile.description > 20, "Missing choreography rationale: " .. id)
        local signature, growth, travel, turn = {}, 1, 0, 0
        for index = 0, 100 do
            local phase = index / 100
            local normal = Motion.bodySample(id, phase, 1)
            growth = math.max(growth, normal.scale)
            travel = math.max(travel, math.abs(normal.x) + math.abs(normal.y) + math.abs(normal.z))
            turn = math.max(turn, math.abs(normal.rx), math.abs(normal.ry), math.abs(normal.rz))
            if index % 10 == 0 then
                for _, key in { "x", "y", "z", "rx", "ry", "rz", "scale" } do
                    table.insert(signature, string.format("%.3f", normal[key]))
                end
            end
            for _, strength in { 0, 0.25, 1, 2 } do
                local body = Motion.bodySample(id, phase, strength)
                for _, value in body do
                    assert(
                        value == value and math.abs(value) < 30,
                        "Invalid whole-model motion: " .. id
                    )
                end
                assert(
                    body.scale >= 0.65 and body.scale <= 1.65,
                    "Whole-model size escaped framing: " .. id
                )
                if strength == 0 then
                    samePose(body, Motion.bodySample(id, 0, 1), 0)
                end
            end
        end
        assert(
            growth >= 1.07 and travel >= 0.035,
            "Trigger still lacks a visible body reaction: " .. id
        )
        if turn >= math.pi * 1.9 then
            wholeTurns += 1
        end
        local key = table.concat(signature, ",")
        assert(
            not signatures[key],
            "Duplicated whole-model choreography: " .. id .. "/" .. tostring(signatures[key])
        )
        signatures[key] = id
        for _, strength in { 0.25, 1, 2 } do
            for _, phase in { 0.000001, 0.999999 } do
                local body = Motion.bodySample(id, phase, strength)
                assert(math.abs(body.scale - 1) < 0.000001, "Scale snaps at idle: " .. id)
                assert(
                    math.abs(body.x) + math.abs(body.y) + math.abs(body.z) < 0.000001,
                    "Body snaps at idle: " .. id
                )
                for _, axis in { "rx", "ry", "rz" } do
                    assert(
                        math.abs(math.sin(body[axis])) < 0.000001
                            and math.cos(body[axis]) > 0.999999,
                        "Completed spin changes heading at fractional strength: " .. id
                    )
                end
            end
        end
    end
    assert(count == 78 and wholeTurns >= 6, "Incomplete individual performance/spin coverage")
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
                    for key, value in pairs(pose) do
                        assert(
                            value == value
                                and math.abs(value)
                                    < (if key:sub(1, 1) == "r" then math.pi * 20 else 10),
                            "Nonfinite or excessive evolution motion: " .. id
                        )
                    end
                    assert(
                        pose.scale >= 0.65 and pose.scale <= 2,
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
    local unlockModels, chestModels, eventModels = 0, 0, 0
    for id, profile in pairs(Motion.Profiles) do
        if not profile.groups then
            continue
        end
        if profile.chest then
            chestModels += 1
        elseif id:sub(1, 6) == "event_" then
            eventModels += 1
        else
            unlockModels += 1
        end
        for _, group in profile.groups do
            local moved = false
            local neutralPose = Motion.sample(id, group, 0, 1, 0.5, 0.6, 0.4)
            samePose(neutralPose, Motion.sample(id, group, 1, 1, 0.5, 0.6, 0.4), 0)
            for index = 0, 100 do
                local pose = Motion.sample(id, group, index / 100, 2, 0.5, 0.6, 0.4)
                for key, value in pairs(pose) do
                    assert(
                        value == value
                            and math.abs(value)
                                < (if key:sub(1, 1) == "r" then math.pi * 20 else 10),
                        "Unbounded new motion: " .. id
                    )
                    moved = moved or math.abs(value - neutralPose[key]) > 0.00001
                end
                assert(
                    pose.scale >= (if group == "RainDrop" then 0.4 else 0.65) and pose.scale <= 2,
                    "New model exceeded scale envelope: " .. id .. "/" .. group
                )
            end
            -- These connected structures intentionally share the whole-object
            -- action; an independent bend would split the wand/kite/container.
            local bodyOnly = {
                ["bubble_wand/WandStem"] = true,
                ["bubble_wand/WandLoop"] = true,
                ["bubble_wand/WandBubble"] = true,
                ["ozone_orb/OzoneShell"] = true,
                ["aurora_kite/KiteSail"] = true,
                ["aurora_kite/KiteSpar"] = true,
                ["lily_pad/LilyPad"] = true,
                ["biolume_jar/LumeStem"] = true,
            }
            assert(
                moved or bodyOnly[id .. "/" .. group],
                "Named motion group has no animation: " .. id .. "/" .. group
            )
            local endPose = Motion.sample(id, group, 0.999999, 1, 0.5, 0.6, 0.4)
            for _, axis in { "rx", "ry", "rz" } do
                assert(math.abs(math.sin(endPose[axis])) < 0.0001, "Motion snaps at rest: " .. id)
            end
        end
        if profile.chest then
            assert(profile.duration >= 3.4, "Chest anticipation was shortened")
            for index = 0, 52 do
                local closed = Motion.sample(id, "ChestLid", index / 100, 1, 0, 0, 0)
                assert(closed.rx == 0, "Chest opens before its long pressure build finishes")
            end
            local opening = Motion.sample(id, "ChestLid", 0.60, 1, 0, 0, 0)
            local holding = Motion.sample(id, "ChestLid", 0.87, 1, 0, 0, 0)
            assert(opening.rx < -math.pi / 2, "Chest must visibly open past upright")
            assert(opening.rx == holding.rx, "Chest must hold open for its reveal")
            for index = 0, 100 do
                local sampleTime = index / 100
                local treasure = Motion.sample(id, "ChestTreasure", sampleTime, 2, 0, 0, 0)
                if treasure.y > 0 then
                    local opened = Motion.sample(id, "ChestLid", sampleTime, 2, 0, 0, 0)
                    assert(opened.rx == opening.rx, "Treasure crosses a closing or closed lid")
                end
            end
        end
    end
    -- Review corrections: the wand's attached bubbles no longer spit outward;
    -- the capsule's complete cap clears its shoulder and comes back to its seat.
    for index = 0, 100 do
        local sampleTime = index / 100
        for _, group in { "WandStem", "WandLoop", "WandBubble" } do
            samePose(
                Motion.sample("bubble_wand", group, sampleTime, 2, 0, 1, 0),
                Motion.sample("bubble_wand", group, 0, 2, 0, 1, 0),
                0
            )
        end
        local cap = Motion.sample("burst_capsule", "BurstCap", sampleTime, 2, 0, 1.765, 0)
        assert(cap.y >= 0, "Capsule cap sinks through its seat")
        if sampleTime >= 0.76 then
            samePose(cap, Motion.sample("burst_capsule", "BurstCap", 0, 2, 0, 1.765, 0), 0.000001)
        end
    end
    assert(
        math.abs(Motion.bodySample("bubble_wand", 0.62, 1).ry) > math.pi * 1.99,
        "Wand must complete its long-axis twirl"
    )
    assert(
        Motion.sample("burst_capsule", "BurstCap", 0.4, 1, 0, 1.765, 0).y > 1,
        "Cap does not visibly lift off"
    )
    assert(
        unlockModels == 18 and chestModels == 4 and eventModels == 4,
        "New motion coverage incomplete"
    )
    print(
        "PASS item motion: figure eight, frozen activation, smooth handoff, 13 evolutions, 18 unlock devices, 4 opening chests and 4 event emblems"
    )
end
