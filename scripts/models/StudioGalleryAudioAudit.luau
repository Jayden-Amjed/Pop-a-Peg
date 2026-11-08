-- Client-only, bounded QA for real Sound instances. The caller pauses/mutes the
-- visible inspector first. This owns a separate controller and cleans it up.
-- IsPlaying/time advancement are engine evidence, not proof of human audibility.
return function(first, last)
    local started = os.clock()
    local deadline = started + 40
    local report = {
        schema = 1,
        ok = false,
        requested = 0,
        checked = 0,
        passed = 0,
        failed = 0,
        items = {},
        failures = {},
        unrun = {},
        assets = {},
        loadedAssetFailures = {},
        maximumLiveVoices = 0,
        maximumLiveToneVoices = 0,
        maximumPendingNotes = 0,
        maximumTotalVolume = 0,
        maximumPlaybackLoudness = 0,
        scope = "Real asset loading, Sound.IsPlaying, advancing TimePosition, positive finite gain, bounded voices, cancellation and disposal. No recorded output or human-listening claim.",
    }
    local function finish()
        report.elapsedSeconds = os.clock() - started
        report.ok = report.checked == report.requested
            and report.failed == 0
            and #report.failures == 0
            and #report.unrun == 0
            and #report.loadedAssetFailures == 0
        return report
    end
    if not game:GetService("RunService"):IsClient() then
        table.insert(report.failures, "Run in the dedicated gallery Client DataModel")
        return finish()
    end
    local library = game:GetService("ReplicatedStorage"):FindFirstChild("CatalogLibrary")
    if not library then
        table.insert(report.failures, "Missing CatalogLibrary")
        return finish()
    end
    local loaded, Audio, Timeline, catalog = pcall(function()
        return require(library.GalleryAudio),
            require(library.GallerySoundTimeline),
            require(library.CatalogInfo)
    end)
    if not loaded then
        table.insert(report.failures, "Audio dependencies failed: " .. tostring(Audio))
        return finish()
    end
    local function index(value, fallback)
        if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
            return fallback
        end
        return math.clamp(math.floor(value), 1, #catalog)
    end
    first, last = index(first, 1), index(last, #catalog)
    if first > last or last - first + 1 > 26 then
        table.insert(report.failures, "Request an ordered batch of at most 26 models")
        return finish()
    end
    report.first, report.last, report.requested = first, last, last - first + 1
    local created, audio = pcall(Audio.new)
    if not created then
        table.insert(report.failures, "Could not create audio controller: " .. tostring(audio))
        return finish()
    end
    audio:setVolume(0.35)
    local backend = audio.sounds
    local folder, group = backend.folder, backend.group
    local closed = false
    local uniqueAssets, preload = {}, {}
    for _, sound in folder:GetChildren() do
        if sound:IsA("Sound") and not uniqueAssets[sound.SoundId] then
            uniqueAssets[sound.SoundId] = sound
            table.insert(preload, sound)
        end
    end
    local preloadDone = false
    task.spawn(function()
        local success, problem = pcall(function()
            game:GetService("ContentProvider"):PreloadAsync(preload, function(id, status)
                if not closed then
                    report.assets[id] = status.Name
                end
            end)
        end)
        if not closed and not success then
            table.insert(report.failures, "ContentProvider preload error: " .. tostring(problem))
        end
        preloadDone = true
    end)

    local function finite(value)
        return type(value) == "number" and value == value and math.abs(value) < math.huge
    end
    local function assertStopped(label)
        assert(#backend.pendingNotes == 0, label .. ": pending notes survived")
        for _, sound in folder:GetChildren() do
            if sound:IsA("Sound") then
                assert(not sound.IsPlaying, label .. ": a Sound remains playing")
            end
        end
        for _, voice in backend.toneVoices do
            assert(voice.duration == 0, label .. ": active tone envelope survived")
        end
    end
    local function sourceVoices(event)
        local result = {}
        if event.kind == "item" then
            for _, voice in backend.toneVoices do
                table.insert(result, voice.sound)
            end
        else
            for _, voice in backend.pools[event.id].voices do
                table.insert(result, voice.sound)
            end
        end
        return result
    end
    local function inspectMix()
        local live, volume = 0, 0
        for _, sound in folder:GetChildren() do
            if sound:IsA("Sound") then
                assert(finite(sound.Volume) and sound.Volume >= 0, "Invalid Sound.Volume")
                assert(
                    finite(sound.TimePosition) and sound.TimePosition >= 0,
                    "Invalid TimePosition"
                )
                if sound.IsPlaying then
                    live += 1
                    volume += sound.Volume * group.Volume
                end
            end
        end
        assert(finite(volume), "Nonfinite total volume")
        assert(live <= 42, "Live voices exceeded 12 tones plus ten three-voice cue pools")
        assert(#backend.pendingNotes <= 32, "Pending-note budget exceeded")
        local tones = 0
        for _, voice in backend.toneVoices do
            if voice.sound.IsPlaying then
                tones += 1
            end
        end
        assert(tones <= 12, "Live tone budget exceeded")
        report.maximumLiveVoices = math.max(report.maximumLiveVoices, live)
        report.maximumLiveToneVoices = math.max(report.maximumLiveToneVoices, tones)
        report.maximumPendingNotes = math.max(report.maximumPendingNotes, #backend.pendingNotes)
        report.maximumTotalVolume = math.max(report.maximumTotalVolume, volume)
    end

    local successful, problem = pcall(function()
        local preloadDeadline = math.min(deadline, os.clock() + 8)
        while not preloadDone and os.clock() < preloadDeadline do
            task.wait(0.03)
        end
        for id, sound in uniqueAssets do
            if not sound.IsLoaded then
                table.insert(report.loadedAssetFailures, id)
            end
        end
        if not preloadDone then
            table.insert(report.failures, "ContentProvider preload exceeded eight seconds")
        end

        for itemIndex = first, last do
            local id = catalog[itemIndex].id
            if os.clock() > deadline - 2 then
                table.insert(report.unrun, id)
                continue
            end
            local entry = { id = id, ok = false, scheduled = 0, fired = 0, observed = 0, cues = {} }
            table.insert(report.items, entry)
            report.checked += 1
            local passed, reason = pcall(function()
                local events = Timeline.forId(id)
                assert(events and #events > 0, "Missing sound timeline")
                entry.scheduled = #events
                assert(audio:start(id), "Timeline did not start")
                local before = audio.fired
                local cursor = 1
                while cursor <= #events do
                    local phase = events[cursor].phase
                    local observations = {}
                    local hasMotif = false
                    while cursor <= #events and events[cursor].phase == phase do
                        local event = events[cursor]
                        hasMotif = hasMotif or event.kind == "item"
                        local observation = {
                            kind = event.kind,
                            id = event.id,
                            phase = phase,
                            playing = false,
                            advancing = false,
                            positiveGain = false,
                            peakLoudness = 0,
                        }
                        table.insert(entry.cues, observation)
                        table.insert(
                            observations,
                            { result = observation, voices = sourceVoices(event), positions = {} }
                        )
                        cursor += 1
                    end
                    audio:step(phase)
                    -- Let the complete short motif run, including later notes.
                    local observeUntil =
                        math.min(deadline, os.clock() + (if hasMotif then 0.40 else 0.16))
                    repeat
                        inspectMix()
                        for _, sample in observations do
                            local observation = sample.result
                            for _, sound in sample.voices do
                                if sound.IsPlaying and sound.IsLoaded then
                                    observation.playing = true
                                    if sound.Volume * group.Volume > 0 then
                                        observation.positiveGain = true
                                    end
                                    local previous = sample.positions[sound]
                                    if previous and sound.TimePosition > previous + 0.0001 then
                                        observation.advancing = true
                                    end
                                    sample.positions[sound] = sound.TimePosition
                                    local readable, loudness = pcall(function()
                                        return sound.PlaybackLoudness
                                    end)
                                    if readable and finite(loudness) then
                                        observation.peakLoudness =
                                            math.max(observation.peakLoudness, loudness)
                                        report.maximumPlaybackLoudness =
                                            math.max(report.maximumPlaybackLoudness, loudness)
                                    end
                                end
                            end
                        end
                        task.wait(0.016)
                    until os.clock() >= observeUntil
                    for _, sample in observations do
                        local got = sample.result
                        assert(
                            got.playing and got.advancing and got.positiveGain,
                            "No advancing positive-gain Sound observed for "
                                .. got.kind
                                .. ":"
                                .. got.id
                        )
                        entry.observed += 1
                    end
                end
                entry.fired = audio.fired - before
                assert(entry.fired == entry.scheduled, "Logical cue count differs")
                audio:suspend()
                assertStopped("Pause")
                audio:resume(1)
                assert(audio:step(1) == 0, "Resume replayed completed cues")
            end)
            audio:stop()
            entry.ok = passed
            if passed then
                report.passed += 1
            else
                report.failed += 1
                entry.error = tostring(reason)
            end
        end

        audio:start("coin")
        audio:step(0.30)
        task.wait(0.025)
        audio:setMuted(true)
        assert(group.Volume == 0, "Mute left the SoundGroup audible")
        assertStopped("Mute")
        audio:start("chest_common")
        assert(audio:step(1) == 0, "Muted trigger emitted cues")
        audio:setMuted(false)
        assert(audio:step(1) == 0, "Unmute replayed skipped cues")
        report.cancellation = "PASS pause/resume, mute and stale-cue suppression"
    end)
    if not successful then
        table.insert(report.failures, tostring(problem))
    end
    closed = true
    local cleanupOk, cleanupProblem = pcall(function()
        audio:destroy()
        audio:destroy()
        assert(folder.Parent == nil and group.Parent == nil, "Audio instances survived disposal")
        assert(not backend.toneConnection.Connected, "Audio Heartbeat survived disposal")
        assert(not audio:start("coin") and audio:step(1) == 0, "Disposed controller resumed")
    end)
    report.cleanup = cleanupOk
    if not cleanupOk then
        table.insert(report.failures, "Audio cleanup: " .. tostring(cleanupProblem))
    end
    return finish()
end
