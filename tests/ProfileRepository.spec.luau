local Repository = if script
    then require(game:GetService("ServerScriptService").Server.ProfileRepository)
    else require("../src/server/ProfileRepository")
local Profile = if script
    then require(game:GetService("ReplicatedStorage").Shared.Profile)
    else require("../src/shared/Profile")

local function copy(value)
    if type(value) ~= "table" then
        return value
    end
    local result = {}
    for key, entry in value do
        result[key] = copy(entry)
    end
    return result
end

local function fakeStore()
    local fake = { data = {}, plan = {}, calls = 0, callbacks = 0 }
    function fake:UpdateAsync(key, transform)
        self.calls += 1
        local operation = table.remove(self.plan, 1)
        if operation == "before" then
            error("Simulated service outage")
        end
        local previous = copy(self.data[key])
        self.callbacks += 1
        local nextValue = transform(previous)
        if operation == "repeat" then
            self.callbacks += 1
            nextValue = transform(copy(self.data[key]))
        elseif operation == "takeover" then
            self.data[key]._session = { token = "competing-server", expiresAt = 100000 }
            self.callbacks += 1
            nextValue = transform(copy(self.data[key]))
        end
        if nextValue ~= nil then
            self.data[key] = copy(nextValue)
        end
        if operation == "after" then
            error("Simulated lost committed response")
        end
        return copy(nextValue)
    end
    return fake
end

return function()
    local now, waited, generated = 1000, 0, 0
    local function repository(store, prefix)
        return Repository.new({
            store = store,
            clock = function()
                return now
            end,
            wait = function(seconds)
                waited += seconds
            end,
            newToken = function()
                generated += 1
                return prefix .. generated
            end,
        })
    end

    local store = fakeStore()
    store.data.player_1 = { bestRound = 40, chests = { common = 3 } }
    store.plan = { "after", "repeat" }
    local a = repository(store, "a")
    local profile, status = a:load(1)
    assert(
        profile and status == "saved" and profile.chests.common == 3,
        "Ambiguous acquire retry recovers the same owned lease"
    )
    assert(
        store.calls == 2 and store.callbacks == 3 and waited == 1,
        "Real adapter retries and repeated UpdateAsync transforms executed"
    )
    local b = repository(store, "b")
    local blocked, locked = b:load(1)
    assert(not blocked and locked == "locked", "Another repository cannot acquire live lease")
    local calls = store.calls
    assert(not b:save(1, Profile.clean(nil)), "Unacquired repository cannot save defaults")
    assert(store.calls == calls, "Blocked owner never calls UpdateAsync to save")

    profile.chests.common = 1
    profile.research = 5
    store.plan = { "after", "repeat" }
    local saved, saveStatus = a:save(1, profile)
    assert(
        saved and saveStatus == "saved" and store.data.player_1.chests.common == 1,
        "Ambiguous consumed balance save resolves without resurrection"
    )
    assert(
        store.data.player_1._revision == 1,
        "Retried write ID commits one revision even when callback repeats"
    )
    profile.chests.common = 0
    store.plan = { "before", "repeat" }
    assert(a:save(1, profile), "Pre-commit timeout retries the same snapshot")
    assert(
        store.data.player_1.chests.common == 0 and store.data.player_1._revision == 2,
        "Callback retry writes consumed balance once"
    )
    store.plan = { "after", "repeat" }
    assert(a:save(1, profile, true), "Release retries acknowledge already committed release")
    assert(
        store.data.player_1._session == nil and store.data.player_1._revision == 3,
        "Release leaves no lease and no duplicate write"
    )
    assert(not a:save(1, profile), "Released token is cleared")
    local joined = b:load(1)
    assert(
        joined and joined.chests.common == 0 and joined.research == 5,
        "Reconnect loads durable consumed balances"
    )

    store.plan = { "takeover" }
    local lost, lostStatus = b:save(1, joined)
    assert(not lost and lostStatus == "locked", "Repeated callback rechecks changed owner")
    assert(
        store.data.player_1._session.token == "competing-server",
        "Stale write cannot overwrite competing session"
    )
    calls = store.calls
    assert(
        not b:save(1, joined) and store.calls == calls,
        "Lost token cannot attempt another write"
    )

    local unavailable = fakeStore()
    unavailable.data.player_9 = { bestRound = 900, chests = { rare = 8 } }
    unavailable.plan = { "before", "before", "before" }
    local fail = repository(unavailable, "failed")
    local missing, unavailableStatus = fail:load(9)
    assert(
        missing == nil and unavailableStatus == "unavailable",
        "Failed load returns no playable default profile"
    )
    calls = unavailable.calls
    assert(
        not fail:save(9, Profile.clean(nil)) and unavailable.calls == calls,
        "Failed load cannot overwrite existing record"
    )
    assert(
        unavailable.data.player_9.bestRound == 900 and unavailable.data.player_9.chests.rare == 8,
        "Outage leaves prior progress intact"
    )

    local expired = fakeStore()
    local old = repository(expired, "old")
    local oldProfile = old:load(3)
    now += 181
    local replacement = repository(expired, "new")
    local newProfile = replacement:load(3)
    assert(oldProfile and newProfile, "Expired lease can be recovered by another server")
    assert(not old:save(3, oldProfile), "Expired owner cannot write after takeover")
    newProfile.chests.legendary = 4
    assert(replacement:save(3, newProfile), "New owner can persist normally")

    local session = repository(nil, "studio")
    local fresh, mode = session:load(-1)
    assert(mode == "session" and fresh, "Studio fallback is explicit")
    fresh.chests.common = 2
    assert(session:save(-1, fresh, true), "Session save works without any cloud adapter")
    local rejoined = session:load(-1)
    assert(rejoined.chests.common == 2, "Session-local reconnect keeps progress")
    print(
        "PASS profile repository: fake UpdateAsync acquisition, duplicate callbacks, pre/post-commit timeouts, release retry, stale owners, outages and Studio fallback"
    )
end
