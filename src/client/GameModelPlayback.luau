-- Small playback clock shared by the Blender mount and its lifecycle contracts.
-- A proc during an active performance coalesces into one next performance.
local Playback = {}

local function bounded(value, fallback, low, high)
    return if type(value) == "number" and value == value
        then math.clamp(value, low, high)
        else fallback
end

function Playback.new(duration)
    assert(
        type(duration) == "number" and duration > 0 and duration < math.huge,
        "Finite positive duration required"
    )
    local state = { duration = duration, age = 0, active = false, strength = 1, params = nil }
    local queuedStrength, queuedParams

    function state:pulse(amount, params)
        local strength = bounded(amount, 1, 0, 2)
        if strength <= 0 then
            return "ignored"
        end
        if self.active then
            queuedStrength = math.max(queuedStrength or 0, strength)
            queuedParams = params
            return "queued"
        end
        self.strength, self.params, self.age, self.active = strength, params, 0, true
        return "started"
    end

    function state:step(dt)
        if not self.active then
            return 1, false
        end
        self.age += bounded(dt, 0, 0, 0.1)
        local phase = math.min(1, self.age / self.duration)
        if self.age + 1e-9 >= self.duration then
            phase, self.active = 1, false
        end
        return phase, not self.active
    end

    function state:dequeue()
        if self.active or not queuedStrength then
            return false
        end
        local strength, params = queuedStrength, queuedParams
        queuedStrength, queuedParams = nil, nil
        return self:pulse(strength, params) == "started"
    end

    function state:reset()
        self.age, self.active, self.params = 0, false, nil
        queuedStrength, queuedParams = nil, nil
    end

    return state
end

return Playback
