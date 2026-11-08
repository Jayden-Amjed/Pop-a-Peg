local Rng = {}
Rng.__index = Rng

local MODULUS = 2147483647

function Rng.new(seed)
    if type(seed) ~= "number" or seed ~= seed or math.abs(seed) == math.huge then
        seed = 1
    end
    local state = math.floor(math.abs(seed)) % MODULUS
    return setmetatable({ state = math.max(1, state) }, Rng)
end

function Rng:number()
    -- The product stays below the exact-integer limit of a double.
    self.state = (self.state * 48271) % MODULUS
    return (self.state - 1) / (MODULUS - 1)
end

function Rng:integer(low, high)
    assert(
        low == math.floor(low) and high == math.floor(high) and low <= high,
        "Invalid integer interval"
    )
    return low + math.floor(self:number() * (high - low + 1))
end

function Rng:shuffle(array)
    for index = #array, 2, -1 do
        local other = self:integer(1, index)
        array[index], array[other] = array[other], array[index]
    end
    return array
end

return Rng
