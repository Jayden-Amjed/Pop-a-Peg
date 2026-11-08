# Studio verification

Use the current task record for observed results and exact tested source identities.
The procedures below describe checks to run; they are not a claim that the current
revision has passed them. Pure layout tests, simulated DataStore failures and native
Studio interaction each cover different boundaries.

## Eight-client arcade smoke test

These two opt-in scripts are **not** mapped by `default.project.json`. Use only an
isolated generated development place with one Studio operator and Rojo disconnected.
The harness starts runs, launches and ends shots, changes view, and disconnects one
test player. Never install it in a shared or published experience.

1. Build the current source and open the generated place. Stop play.
2. Create `ServerScriptService.ArcadeMultiQA` as a Script with the exact source of
   [ArcadeSmoke.server.luau](ArcadeSmoke.server.luau).
3. Create `StarterPlayer.StarterPlayerScripts.ArcadeMultiQA` as a LocalScript with
   the exact source of [ArcadeSmoke.client.luau](ArcadeSmoke.client.luau).
4. Disable `ServerScriptService.Server.Main` in **Edit**. The isolated server
   harness seeds eight distinct Studio session profiles (3–10 Meadow chests,
   13–20 research, 251–258 saved restocks, starter ownership), then enables Main at runtime. It asserts
   Studio mode and cannot contact production storage. Through the selected Edit
   DataModel, execute:

   ```lua
   return game:GetService("StudioTestService"):ExecuteMultiplayerTestAsync(8, "ArcadeEightClients")
   ```

5. Inspect the returned report: `ok = true`, `maxPlayers = 8`, eight entries for
   ready/chestA/chestB/replayA/wrongReplay/research/market/start/runChestReject/launch/hub/resume,
   saved-profile checks, seven idle entries, and a cleared departed station.
   The client readiness check waits for camera, GUI and character state rather
   than assuming a fixed startup duration.
6. Stop the test if needed. Restore Edit `Main.Disabled=false` and remove only the
   two exact temporary scripts above. Verify normal source and return to Edit.

The test checks distinct station allocation, independent runs, in-flight return
rejection, board/hub camera and character restoration, resume and departure.
The market stage buys one Uncommon chest per player, retries the same request,
rejects unaffordable/rebound requests, and checks the saved wallet and visible
hub counter. Run-view purchasing is rejected. Rejection notices are retained by
sequence in the harness so ordinary snapshots cannot erase an acknowledgement.
It also verifies each client sees its own cabinet beacon and exactly one enabled
cabinet prompt, including after returning from a run.
It is eight native Studio clients, not a measurement of eight physical devices or
production network performance. `ArcadeSessions.spec.luau` additionally covers
overflow rejection, freed-station reuse, record isolation and victory-to-Endless resume.

## Model identity and animation audit

Execute the exact contents of `tests/studio/ModelAudit.luau` through the selected
isolated Studio DataModel after installing the production model/motion modules.
The audit creates only unparented models and destroys them after checking:

- All 78 model identities exist, including every equipment, evolution, perk,
  Supply, chest, event emblem and utility.
- Geometry signatures remain distinct after excluding colors, material, names and
  tags; a recolor is not a new object.
- Bounds and part counts stay within the audit's limits; preview parts cannot
  collide, touch or query the game world.
- Declared motion groups exist and activation restores position, size and color.
- Level-five builds remain within bounds.

Record the returned counts and maximum part count in the task. Also view perk
choices, event choices and chest openings natively: geometry assertions alone do
not establish visible figure-eight motion or a readable presentation.

## Hub progression and persistence boundaries

`ProgressionPlay.client.luau` is an opt-in ordinary-action smoke test. Execute it
in a fresh isolated client and inspect `_G.ProgressionPlay` until `running=false`.
It aims using the ordinary preview, clears three rounds, deliberately ends later
shots to reach defeat, opens the earned chest, and asserts that a new run gains
exactly that blueprint. It grants no state. Record its result separately from
the seeded multiplayer fixture.

In an isolated development session, verify the normal chest flow: successfully
clear at least three rounds, finish a defeat, return to the hub, open the earned
chest, and start a new run. Milestones at 15/40/65/100 and each Endless 50 have
separate award contracts. Returning/resuming alone must not add a chest.

For bounded UI coverage, a temporary server-owned fixture may seed known chest
counts and research before player join. Record that fixture separately from normal
gameplay evidence; never add a grant remote or leave it in a production build.
Assert one chest consumed, one new blueprint owned, and a matching request receipt.
For research, check the selected item tier's exact debit and new ownership. Verify
that a parked run keeps its original pool, while a new run can roll the new item.

Retry the same opening request after a different completed request and after
cleaning/reloading the profile. The original result should be acknowledged without
another debit or serial increment. Rebinding that ID to another tier or operation
must fail. The persisted retry history covers the newest 64 operations; do not
describe it as an unbounded historical ledger.

Inspect all three leaderboard categories and their mode labels. Studio should show
session time, a separate Endless record and an honest empty Robux board while
purchases are disabled. Production global calls need separate target-specific
verification. `ProfileRepository.spec.luau` exercises the real adapter against an
injected fake `UpdateAsync`, including callback retries, pre/post-commit timeouts,
lease takeover, release retries and failed-load protection. It does not contact
or prove availability of Roblox's production DataStore service.

## Mobile and safe-area presentation

`RestockPlay.client.luau` runs two ordinary native runs to defeat, using visible
first-hit preview aiming and real shop purchases. It grants no currency or scores,
tracks settled extras against the final hub wallet, and checks receipt size.
Inspect `_G.RestockPlay` after asynchronous completion. Its optional 45-simulated-
second End Shot action is reported separately from natural drains.

`MarketFixture.server.luau` is a separate, explicitly granted 350-restock UI
fixture. It requires unpublished Studio session storage and normal Main disabled
in Edit. Use real hub controls to buy/open chests and compare wallet/receipt state;
this fixture is transaction/UI evidence, never an earning-rate playtest. Remove
the fixture and enable normal Main afterward.

`AudioSmoke.client.luau` checks loaded/playing native light and bass voices,
bounded overlap, mute and cleanup. It does not establish subjective listening
quality or device speaker response.

Exercise both portrait and short landscape viewports, including asymmetric notch
and bottom insets. Inspect the hub dock, chest opening/reveal, workshop item detail,
leaderboard pagination, board aiming, shop and perk/event choices. Verify the
following through actual UI interactions as well as bounds assertions:

- Core-safe roots and board projection agree; Roblox controls do not cover primary
  actions, navigation or labels.
- Compact **STATS** exposes shot counters and owned perks; short landscape tabs
  preserve both views.
- **RACK / SELL** can open and close during choices without permanently compressing
  offers or hiding the close control.
- Compact evolution summaries open the full recipe inspector and can be dismissed.
- Touch-sized action regions remain reachable, text has readable hierarchy, and
  model animations do not cause neighboring controls to move or rebuild.

Restore fixture dimensions, controls and source after testing, remove only the
temporary QA objects, and stop Play. Native resized/emulated viewports are useful
evidence but do not substitute for a physical touch-device test. Keep those results
and any unrun checks separate in the task handoff.
