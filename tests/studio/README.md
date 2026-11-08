# Eight-client arcade smoke test

These two opt-in scripts are **not** mapped by `default.project.json`. Use only an
isolated generated development place with one Studio operator and Rojo disconnected.
The harness starts runs, launches and ends shots, changes view, and disconnects one
test player. Never install it in a shared or published experience.

1. Build the current source and open the generated place. Stop play.
2. Create `ServerScriptService.ArcadeMultiQA` as a Script with the exact source of
   [ArcadeSmoke.server.luau](ArcadeSmoke.server.luau).
3. Create `StarterPlayer.StarterPlayerScripts.ArcadeMultiQA` as a LocalScript with
   the exact source of [ArcadeSmoke.client.luau](ArcadeSmoke.client.luau).
4. Through the selected Studio MCP Edit DataModel, execute:

   ```lua
   return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(8, "ArcadeEightClients")
   ```

5. Inspect the returned report: `ok = true`, `maxPlayers = 8`, eight entries for
   ready/start/launch/hub/resume, seven idle entries, and a cleared departed station.
   The client readiness check waits for camera, GUI and character state rather
   than assuming a fixed startup duration.
6. Stop the test if needed. Remove only the two exact temporary scripts above.
   Verify the normal source is intact and return the isolated place to Edit.

The test checks distinct station allocation, independent runs, in-flight return
rejection, board/hub camera and character restoration, resume and departure.
It is eight native Studio clients, not a measurement of eight physical devices or
production network performance. `ArcadeSessions.spec.luau` additionally covers
overflow rejection, freed-station reuse, record isolation and victory-to-Endless resume.
