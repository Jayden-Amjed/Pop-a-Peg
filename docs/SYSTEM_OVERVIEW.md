# System overview

An eight-player aquarium arcade connects each player's server-owned run to a
locally rendered 3D board. The client
aims and requests actions; the server simulates every bounce, scores every pop,
and chooses all upgrade offers. Native parts form the board and arcade; item
previews use imported Blender MeshParts with recorded asset dependencies. Standard Roblox avatars
walk through the shared hub. Short
sound cues use public Roblox audio IDs documented in [Asset sources](ASSETS.md).

## Mapping and trust

| Source | Studio destination | Instance type / responsibility |
| --- | --- | --- |
| `src/server/Main.server.luau` | `ServerScriptService.Server.Main` | `Script`; authoritative server work. |
| `src/server/ArcadeSessions.luau` | `ServerScriptService.Server.ArcadeSessions` | Pure eight-station allocation, private runs, pause/resume, roster and record capture. |
| `src/server/HubWorld.luau` | `ServerScriptService.Server.HubWorld` | Original walkable aquarium arcade, cabinets, prompts and occupancy screens. |
| `src/server/LeaderboardService.luau` | `ServerScriptService.Server.LeaderboardService` | Global ordered rankings, cached refresh and explicit session/unavailable modes. |
| `src/client/Main.client.luau` | `StarterPlayer.StarterPlayerScripts.Client.Main` | `LocalScript`; copied into each player's `PlayerScripts`. |
| `src/client/HubPresentation.luau` | `StarterPlayer.StarterPlayerScripts.Client.HubPresentation` | Hub navigation, collection, records, roster and preview cleanup. |
| `src/client/HubLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.HubLayout` | Responsive hub panel and gallery geometry. |
| `src/client/HubProgressionPanel.luau` | `StarterPlayer.StarterPlayerScripts.Client.HubProgressionPanel` | Chest opening, blueprint research, reward acknowledgement and leaderboard views. |
| `src/client/HubProgressionLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.HubProgressionLayout` | Safe-area chest, workshop, blueprint and ranking panel geometry. |
| `src/client/HubAmbience.luau` | `StarterPlayer.StarterPlayerScripts.Client.HubAmbience` | Local fish and bubble motion with rest-pose restoration. |
| `src/client/HubGuide.luau` | `StarterPlayer.StarterPlayerScripts.Client.HubGuide` | Local assigned-cabinet beacon, outline and prompt filtering, restored on disposal. |
| `src/shared/` | `ReplicatedStorage.Shared` | Modules for board rules, deterministic physics, progression, catalog, profiles, number formatting, and reward timelines. |
| `src/shared/RestockCurve.luau` | `ReplicatedStorage.Shared.RestockCurve` | Shared successive restock costs, stage limits and meter progress. |
| `src/shared/Stages.luau` | `ReplicatedStorage.Shared.Stages` | Pure consecutive level goals and successful-clear descriptors. |
| `src/shared/ChestProgression.luau` | `ReplicatedStorage.Shared.ChestProgression` | Earned chest tiers, duplicate-protected unlocks, research and bounded request receipts. |
| `src/shared/Leaderboards.luau` | `ReplicatedStorage.Shared.Leaderboards` | Ranking categories, bounded values and deterministic top-ten session sorting. |
| `src/shared/ProfileLease.luau` | `ReplicatedStorage.Shared.ProfileLease` | Pure atomic acquire/write transforms with owner checks and retry identities. |
| `src/client/Presentation.luau` | `StarterPlayer.StarterPlayerScripts.Client.Presentation` | Local camera, board, responsive controls, counters, and menus. |
| `src/client/RunLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.RunLayout` | Pure core-safe portrait/landscape geometry for the board, controls, rack and details. |
| `src/client/BoardArt.luau` | `StarterPlayer.StarterPlayerScripts.Client.BoardArt` | Original pearl/aqua enclosure and attached settlement monitor, separate from collision rules. |
| `src/client/HoverInspector.luau` | `StarterPlayer.StarterPlayerScripts.Client.HoverInspector` | Reusable hover, focus, and touch inspection with ordered effect rows and modeled evolution recipes. |
| `src/client/ItemDetailCard.luau` | `StarterPlayer.StarterPlayerScripts.Client.ItemDetailCard` | Shared model/name/effect/evolution compartments for shop inspection, hover inspector and gallery recipe detail; scrolls long content. |
| `src/client/ItemDetailLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.ItemDetailLayout` | Pure measured compartment geometry, including every effect and recipe at readable sizes. |
| `src/client/EvolutionDisplay.luau` | `StarterPlayer.StarterPlayerScripts.Client.EvolutionDisplay` | Shared ingredient + ingredient = result model rows with live level/readiness labels. |
| `src/client/UiTheme.luau` | `StarterPlayer.StarterPlayerScripts.Client.UiTheme` | Shared pearl/aqua panels, cartoon headings, button states and native GUI constructors across run and arcade screens. |
| `src/client/GameItemModels.luau`, `GameModelPlayback.luau` | Client modules with matching names | Gameplay Blender clones, asset preloading, cached framing, bounded activation queue and cleanup. |
| `art/catalog/CatalogAssets.rbxm`, `scripts/models/` runtime modules | `ReplicatedStorage.CatalogAssets`, `CatalogLibrary` | Reviewed meshes and shared Blender choreography, physical effect anchors and instruments. |
| `src/client/ItemModels.luau` | `StarterPlayer.StarterPlayerScripts.Client.ItemModels` | Frozen native reference and explicit remote-load failure fallback. |
| `src/client/ItemMotion.luau` | `StarterPlayer.StarterPlayerScripts.Client.ItemMotion` | Per-model moving groups, activation samples, and paused/resumed figure-eight idle motion. |
| `src/client/ItemChoreography.luau`, `src/client/motion/` | Client modules with matching names | 78 distinct body/mechanism performances and shared smooth timing curves. |
| `src/client/NativeAssemblies.luau` | `StarterPlayer.StarterPlayerScripts.Client.NativeAssemblies` | Native attachment pivots and groups; no geometry changes. |
| `src/client/InventorySelection.luau` | `StarterPlayer.StarterPlayerScripts.Client.InventorySelection` | Pure select, deselect, swap-request, and invalid-phase rules. |
| `src/client/ShopLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.ShopLayout` | Responsive offer/Supplies/drawer geometry and shared inspector recipe equations. |
| `src/client/ShopView.luau` | `StarterPlayer.StarterPlayerScripts.Client.ShopView` | Original pearl/aqua shop presentation; existing Catalog and Run rules own decisions. |
| `src/client/ChoiceLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.ChoiceLayout` | Two visible perk/event choices and result summaries with bounded models, text and actions. |
| `src/client/Feedback.luau` | `StarterPlayer.StarterPlayerScripts.Client.Feedback` | Score flights, trigger cues, counter display, and receipt-driven board animation. |
| `src/client/SoundEffects.luau` | `StarterPlayer.StarterPlayerScripts.Client.SoundEffects` | Bounded sound pools, cue timing, preload, and mute control. |
| `src/client/GameSoundEffects.luau` | `StarterPlayer.StarterPlayerScripts.Client.GameSoundEffects` | Uses reviewed item instruments on the gameplay sound instance without changing the native bank. |
| `src/shared/ItemFeedback.luau` | `ReplicatedStorage.Shared.ItemFeedback` | Per-item/perk note motifs, timing, visual accents, and effect styles. |
| `src/shared/RewardTimeline.luau` | `ReplicatedStorage.Shared.RewardTimeline` | Pure visual planning for restore, refill, merge, and batched reward steps. |
| `src/shared/Profile.luau` | `ReplicatedStorage.Shared.Profile` | Profile v2 cleaning, old ownership migration and record-only run merges. |
| `src/server/ProfileStore.luau` | `ServerScriptService.Server.ProfileStore` | Roblox service wrapper for persistent profiles or Studio session fallback. |
| `src/server/ProfileRepository.luau` | `ServerScriptService.Server.ProfileRepository` | Injectable DataStore adapter, lease acquisition, bounded retries and safe release. |
| `assets/` | `ReplicatedStorage.Assets` | Folder of intentional source assets, initially empty. |
| `default.project.json` | `Workspace` and service roots | Explicit scene properties and filesystem mapping. |

The project's `emitLegacyScripts: true` and Rojo filename suffixes determine
the script classes above. Keep these settings and suffixes intentional;
renaming a file can change its runtime behavior. Build checks inspect the generated
instances; Studio execution is a separate check.

The client is untrusted. Keep secrets and authoritative decisions on the server;
anything in `ReplicatedStorage` is available to clients. `PegRemotes.Action`
accepts bounded requests with a per-player rate limit; `Run` validates phase,
indices, balances, and aim values. The client never supplies score or inventory.
`PegRemotes.State` sends snapshots only to the owning player. Shared modules are
not shared mutable memory across client and server.

## Arcade and player lifecycle

`ArcadeSessions` reserves one of eight stations before profile/character loading
yields. A join starts in the hub with no run. `startRun` creates a private `Run`,
or resumes the same instance; `enterHub` captures records and pauses it. Flight
and settlement cannot be parked. Victory remains resumable so Endless is available;
a lost run starts fresh. `runId` changes only when the session replaces a Run.
Departure frees the station and saves records and hub progression, not the unfinished run. Roster
snapshots expose station/name/mode/round/record, never another player's inventory.

`Main.server` loads walking avatars, disables avatar-to-avatar collisions, anchors
them at their assigned cabinets during runs, and restores movement on hub return.
Character respawns and delayed loads reapply the current mode. Cabinet prompts
validate ownership and distance. The Play button is also available from anywhere
in the hub. Overflow joins are rejected; a published place should also configure
Max Players = 8 through Creator Dashboard. That setting is not changed by source.

`HubWorld` places original native geometry around a separate world center at Z=1000,
away from local board geometry. Eight cabinets surround a central aquarium, with
seating, plants, gallery, chest pavilion and leaderboard stations. `HubAmbience`
moves fish/bubble groups on the client only while the hub is mounted; reduced motion
disables it, and destruction restores all poses and transparency.
Seafoam fields and pearl paths add floor contrast; cabinet numbers, lagoon reef,
canopy and layered bases add depth while preserving station coordinates and collision
geometry. `HubGuide` enables only the assigned cabinet's Play prompt locally and
adds a gold beacon/outline. It waits for late-replicated parts, hides while a modal
is open and restores original prompt states when disposed. Server ownership and
proximity checks remain authoritative.

Client Main mounts either hub or board presentation, restores Custom/Humanoid
camera and walking controls in the hub, and uses the fixed Scriptable camera during
runs. Completed reward receipt identities survive hub visits to prevent replay;
new run identities reset that cache. Walking/jump controls pause while a hub panel
is open, then resume without resetting camera orientation. The initial connection
card stays visible until a snapshot; start/return actions have pending feedback
and an eight-second retry timeout. The Arcade button shares the hint strip without
covering rack slots. Collection models page through 13 evolutions,
show their ingredients/effects and use persisted discovery IDs. Hub navigation and
world kiosk prompts share the same collection/records panels. A three-step How to
Play panel introduces controls, upgrades and evolutions. Compact panels switch
between models/stats or bests/levels so their contents remain available. Hub motion
honors GuiService.ReducedMotionEnabled as well as the explicit player override.
No payment flow exists.

`HubProgressionPanel` shares the hub modal lifecycle for chest opening, the blueprint
workshop and paged leaderboards. `OpenChests` and `OpenLeaderboards` world prompts
open the same views as their navigation controls. Layout regions come from
`HubProgressionLayout`; model previews use the common animation/cleanup handles.
The client sends a stable UUID for each request and reuses it for a retry. The
server owns the chest count, result, restock wallet, research balance and receipt serial; animations
cannot grant an item. `lastOpened.requestId` acknowledges the matching request.

## Hub rewards and ranking data

`Catalog.ItemIds` contains 40 base equipment types, 18 added for the chest loop.
`Catalog.StarterIds` defines the initial eight: Tap Driver, Sun Prism, Shore Meter,
Landing Shell, Survey Lens, Reef Chime, Compass and Seed Bank. Each equipment entry
has a Common, Uncommon, Rare or Legendary tier. `Profile.itemUnlocks` is ownership;
legacy `unlocks` remains discovery/achievement history. `Run.new` freezes the owned
equipment set for that run, and shop draws and purchases reject locked items.
Unlocking equipment in the hub changes future new runs, not a currently parked run.

`Run.highestClearedRound` advances only on a successful quota result.
`ChestProgression.observe` awards a Lagoon/Uncommon chest for clear 15, Aurora/Rare
for clears 40 and 65, Celestial/Legendary for clear 100 and each subsequent completed
50-round Endless milestone. A defeat after at least three successful clears grants
one additional chest: Common below 15, Uncommon at 15–39, Rare at 40–99, Legendary
at 100 or more. Per-run markers prevent repeat capture, hub visits or resumes from
duplicating rewards. New runs reset those markers and receive a new run identity.

`buyChest`, `openChest` and `researchItem` are hub-only authoritative actions.
Extra restocks beyond the first per settled shot credit a persistent wallet;
purchase buys one unopened chest of the chosen tier. The hub shows the wallet,
all tier prices and separate Buy/Open buttons. Normal board rewards remain intact.
`Profile.restockCredits` defaults to zero for older profiles and is bounded at
1e12. `rewardedRestockReceipt` is a per-run settlement watermark; capture runs
before resetting it on a new run. Snapshots/animations cannot award credits.
Chest prices are 100/250/500/1000 from Common to Legendary and remain server-owned.
The chest cap is checked before charging. Purchase receipts join the existing
persisted 64-request ledger; retrying a purchased-and-opened chest cannot refill it.
A chest chooses
an unowned base item of its exact tier. Exhausted tiers instead give research
1/3/6/10; targeted unlocks cost 6/12/24/40 from Common to Legendary. The profile's
newest 64 receipts bind each request ID to its operation and tier/item. A retry
re-acknowledges the original result without another charge or serial increment;
changed-target reuse is rejected. The full ledger stays server-side. This is a
bounded retry guarantee, not permanent retention of every historical request ID.

`ArcadeSessions` accrues actual server elapsed seconds, including the hub, rather
than simulation-speed-adjusted time. `bestEndlessRound` changes only after entering
Endless; campaign best round remains a separate record. `LeaderboardService` writes
monotonic values to separate ordered stores for time, Endless round and experience
Robux spent, refreshes cached global top tens, and labels Studio results as session
rankings. Cloud errors expose unavailable/stale state. `HubWorld:setLeaderboards`
updates the physical displays from that same server snapshot. No purchase products
or receipt handler are enabled, so Robux spending is not fabricated from coins or
client input and its board starts empty.

## Run rules

`Board` owns the 21 values, quota calculation, single pop, refill, and disjoint
merge rules. `Simulation` uses a fixed 1/120-second step with swept collisions;
value-1 pegs are pass-through, while higher values reflect the ball. The aim
preview uses the same rule without mutating live values.
`Run` owns the phase machine, trigger queue, inventory, coins, balls, scheduled
shops/perks/events, and endless progression. Seeded RNG makes mechanics testable
without Studio. A shot's active values are separate from the next-round baseline.

There are five total balls, with one spent on launch. `RestockCurve` awards the first
restock at the round quota, then doubles each successive cost. Total thresholds
are 1, 3, 7, 15 and so on times the quota. Stage caps are 6 restocks through round 15,
8 through 40, 10 through 65, then 12. At shot end each awards a coin and restores one ball up to the five-ball
cap. Zero balls after settlement ends the run. Each attempt starts with zero score
and the baseline board. Successful settlement restores that baseline, fills empty
slots, and merges disjoint equal pairs once per earned restock. A board clear
doubles the score and ends the shot. Elapsed time is displayed without a normal
timeout; manual End Shot does not activate drain-only equipment.

The server advances each player's run independently. The presentation interpolates
snapshots and draws effects; it cannot award rewards or change board rules. Model
instances and camera state are local to each client, so boards do not collide or
share progress.

`Stages` divides the same continuous run into Meadow Shore (rounds 1–15), Glass
Lagoon (16–40), Sunlit Reef (41–65), and Aurora Ocean (66–100), followed by Endless
Current levels of 50 rounds each. `forRound` reports the active goal and counts only
previously completed rounds; `completed` supplies a clear descriptor at an exact
goal. `Run` calls it only after a successful settlement, saves `level_N` as a record
unlock, and puts the descriptor in the event stream and settlement receipt.
Boss modifiers occur at the four campaign goals. Clearing round 100 unlocks
victory and optional endless play; subsequent quota scaling starts at round 101.
The snapshot's `stage` and `stageCleared` fields drive the round panel and completion
feedback. Failed attempts stay on the same round without awarding a level clear.

The front camera follows the viewport layout; pointer movement changes aim only.
Background clouds use opaque parts and sky bands meet without coplanar overlap.
Aim guides do not cast shadows, keeping moving controls from changing the scenery.
`BoardArt` constructs the decorative enclosure from original native parts:
rounded pearl layers, opaque water-depth bands, curved aqua channels, leaf accents,
and a decorated monitor attached above the board's right corner. The monitor adds
layered seals, cheek vents, pearl crown, leaves, visible data cable and hinge,
bubble antenna, inset progress channel, and four campaign lights. These parts are
anchored, noncolliding, nonqueryable and shadowless; they never alter peg positions
or simulated walls. The monitor supplies world-space screen corners, native status
lights and progress segments. `setStage` marks completed campaign lights lime,
the current one gold, and future ones pale. `Presentation` projects status text
onto that screen and places Skip below it, with a larger legible panel at compact
sizes. The screen's original projection corners and simulated playfield are unchanged.

## Equipment, purchases, and choices

`Catalog` supplies stable item IDs, display names, trigger thresholds, prices,
families, and evolution recipes. Hybrid items specify ordered operation lists;
`Run` executes the same pop, double, halve, score, and relay primitives used by
simpler items. A single activation context preserves targets between operations.
`Catalog.detail(id, level)` derives ordered typed effect rows from these lists and
returns the trigger, kind, current level, and available recipes. Levels 1–4 show
current and next-level amounts; level 5 shows only its current power. Fixed
operations remain fixed rather than scaling with the item's level.
`HoverInspector` renders triggers in yellow, benefits in green and costs in red,
without a paragraph interpreting the tradeoff. An evolved item lists each of its
two triggers followed by that channel's effects.
Only explicitly registered rack anchors open passive pointer inspection, at60%
of the prior panel dimensions. Explicit selection/touch/focus retains full-size
details and readable fonts; the content scrolls instead of scaling the text.

| Hybrid | Ordered effects and cost |
| --- | --- |
| Gain Dial | Increase score by 15% per level (75% at level 5), then halve the highest peg once. |
| Soft Current | Halve two pegs per level (ten at level 5), then pop the lowest once. |
| Burst Capsule | Double one random center, pop two nearest other pegs per level (ten at level 5), then halve the center. |

Goldfish doubles the lowest live peg every six pops; Fishbowl pops the highest peg
every three doubles. Their upgrades increase output. Fishbowl enters the catalog
pool through persistent blueprint ownership. Old round-based growth access migrates
when loading an earlier profile; new runs earn additional ownership through chests
or research. Other families connect doubles to Reef
Chime, halves to Pearl Scale, and neighboring slots through Current Relay and Echo
Shell. The queue processes up to 32 activations per slice. Queued signals retain
their causal ancestry: an item/perk cannot activate again through descendants of
its own activation. Fresh physical hits start fresh chains. Evolved channels have
separate identities, preserving combinations across their original triggers.
Direct relay chains carry a depth budget tied to the unlocked slot count;
coalescing preserves causal traces, depths and evolved trigger channels.
A shared limit of 4,096 item/perk activations
per shot also bounds branching cascades. Reaching it emits one `chainLimit` event
(**OVERDRIVE COMPLETE**), discards pending activations and prevents further ones
until the next shot. Ball physics and manual End Shot continue normally, and a
drained ball can settle instead of waiting through millions of relay activations.

Direct score bonuses use the current round quota per item level: Shore Meter 8%,
Landing Shell 15%, Dew Cell 3%, and Quota Bonus 5%. Their descriptions derive from
the same catalog operations. Quota Bonus cannot repeatedly trigger its own quota
crossings; the shared curve also governs authoritative rewards and displayed meters.

The client and server share `Catalog.purchaseState(inventory, slots, offer, coins)`.
It returns the purchase action, eligibility, target slot/level, price, and rejection
reason. `Catalog.MaxLevel` is 5. A matching uncapped copy upgrades by one in place,
even in a full rack; it takes precedence over matching capped copies. If only capped
copies exist, that base-item offer is unavailable even with an empty slot. New
items need capacity; Supplies do not. Tuning Oil and upgrade events also add one
level to an eligible item, or award four coins when none qualify. Moving two
equal-level copies together merges them one level higher if uncapped; other moves
swap the entries. Rejected purchases neither spend coins nor consume offers.

The original equipment set retains these evolution paths; newly discoverable
equipment expands trigger combinations without inventing unfinished recipes:

| Level-5 ingredients | Evolved item |
| --- | --- |
| Goldfish + Fishbowl | Aurora Aquarium |
| Sun Prism + Reef Chime | Spectrum Reef |
| Shore Meter + Wave Spring | Tidal Engine |
| Tide Clock + Dew Cell | Storm Clock |
| Survey Lens + Compass | Horizon Observatory |
| Seed Bank + Coral Garden | Eden Greenhouse |
| Soft Current + Pearl Scale | Pearl Turbine |
| Current Relay + Echo Shell | Current Nexus |
| Landing Shell + Ocean Chorus | Ocean Orchestra |
| Tap Driver + Burst Capsule | Bubble Reactor |
| Gain Dial + Quota Bonus | Solar Treasury |
| Sun Prism + Goldfish | Sun Koi |
| Tide Clock + Wave Spring | Tide Gyroscope |

`Catalog.evolutionsFor` returns independent recipe rows, and `evolutionState`
checks the current inventory for two matching level-5 ingredients. Eligible
evolutions enter ordinary equipment offer slots with a zero-coin **EVOLVE** action.
The server rechecks both ingredients before atomically consuming them, puts the
level-5 result in the first ingredient's slot, and frees the second slot. Client
purchase/cycle requests include the expected item ID so a changed offer cannot
silently buy a different item. An evolved item has a distinct catalog ID outside
the random equipment pool, cannot upgrade further, and has no further recipe panel.
Its two channels retain the original triggers and ordered operations at level 5.
Natural events advance each channel independently; a direct relay activation runs
both channels. Fixed operations retain their original one-time behavior.

Each shop rolls four equipment offers. At round 11 and later it also rolls at most
two immediate-use Supplies, independently of rack size. On a full rack, openings
and rerolls reserve positions 1–2 for owned uncapped items, preferring distinct IDs.
One ID repeats only when its owned copies have two upgrade levels remaining in
total. If fewer than two useful upgrades remain, only that many are reserved.
Positions 3–4 keep ordinary random draws unless held or replaced by ready evolutions.
An eligible held upgrade occupies position 1; other held offers move out of reserved
positions without changing their price. A partial rack retains the previous
single-upgrade opportunity before evolution offers are applied.
Eligible evolution offers refresh after shop
rolls, equipment/Supply purchases, moves and sales; an invalid recipe is removed.
Held offers and guaranteed upgrade cards remain intact, including sold guaranteed
cards: buying does not replenish the shop. If eligible recipes exceed the available cards,
`cycleEvolution` scans cyclically through hidden choices for free, including when
a held offer leaves fewer evolution slots. It never adds a fifth equipment card
or displaces Supplies. Buying a slot or filling the final empty slot never rerolls
the shop; the full-rack rule is evaluated on the next opening or reroll.
`skipPerk` is valid only for an outstanding perk choice;
it consumes that choice for five coins without granting a perk. Shop and perk
interfaces display these server-owned rules rather than deriving separate prices
or upgrade eligibility.
`EvolutionDisplay` renders up to two square-model equations per base equipment
inspection panel: ingredient + ingredient = result. Ingredient labels are
**NEED**, **L1/5** through **L4/5**, or **READY**; result labels use **EVOLVED** or
compact **EVO**. Readiness refreshes from authoritative inventory snapshots.
Perks, Supplies and evolved items omit recipe sections. Supplies retain **On purchase**
as their trigger and **Use** only on the purchase button.

## Feedback and settlement

`CounterProgress` reads the same `RestockCurve` as the server, bounds palette
indices, and shows the next restock cost, earned/maximum count and a full meter
at the cap. It avoids huge-number modulo errors. Boss quotas stay within the numerical score
ceiling, including fully grown boards.

Snapshots carry authoritative totals, a bounded recent event list, and a durable
`settlementReceipt` after numerical settlement completes. Events identify score
deltas and their peg/item source, goal crossings, triggers, coin changes, and ball
changes. Counter totals reconcile feedback even if an older event leaves the
history. Trigger events carry item identity, operation, source slot, and target peg
or slot; purchases and perk choices have separate events. Event and receipt IDs
are scoped to a run identity. Hub resume preserves that identity, while a restart
creates a new identity so the client discards prior run receipts safely.

`shotStats` exposes the live trigger counters. `lastShotStats` and receipt `stats`
preserve final pops, walls, doubles, halves, quotas, elapsed time, first hit, drain,
clear, and item/perk activations with round and shot IDs. The last-shot record
survives automatic aim and shop transitions until the next launch. The interface
can also clear its display when the player clicks the shop's Next Round button.

The receipt records the spent shot board, restored baseline, refill/merge
transitions, final board, and before/after reward balances. `Run` processes at most
32 restocks per settlement slice, with a stage-dependent shot cap of 6–12. Receipts keep
every cycle through five restocks; larger settlements retain the first three and
last two, with cycle indices preserving the omitted count. The client planner also
bounds older/uncompressed receipts to five complete cycles, credits gaps exactly
once and uses recorded before/final board values for batch transitions.

`RewardTimeline` turns that receipt into a bounded visual sequence. `Feedback`
waits for final score/restock flights, restores the board, animates falling refills
and matching-pair merges, and delivers coin/ball cues. It then requests `continue`
automatically from the server's `result` phase. The client keeps the final board
visible through shops and choices until the next aim snapshot. Skip completes the
presentation with the same authoritative rewards. Terminal results open the run
summary instead of continuing. There is no ordinary result confirmation modal.

Natural drain adds durable ordered activation groups with sparse peg changes and
cue events to the receipt. Their model performances and score arrivals finish
before restoration; rolling event-history limits do not discard the drain replay.
Target beams do not retrigger an already-playing drain model. Skip clears model,
FX and audio queues before applying final values. Automatic continue carries its
receipt ID, preventing a delayed retry from consuming the next shop route.
Growth events produce a separate receipt: apply four random peg doubles, visibly
shuffle, then one free refill/merge with a coin and capped ball. Event receipts
do not add saved restock credits or advance another round; banked seeds remain
temporary next-shot growth.

`Presentation` exposes the board, counters, controls, and viewport anchors to
`Feedback`; `GameItemModels` mounts the reviewed Blender catalog, `CatalogMotion`
and `BlenderChoreography` animate its groups, and `UiTheme` supplies GUI styling.
`ShopView` owns the original pearl/aqua shop skin. `ShopLayout` keeps four equipment
cards above a horizontal Supplies strip. Large desktops have an inspection sidebar;
landscape phones open details on tap. A modal rack drawer preserves all seven slots,
selling and slot purchases, with an input-blocking scrim and safe global Z layers.
Shop previews fit their idle motion envelope and ignore activation pulses; gameplay
mounts retain their full activation envelope. The rack keeps larger previews across play,
perk and event choices, using the shared Hold-style pearl surfaces. Selection, purchase
eligibility, and held/sold state update existing cards instead of destroying their
models. `HoverInspector` opens on rack pointer entry or UI focus, and pins open on touch;
it closes when its anchor disappears or an explicit close action occurs.
`InventorySelection` clears a selection after a swap request, holds further
rack actions until acknowledgment or timeout, and rejects selection changes outside
aim/shop phases. An owned-perk strip stays available between choices and highlights
the perk identified by an activation event.

`RunLayout` uses coordinates relative to the core-safe root for portrait and short
landscape screens. The board projection, counters, launch controls and session
navigation use that same area. Compact details expose shot statistics and owned
perks, while the shop's rack drawer preserves selling/reordering without permanently
shrinking every offer. Item inspection opens the complete recipe/effect panel.
Layout contracts and native viewport checks are complementary; neither
alone establishes physical touch-device behavior.

The Blender catalog contains 78 distinct original models: 40 equipment, 13 evolved,
eight perk, three Supply and 14 utility/reward designs. Perks do not reuse equipment
geometry. Four chest builders have tier-specific bodies, lids and hinge activation
profiles; four dedicated event emblems replace equipment aliases. Equipment
retains authored upgrade details and UI level badges, while evolved models render at their
fixed maximum tier. Idle motion follows a bounded 4.2-second figure-eight path with gentle tilt. Activations
freeze the current idle pose, apply the item's moving-group animation relative to
that pose, then resume idle velocity smoothly after the last queued activation.
The [individual choreography](ITEM_ANIMATION_GUIDE.md) adds whole-object anticipation,
growth, recoil and appropriate completed turns. Articulation happens first; a
coherent body transform scales both dimensions and offsets. Connected material
pieces share group/pivot timing. Retriggers, including Prism aiming, queue rather
than rewinding a partial spin. A cached full-motion envelope keeps cameras still.
The same idle controller animates perk choices, event prompts and hub reward
previews as well as equipment. It has no effect on run mechanics. Static/reduced-motion mounts
disable idle movement. Reduced-motion activations use a uniform 4% pulse without
mechanism movement or spins; their camera envelope is cached separately.

Only perk models retain the generic white display circle; equipment, currency and
Supply previews omit it. `ItemModels` renders one geometry pass; enlarged black
clone masks and generic bounding-box upgrade rails/nodes were removed after native
comparisons reproduced ghost edges and floating trim. The legacy outline option
is harmlessly ignored. A weak ownership table retires an existing viewport handle
before replacement, and stale disposal cannot clear a newer camera. Preserve
authored moving groups and model identity when applying the
[model style guide](MODEL_STYLE_GUIDE.md). The [Blender workflow](MODELING_WORKFLOW.md)
documents the implemented conversion. `GameModelLoader` preloads the shared mesh
sets with four concurrent jobs and a 15-second timeout. Failed loads expose their
state and use the frozen native reference as a fallback.

Score, coin, and restock arrivals pulse their counters. Launching spends a ball
directly in the reserve display; only restored balls use reward flights. Perk
highlights and counter pulses follow authoritative events and displayed arrivals,
so they do not change balances or trigger timing.
The score, restock, wallet, reserve and trigger panels retain their assigned colors
through count changes and scale pulses. Titles, buttons and nested item/evolution
compartments share Hold's gradient, navy outline and rounded shadow while keeping
green actions, aqua headings and gold rewards/holds. SurfaceColor retains each
intended fill across disabled/selected refreshes; disabled controls use gray.
Trigger/benefit/cost text remains yellow/green/red; recipe ready/result tiles use
mint/gold tints with navy outlines.

`ItemFeedback` defines distinct catalog motifs and visual signatures by stable ID,
including four-note motifs for the 13 evolutions. Item activations produce dense
native GUI bursts, swirls, multiple beams, impact rings and ribbons with per-item
shapes, colors and motion. Evolved activations use larger bursts and an evolution
purchase triggers its own celebration. Decorative effects stop at 184 active
entries within a 240-entry total budget, reserving capacity for 56 score/reward
arrivals. Reduced motion limits a burst to three particles with no orbiting path.
These visual limits are independent of the authoritative activation budget.
`GameSoundEffects` supplies the reviewed 78-phrase bank through the existing
`SoundEffects` bounded voice and note pools, limits
cue frequency, supports mute, and leaves gameplay functional if audio cannot load.
Targeted beams use explicit source/target IDs; restarts clear pending visual and
item-audio work. Asset IDs, creators, and restoration requirements live in
[Asset sources](ASSETS.md).

## Persistent progress and save ownership

Profile version 2 retains best score, campaign/best round, Endless record, elapsed
play seconds, recorded experience Robux spending, legacy discoveries, equipment
ownership, earned chest balances, research and a bounded retry ledger. Evolving
still records the evolved ID as a collection discovery. An old v1 profile migrates
recognized base-equipment discoveries and workshop/growth/relay access into
ownership, in addition to the starter set. New run achievements do not repeat that
one-time migration. Run coins, board values, rack levels and perks are not saved.

`ProfileStore` retains the existing `PopAPeg_Records_v1` keyspace so profiles migrate
in place, but delegates persistence to `ProfileRepository`. Published non-Studio
sessions acquire an exclusive 180-second lease through `UpdateAsync`; autosaves
renew it. Every write rechecks the owner token and replaces the complete cleaned
profile atomically. Consumable counts are never max-merged, which would resurrect
spent chests or research. `Profile.merge` is only for capturing monotonic records
and ownership from the current run, not for merging competing persisted balances.

Failed or locked loads return no playable default profile and cannot write over
real data. Losing lease ownership stops the old session from saving. Save attempts
retain one write identity across retries; a committed write or release whose reply
was lost can be acknowledged without applying another revision. Progression actions
serialize against saves. A failed save retains coherent session state, reports the
failure and blocks further chest/research spending while periodic saves retry.
Departure waits for outstanding writes before its final save/release.

Studio uses an in-memory session repository and explicitly labels it. Injectable
adapter tests simulate service failures, repeated `UpdateAsync` callbacks, ambiguous
commit responses, stale owners and release retries. Those tests do not establish
production DataStore availability. No external HTTP service or credentials are
required by this source; observed runtime and publication evidence belongs in
[PROJECT_STATUS](../PROJECT_STATUS.md) and the current task.

The persistence boundaries follow Roblox's guidance on
[player data, session locking and atomic writes](https://create.roblox.com/docs/cloud-services/data-stores/player-data-purchasing)
and [ordered data stores](https://create.roblox.com/docs/cloud-services/data-stores).
Any future spending integration must use verified server-side purchase receipts;
see [MarketplaceService.ProcessReceipt](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService#ProcessReceipt).
No purchase receipt handler is enabled in this task.

## Ownership and restoration

| Content | Authority and storage policy |
| --- | --- |
| Scripts | `src/` is authoritative. Rojo sends filesystem edits to Studio. Reviewed MCP `Source` capture or deliberate shared XML export can stage Studio edits before promoting them to files. |
| Mapped scene properties | `default.project.json` is authoritative. Translate intentional Studio changes into this mapping; do not expect automatic writeback. |
| Models | An intentionally adopted `.rbxm` or `.rbxmx` in `assets/` may be authoritative, mapped beneath `ReplicatedStorage.Assets`. Record ownership and any additional placement mapping; do not keep a competing authoritative Studio copy. |
| Terrain | Not represented by this starter's source. A later terrain task must choose a source place template or documented terrain export and prove restoration; a saved generated place alone is not source. |
| Place templates | Intentional `.rbxl`/`.rbxlx` source templates may be versioned outside `build/` when needed. Define how code is injected and how a fresh clone restores them before adopting one. |
| External asset IDs | Audio and mesh dependencies are recorded in [Asset sources](ASSETS.md). Source control cannot supply asset access; verify loading in the target experience. Game item previews and the galleries use recorded owner-account MeshIds. Failed mesh loads use an observable native fallback; missing audio does not block play. |
| Generated places / temporary exports | `build/` and `scratch/` are ignored. Regenerate builds; review exports before promoting intentional changes. |
| Tools | `.tools/` is ignored; `scripts/setup.ps1` restores pinned binaries. |

Extensions are not blanket-ignored: an intentional source model/place can be
tracked. Keep one authority for each subtree. Never map a generated place back
into the same project or silently replace Studio-only content through sync.

A fresh checkout restores the game using Git, PowerShell, internet access for
the pinned tools, and `setup.ps1` → `check.ps1` → `build.ps1`. Studio and a Roblox
account are prerequisites for runtime/sync checks. New private assets, terrain,
or templates must add their own explicit restoration steps.

The [Blender pilot gallery](BLENDER_PILOTS.md) uses `blender-pilots.project.json`,
an engine-exported model under `art/models/`, and isolated code under
`scripts/models/`. It does not load the game server, profiles, hub or production UI.
Editable `.blend` sources are authoritative for the next mesh revision; normal
exports preserve them. The Python builders are explicit regeneration recipes.
Committed manifests and uploaded artifacts identify the tested import revision;
candidate exports stay in ignored `build/model-exports/` until reviewed/imported.

The [full catalog inspector](CATALOG_GALLERY.md) builds with
`catalog-gallery.project.json`. `art/catalog/CatalogAssets.rbxm` restores 78 models
with 477 MeshParts; 75 editable sources live under `art/catalog/` and the original
three stay under `art/models/`. Ten initial uploads and the immutable RBX-025 and
RBX-027 revision receipts cover the active meshes.
`CatalogMotion` uses `BlenderChoreography`, which layers Blender-only performances
over the frozen native definitions without modifying them. `CatalogEffects` uses
78 per-item designs from `CatalogEffectProfiles` and physical surface/assembly
anchors from `CatalogEffectAnchors` in a bounded sibling part pool.
`GallerySoundBank` and `GallerySoundEngine` provide 78 authored phrases across 12
timbre families while reusing the existing audio assets. The original pilot gallery
uses the motion adapter too. Only the selected model plus
an optional native comparison mounts in viewports. `PreviewLighting` is shared
with normal item cards; `UiTheme` adds restrained contrast. Gameplay uses the same
Blender models and motion through GameItemModels. It preloads shared mesh sets,
caches each ID's moving-geometry bounds, lazily creates effect pools and retains
observable frozen-native fallback if a remote mesh load fails. Native sources
remain unchanged. Source files, upload receipts, runtime copies, tests and publication
remain distinct; see the task and dashboard for current verification.

Gameplay cameras stay fixed and frame the complete sampled mechanism movement.
Decorative particle tips may reach/crop at card edges; gallery framing includes
their complete bounds. Wider shop/choice previews, adaptive owned-perk rows and
larger desktop hub panels improve readability without shrinking compact controls.

Natural-drain growth on Seed Bank, Rain Catcher and Monsoon Loom banks a bounded
next-shot benefit after all restocks. Each peg receives at most one saved double;
baseline and quota stay unchanged. See [drain rules and client fields](DRAIN_ITEM_AUDIT.md).
`PlaytestAccess` currently enables all40 equipment pools and13 evolution previews
only for user583716264. It projects temporary access without writing grants to the
real profile. Disable its server flag and restart for ordinary access. Coins,
chests, item levels, level5 evolution requirements and earned records remain normal.

## Development and publication

A local generated place is the default development target. Independent operators
use distinct local files/development places and ports, or one integration operator
tests branches sequentially. Record ownership in each task handoff.

The public Roblox experience, if later selected, is a separate target. Its source,
place ID, observed published version, verification, and rollback reference belong
in the release task and the current dashboard. Git commits, GitHub merges, build
artifacts, and Studio playtests do not publish an experience.
