local Stages = if script
    then require(game:GetService("ReplicatedStorage").Shared.Stages)
    else require("../src/shared/Stages")

return function()
    assert(Stages.CampaignEnd == 100, "Campaign goal must match the fourth level")
    local boundaries = {
        { 1, 1, 1, 15 },
        { 15, 1, 1, 15 },
        { 16, 2, 16, 40 },
        { 40, 2, 16, 40 },
        { 41, 3, 41, 65 },
        { 65, 3, 41, 65 },
        { 66, 4, 66, 100 },
        { 100, 4, 66, 100 },
        { 101, 5, 101, 150 },
        { 150, 5, 101, 150 },
        { 151, 6, 151, 200 },
        { 200, 6, 151, 200 },
        { 201, 7, 201, 250 },
    }
    for _, case in boundaries do
        local round, index, first, target = table.unpack(case)
        local stage = Stages.forRound(round)
        assert(
            stage.index == index and stage.startRound == first and stage.targetRound == target,
            "Round assigned to the wrong level"
        )
        assert(stage.completed == round - first, "Only earlier rounds count before settlement")
        assert(stage.progress >= 0 and stage.progress < 1, "Arrival cannot complete a level")
        assert(not stage.cleared, "A failed attempt on the target must leave its level open")
        local cleared = Stages.completed(round)
        if round == target then
            assert(cleared and cleared.cleared and cleared.progress == 1, "Goal did not clear")
            assert(
                cleared.completed == target - first + 1,
                "The successful target round must count toward completion"
            )
        else
            assert(cleared == nil, "An intermediate round cannot clear a level")
        end
    end

    local previous
    for round = 1, 500 do
        local stage = Stages.forRound(round)
        if previous and previous.index == stage.index then
            assert(stage.progress > previous.progress, "Progress must rise inside a level")
        elseif previous then
            assert(stage.index == previous.index + 1, "Level sequence skipped an index")
            assert(stage.progress == 0, "New level begins with empty progress")
            assert(stage.startRound == previous.targetRound + 1, "Levels overlap or leave a gap")
        end
        previous = stage
    end

    for _, invalid in { -1, 0, 15.5, math.huge, -math.huge, 0 / 0, "15", false, {} } do
        assert(Stages.completed(invalid) == nil, "Invalid round cannot earn a clear")
        local stage = Stages.forRound(invalid)
        assert(
            stage.index >= 1 and stage.progress >= 0 and stage.progress < 1,
            "Invalid input produced unsafe stage data"
        )
    end
    assert(Stages.completed(nil) == nil, "Missing round cannot earn a clear")
    assert(Stages.forRound(nil).index == 1, "Missing round should show the first goal")
    assert(Stages.forRound(15.9).targetRound == 15, "Fractional display rounds round down")
    assert(Stages.forRound(1000000).targetRound == 1000000, "Endless goals must stay bounded")
    assert(Stages.forRound(1e300).targetRound <= 9007199254740900, "Round precision overflow")

    local changed = Stages.completed(15)
    changed.name = "Changed"
    assert(Stages.forRound(15).name == "Meadow Shore", "Returned stage data must be independent")
    print("PASS stages: continuous goals, successful-clear descriptors, endless and invalid inputs")
end
