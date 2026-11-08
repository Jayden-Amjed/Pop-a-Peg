local Boards = {}
Boards.Categories = {
    { id = "time", field = "playSeconds", title = "MOST TIME PLAYED" },
    { id = "endless", field = "bestEndlessRound", title = "ENDLESS RECORD" },
    { id = "robux", field = "robuxSpent", title = "MOST ROBUX SPENT" },
}

function Boards.value(profile, field)
    local value = profile and profile[field]
    if type(value) ~= "number" or value ~= value or value == math.huge then
        return 0
    end
    return math.clamp(math.floor(value), 0, 1e12)
end

function Boards.rank(entries)
    local ranked = {}
    for _, entry in entries do
        if entry.value > 0 then
            table.insert(ranked, { userId = entry.userId, name = entry.name, value = entry.value })
        end
    end
    table.sort(ranked, function(a, b)
        if a.value == b.value then
            return a.userId < b.userId
        end
        return a.value > b.value
    end)
    while #ranked > 10 do
        table.remove(ranked)
    end
    return ranked
end

function Boards.session(sessions)
    local result = { mode = "session", updatedAt = 0, categories = {} }
    for _, category in Boards.Categories do
        local entries = {}
        for _, session in sessions do
            if not session.loading then
                table.insert(entries, {
                    userId = session.userId,
                    name = session.name,
                    value = Boards.value(session.profile, category.field),
                })
            end
        end
        result.categories[category.id] = { entries = Boards.rank(entries), title = category.title }
    end
    return result
end

return Boards
