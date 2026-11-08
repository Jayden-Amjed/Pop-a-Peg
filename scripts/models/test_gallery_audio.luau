local Catalog = require("./CatalogInfo")
local Timeline = require("./GallerySoundTimeline")
local GalleryAudio = require("./GalleryAudio")
local Signatures = require("../../src/shared/ItemFeedback")

local cueNames = {
    click = true,
    coin = true,
    launch = true,
    restock = true,
    goal = true,
    merge = true,
    clear = true,
}
local count = 0
for _, metadata in Catalog do
    local events = Timeline.forId(metadata.id)
    assert(events and #events > 0, "Silent catalog model: " .. metadata.id)
    assert(#events <= 9, "Unbounded gallery sequence")
    local previous = 0
    for _, event in events do
        assert(event.phase >= previous and event.phase < 1, "Unordered or post-animation cue")
        assert(event.gain > 0 and event.gain <= 1, "Unbounded sound gain")
        assert(
            if event.kind == "item" then Signatures.Profiles[event.id] else cueNames[event.id],
            "Unknown sound dependency"
        )
        previous = event.phase
    end
    count += 1
end
assert(count == 78, "Catalog coverage changed")
assert(Timeline.forId("missing") == nil, "Unknown model plays unrelated sound")
assert(Timeline.forId("bubble_wand")[1].phase == 0.68, "Wand pop lost synchronization")
assert(Timeline.forId("burst_capsule")[1].phase == 0.30, "Cap release lost synchronization")
assert(Timeline.forId("coin_press")[1].phase == 0.40, "Press strike lost synchronization")
for _, id in { "chest_common", "chest_uncommon", "chest_rare", "chest_legendary" } do
    local events = Timeline.forId(id)
    assert(
        events[6].phase < 0.52 and events[7].phase == 0.56 and events[9].phase == 0.64,
        "Chest skipped anticipation/boom/reveal ordering"
    )
end

local backend = { calls = {}, stops = 0, destroyed = 0 }
function backend:stopAll()
    self.stops += 1
end
function backend:playItem(id)
    table.insert(self.calls, id)
end
function backend:play(id)
    table.insert(self.calls, id)
end
function backend:setMuted(value)
    self.muted = value
end
function backend:setVolume(value)
    self.volume = value
end
function backend:destroy()
    self.destroyed += 1
end

local audio = GalleryAudio.new(backend)
assert(audio:start("coin_press"), "Known item did not start")
assert(audio:step(0.39) == 0, "Press sounded before its strike")
assert(audio:step(0.40) == 1, "Press did not sound on its strike")
assert(audio:step(0.40) == 0 and audio:step(0.9) == 0, "Held frame repeated an attack")
assert(#backend.calls == 1, "Press sound count changed")
audio:suspend()
audio:resume(0.40)
assert(audio:step(0.8) == 0, "Resume replayed the press impact")
audio:start("coin_press", 0.6)
assert(audio:step(0.8) == 0, "Start from scrub position dumped old cues")
audio:start("coin_press")
assert(audio:step(0.6) == 1, "Explicit restart failed to reset cursor")
audio:start("chest_common")
assert(audio:step(0.51) == 6, "Chest lost its six anticipation rattles")
audio:suspend()
assert(audio:step(0.65) == 0, "Paused gallery played sound")
audio:resume(0.51)
assert(audio:step(0.56) == 2 and audio:step(0.64) == 1, "Resumed chest lost boom/reveal")
audio:start("chest_rare")
audio:setMuted(true)
assert(audio:step(0.60) == 0, "Muted sequence played an attack")
audio:setMuted(false)
assert(audio:step(0.62) == 0, "Unmute dumped stale rattles")
assert(audio:step(0.64) == 1, "Unmuted reveal was not audible")
audio:start("bubble_wand")
audio:step(0.5)
assert(audio:step(0.1) == 0 and not audio.active, "Backward seek kept a live cue schedule")
audio:resume(0.1)
assert(audio:step(0.68) == 1, "Resume after seek lost future wand pop")
audio:stop()
assert(audio:step(1) == 0, "Selection cancellation left old audio running")
audio:setVolume(0.25)
assert(backend.volume == 0.25, "Volume control did not reach the audio backend")

-- Sampling rates/speed do not alter the number or order of attacks per cycle.
for _, stepSize in { 0.003, 0.015, 0.073, 0.24 } do
    for _ = 1, 5 do
        local before = #backend.calls
        audio:start("chest_legendary")
        local progress = 0
        while progress < 1 do
            progress = math.min(1, progress + stepSize)
            audio:step(progress)
        end
        assert(#backend.calls - before == 9, "Speed/frame rate repeated or omitted an event")
    end
end
audio:destroy()
audio:destroy()
assert(
    backend.destroyed == 1 and audio:step(1) == 0 and not audio:start("coin"),
    "Destroyed controller resurrected"
)
print(
    "PASS gallery audio: 78 models; phase-aligned events; single-fire loops, pause/resume, seek, mute, cancellation and disposal"
)
