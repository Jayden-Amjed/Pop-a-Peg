local Bank = require("./GallerySoundBank")
local Engine = require("./GallerySoundEngine")
local Catalog = require("./CatalogInfo")

local descriptors, shapes, families = {}, {}, {}
local count, low, high, longest = 0, math.huge, -math.huge, 0
for _, metadata in Catalog do
    local id = metadata.id
    local p = assert(Bank.Profiles[id], "Missing gallery instrument: " .. id)
    local descriptor = p.timbre
        .. ":"
        .. table.concat(p.notes, ",")
        .. ":"
        .. table.concat(p.rhythm, ",")
        .. ":"
        .. tostring(p.duration)
    assert(not descriptors[descriptor], "Identical audible instrument/phrase: " .. id)
    assert(not shapes[p.description], "Repeated review description: " .. id)
    descriptors[descriptor], shapes[p.description], families[p.timbre] = true, true, true
    local notes = Bank.notes(id)
    assert(#notes > #p.notes and #notes <= 15, "Missing spectral partials or unbounded bank")
    local fresh = Bank.notes(id)
    notes[1].wait = -10
    assert(
        fresh[1].wait >= 0 and Bank.notes(id)[1].wait >= 0,
        "Voice scheduling mutated an authored phrase"
    )
    for _, offset in p.notes do
        low, high = math.min(low, offset), math.max(high, offset)
    end
    for _, note in fresh do
        assert(note.wait >= 0 and note.duration > 0 and note.duration <= 0.75, "Unbounded timing")
        longest = math.max(longest, note.wait + note.duration)
        assert(note.gain > 0 and note.gain <= 0.1, "Unbounded partial gain")
        local zero, endGain = Bank.sample(note, 0), Bank.sample(note, note.duration)
        assert(zero == 0 and endGain == 0, "Tone envelope clicks at an endpoint")
        for step = 0, 100 do
            local gain, pitch = Bank.sample(note, note.duration * step / 100)
            assert(gain == gain and gain >= 0 and gain <= note.gain, "Invalid envelope")
            assert(
                pitch == pitch and pitch >= 0.16 and pitch <= 8,
                "Invalid bounded playback pitch"
            )
        end
        local invalidGain, invalidPitch = Bank.sample(note, 0 / 0)
        assert(invalidGain == 0 and invalidPitch == invalidPitch, "Invalid age leaked a NaN")
    end
    count += 1
end
local timbreCount = 0
for _ in families do
    timbreCount += 1
end
assert(count == 78 and timbreCount == 12, "Sound coverage or spectrum variety regressed")
assert(high - low >= 40 and longest < 1.1, "Sound register/duration range changed")
assert(Bank.notes("unknown") == nil, "Unknown item borrowed another sound")

-- Exercise the real gallery engine with only the Roblox Sound boundary mocked.
local backend = { toneVoices = {}, pendingNotes = {}, toneTokens = 6, muted = false, cueCalls = 0 }
for _ = 1, Bank.Limits.voices do
    local sound = { IsLoaded = true, IsPlaying = false, Volume = 0, TimePosition = 0 }
    function sound:Play()
        self.IsPlaying = true
    end
    function sound:Stop()
        self.IsPlaying = false
    end
    table.insert(backend.toneVoices, { sound = sound, age = 0, duration = 0 })
end
function backend:play()
    self.cueCalls += 1
end
local engine = Engine.new(backend)
local observedVoices, maximumMix = 0, 0
for _, metadata in Catalog do
    assert(engine:playItem(metadata.id), "Engine refused a separated preview: " .. metadata.id)
    local heard = false
    for _ = 1, 144 do
        engine:_stepTones(1 / 120)
        local voices, mix = 0, 0
        for _, voice in engine.toneVoices do
            if voice.sound.IsPlaying then
                voices += 1
                mix += voice.sound.Volume
                heard = heard or voice.sound.Volume > 0
            end
        end
        observedVoices, maximumMix = math.max(observedVoices, voices), math.max(maximumMix, mix)
        assert(voices <= 12 and #engine.pendingNotes <= 32, "Voice or pending-note budget exceeded")
        assert(mix <= Bank.Limits.mix + 0.000001, "Mix headroom exceeded")
    end
    assert(heard and #engine.pendingNotes == 0, "Preview remained silent or leaked scheduled notes")
    for _, voice in engine.toneVoices do
        assert(not voice.sound.IsPlaying, "Tone tail did not finish")
    end
end
engine.toneTokens = 6
for _ = 1, 20 do
    engine:playItem("lagoon_synth")
end
assert(#engine.pendingNotes <= 32, "Repeated triggers exceeded pending budget")
engine.muted = true
assert(not engine:playItem("relay"), "Muted gallery accepted a new motif")
engine.destroyed = true
local pending = #engine.pendingNotes
engine:_stepTones(1)
assert(#engine.pendingNotes == pending, "Destroyed engine continued advancing voices")
assert(observedVoices >= 6, "Distinct partials did not overlap into new timbres")
print(
    string.format(
        "PASS gallery sound bank: %d unique phrases, %d spectral families, %d-semitone register, %.2fs max phrase; real engine peak %d/12 voices and %.3f/0.32 mix",
        count,
        timbreCount,
        high - low,
        longest,
        observedVoices,
        maximumMix
    )
)
