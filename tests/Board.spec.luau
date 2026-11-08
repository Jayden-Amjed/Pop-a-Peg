local Shared = if script then game:GetService("ReplicatedStorage"):WaitForChild("Shared") else nil
local Board = if Shared then require(Shared.Board) else require("../src/shared/Board")
local Simulation = if Shared
    then require(Shared.Simulation)
    else require("../src/shared/Simulation")
local Rng = if Shared then require(Shared.Rng) else require("../src/shared/Rng")
local Format = if Shared then require(Shared.Format) else require("../src/shared/Format")

local function near(actual, expected, message)
    assert(
        math.abs(actual - expected) < 1e-8,
        message or (tostring(actual) .. " ~= " .. tostring(expected))
    )
end

local function filled(value)
    local values = {}
    for id = 1, #Board.Slots do
        values[id] = value
    end
    return values
end

local function counts(values)
    local result = {}
    for _, value in ipairs(values) do
        result[value] = (result[value] or 0) + 1
    end
    return result
end

return function()
    assert(#Board.Slots == 21, "Board must contain exactly 21 usable slots")
    for id, slot in ipairs(Board.Slots) do
        assert(
            slot.id == id and math.abs(slot.x) < Board.Geometry.width / 2,
            "Invalid slot geometry"
        )
    end
    local rng, twin = Rng.new(2407), Rng.new(2407)
    for _ = 1, 200 do
        local value = rng:number()
        assert(
            value == twin:number() and value >= 0 and value < 1,
            "Seeded random sequence diverged"
        )
        local pick = rng:integer(2, 7)
        assert(
            pick == twin:integer(2, 7) and pick >= 2 and pick <= 7,
            "Integer RNG left its interval or diverged"
        )
    end
    local initial = Board.new(Rng.new(100))
    assert(
        counts(initial)[2] == 11 and counts(initial)[1] == 10,
        "Initial board distribution incorrect"
    )
    assert(
        Board.potential(initial) == 43 and Board.quota(initial, 0) == 10,
        "Initial quota does not match potential"
    )
    local copy = Board.copy(initial)
    Board.jumble(copy, Rng.new(8))
    assert(counts(copy)[2] == 11 and counts(copy)[1] == 10, "Jumble changed value distribution")
    copy[1] = 0
    assert(initial[1] ~= 0, "Board copy shares source storage")

    local values = filled(0)
    values[1] = 8
    local total = 0
    for _, expected in ipairs({ 8, 4, 2, 1 }) do
        local points, old, new = Board.pop(values, 1)
        assert(
            points == expected and old == expected and new == math.floor(expected / 2),
            "Pop did not score before halving"
        )
        total += points
    end
    assert(
        total == 15 and Board.isClear(values) and Board.pop(values, 1) == 0,
        "Full peg score or removal incorrect"
    )
    assert(Board.quota(values, 0) == 1, "Empty board quota must stay positive")

    values = filled(1)
    local transitions = Board.restock(values, 1, Rng.new(1))
    local first = counts(values)
    assert(
        #transitions == 10 and first[2] == 10 and first[1] == 1 and first[0] == 10,
        "Restock failed disjoint pairing"
    )
    assert(first[4] == nil, "Merge products merged recursively in one generation")
    Board.restock(values, 2, Rng.new(1))
    local second = counts(values)
    assert(
        second[4] == 5 and second[2] == 5 and second[1] == 1 and second[0] == 10,
        "Second restock failed refill or pairing"
    )

    values = filled(0)
    for id = 1, 6 do
        values[id] = 2
    end
    for id = 7, 11 do
        values[id] = 4
    end
    assert(
        Board.potential(values) == 53 and Board.quota(values, 0) == 12,
        "Quota calculation incorrect"
    )
    Board.restock(values, 2, Rng.new(1))
    local third = counts(values)
    assert(
        third[2] == 5 and third[4] == 4 and third[8] == 2 and third[0] == 10,
        "Mixed value merge failed"
    )
    assert(
        Board.potential(values) == 73 and Board.quota(values, 0) == 17,
        "Restocked quota incorrect"
    )
    assert(Board.quota({ 57 }, 0) == 27, "Quota must round to nearest integer")
    assert(
        Board.quota({ 4 }, 9) == 7 and Board.quota({ 4 }, 17) == 14,
        "Shop multiplier boundary incorrect"
    )
    assert(Board.quota({ 4 }, 18) == 18, "Exponential quota progression incorrect")
    values = filled(0)
    Board.restock(values, 5, Rng.new(1))
    assert(counts(values)[4] == 10 and counts(values)[2] == 1, "Restock tier boundary incorrect")

    local empty = filled(0)
    local whole, parts = Simulation.new(0.6), Simulation.new(0.6)
    Simulation.step(whole, 0.5, empty, Rng.new(3))
    local partsRng = Rng.new(3)
    for _ = 1, 60 do
        Simulation.step(parts, 1 / 120, empty, partsRng)
    end
    near(whole.x, parts.x, "Frame partition changed trajectory")
    near(whole.y, parts.y)
    near(whole.vx, parts.vx)
    near(whole.vy, parts.vy)

    values = filled(0)
    values[1] = 1
    local fast = Simulation.new(0)
    fast.x, fast.y, fast.vx, fast.vy = Board.Slots[1].x, Board.Slots[1].y + 3, 0, -500
    local hits = 0
    Simulation.step(fast, 0.07, values, Rng.new(3), function(id)
        hits += 1
        assert(id == 1, "Collision selected an empty peg")
        Board.pop(values, id)
    end)
    assert(
        hits == 1 and values[1] == 0 and fast.vy < 0 and fast.vx == 0,
        "One-point peg must pop without reflecting the ball"
    )

    values = filled(0)
    values[1] = 2
    local solid = Simulation.new(0)
    solid.x, solid.y, solid.vx, solid.vy = Board.Slots[1].x, Board.Slots[1].y + 3, 0, -500
    local solidHits = 0
    Simulation.step(solid, 0.07, values, Rng.new(3), function(id)
        solidHits += 1
        Board.pop(values, id)
    end)
    assert(
        solidHits == 1 and values[1] == 1 and solid.vy > 0,
        "Two-point peg must reflect before becoming pass-through"
    )

    values = filled(0)
    local weakId, solidId
    for id, slot in ipairs(Board.Slots) do
        if slot.x == 0 and math.abs(slot.y - 8.2) < 1e-8 then
            weakId = id
        elseif slot.x == 0 and math.abs(slot.y - 4.8) < 1e-8 then
            solidId = id
        end
    end
    assert(weakId and solidId, "Preview fixture slots missing")
    values[weakId], values[solidId] = 1, 2
    local throughPreview = Simulation.preview(0, values)
    local lastPreviewPoint = throughPreview[#throughPreview]
    assert(
        lastPreviewPoint.y < Board.Slots[weakId].y and lastPreviewPoint.y > Board.Slots[solidId].y,
        "Aim preview stopped on a one-point peg or passed through a solid peg"
    )
    assert(values[weakId] == 1 and values[solidId] == 2, "Preview changed live peg values")

    values = filled(0)
    values[1] = 16
    local overlap = Simulation.new(0)
    overlap.x, overlap.y = Board.Slots[1].x, Board.Slots[1].y
    local contactHits = 0
    Simulation.step(overlap, 1 / 120, values, Rng.new(9), function()
        contactHits += 1
    end)
    local dx, dy = overlap.x - Board.Slots[1].x, overlap.y - Board.Slots[1].y
    assert(
        math.sqrt(dx * dx + dy * dy) >= Board.Geometry.pegRadius + Board.Geometry.ballRadius,
        "Peg penetration not corrected"
    )
    assert(contactHits == 1, "Overlap emitted duplicate contacts")

    local wallBall = Simulation.new(1)
    wallBall.x, wallBall.vx, wallBall.vy = 9.5, 30, 0
    local walls = 0
    Simulation.step(wallBall, 0.1, empty, Rng.new(3), nil, function()
        walls += 1
    end)
    assert(
        walls == 1 and wallBall.vx < 0 and wallBall.x <= 10 - Board.Geometry.ballRadius,
        "Wall reflection or event incorrect"
    )
    local falling = Simulation.new(0)
    assert(
        Simulation.step(falling, 10, empty, Rng.new(1)) == "drain" and not falling.active,
        "Empty-board ball did not drain"
    )
    assert(Simulation.step(falling, 1, empty, Rng.new(1)) == nil, "Drain must emit once")
    local previewSource = Board.copy(initial)
    local preview = Simulation.preview(0.2, previewSource)
    assert(#preview > 1 and #preview <= 29, "Preview point count unbounded or empty")
    for id, value in ipairs(initial) do
        assert(previewSource[id] == value, "Preview mutated live pegs")
    end

    assert(
        Format.number(1250) == "1.25K" and Format.number(999999) == "1M",
        "Compact formatting boundary incorrect"
    )
    assert(
        Format.integer(1234567) == "1,234,567" and Format.integer(-1200) == "−1,200",
        "Integer grouping incorrect"
    )
    assert(
        Format.number(math.huge) == "∞" and Format.number(0 / 0) == "—",
        "Nonfinite formatting incorrect"
    )
    assert(Format.number(1e100) == "1.00e100", "Large number formatting incorrect")
    local replay = filled(0)
    replay[1], replay[3] = 4, 4
    local _, cycle = Board.restock(replay, 5, Rng.new(5), true)
    local reproduced = Board.copy(cycle.beforeValues)
    for _, refill in ipairs(cycle.refills) do
        assert(reproduced[refill.to] == 0, "Refill transition targets occupied slot")
        reproduced[refill.to] = refill.value
    end
    for _, merge in ipairs(cycle.merges) do
        assert(
            reproduced[merge.from] == reproduced[merge.to],
            "Merge transition combines different values"
        )
        reproduced[merge.from], reproduced[merge.to] = 0, merge.value
    end
    for id, value in ipairs(replay) do
        assert(
            reproduced[id] == value and cycle.afterValues[id] == value,
            "Captured restock does not reproduce the board"
        )
    end
    return true
end
