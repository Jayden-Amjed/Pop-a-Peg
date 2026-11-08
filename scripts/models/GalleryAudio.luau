-- One sound controller for the selected model, including native comparison.
-- A seek is silent; only explicit start/resume can advance the cue cursor.
local Timeline = if script
    then require(script.Parent.GallerySoundTimeline)
    else require("./GallerySoundTimeline")
local GalleryAudio = {}
GalleryAudio.__index = GalleryAudio

local function pose(value)
    if type(value) ~= "number" or value ~= value then
        return 0
    end
    return math.clamp(value, 0, 1)
end

function GalleryAudio.new(sounds)
    if not sounds then
        sounds = require(script.Parent.GallerySoundEngine).new()
    end
    return setmetatable({
        sounds = sounds,
        events = {},
        cursor = 1,
        lastPose = 0,
        active = false,
        muted = false,
        starts = 0,
        fired = 0,
        lastEvent = "",
    }, GalleryAudio)
end

function GalleryAudio:stop()
    if self.destroyed then
        return
    end
    self.active = false
    self.sounds:stopAll()
end

function GalleryAudio:start(id, fromPose)
    if self.destroyed then
        return false
    end
    self:stop()
    self.events = Timeline.forId(id) or {}
    self.id, self.cursor, self.lastPose = id, 1, pose(fromPose)
    -- Starting from a scrubbed pose never dumps all preceding notes at once.
    while self.events[self.cursor] and self.events[self.cursor].phase < self.lastPose do
        self.cursor += 1
    end
    self.active = #self.events > 0
    self.starts += 1
    return self.active
end

function GalleryAudio:suspend()
    self:stop()
end

function GalleryAudio:resume(fromPose)
    if self.destroyed then
        return
    end
    self:stop()
    self.lastPose = pose(fromPose)
    -- Resume preserves the consumed cursor, and skips any silently scrubbed gap.
    while self.events[self.cursor] and self.events[self.cursor].phase <= self.lastPose do
        self.cursor += 1
    end
    self.active = true
end

function GalleryAudio:step(currentPose)
    if self.destroyed or not self.active then
        return 0
    end
    local current = pose(currentPose)
    if current < self.lastPose then
        -- A loop/restart must call start explicitly. A backward seek cannot
        -- replay the whole sequence accidentally or leave an old voice running.
        self:stop()
        self.lastPose = current
        return 0
    end
    local count = 0
    while self.events[self.cursor] and self.events[self.cursor].phase <= current do
        local event = self.events[self.cursor]
        self.cursor += 1
        if not self.muted then
            if event.kind == "item" then
                self.sounds:playItem(event.id, event.gain)
            else
                self.sounds:play(event.id, event.pitch, event.gain)
            end
            count += 1
            self.fired += 1
            self.lastEvent = event.id
        end
    end
    self.lastPose = current
    return count
end

function GalleryAudio:setMuted(muted)
    if self.destroyed then
        return
    end
    self.muted = muted == true
    self.sounds:setMuted(self.muted)
end

function GalleryAudio:setVolume(volume)
    if not self.destroyed then
        self.sounds:setVolume(volume)
    end
end

function GalleryAudio:destroy()
    if self.destroyed then
        return
    end
    self:stop()
    self.destroyed = true
    self.sounds:destroy()
end

return GalleryAudio
