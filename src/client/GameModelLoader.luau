-- Injectable scheduling keeps hung/late asset requests from consuming the whole
-- preload queue. Only the first completion can release a worker slot.
local Loader = {}

function Loader.new(options)
    assert(type(options.load) == "function", "Asset loader callback required")
    assert(
        type(options.defer) == "function" and type(options.delay) == "function",
        "Task scheduling required"
    )
    assert(type(options.cancel) == "function", "Task cancellation required")
    local limit, timeout = options.limit or 4, options.timeout or 15
    assert(
        limit >= 1 and limit <= 8 and timeout > 0 and timeout < math.huge,
        "Invalid preload bounds"
    )
    local records, queue, active = {}, {}, 0
    local scheduler, pump = {}, nil

    pump = function()
        while active < limit and #queue > 0 do
            local id = table.remove(queue, 1)
            local record = records[id]
            record.phase = "Fetching"
            active += 1
            local completed, worker, deadline = false, nil, nil
            local function fail(message)
                if not completed then
                    table.insert(record.failures, tostring(message))
                end
            end
            local function finish(message)
                if completed then
                    return false
                end
                if message then
                    fail(message)
                end
                completed = true
                if deadline then
                    options.cancel(deadline)
                    deadline = nil
                end
                record.state = if #record.failures == 0 then "Ready" else "Failed"
                record.phase = "Complete"
                active -= 1
                if record.state == "Failed" and options.onFailure then
                    pcall(options.onFailure, id, record.failures)
                end
                pump()
                return true
            end
            deadline = options.delay(timeout, function()
                -- Do not try to cancel this currently executing timer.
                deadline = nil
                if
                    finish("Asset preload exceeded " .. tostring(timeout) .. " seconds") and worker
                then
                    options.cancel(worker)
                end
            end)
            worker = options.defer(function()
                local ok, failure = pcall(options.load, id, fail)
                finish(if ok then nil else tostring(failure))
            end)
        end
    end

    function scheduler:request(id)
        if records[id] then
            return records[id]
        end
        local record = { state = "Loading", phase = "Queued", failures = {} }
        records[id] = record
        table.insert(queue, id)
        pump()
        return record
    end

    function scheduler:get(id)
        return records[id]
    end

    function scheduler:inspect()
        return { active = active, queued = #queue, limit = limit, timeout = timeout }
    end

    return scheduler
end

return Loader
