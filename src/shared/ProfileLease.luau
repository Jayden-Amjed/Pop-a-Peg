-- Pure UpdateAsync transforms. Every write checks the owner, including after a
-- timeout/retry. A failed load never obtains a token that can save defaults.
local Shared = if script then game:GetService("ReplicatedStorage").Shared else nil
local Profile = if Shared then require(Shared.Profile) else require("./Profile")
local Lease = { Lifetime = 180 }

function Lease.acquire(previous, token, now)
    local lock = type(previous) == "table" and previous._session
    if
        type(lock) == "table"
        and lock.token ~= token
        and type(lock.expiresAt) == "number"
        and lock.expiresAt > now
    then
        return nil
    end
    local result = Profile.clean(previous)
    result._session = { token = token, expiresAt = now + Lease.Lifetime }
    result._revision =
        math.max(0, math.floor(tonumber(type(previous) == "table" and previous._revision) or 0))
    return result
end

function Lease.write(previous, profile, token, now, release, writeId)
    local lock = type(previous) == "table" and previous._session
    local receipt = type(previous) == "table" and previous._lastWrite
    if
        writeId
        and type(receipt) == "table"
        and receipt.token == token
        and receipt.id == writeId
        and (lock == nil or (type(lock) == "table" and lock.token == token))
    then
        -- The prior attempt committed but its response was lost. This also works
        -- for release, whose successful first attempt removed the lease.
        return previous
    end
    if type(lock) ~= "table" or lock.token ~= token then
        return nil
    end
    local result = Profile.clean(profile)
    result._revision = math.max(0, math.floor(tonumber(previous._revision) or 0)) + 1
    if writeId then
        result._lastWrite = { token = token, id = writeId }
    end
    if not release then
        result._session = { token = token, expiresAt = now + Lease.Lifetime }
    end
    return result
end

return Lease
