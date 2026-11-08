--!strict

-- Levels are consecutive goals within one run. Reaching a target is not enough:
-- Run calls completed only after that round has settled successfully.
local Stages = { CampaignEnd = 100 }

local campaign = {
    { name = "Meadow Shore", targetRound = 15 },
    { name = "Glass Lagoon", targetRound = 40 },
    { name = "Sunlit Reef", targetRound = 65 },
    { name = "Aurora Ocean", targetRound = 100 },
}

-- The arithmetic stays exact even for a theoretical very long endless run.
local maxRound = 9007199254740900

local function validRound(value: any): boolean
    return type(value) == "number"
        and value == value
        and value >= 1
        and value <= maxRound
        and value % 1 == 0
end

local function normalizedRound(value: any): number
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        return 1
    end
    return math.clamp(math.floor(value), 1, maxRound)
end

function Stages.forRound(value: any)
    local round = normalizedRound(value)
    local index, startRound, targetRound, name = 1, 1, 15, "Meadow Shore"
    if round > Stages.CampaignEnd then
        local endless = math.floor((round - Stages.CampaignEnd - 1) / 50) + 1
        index = #campaign + endless
        startRound = Stages.CampaignEnd + (endless - 1) * 50 + 1
        targetRound = Stages.CampaignEnd + endless * 50
        name = "Endless Current " .. tostring(endless)
    else
        for order, stage in campaign do
            index, targetRound, name = order, stage.targetRound, stage.name
            if round <= targetRound then
                break
            end
            startRound = targetRound + 1
        end
    end
    local completed = round - startRound
    return {
        index = index,
        name = name,
        startRound = startRound,
        targetRound = targetRound,
        completed = completed,
        progress = math.clamp(completed / (targetRound - startRound + 1), 0, 1),
        cleared = false,
    }
end

function Stages.completed(round: any)
    if not validRound(round) then
        return nil
    end
    local stage = Stages.forRound(round)
    if round ~= stage.targetRound then
        return nil
    end
    stage.completed = stage.targetRound - stage.startRound + 1
    stage.progress = 1
    stage.cleared = true
    return stage
end

return Stages
