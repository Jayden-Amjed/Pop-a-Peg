-- Run with the pinned Luau CLI. This exercises the real adapter with a small
-- mathematical value-type double; it does not prove mesh/import/render quality.
local Adapter = require("./CatalogMotion")
local Motion = require("./BlenderChoreography")
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
function frameMeta:Inverse()
    local r = self.r
    local inverse = matrix({ r[1], r[4], r[7], r[2], r[5], r[8], r[3], r[6], r[9] }, V.new())
    inverse.Position = rotate(inverse, self.Position * -1)
    return inverse
end
frameMeta.__index = frameMeta
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
    function model:GetBoundingBox()
        local low, high =
            { math.huge, math.huge, math.huge }, { -math.huge, -math.huge, -math.huge }
        for _, object in parts do
            for index, axis in { "X", "Y", "Z" } do
                low[index] =
                    math.min(low[index], object.CFrame.Position[axis] - object.Size[axis] / 2)
                high[index] =
                    math.max(high[index], object.CFrame.Position[axis] + object.Size[axis] / 2)
            end
        end
        return CF.new(), V.new(high[1] - low[1], high[2] - low[2], high[3] - low[3])
    end
    local adapter = Adapter.new(model, types)
    local apply = adapter.apply
    -- Check whole-body composition, then strip it to run the mechanism/contact
    -- invariants in model space. This also catches scaling positions but not sizes.
    function adapter:apply(t, strength, rootPose)
        rootPose = rootPose or CF.new()
        apply(self, t, strength, rootPose)
        local body = Motion.bodySample(id, t, strength)
        local size = self.restSize
        local frame = rootPose
            * CF.new(body.x * size.X, body.y * size.Y, body.z * size.Z)
            * CF.Angles(body.rx, body.ry, body.rz)
        for _, object in parts do
            local localFrame = frame:Inverse() * object.CFrame
            object.CFrame = rootPose
                * CF.new(localFrame.Position / body.scale)
                * (localFrame - localFrame.Position)
            object.Size /= body.scale
        end
    end
    return adapter
end

-- Different source Z values previously separated the barrel's material pieces.
local a = part("Lens", V.new(0, 0, -0.4), V.new(), V.new(0, 2, -0.4))
local b = part("Lens", V.new(0, 0, 0.6), V.new(), V.new(0, 2, 0.6))
local lens = controller("survey_lens", { a, b })
for i = 1, 39 do
    lens:apply(i / 40, 2, CF.new())
    local state = Motion.sample("survey_lens", "Lens", i / 40, 2, 0, 2, 0.1)
    near(distance(a.CFrame.Position, b.CFrame.Position), state.scale, "Rigid lens assembly split")
end
local sampled = Motion.sample("survey_lens", "Lens", 0.5, 2, 0, 2, 0.1)
lens:apply(0.5, 2, CF.new())
local expectedLens = CF.new(sampled.x, sampled.y, sampled.z)
    * CF.Angles(sampled.rx, sampled.ry, sampled.rz)
    * CF.new(0, 0, 0.1 * sampled.scale)
nearVector(
    (a.CFrame.Position + b.CFrame.Position) / 2,
    expectedLens.Position,
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
    2 * Motion.sample("growth_ring", "Orbit", 0.5, 2, 0, 0, 0).scale,
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

-- The minted coin is a flat two-material assembly resting on the anvil. The die
-- meets it only after the free travel, then stays in contact while flattening it.
local mintPivot = V.new(0, 0.57, 0)
local minted = part("MintCoin", V.new(0, 0.625, 0), mintPivot, nil, V.new(0.78, 0.11, 0.78))
local stamp = part("MintCoin", V.new(0, 0.6925, 0), mintPivot, nil, V.new(0.25, 0.025, 0.25))
local die = part("PressScrew", V.new(0, 1.1, 0), V.new(0, 1.5, 0), nil, V.new(0.9, 0.13, 0.9))
local crank = part("Crank", V.new(0, 2.55, 0), V.new(0, 2.55, 0), nil, V.new(1.4, 0.15, 0.15))
local press = controller("coin_press", { minted, stamp, die, crank })
for strength = 1, 2 do
    for index = 0, 200 do
        local phase = index / 200
        press:apply(phase, strength, CF.new())
        near(minted.CFrame.Position.Y - minted.Size.Y / 2, 0.57, "Coin lifted off the anvil")
        near(minted.Size.X, 0.78, "Coin flattened radially instead of vertically")
        near(
            stamp.CFrame.Position.Y - stamp.Size.Y / 2,
            minted.CFrame.Position.Y + minted.Size.Y / 2,
            "Minted stamp separated from coin"
        )
        near(crank.CFrame.Position.Y, 2.55, "Top crank travelled with the die")
        local gap = die.CFrame.Position.Y
            - die.Size.Y / 2
            - (stamp.CFrame.Position.Y + stamp.Size.Y / 2)
        assert(gap >= -0.000001, "Die penetrated its minted coin")
        if Motion.sample("coin_press", "MintCoin", phase, strength, 0, 0.6, 0).axial < 1 then
            near(gap, 0, "Squashed coin lost contact with press die")
        end
    end
end
-- Quota's visible impact belongs on its paper tray. Even reduced positive
-- strength completes the mechanical stroke; strength shapes body recoil instead.
local quotaPivot = V.new(0.35, 1.48, 0)
local ink = part("Stamp", V.new(0.35, 0.94, 0), quotaPivot, nil, V.new(0.77, 0.10, 0.69))
local quotaHead = part("Stamp", V.new(0.35, 1.10, 0), quotaPivot, nil, V.new(0.74, 0.26, 0.66))
local paper = part("Fixed", V.new(0.23, 0.451, 0), V.new(), nil, V.new(0.65, 0.012, 0.035))
local quota = controller("quota_bonus", { ink, quotaHead, paper })
for _, strength in { 0.1, 0.25, 1, 2 } do
    for step = 0, 100 do
        local phase = step / 100
        quota:apply(phase, strength, CF.new())
        local gap = ink.CFrame.Position.Y
            - ink.Size.Y / 2
            - (paper.CFrame.Position.Y + paper.Size.Y / 2)
        assert(gap >= -0.000001, "Quota die penetrated its tray")
        near(quotaHead.CFrame.Position.Y - ink.CFrame.Position.Y, 0.16, "Quota stamp split")
        if phase >= 0.25 and phase <= 0.29 then
            near(gap, 0, "Quota effect beat does not coincide with tray contact")
        end
    end
end
quota:apply(0.27, 0, CF.new())
near(ink.CFrame.Position.Y, 0.94, "Zero-strength quota did not stay at rest")

-- Separate materials in the removed cap must travel as one rigid object.
local capPivot = V.new(0, 1.765, 0)
local capPearl = part("BurstCap", V.new(0, 1.95, 0), capPivot)
local capPin = part("BurstCap", V.new(0, 2.5, 0), capPivot)
local capsule = controller("burst_capsule", { capPearl, capPin })
for index = 0, 100 do
    capsule:apply(index / 100, 2, CF.new())
    near(
        distance(capPearl.CFrame.Position, capPin.CFrame.Position),
        0.55,
        "Cap material assembly split"
    )
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
assert(math.abs(keyA.CFrame.r[6] - keyB.CFrame.r[6]) > 0.01, "Independent key phases collapsed")

-- The relay/synth's mount is fixed relative to the device, not the viewport.
-- Their new whole-device pops must grow connected spacing and dimensions by the
-- same factor, then restore exactly without feeding posed geometry back as rest.
for _, id in { "relay", "lagoon_synth" } do
    local left = part("Fixed", V.new(-0.5, 0, 0), V.new(), nil, V.new(1, 1, 1))
    local right = part("Fixed", V.new(0.5, 0, 0), V.new(), nil, V.new(1, 1, 1))
    local model = {}
    function model:GetAttribute(name)
        return if name == "ItemId" then id else nil
    end
    function model:GetDescendants()
        return { left, right }
    end
    function model:GetBoundingBox()
        return CF.new(), V.new(2, 1, 1)
    end
    local raw = Adapter.new(model, types)
    local root = CF.new(3, -2, 1) * CF.Angles(0.2, -0.3, 0.1)
    for _, strength in { 0, 1, 2 } do
        for step = 0, 100 do
            local phase = step / 100
            raw:apply(phase, strength, root)
            local body = Motion.bodySample(id, phase, strength)
            local reaction = root
                * CF.new(body.x * 2, body.y, body.z)
                * CF.Angles(body.rx, body.ry, body.rz)
            nearFrame(left.CFrame, reaction * CF.new(-0.5 * body.scale, 0, 0), "Mount frame drift")
            nearFrame(
                right.CFrame,
                reaction * CF.new(0.5 * body.scale, 0, 0),
                "Cabinet frame drift"
            )
            near(left.Size.X, body.scale, "Left mount did not resize")
            near(right.Size.X, body.scale, "Right mount did not resize")
            near(
                distance(left.CFrame.Position, right.CFrame.Position),
                (left.Size.X + right.Size.X) / 2,
                "Whole-model pop split connected fixed parts"
            )
        end
    end
    raw:apply(0.27, 1, root)
    assert(left.Size.X > 1.23, "Main pop too small at normal strength")
    raw:apply(0.73, 2, root)
    raw:apply(0, 1, root)
    nearFrame(left.CFrame, root * CF.new(-0.5, 0, 0), "Backward scrub failed to restore mount")
    nearVector(left.Size, V.new(1, 1, 1), "Backward scrub failed to restore size")
end

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
        nearFrame(
            moving.CFrame,
            CF.new(2, 0, 0) * rest,
            "Rest pose did not restore: " .. id .. "/" .. tostring(endpoint)
        )
        nearVector(moving.Size, originalSize, "Rest size did not restore")
        assert(moving.Color == originalColor, "Rest color did not restore")
    end
end
assert(profiles == 78, "Expected all 78 catalog motion profiles")
print(
    "PASS catalog adapter: 78 profiles, rigid assemblies, shared scale, seed contact, spring socket/cap, chest hinge, authored phase, independent phases, exact reset and restrained glow"
)
