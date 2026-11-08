-- Pure normalized choreography curves. All transitions have zero end velocity.
local Curves = {}

function Curves.phase(t, first, last)
    local u = math.clamp((t - first) / math.max(0.000001, last - first), 0, 1)
    return u * u * u * (u * (u * 6 - 15) + 10)
end

function Curves.pulse(t, first, peak, last)
    if t <= peak then
        return Curves.phase(t, first, peak)
    end
    return 1 - Curves.phase(t, peak, last)
end

function Curves.spin(t, first, last, turns)
    assert(turns % 1 == 0, "A completed spin must use whole revolutions")
    return Curves.phase(t, first, last) * turns * math.pi * 2
end

function Curves.ring(t, first, last, cycles)
    local u = Curves.phase(t, first, last)
    return math.sin(u * math.pi * 2 * cycles) * math.sin(u * math.pi) ^ 2
end

function Curves.body()
    return { x = 0, y = 0, z = 0, rx = 0, ry = 0, rz = 0, scale = 1 }
end

return table.freeze(Curves)
