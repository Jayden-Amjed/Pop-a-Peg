local Loader = require("../../src/client/GameModelLoader")

local function fixture(load)
    local now, tasks, sequence, warnings, late = 0, {}, 0, {}, {}
    local function schedule(delay, callback)
        sequence += 1
        local item = {
            due = now + delay,
            order = sequence,
            thread = coroutine.create(callback),
            cancelled = false,
        }
        table.insert(tasks, item)
        return item
    end
    local loader = Loader.new({
        limit = 2,
        timeout = 15,
        defer = function(callback)
            return schedule(0, callback)
        end,
        delay = schedule,
        cancel = function(item)
            item.cancelled = true
        end,
        onFailure = function(id)
            table.insert(warnings, id)
        end,
        load = function(id, fail)
            late[id] = { thread = coroutine.running(), fail = fail }
            load(id, fail)
        end,
    })
    local function advance(dt)
        local ending = now + dt
        while true do
            table.sort(tasks, function(a, b)
                return a.due < b.due or (a.due == b.due and a.order < b.order)
            end)
            local item = tasks[1]
            if not item or item.due > ending then
                break
            end
            table.remove(tasks, 1)
            now = item.due
            if not item.cancelled then
                local ok, failure = coroutine.resume(item.thread)
                assert(ok, tostring(failure))
            end
        end
        now = ending
    end
    return loader, advance, late, warnings
end

local loader, advance, late, warnings = fixture(function(id, fail)
    if id == "hang-a" or id == "hang-b" then
        coroutine.yield()
    elseif id == "failed" then
        fail("mesh rejected")
    elseif id == "thrown" then
        error("request error")
    end
end)
local a, b = loader:request("hang-a"), loader:request("hang-b")
assert(loader:request("hang-a") == a, "Repeated model created another request")
local ready, failed, thrown =
    loader:request("ready"), loader:request("failed"), loader:request("thrown")
assert(
    loader:inspect().active == 2 and loader:inspect().queued == 3,
    "Unbounded or skipped request queue"
)
advance(0)
advance(14.99)
assert(
    a.state == "Loading" and b.state == "Loading" and ready.phase == "Queued",
    "Request timed out too early"
)
advance(0.01)
assert(a.state == "Failed" and b.state == "Failed", "Hung request retained a worker slot")
assert(
    ready.state == "Ready" and failed.state == "Failed" and thrown.state == "Failed",
    "Timeout did not pump remaining work"
)
assert(
    loader:inspect().active == 0 and loader:inspect().queued == 0,
    "Worker slot leaked after completion"
)
assert(#a.failures == 1 and #b.failures == 1 and #warnings == 4, "Duplicate failure completion")

-- Simulate callback/completion arriving after cancellation. This deliberately
-- ignores the test scheduler's cancelled flag to exercise the completed guard.
late["hang-a"].fail("late transport failure")
late.ready.fail("late callback after successful completion")
assert(coroutine.resume(late["hang-a"].thread), "Late completion simulation failed")
assert(a.state == "Failed" and #a.failures == 1, "Late success overwrote timeout or added failure")
assert(
    ready.state == "Ready" and #ready.failures == 0,
    "Late callback invalidated completed preload"
)
assert(loader:inspect().active == 0 and #warnings == 4, "Late completion released slot twice")
advance(100)
assert(
    loader:inspect().active == 0 and ready.state == "Ready",
    "Cancelled deadline ran after success"
)

local cache, tick = fixture(function() end)
local results = {}
for index = 1, 78 do
    results[index] = cache:request("model-" .. index)
end
tick(0)
for _, result in results do
    assert(result.state == "Ready", "Warm preload queue did not drain")
end
assert(cache:inspect().active == 0, "Warm requests leaked slots")
tick(20)
for _, result in results do
    assert(result.state == "Ready", "Warm result later timed out")
end
print(
    "PASS Blender asset loader: 15-second deadline, bounded queue, exact-once slot release, late callback/completion isolation and 78-entry warm cache"
)
