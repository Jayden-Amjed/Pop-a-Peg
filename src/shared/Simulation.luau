local Board = if script then require(script.Parent.Board) else require("./Board")

local Simulation = {}
local GEOMETRY = Board.Geometry
local STEP = 1 / 120
local GRAVITY = 19
local LAUNCH_SPEED = 17
local MAX_SPEED = 55
local RADIUS = GEOMETRY.ballRadius + GEOMETRY.pegRadius
local EPSILON = 0.00001
local CONTACT_DELAY = 0.055
local LEFT = -GEOMETRY.width / 2 + GEOMETRY.ballRadius
local RIGHT = GEOMETRY.width / 2 - GEOMETRY.ballRadius
local CEILING = GEOMETRY.top - GEOMETRY.ballRadius

Simulation.FixedStep = STEP
Simulation.MaxAngle = 1.25

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

function Simulation.new(angle)
    angle = if finite(angle)
        then math.max(-Simulation.MaxAngle, math.min(Simulation.MaxAngle, angle))
        else 0
    return {
        x = GEOMETRY.launchX,
        y = GEOMETRY.launchY,
        vx = math.sin(angle) * LAUNCH_SPEED,
        vy = -math.cos(angle) * LAUNCH_SPEED,
        active = true,
        elapsed = 0,
        _accumulator = 0,
        _contacts = {},
    }
end

local function earliestContact(ball, remaining, values)
    local time = remaining + EPSILON
    local kind, pegId
    local function consider(candidate, candidateKind, candidateId)
        if candidate >= -EPSILON and candidate <= remaining and candidate < time then
            time = math.max(0, candidate)
            kind = candidateKind
            pegId = candidateId
        end
    end
    if ball.vx < 0 then
        consider((LEFT - ball.x) / ball.vx, "left")
    elseif ball.vx > 0 then
        consider((RIGHT - ball.x) / ball.vx, "right")
    end
    if ball.vy > 0 then
        consider((CEILING - ball.y) / ball.vy, "ceiling")
    elseif ball.vy < 0 then
        consider((GEOMETRY.bottom - ball.y) / ball.vy, "drain")
    end

    local speedSquared = ball.vx * ball.vx + ball.vy * ball.vy
    if speedSquared > 0 then
        for id, slot in ipairs(Board.Slots) do
            if (values[id] or 0) > 0 then
                local dx, dy = ball.x - slot.x, ball.y - slot.y
                local separation = dx * dx + dy * dy - RADIUS * RADIUS
                local toward = dx * ball.vx + dy * ball.vy
                if separation < 0 then
                    consider(0, "peg", id)
                elseif toward < 0 then
                    local discriminant = toward * toward - speedSquared * separation
                    if discriminant >= 0 then
                        consider((-toward - math.sqrt(discriminant)) / speedSquared, "peg", id)
                    end
                end
            end
        end
    end
    return kind, pegId, time
end

local function pegBounce(ball, id, rng)
    local slot = Board.Slots[id]
    local nx, ny = ball.x - slot.x, ball.y - slot.y
    local distance = math.sqrt(nx * nx + ny * ny)
    if distance < EPSILON then
        nx, ny = 0, 1
    else
        nx, ny = nx / distance, ny / distance
    end
    ball.x = slot.x + nx * (RADIUS + EPSILON)
    ball.y = slot.y + ny * (RADIUS + EPSILON)
    local normalSpeed = ball.vx * nx + ball.vy * ny
    if normalSpeed < 0 then
        ball.vx -= 1.92 * normalSpeed * nx
        ball.vy -= 1.92 * normalSpeed * ny
        local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
        if speed > 0 and speed < 8.5 then
            ball.vx *= 8.5 / speed
            ball.vy *= 8.5 / speed
        end
        if rng then
            local offset = (rng:number() * 2 - 1) * math.pi / 180
            local cosine, sine = math.cos(offset), math.sin(offset)
            ball.vx, ball.vy = ball.vx * cosine - ball.vy * sine, ball.vx * sine + ball.vy * cosine
        end
        -- A shallow collision must leave the surface, including after jitter.
        local departing = ball.vx * nx + ball.vy * ny
        if departing < 0.05 then
            ball.vx += (0.05 - departing) * nx
            ball.vy += (0.05 - departing) * ny
        end
    end
end

local function integrate(ball, values, rng, onHit, onWall)
    ball.elapsed += STEP
    ball.vy -= GRAVITY * STEP
    local speed = math.sqrt(ball.vx * ball.vx + ball.vy * ball.vy)
    if speed > MAX_SPEED then
        ball.vx *= MAX_SPEED / speed
        ball.vy *= MAX_SPEED / speed
    end
    local remaining = STEP
    -- Swept contacts handle fast movement; the iteration bound prevents a wedged
    -- ball from consuming an entire server frame in zero-time contacts.
    for _ = 1, 8 do
        local kind, id, time = earliestContact(ball, remaining, values)
        if not kind then
            ball.x += ball.vx * remaining
            ball.y += ball.vy * remaining
            break
        end
        ball.x += ball.vx * time
        ball.y += ball.vy * time
        remaining -= time
        if kind == "drain" then
            ball.active = false
            return "drain"
        elseif kind == "peg" then
            pegBounce(ball, id, rng)
            if ball.elapsed >= (ball._contacts[id] or -1) then
                ball._contacts[id] = ball.elapsed + CONTACT_DELAY
                if onHit then
                    onHit(id)
                end
            end
        else
            if kind == "left" then
                ball.x, ball.vx = LEFT + EPSILON, math.abs(ball.vx) * 0.94
            elseif kind == "right" then
                ball.x, ball.vx = RIGHT - EPSILON, -math.abs(ball.vx) * 0.94
            else
                ball.y, ball.vy = CEILING - EPSILON, -math.abs(ball.vy) * 0.94
            end
            if onWall then
                onWall()
            end
        end
        if not ball.active or remaining <= EPSILON then
            break
        end
    end
    if ball.active and ball.y <= GEOMETRY.bottom then
        ball.active = false
        return "drain"
    end
    return nil
end

function Simulation.step(ball, dt, values, rng, onHit, onWall)
    if not ball.active or not finite(dt) or dt <= 0 then
        return nil
    end
    ball._accumulator = (ball._accumulator or 0) + dt
    ball._contacts = ball._contacts or {}
    while ball._accumulator + 1e-12 >= STEP and ball.active do
        ball._accumulator = math.max(0, ball._accumulator - STEP)
        if integrate(ball, values, rng, onHit, onWall) == "drain" then
            return "drain"
        end
    end
    return nil
end

function Simulation.preview(angle, values)
    local ball = Simulation.new(angle)
    local points = { { x = ball.x, y = ball.y } }
    local function stop()
        ball.active = false
    end
    for _ = 1, 28 do
        Simulation.step(ball, 1 / 30, values, nil, stop, stop)
        table.insert(points, { x = ball.x, y = ball.y })
        if not ball.active then
            break
        end
    end
    return points
end

return Simulation
