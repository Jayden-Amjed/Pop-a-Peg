-- Public Roblox / licensed Creator Store audio. Provenance is in docs/ASSETS.md.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")
local RunService = game:GetService("RunService")
local Signatures = require(game:GetService("ReplicatedStorage").Shared.ItemFeedback)

local SoundEffects = {}
SoundEffects.__index = SoundEffects

SoundEffects.Cues = {
    pop = { id = 9119319842, volume = 0.3, pitch = 1.45, duration = 0.24, gap = 0.045 },
    click = { id = 9119669074, volume = 0.16, pitch = 1.9, duration = 0.1, gap = 0.08 },
    launch = { id = 9119319842, volume = 0.23, pitch = 0.9, duration = 0.3, gap = 0.15 },
    coin = { id = 127645268874265, volume = 0.3, pitch = 1.1, duration = 0.65, gap = 0.09 },
    purchase = { id = 127645268874265, volume = 0.38, pitch = 0.94, duration = 1.5, gap = 0.15 },
    goal = { id = 9119642864, volume = 0.22, pitch = 1.4, duration = 0.7, gap = 0.2 },
    restock = { id = 9114210044, volume = 0.25, pitch = 0.78, duration = 0.40, gap = 0.12 },
    merge = { id = 9114210044, volume = 0.18, pitch = 1.15, duration = 0.23, gap = 0.07 },
    trigger = { id = 9126132550, volume = 0.12, pitch = 1.2, duration = 0.16, gap = 0.075 },
    clear = { id = 9119642864, volume = 0.3, pitch = 0.95, duration = 1.5, gap = 0.6 },
}

SoundEffects.ToneAsset = 77129402344871
SoundEffects.MaxToneVoices = Signatures.AudioLimits.voices
SoundEffects.MaxPendingNotes = Signatures.AudioLimits.pending

function SoundEffects.new()
    local self = setmetatable({
        pools = {},
        lastPlayed = {},
        serial = 0,
        muted = false,
        loaded = {},
        toneVoices = {},
        pendingNotes = {},
        itemLastPlayed = {},
        toneTokens = 6,
    }, SoundEffects)
    self.folder = Instance.new("Folder")
    self.folder.Name = "PegSoundEffects"
    self.folder.Parent = SoundService
    self.group = Instance.new("SoundGroup")
    self.group.Name = "GameFeedback"
    self.group.Volume = 0.7
    self.group.Parent = SoundService
    local preload = {}
    local seen = {}
    for name, cue in pairs(SoundEffects.Cues) do
        local pool = {}
        for index = 1, 3 do
            local sound = Instance.new("Sound")
            sound.Name = name .. index
            sound.SoundId = "rbxassetid://" .. cue.id
            sound.SoundGroup = self.group
            sound.Volume = cue.volume
            sound.Parent = self.folder
            table.insert(pool, { sound = sound, serial = 0 })
            if not seen[cue.id] then
                seen[cue.id] = true
                table.insert(preload, sound)
            end
        end
        self.pools[name] = { voices = pool, nextVoice = 1 }
    end
    for index = 1, SoundEffects.MaxToneVoices do
        local sound = Instance.new("Sound")
        sound.Name = "SineVoice" .. index
        sound.SoundId = "rbxassetid://" .. SoundEffects.ToneAsset
        sound.SoundGroup = self.group
        sound.Volume = 0
        sound.Parent = self.folder
        table.insert(self.toneVoices, { sound = sound, age = 0, duration = 0 })
        if index == 1 then
            table.insert(preload, sound)
        end
    end
    self.toneConnection = RunService.Heartbeat:Connect(function(dt)
        self:_stepTones(math.min(dt, 0.1))
    end)
    task.spawn(function()
        pcall(function()
            ContentProvider:PreloadAsync(preload, function(id, status)
                if not self.destroyed then
                    self.loaded[id] = status == Enum.AssetFetchStatus.Success
                end
            end)
        end)
    end)
    return self
end

function SoundEffects:setMuted(muted)
    self.muted = muted == true
    self.group.Volume = if self.muted then 0 else 0.7
    if self.muted then
        self:clearItems()
    end
end

function SoundEffects:clearItems()
    table.clear(self.pendingNotes)
    for _, voice in ipairs(self.toneVoices) do
        voice.sound:Stop()
        voice.sound.Volume = 0
        voice.duration = 0
    end
end

function SoundEffects:playItem(id)
    if self.destroyed or self.muted or not Signatures.Profiles[id] then
        return false
    end
    local now = os.clock()
    if now - (self.itemLastPlayed[id] or -100) < 0.14 or self.toneTokens < 1 then
        return false
    end
    local notes = Signatures.sound(id)
    if #self.pendingNotes + #notes > SoundEffects.MaxPendingNotes then
        return false
    end
    self.itemLastPlayed[id] = now
    self.toneTokens -= 1
    for _, note in ipairs(notes) do
        table.insert(self.pendingNotes, note)
    end
    return true
end

function SoundEffects:_stepTones(dt)
    if self.destroyed then
        return
    end
    self.toneTokens = math.min(6, self.toneTokens + dt * 12)
    local totalVolume = 0
    for _, voice in ipairs(self.toneVoices) do
        if voice.duration > 0 then
            voice.age += dt
            local t = voice.age / voice.duration
            if t >= 1 then
                voice.sound:Stop()
                voice.sound.Volume = 0
                voice.duration = 0
            else
                local gain, pitch = Signatures.soundSample(voice.note, voice.age)
                voice.gain = gain
                voice.sound.PlaybackSpeed = pitch
                totalVolume += gain
            end
        end
    end
    -- Reserve headroom even when many low oscillators briefly line up in phase.
    -- This only scales item voices; coin/goal cues keep their separate mix space.
    local mixGain = Signatures.mixGain(totalVolume)
    for _, voice in ipairs(self.toneVoices) do
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
            for _, voice in ipairs(self.toneVoices) do
                if voice.duration == 0 then
                    available = voice
                    break
                end
                if not available or voice.age > available.age then
                    available = voice
                end
            end
            if available and available.sound.IsLoaded and not self.muted then
                available.age, available.duration = 0, note.duration
                available.note = note
                available.sound:Stop()
                available.sound.TimePosition = 0.04
                available.sound.PlaybackSpeed = note.pitch
                available.sound.Volume = 0
                available.sound:Play()
            end
        end
    end
end

function SoundEffects:play(name, pitch)
    local cue = SoundEffects.Cues[name]
    if self.destroyed or self.muted or not cue then
        return
    end
    local now = os.clock()
    if now - (self.lastPlayed[name] or -100) < cue.gap then
        return
    end
    self.lastPlayed[name] = now
    local pool = self.pools[name]
    local voice = pool.voices[pool.nextVoice]
    pool.nextVoice = pool.nextVoice % #pool.voices + 1
    local sound = voice.sound
    -- Asset failures should leave a playable silent game, never block a round.
    if not sound.IsLoaded then
        return
    end
    self.serial += 1
    voice.serial = self.serial
    local serial = voice.serial
    sound:Stop()
    sound.TimePosition = 0
    sound.PlaybackSpeed = cue.pitch * math.clamp(pitch or 1, 0.75, 1.4)
    sound:Play()
    task.delay(cue.duration, function()
        if not self.destroyed and voice.serial == serial then
            sound:Stop()
        end
    end)
end

function SoundEffects:destroy()
    if self.destroyed then
        return
    end
    self.destroyed = true
    self.toneConnection:Disconnect()
    self.folder:Destroy()
    self.group:Destroy()
end

return SoundEffects
