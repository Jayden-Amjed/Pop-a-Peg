-- Run in an isolated Studio client after installing the exact production modules.
-- Audible native smoke: light, original heavy, new heavy, evolved heavy, overload,
-- mute and cleanup. Does not modify a player's gameplay or persistence.
local Client = game:GetService("StarterPlayer").StarterPlayerScripts.Client
local SoundEffects = require(Client.SoundEffects)
local Signatures = require(game:GetService("ReplicatedStorage").Shared.ItemFeedback)
local audio = SoundEffects.new()
local report = { loaded = false, samples = {}, maxVolume = 0, maxActive = 0, maxPending = 0 }
local ok, failure = pcall(function()
    local deadline = os.clock() + 15
    while not audio.toneVoices[1].sound.IsLoaded and os.clock() < deadline do
        task.wait(0.1)
    end
    assert(audio.toneVoices[1].sound.IsLoaded, "C4 source did not load")
    report.loaded = true
    for _, id in { "resonator", "spring_coil", "moss_capacitor", "bubble_reactor" } do
        assert(audio:playItem(id), "Native motif did not schedule: " .. id)
        local sample =
            { id = id, weight = Signatures.Profiles[id].weight, minPitch = 10, active = 0 }
        for _ = 1, 30 do
            task.wait(0.016)
            for _, voice in audio.toneVoices do
                if voice.sound.IsPlaying then
                    sample.active += 1
                    sample.minPitch = math.min(sample.minPitch, voice.sound.PlaybackSpeed)
                end
            end
        end
        assert(sample.active > 0, "No native playing voices: " .. id)
        if sample.weight == "heavy" then
            assert(sample.minPitch < 0.39, "Native impact never reached bass register: " .. id)
        else
            assert(sample.minPitch >= 1, "Light motif unexpectedly dropped into bass")
        end
        table.insert(report.samples, sample)
    end
    for _ = 1, 90 do
        for id in Signatures.Profiles do
            audio:playItem(id)
        end
        task.wait(0.016)
        local active, total = 0, 0
        for _, voice in audio.toneVoices do
            total += voice.sound.Volume
            if voice.sound.IsPlaying then
                active += 1
            end
        end
        assert(
            total <= Signatures.AudioLimits.mixVolume + 1e-6,
            "Native item mix exceeded headroom"
        )
        assert(active <= 12 and #audio.pendingNotes <= 32, "Native sound pool exceeded bounds")
        report.maxVolume = math.max(report.maxVolume, total)
        report.maxActive = math.max(report.maxActive, active)
        report.maxPending = math.max(report.maxPending, #audio.pendingNotes)
    end
    audio:setMuted(true)
    assert(audio.group.Volume == 0 and #audio.pendingNotes == 0, "Mute left pending audible work")
    assert(not audio:playItem("bubble_reactor"), "Muted item scheduled")
    for _, voice in audio.toneVoices do
        assert(
            not voice.sound.IsPlaying and voice.sound.Volume == 0,
            "Mute left a native voice playing"
        )
    end
end)
audio:destroy()
assert(
    audio.folder.Parent == nil and audio.group.Parent == nil,
    "Audio objects leaked after destruction"
)
assert(ok, failure)
print("PASS audio smoke: " .. game:GetService("HttpService"):JSONEncode(report))
return report
