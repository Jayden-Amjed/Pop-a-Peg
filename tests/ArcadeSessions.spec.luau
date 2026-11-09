local ArcadeSessions = if script
    then require(game:GetService("ServerScriptService").Server.ArcadeSessions)
    else require("../src/server/ArcadeSessions")
local playtestAccess = if script
    then require(script.Parent["PlaytestAccess.spec"])
    else require("./PlaytestAccess.spec")

return function()
    local arcade = ArcadeSessions.new()
    for id = 1, 8 do
        local session = arcade:add(id, "Player " .. id, { bestRound = id })
        assert(session and session.station == id and session.view == "hub", "Join gets unique pod")
        assert(session.run == nil, "Joining does not begin a run")
    end
    assert(not arcade:add(9, "Overflow"), "Only eight stations may be occupied")
    assert(not arcade:add(1, "Duplicate"), "Duplicate joins do not allocate a station")
    assert(#arcade:roster() == 8, "All eight players appear in roster")
    assert(not arcade:action(1, "buy", { index = 1 }), "Hub cannot change a run")
    assert(arcade:action(1, "startRun", {}, 123))
    assert(arcade:action(2, "startRun", {}, 123))
    local a, b = arcade.players[1].run, arcade.players[2].run
    assert(arcade:snapshot(1).runId == 1, "First run receives identity")
    assert(
        a ~= b and a.inventory ~= b.inventory and a.values ~= b.values,
        "Runs do not share tables"
    )
    a.coins = 50
    assert(b.coins ~= 50, "Run power is private")
    assert(not arcade:action(1, "startRun", {}, 456), "Duplicate start preserves active run")
    assert(arcade:action(1, "enterHub"))
    assert(arcade:snapshot(1).hub.canResume, "Paused run is resumable")
    assert(arcade:action(1, "startRun", {}, 999))
    assert(arcade.players[1].run == a and a.coins == 50, "Resume keeps the exact run")
    assert(arcade:action(1, "launch", { angle = 0 }))
    assert(not arcade:action(1, "enterHub"), "Flight cannot be paused through hub")
    local before = a.elapsed
    arcade:step(0.1)
    assert(a.elapsed > before and b.elapsed == 0, "Only the correct shot advances")
    a.phase = "settling"
    assert(not arcade:action(1, "enterHub"), "Settlement remains authoritative")
    a.phase = "shop"
    a.unlocks.aurora_aquarium = true
    a.bestRound = 15
    assert(arcade:action(1, "enterHub"))
    before = a.elapsed
    arcade:step(0.2)
    assert(a.elapsed == before, "Parked runs do not advance")
    local hub = arcade:snapshot(1)
    assert(hub.hub.profile.bestRound == 15, "Hub receives best round")
    assert(table.find(hub.hub.profile.unlocks, "aurora_aquarium"), "Earned discovery reaches hub")
    assert(
        hub.hub.players[1].inventory == nil and hub.hub.players[1].coins == nil,
        "Roster excludes power"
    )
    hub.hub.profile.bestRound = 999
    assert(arcade.players[1].profile.bestRound == 15, "Snapshots cannot mutate records")
    assert(arcade:action(1, "startRun", {}, 42))
    a.phase = "victory"
    a.round = 101 -- Successful round 100 settlement has already advanced the round.
    assert(arcade:action(1, "enterHub"))
    assert(arcade:snapshot(1).hub.canResume, "Winning builds keep their endless option")
    assert(arcade:action(1, "startRun", {}, 42))
    assert(arcade.players[1].run == a and a.phase == "victory", "Resume preserves victory")
    assert(arcade:action(1, "endless"), "Resumed victory can enter endless")
    assert(a.round == 101 and arcade:snapshot(1).runId == 1, "Endless retains the run identity")
    a.phase = "gameover"
    assert(arcade:action(1, "enterHub"))
    assert(not arcade:snapshot(1).hub.canResume, "Lost runs offer new play")
    assert(arcade:action(1, "startRun", {}, 456))
    local fresh = arcade.players[1].run
    assert(arcade:snapshot(1).runId == 2, "New run gets fresh receipt identity")
    assert(fresh ~= a and fresh.round == 1 and fresh.coins ~= 50, "Fresh runs reset power")
    assert(fresh.bestRound == 15 and fresh.unlocks.aurora_aquarium, "Fresh runs keep discoveries")
    local departed = arcade:remove(1)
    assert(departed.profile.bestRound == 15 and #arcade:roster() == 7, "Departure captures profile")
    assert(arcade:add(9, "Replacement").station == 1, "Freed station is reusable")
    assert(not arcade:action(1, "startRun"), "Departed players cannot act")
    assert(arcade:snapshot(1) == nil, "Departure removes snapshots")
    assert(arcade.players[2].run == b, "Joining/leaving does not reset another run")
    for id = 2, 9 do
        arcade:remove(id)
    end
    assert(#arcade:roster() == 0 and next(arcade.stations) == nil, "Empty server frees all pods")
    print(
        "PASS arcade sessions: eight stations, isolation, pause/resume, records, departure and reuse"
    )
    playtestAccess()
end
