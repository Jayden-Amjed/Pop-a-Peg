-- Run after ItemMotion.tag, before centering the native model. This assigns
-- animation metadata only: no shape, size, color or resting transform changes.
-- A shared group AND pivot lets ItemMotion sample one phase for connected pieces.
return function(model, id)
    local V = Vector3.new
    local function assign(part, group, pivot)
        part:SetAttribute("MotionGroup", group)
        part:SetAttribute("MotionPivot", pivot)
    end
    local function nearest(value, choices)
        local result, distance = choices[1], math.huge
        for _, candidate in choices do
            local delta = math.abs(value - candidate)
            if delta < distance then
                result, distance = candidate, delta
            end
        end
        return result
    end
    for _, part in model:GetChildren() do
        if not part:IsA("BasePart") then
            continue
        end
        local group = part:GetAttribute("MotionGroup")
        local p, size = part.Position, part.Size
        if id == "survey_lens" and group == "Lens" then
            -- Lens, barrel, bezel, bolts and focus gear form one rigid telescope.
            -- Their differing authored Z must not create differing focus offsets.
            assign(part, "Lens", V(0, 0.62, 0.12))
        elseif id == "growth_array" and group == "Coral" then
            -- Each plant has its own phase, but all its branches and end caps
            -- scale/rotate from the same planted stem endpoint.
            assign(part, "Coral", V(nearest(p.X, { -0.78, -0.26, 0.26, 0.78 }), -0.54, 0))
        elseif id == "landing_fund" then
            -- The old height classifier left the lower half of the coin fixed.
            -- This spatial region is exactly the coin() call, not the side pearls.
            if math.abs(p.X) <= 0.45 and math.abs(p.Y - 0.05) <= 0.45 and p.Z >= 0.39 then
                assign(part, "CatchCoin", V(0, 0.05, 0.4))
            elseif group == "CatchCoin" then
                -- Do not make a decorative side pearl part of the spinning coin.
                assign(part, "Fixed", p)
            end
        elseif id == "reserve_pack" and group == "ReserveBall" then
            -- A ball's highlight and front disc follow its toss and full turn.
            -- Keep the three balls independent so their juggling remains staggered.
            assign(part, "ReserveBall", V(nearest(p.X, { -0.65, 0, 0.65 }), -0.08, 0))
        elseif id == "burst_capsule" and group == "Pin" then
            -- The pull-ring is many rods; rotating each around itself breaks it.
            assign(part, "Pin", V(0, 1.1, 0))
        elseif id == "relay" then
            if group == "Winding" then
                assign(part, "Winding", V(0, -0.08, 0))
            elseif group == "Contact" then
                assign(part, "Contact", V(0, 0.5, 0.4))
            end
        elseif id == "seed_bank" then
            local x = nearest(p.X, { -0.53, 0, 0.53 })
            if math.abs(p.X - x) < 0.001 and p.Y > 0 and p.Y < 0.6 and math.abs(p.Z) <= 0.21 then
                -- Include the thin stem with its seed. The seed's authored lower
                -- edge is Y = .22 - .87/2; scaling here keeps that edge seated.
                assign(part, "Seed", V(x, -0.215, 0))
            elseif group == "Seed" then
                -- Plinth feet are also Ball-shaped and were caught as seeds.
                assign(part, "Fixed", p)
            elseif group == "Lid" then
                assign(part, "Lid", V(0, 1, 0))
            end
        elseif id == "coin_press" then
            if math.abs(p.X + 0.41) <= 0.31 and math.abs(p.Y + 0.49) <= 0.31 and p.Z >= 0.57 then
                -- Face, rim, twelve ticks and symbol belong to the single front
                -- coin. The independent stack at X=.53 keeps separate pivots.
                assign(part, "MintCoin", V(-0.41, -0.49, 0.58))
            elseif math.abs(p.Y - 1.01) < 0.001 and size.X > 1.7 then
                -- The centered crosshead supports the screw; it must not turn
                -- with it merely because the old classifier matched abs(X)<.22.
                assign(part, "Fixed", p)
            elseif
                group == "PressScrew" or (math.abs(p.X - 0.55) < 0.001 and p.Y > 1.3 and p.Z < 0)
            then
                -- Attach the end knob that the old abs(X)<.22 classifier missed.
                assign(part, "PressScrew", V(0, 0.3, -0.25))
            end
        elseif id == "tuning_oil" then
            if group == "Spout" then
                -- All three joined segments hinge at the can outlet together.
                assign(part, "Spout", V(0.3, -0.09, 0))
            elseif group == "Drop" then
                -- Droplet sphere and pointed cap shrink about a common center.
                assign(part, "Drop", V(1.53, 0.64, 0))
            end
        elseif id == "score" and group == "ScoreBar" then
            -- Cap and tick marks grow with their column, not around independent
            -- centers. Other columns retain their own ascending-wave phase.
            assign(part, "ScoreBar", V(nearest(p.X, { -0.63, 0, 0.63 }), -0.71, 0))
        elseif id == "jumble" then
            local x = nearest(p.X, { -0.7, 0, 0.7 })
            local y = if x == 0 then 0.45 else -0.37
            if math.abs(p.X - x) < 0.001 and math.abs(p.Y - y) < 0.001 and p.Z < 0.27 then
                -- Peg face bolts were Fixed while their two discs orbited away.
                assign(part, "ShufflePeg", V(x, y, 0))
            end
        elseif id == "resonator" and group == "Chime" then
            if p.Y < 0 or p.Z < -0.1 then
                -- The fork bridge and upgrade strut are structural, not chimes.
                assign(part, "Fixed", p)
            else
                assign(part, "Chime", V(0, 0.9, 0))
            end
        elseif id == "encore" and group == "Horn" then
            assign(part, "Horn", V(if p.X < 0 then -0.65 else 0.65, 0.57, -0.15))
        elseif id == "lock" and group == "Shackle" then
            assign(part, "Shackle", V(-0.55, 0.15, 0))
        elseif id == "tap_driver" and group == "Piston" then
            assign(part, "Piston", V(0.78, 0.45, 0))
        elseif id == "wall_meter" and group == "Bumper" then
            assign(part, "Bumper", V(-0.88, 0, 0))
        elseif id == "balance_scale" and group == "Pan" then
            -- Preserve left/right independence while carrying each pan's pearl,
            -- dish layers and suspension rods as one assembly.
            assign(part, "Pan", V(if p.X < 0 then -1.02 else 1.02, -0.38, 0))
        elseif id == "quota_bonus" and group == "Stamp" then
            assign(part, "Stamp", V(0.3, 0.3, 0))
        elseif id == "echo_plate" and group == "ShellRibs" then
            assign(part, "ShellRibs", V(0, 0.05, 0))
        end
    end
end
