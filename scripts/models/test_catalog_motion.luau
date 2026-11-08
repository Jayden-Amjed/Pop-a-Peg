-- Run with the pinned Luau CLI. This exercises the real adapter with a small
-- mathematical value-type double; it does not prove mesh/import/render quality.
local Adapter = require("./CatalogMotion")
local Motion = require("../../src/client/ItemMotion")
local V, CF, Color = {}, {}, {}
local vectorMeta, frameMeta = {}, {}
function V.new(x, y, z)
    return setmetatable({ X = x or 0, Y = y or 0, Z = z or 0 }, vectorMeta)
end
function vectorMeta.__add(a, b)
    return V.new(a.X + b.X, a.Y + b.Y, a.Z + b.Z)
end
function vectorMeta.__sub(a, b)
    return V.new(a.X - b.X, a.Y - b.Y, a.Z - b.Z)
end
function vectorMeta.__mul(a, b)
    return V.new(a.X * b, a.Y * b, a.Z * b)
end
function vectorMeta.__div(a, b)
    return a * (1 / b)
end
local function matrix(r, p)
    return setmetatable({ r = r, Position = p }, frameMeta)
end
function CF.new(x, y, z)
    return matrix({ 1, 0, 0, 0, 1, 0, 0, 0, 1 }, if type(x) == "table" then x else V.new(x, y, z))
end
local function rotate(frame, v)
    local m = frame.r
    return V.new(
        m[1] * v.X + m[2] * v.Y + m[3] * v.Z,
        m[4] * v.X + m[5] * v.Y + m[6] * v.Z,
        m[7] * v.X + m[8] * v.Y + m[9] * v.Z
    )
end
function frameMeta.__mul(a, b)
    local r = {}
    for row = 0, 2 do
        for column = 1, 3 do
            r[row * 3 + column] = a.r[row * 3 + 1] * b.r[column]
                + a.r[row * 3 + 2] * b.r[column + 3]
                + a.r[row * 3 + 3] * b.r[column + 6]
        end
    end
    return matrix(r, a.Position + rotate(a, b.Position))
end
function frameMeta.__sub(a, b)
    return matrix(table.clone(a.r), a.Position - b)
end
function CF.Angles(x, y, z)
    local cx, sx, cy, sy, cz, sz =
        math.cos(x), math.sin(x), math.cos(y), math.sin(y), math.cos(z), math.sin(z)
    return matrix({ 1, 0, 0, 0, cx, -sx, 0, sx, cx }, V.new())
        * matrix({ cy, 0, sy, 0, 1, 0, -sy, 0, cy }, V.new())
        * matrix({ cz, -sz, 0, sz, cz, 0, 0, 0, 1 }, V.new())
end
function Color.new(r, g, b)
    local color = { R = r, G = g, B = b, alpha = 0 }
    function color:Lerp(other, alpha)
        local result = Color.new(
            self.R + (other.R - self.R) * alpha,
            self.G + (other.G - self.G) * alpha,
            self.B + (other.B - self.B) * alpha
        )
        result.alpha = alpha
        return result
    end
    return color
end
local types = { Vector3 = V, CFrame = CF, Color3 = Color }
local function near(a, b, message)
    assert(
        math.abs(a - b) < 0.000001,
        (message or "Values differ") .. ": " .. tostring(a) .. ", " .. tostring(b)
    )
end
local function nearVector(a, b, message)
    near(a.X, b.X, message)
    near(a.Y, b.Y, message)
    near(a.Z, b.Z, message)
end
local function nearFrame(a, b, message)
    nearVector(a.Position, b.Position, message)
    for i = 1, 9 do
        near(a.r[i], b.r[i], message)
    end
end
local function distance(a, b)
    local d = a - b
    return math.sqrt(d.X ^ 2 + d.Y ^ 2 + d.Z ^ 2)
end
local function part(group, position, pivot, authored, size, span)
    local object = {
        CFrame = CF.new(position),
        Size = size or V.new(1, 1, 1),
        Color = Color.new(0.2, 0.4, 0.6),
        attributes = {
            MotionGroup = group,
            MotionPivot = pivot,
            AuthoredPosition = authored or position,
            CompressionSpan = span,
        },
    }
    function object:IsA(class)
        return class == "BasePart"
    end
    function object:GetAttribute(name)
        return self.attributes[name]
    end
    return object
end
local function controller(id, parts)
    local model = {}
    function model:GetAttribute(name)
        return if name == "ItemId" then id else nil
    end
    function model:GetDescendants()
        return parts
    end
    return Adapter.new(model, types)
end

-- Different source Z values previously separated the barrel's material pieces.
local a = part("Lens", V.new(0, 0, -0.4), V.new(), V.new(0, 2, -0.4))
local b = part("Lens", V.new(0, 0, 0.6), V.new(), V.new(0, 2, 0.6))
local lens = controller("survey_lens", { a, b })
for i = 1, 39 do
    lens:apply(i / 40, 2, CF.new())
    near(distance(a.CFrame.Position, b.CFrame.Position), 1, "Rigid lens assembly split")
end
local sampled = Motion.sample("survey_lens", "Lens", 0.5, 2, 0, 2, 0.1)
lens:apply(0.5, 2, CF.new())
near(
    (a.CFrame.Position.Z + b.CFrame.Position.Z) / 2,
    0.1 + sampled.z,
    "Must sample authored coordinates"
)
local repeated = a.CFrame
lens:apply(0.8, 2, CF.new())
lens:apply(0.5, 2, CF.new())
nearFrame(a.CFrame, repeated, "Pose sampling accumulated transforms")

-- Connected seedlings remain touching while both center offsets and sizes grow.
local pod = part("Seed", V.new(0, 0.5, 0), V.new(), nil, V.new(1, 1, 1))
local stem = part("Seed", V.new(0, 1.5, 0), V.new(), nil, V.new(0.1, 1, 0.1))
local seeds = controller("seed_bank", { pod, stem })
for i = 0, 40 do
    seeds:apply(i / 40, 2, CF.new())
    near(
        pod.CFrame.Position.Y + pod.Size.Y / 2,
        stem.CFrame.Position.Y - stem.Size.Y / 2,
        "Seed/stem contact broke"
    )
end

-- Shared rotation plus scale transforms an entire assembly, including spacing.
local orbitA = part("Orbit", V.new(-1, 0, 0), V.new())
local orbitB = part("Orbit", V.new(1, 0, 0), V.new())
controller("growth_ring", { orbitA, orbitB }):apply(0.5, 2, CF.new())
near(
    distance(orbitA.CFrame.Position, orbitB.CFrame.Position),
    2 * 1.16,
    "Orbit spacing did not grow with its pieces"
)

-- Continuous Wave Spring retains its lower socket and rigid top assembly.
local coil = part("SpringMesh", V.new(0, 0.88, 0), V.new(), nil, V.new(1.3, 1.76, 1.3), 1.76)
local guide = part("SpringGuide", V.new(0, 0.88, 0), V.new(), nil, V.new(0.2, 1.76, 0.2), 1.76)
local cap = part("Weight", V.new(0, 1.94, 0), V.new(0, 1.94, 0), nil, V.new(1.5, 0.3, 1.5), 1.76)
local pad = part("Weight", V.new(0, 2.13, 0), V.new(0, 2.13, 0), nil, V.new(1.3, 0.1, 1.1), 1.76)
local spring = controller("spring_coil", { coil, guide, cap, pad })
for i = 0, 100 do
    spring:apply(i / 100, 2, CF.new(0, 3, 0))
    near(coil.CFrame.Position.Y - coil.Size.Y / 2, 3, "Spring lower socket slipped")
    near(guide.CFrame.Position.Y - guide.Size.Y / 2, 3, "Guide lower socket slipped")
    near(pad.CFrame.Position.Y - cap.CFrame.Position.Y, 0.19, "Top spring assembly split")
    near(coil.Size.X, 1.3, "Spring radial thickness changed")
    near(cap.Size.Y, 0.3, "Spring cap compressed")
end

-- A chest lid's hinge point is invariant through its complete open/close cycle.
local hinge = V.new(0, -0.25, -0.5)
local lid = part("ChestLid", V.new(0, 0.25, 0), hinge)
local chest = controller("chest_common", { lid })
local hingeInLid = hinge - lid.CFrame.Position
for i = 0, 40 do
    chest:apply(i / 40, 2, CF.new())
    nearVector(
        lid.CFrame.Position + rotate(lid.CFrame, hingeInLid),
        hinge,
        "Lid detached from hinge"
    )
end

-- Distinct explicit pivots keep individual key timing; they are not one rigid mesh.
local keyA = part("SynthKey", V.new(-0.5, 0, 0), V.new(-0.5, 0, 0))
local keyB = part("SynthKey", V.new(0.5, 0, 0), V.new(0.5, 0, 0))
controller("lagoon_synth", { keyA, keyB }):apply(0.25, 1, CF.new())
assert(
    math.abs(keyA.CFrame.Position.Y - keyB.CFrame.Position.Y) > 0.01,
    "Independent key phases collapsed"
)

-- Exercise all 78 profile adapters at both strengths and restore exact originals.
local profiles = 0
for id, profile in Motion.Profiles do
    profiles += 1
    local group = if profile.groups then profile.groups[1] else "Preview"
    local moving = part(group, V.new(0.3, 0.5, 0.1), V.new(0.1, -0.2, 0), V.new(0.3, 1.5, 0.1))
    local fixed = part("Fixed", V.new(0, -0.5, 0), V.new())
    moving.CFrame = moving.CFrame * CF.Angles(0.1, math.pi, 0.3)
    local rest, originalSize, originalColor = moving.CFrame, moving.Size, moving.Color
    local motion = controller(id, { moving, fixed })
    near(motion.duration, profile.duration, "Duration mismatch")
    for strength = 1, 2 do
        for i = 0, 40 do
            motion:apply(i / 40, strength, CF.new())
            for _, v in
                {
                    moving.CFrame.Position.X,
                    moving.CFrame.Position.Y,
                    moving.CFrame.Position.Z,
                    moving.Size.X,
                    moving.Size.Y,
                    moving.Size.Z,
                }
            do
                assert(v == v and math.abs(v) < 100, "Unbounded adapter pose: " .. id)
            end
            assert(
                moving.Size.X > 0 and moving.Size.Y > 0 and moving.Size.Z > 0,
                "Invalid mesh size"
            )
            assert(moving.Color.alpha <= 0.22, "Glow washed out preview contrast")
            nearFrame(fixed.CFrame, CF.new(0, -0.5, 0), "Fixed structure moved")
        end
    end
    for _, endpoint in { 0, 1, 0 / 0 } do
        motion:apply(endpoint, 2, CF.new(2, 0, 0))
        nearFrame(moving.CFrame, CF.new(2, 0, 0) * rest, "Rest pose did not restore")
        nearVector(moving.Size, originalSize, "Rest size did not restore")
        assert(moving.Color == originalColor, "Rest color did not restore")
    end
end
assert(profiles == 78, "Expected all 78 catalog motion profiles")
print(
    "PASS catalog adapter: 78 profiles, rigid assemblies, shared scale, seed contact, spring socket/cap, chest hinge, authored phase, independent phases, exact reset and restrained glow"
)
