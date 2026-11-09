local Playback = require("../../src/client/GameModelPlayback")
local Catalog = require("./CatalogInfo")
local Motion = require("./BlenderChoreography")
local count = 0
local function drain(clock)
    local frames, completed = 0, false
    while clock.active do
        local phase
        phase, completed = clock:step(0.1)
        frames += 1
        assert(phase >= 0 and phase <= 1, "Phase left the normalized range")
        assert(frames < 1000, "Playback never completes")
    end
    assert(completed, "No endpoint frame was rendered")
    return frames
end

for _, item in Catalog do
    local duration = Motion.Profiles[item.id].duration
    local clock = Playback.new(duration)
    assert(not clock.active and clock:step(0.2) == 1, "Idle clock advanced")
    assert(clock:pulse(0) == "ignored" and not clock.active, "Zero-strength proc started")
    assert(clock:pulse(0.7, { sequence = "first" }) == "started", "First proc did not start")
    local age = clock.age
    clock:step(0 / 0)
    clock:step(-100)
    assert(clock.age == age, "Invalid delta advanced a chest")
    clock:step(200)
    assert(clock.age == 0.1, "Large frame skipped the entire animation")
    for index = 1, 100 do
        assert(
            clock:pulse(index / 30, { sequence = index }) == "queued",
            "Retrigger bypassed queue"
        )
    end
    assert(clock.age == 0.1, "Continuous procs restarted the active animation")
    local frames = drain(clock)
    assert(frames >= math.ceil(duration / 0.1) - 2, "Premature completion")
    assert(clock:dequeue() and clock.active and clock.age == 0, "Queued proc did not start cleanly")
    assert(
        clock.strength == 2 and clock.params.sequence == 100,
        "Queue did not coalesce to one strongest/latest proc"
    )
    drain(clock)
    assert(not clock:dequeue(), "Queue grew with every proc")
    assert(clock:pulse(1) == "started", "Completed clock could not restart")
    clock:pulse(1)
    clock:reset()
    assert(not clock.active and not clock:dequeue(), "Disposal retained an activation")
    count += 1
end
assert(count == 78, "Catalog coverage changed")
print(
    "PASS Blender game playback: 78 durations, bounded slow frames, coalesced retriggers, endpoint completion and disposal"
)
