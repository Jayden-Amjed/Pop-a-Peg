--!strict

local Smoke = {}

function Smoke.message(context: string): string
    return string.format("[Starter] %s: shared module OK", context)
end

return table.freeze(Smoke)
