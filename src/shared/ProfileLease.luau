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

function Lease.write(previous, profile, token, now, release)
    local lock = type(previous) == "table" and previous._session
    if type(lock) ~= "table" or lock.token ~= token then
        return nil
    end
    local result = Profile.clean(profile)
    result._revision = math.max(0, math.floor(tonumber(previous._revision) or 0)) + 1
    if not release then
        result._session = { token = token, expiresAt = now + Lease.Lifetime }
    end
    return result
end

return Lease
