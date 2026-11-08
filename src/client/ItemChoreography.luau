-- Shared choreography for native models and imported Blender assemblies.
local Curves = if script then require(script.Parent.motion.Curves) else require("./motion/Curves")
local families = if script
    then {
        require(script.Parent.motion.Mechanical),
        require(script.Parent.motion.Nature),
        require(script.Parent.motion.Rewards),
    }
    else {
        require("./motion/Mechanical"),
        require("./motion/Nature"),
        require("./motion/Rewards"),
    }
local entries = {}
for _, family in families do
    for id, entry in family(Curves) do
        assert(not entries[id], "Duplicate choreography: " .. id)
        assert(type(entry.body) == "function" and type(entry.part) == "function", id)
        entries[id] = table.freeze(entry)
    end
end
local Choreography = { entries = table.freeze(entries), Curves = Curves }

function Choreography.body(id, t, strength)
    local entry = assert(entries[id], "Missing choreography: " .. tostring(id))
    if t <= 0 or t >= 1 or strength <= 0 then
        return Curves.body()
    end
    local result = entry.body(t, strength)
    for key, fallback in Curves.body() do
        if result[key] == nil then
            result[key] = fallback
        end
    end
    return result
end

function Choreography.part(id, group, t, strength, x, y, z, state)
    return entries[id].part(group, t, strength, x, y, z, state) or state
end

return Choreography
