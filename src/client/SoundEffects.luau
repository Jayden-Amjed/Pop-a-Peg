-- Public Roblox / licensed Creator Store audio. Provenance is in docs/ASSETS.md.
local SoundService = game:GetService("SoundService")
local ContentProvider = game:GetService("ContentProvider")

local SoundEffects = {}
SoundEffects.__index = SoundEffects

SoundEffects.Cues = {
    pop = { id = 9119669074, volume = 0.24, pitch = 1.5, duration = 0.2, gap = 0.055 },
    click = { id = 9119669074, volume = 0.16, pitch = 1.9, duration = 0.1, gap = 0.08 },
    launch = { id = 9119669074, volume = 0.25, pitch = 0.8, duration = 0.32, gap = 0.15 },
    coin = { id = 127645268874265, volume = 0.3, pitch = 1.1, duration = 0.65, gap = 0.09 },
    purchase = { id = 127645268874265, volume = 0.38, pitch = 0.94, duration = 1.5, gap = 0.15 },
    goal = { id = 9119642864, volume = 0.22, pitch = 1.4, duration = 0.7, gap = 0.2 },
    restock = { id = 9114210044, volume = 0.27, pitch = 1.15, duration = 0.36, gap = 0.12 },
    merge = { id = 9114210044, volume = 0.2, pitch = 1.7, duration = 0.19, gap = 0.07 },
    trigger = { id = 9126132550, volume = 0.12, pitch = 1.2, duration = 0.16, gap = 0.075 },
    clear = { id = 9119642864, volume = 0.3, pitch = 0.95, duration = 1.5, gap = 0.6 },
}

function SoundEffects.new()
    local self = setmetatable(
        { pools = {}, lastPlayed = {}, serial = 0, muted = false, loaded = {} },
        SoundEffects
    )
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
    self.folder:Destroy()
    self.group:Destroy()
end

return SoundEffects
