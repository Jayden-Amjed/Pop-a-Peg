-- Opt-in UI fixture, NEVER mapped into game builds. Disable normal Main in Edit,
-- install this in ServerScriptService, then Play an isolated unpublished place.
-- Remove the fixture and restore Main.Disabled=false after the test.
assert(game:GetService("RunService"):IsStudio() and game.GameId == 0, "Isolated Studio only")
local main = game.ServerScriptService.Server.Main
assert(main.Disabled, "Disable normal Main before seeding the isolated fixture")
local players = game:GetService("Players")
local deadline = os.clock() + 20
repeat
    task.wait(0.1)
until #players:GetPlayers() > 0 or os.clock() >= deadline
assert(#players:GetPlayers() == 1, "One UI test player required")
local player = players:GetPlayers()[1]
local Profile = require(game.ReplicatedStorage.Shared.Profile)
local Store = require(game.ServerScriptService.Server.ProfileStore)
local saved, mode = Store.save(player.UserId, Profile.clean({ restockCredits = 350 }))
assert(saved and mode == "session", "Fixture must use in-memory storage")
main.Disabled = false
