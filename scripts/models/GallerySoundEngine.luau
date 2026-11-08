-- Override this gallery instance only. The native SoundEffects source, its game
-- instances and shared ItemFeedback bank remain untouched.
local Bank = if script
    then require(script.Parent.GallerySoundBank)
    else require("./GallerySoundBank")
local Engine = {}

function Engine.playItem(self, id, gain)
    local profile = Bank.Profiles[id]
    if self.destroyed or self.muted or not profile then
        return false
    end
    if self.toneTokens < 1 then
        return false
    end
    local notes = Bank.notes(id, gain)
    if #self.pendingNotes + #notes > Bank.Limits.pending then
        return false
    end
    self.toneTokens -= 1
    for _, note in notes do
        table.insert(self.pendingNotes, note)
    end
    if profile.cue then
        self:play(
            profile.cue,
            profile.cuePitch or 1,
            (profile.cueGain or 0.15) * math.clamp(gain or 1, 0, 1)
        )
    end
    return true
end

function Engine._stepTones(self, dt)
    if self.destroyed then
        return
    end
    self.toneTokens = math.min(6, self.toneTokens + dt * 12)
    local totalVolume = 0
    for _, voice in self.toneVoices do
        if voice.duration > 0 then
            voice.age += dt
            if voice.age >= voice.duration then
                voice.sound:Stop()
                voice.sound.Volume, voice.duration = 0, 0
            else
                local gain, pitch = Bank.sample(voice.note, voice.age)
                voice.gain = gain
                voice.sound.PlaybackSpeed = pitch
                totalVolume += gain
            end
        end
    end
    local mixGain = Bank.mixGain(totalVolume)
    for _, voice in self.toneVoices do
        if voice.duration > 0 then
            voice.sound.Volume = voice.gain * mixGain
        end
    end
    for index = #self.pendingNotes, 1, -1 do
        local note = self.pendingNotes[index]
        note.wait -= dt
        if note.wait <= 0 then
            table.remove(self.pendingNotes, index)
            local available
            for _, voice in self.toneVoices do
                if voice.duration == 0 then
                    available = voice
                    break
                end
                -- Retire the quietest fading partial if all twelve are occupied.
                if not available or (voice.gain or 0) < (available.gain or 0) then
                    available = voice
                end
            end
            if available and available.sound.IsLoaded and not self.muted then
                available.age, available.duration, available.note, available.gain =
                    0, note.duration, note, 0
                available.sound:Stop()
                available.sound.TimePosition = 0.04
                local _, pitch = Bank.sample(note, 0)
                available.sound.PlaybackSpeed, available.sound.Volume = pitch, 0
                available.sound:Play()
            end
        end
    end
end

function Engine.new(backend)
    local self = backend or require(script.Parent.SoundEffects).new()
    self.playItem, self._stepTones = Engine.playItem, Engine._stepTones
    self.galleryBank = Bank
    return self
end

return Engine
