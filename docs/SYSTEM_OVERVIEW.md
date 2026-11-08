# System overview

An eight-player aquarium arcade connects each player's server-owned run to a
locally rendered 3D board. The client
aims and requests actions; the server simulates every bounce, scores every pop,
and chooses all upgrade offers. Native parts and GUI elements restore the complete
visual presentation without external models or images. Standard Roblox avatars
walk through the shared hub. Short
sound cues use public Roblox audio IDs documented in [Asset sources](ASSETS.md).

## Mapping and trust

| Source | Studio destination | Instance type / responsibility |
| --- | --- | --- |
| `src/server/Main.server.luau` | `ServerScriptService.Server.Main` | `Script`; authoritative server work. |
| `src/server/ArcadeSessions.luau` | `ServerScriptService.Server.ArcadeSessions` | Pure eight-station allocation, private runs, pause/resume, roster and record capture. |
| `src/server/HubWorld.luau` | `ServerScriptService.Server.HubWorld` | Original walkable aquarium arcade, cabinets, prompts and occupancy screens. |
| `src/client/Main.client.luau` | `StarterPlayer.StarterPlayerScripts.Client.Main` | `LocalScript`; copied into each player's `PlayerScripts`. |
| `src/client/HubPresentation.luau` | `StarterPlayer.StarterPlayerScripts.Client.HubPresentation` | Hub navigation, collection, records, roster and preview cleanup. |
| `src/client/HubLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.HubLayout` | Responsive hub panel and gallery geometry. |
| `src/client/HubAmbience.luau` | `StarterPlayer.StarterPlayerScripts.Client.HubAmbience` | Local fish and bubble motion with rest-pose restoration. |
| `src/shared/` | `ReplicatedStorage.Shared` | Modules for board rules, deterministic physics, progression, catalog, profiles, number formatting, and reward timelines. |
| `src/shared/RestockCurve.luau` | `ReplicatedStorage.Shared.RestockCurve` | Shared successive restock costs, stage limits and meter progress. |
| `src/shared/Stages.luau` | `ReplicatedStorage.Shared.Stages` | Pure consecutive level goals and successful-clear descriptors. |
| `src/client/Presentation.luau` | `StarterPlayer.StarterPlayerScripts.Client.Presentation` | Local camera, board, responsive controls, counters, and menus. |
| `src/client/BoardArt.luau` | `StarterPlayer.StarterPlayerScripts.Client.BoardArt` | Original pearl/aqua enclosure and attached settlement monitor, separate from collision rules. |
| `src/client/HoverInspector.luau` | `StarterPlayer.StarterPlayerScripts.Client.HoverInspector` | Reusable hover, focus, and touch inspection with ordered effect rows and modeled evolution recipes. |
| `src/client/EvolutionDisplay.luau` | `StarterPlayer.StarterPlayerScripts.Client.EvolutionDisplay` | Shared ingredient + ingredient = result model rows with live level/readiness labels. |
| `src/client/UiTheme.luau` | `StarterPlayer.StarterPlayerScripts.Client.UiTheme` | Shared interface colors and native GUI constructors. |
| `src/client/ItemModels.luau` | `StarterPlayer.StarterPlayerScripts.Client.ItemModels` | Original native equipment, perk, currency, and control models with viewport animation. |
| `src/client/ItemMotion.luau` | `StarterPlayer.StarterPlayerScripts.Client.ItemMotion` | Per-model moving groups, activation samples, and paused/resumed figure-eight idle motion. |
| `src/client/InventorySelection.luau` | `StarterPlayer.StarterPlayerScripts.Client.InventorySelection` | Pure select, deselect, swap-request, and invalid-phase rules. |
| `src/client/ShopLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.ShopLayout` | Fixed offer, evolution-equation, and action regions for shops without scrolling. |
| `src/client/ChoiceLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.ChoiceLayout` | Two visible perk/event choices with bounded model, effect and button regions. |
| `src/client/Feedback.luau` | `StarterPlayer.StarterPlayerScripts.Client.Feedback` | Score flights, trigger cues, counter display, and receipt-driven board animation. |
| `src/client/SoundEffects.luau` | `StarterPlayer.StarterPlayerScripts.Client.SoundEffects` | Bounded sound pools, cue timing, preload, and mute control. |
| `src/shared/ItemFeedback.luau` | `ReplicatedStorage.Shared.ItemFeedback` | Per-item/perk note motifs, timing, visual accents, and effect styles. |
| `src/shared/RewardTimeline.luau` | `ReplicatedStorage.Shared.RewardTimeline` | Pure visual planning for restore, refill, merge, and batched reward steps. |
| `src/server/ProfileStore.luau` | `ServerScriptService.Server.ProfileStore` | Versioned records/unlocks persistence. |
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
Departure frees the station and saves records, not the unfinished run. Roster
snapshots expose station/name/mode/round/record, never another player's inventory.

`Main.server` loads walking avatars, disables avatar-to-avatar collisions, anchors
them at their assigned cabinets during runs, and restores movement on hub return.
Character respawns and delayed loads reapply the current mode. Cabinet prompts
validate ownership and distance. The Play button is also available from anywhere
in the hub. Overflow joins are rejected; a published place should also configure
Max Players = 8 through Creator Dashboard. That setting is not changed by source.

`HubWorld` places 820 original parts around a separate world center at Z=1000,
away from local board geometry. Eight cabinets surround a central aquarium, with
seating, plants, gallery and record stations. `HubAmbience` moves 65 parts in ten
fish/bubble groups on the client, only while the hub is mounted; reduced motion
disables it, and destruction restores all poses and transparency.

Client Main mounts either hub or board presentation, restores Custom/Humanoid
camera and walking controls in the hub, and uses the fixed Scriptable camera during
runs. Completed reward receipt identities survive hub visits to prevent replay;
new run identities reset that cache. Collection models page through 13 evolutions,
show their ingredients/effects and use persisted discovery IDs. Hub navigation and
world kiosk prompts share the same collection/records panels. No payment flow exists.

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
`BoardArt` constructs the decorative enclosure from 235 original native parts:
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

| Hybrid | Ordered effects and cost |
| --- | --- |
| Gain Dial | Increase score by 15% per level (75% at level 5), then halve the highest peg once. |
| Soft Current | Halve two pegs per level (ten at level 5), then pop the lowest once. |
| Burst Capsule | Double one random center, pop two nearest other pegs per level (ten at level 5), then halve the center. |

Goldfish doubles the lowest live peg every six pops; Fishbowl pops the highest peg
every three doubles. Their upgrades increase output. Fishbowl enters the catalog
pool through the round-10 growth unlock. Other families connect doubles to Reef
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

All 22 base equipment types have an evolution path:

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
card and inspection panel: ingredient + ingredient = result. Ingredient labels are
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
increase across restarts to prevent replay.

`shotStats` exposes the live trigger counters. `lastShotStats` and receipt `stats`
preserve final pops, walls, doubles, halves, quotas, elapsed time, first hit, drain,
clear, and item/perk activations with round and shot IDs. The last-shot record
survives automatic aim and shop transitions until the next launch. The interface
can also clear its display when the player clicks the shop's Next Round button.

The receipt records the spent shot board, restored baseline, refill/merge
transitions, final board, and before/after reward balances. `Run` processes at most
32 restocks per settlement slice, with a stage-dependent shot cap of 6–12. Receipts keep
every cycle through eight restocks; larger settlements retain the first three and
last two, with cycle indices preserving the omitted count.

`RewardTimeline` turns that receipt into a bounded visual sequence. `Feedback`
waits for final score/restock flights, restores the board, animates falling refills
and matching-pair merges, and delivers coin/ball cues. It then requests `continue`
automatically from the server's `result` phase. The client keeps the final board
visible through shops and choices until the next aim snapshot. Skip completes the
presentation with the same authoritative rewards. Terminal results open the run
summary instead of continuing. There is no ordinary result confirmation modal.

`Presentation` exposes the board, counters, controls, and viewport anchors to
`Feedback`; `ItemModels` supplies reusable native 3D visuals, `ItemMotion` animates
their moving groups, and `UiTheme` supplies GUI styling. `ShopLayout` keeps four
equipment cards and up to two Supplies in distinct groups without a fixed bottom
inspection panel. Reclaimed space enlarges the main models and labels. The rack
grows during play and contracts for shops and choices; perk and event choices use
the same white surfaces and larger text/model treatment. Selection, purchase
eligibility, and held/sold state update existing cards instead of destroying their
models. `HoverInspector` opens on pointer entry or UI focus, and pins open on touch;
it closes when its anchor disappears or an explicit close action occurs.
`InventorySelection` clears a selection after a swap request, holds further
rack actions until acknowledgment or timeout, and rejects selection changes outside
aim/shop phases. An owned-perk strip stays available between choices and highlights
the perk identified by an activation event.

`ItemModels` registers 52 original models, including 13 evolved designs. Equipment
gains visible level accents across five tiers, while evolved models render at their
fixed maximum tier. Idle motion follows a bounded 4.2-second figure-eight path with gentle tilt. Activations
freeze the current idle pose, apply the item's moving-group animation relative to
that pose, then resume idle velocity smoothly after the last queued activation.
The idle controller has no effect on run mechanics. Static/reduced-motion mounts
disable idle movement while retaining activation feedback.

Only perk models retain the generic white display circle; equipment, currency and
Supply previews omit it. `ItemModels` can render an outlined preview using a black
clone in a sibling ViewportFrame behind the colored model. A slightly narrower
camera field of view expands that mask, and animation updates synchronize its
poses and mesh sizes. This avoids separate lines between each model part, but is
a projected silhouette approximation: border width varies with the shape and
transparent geometry can soften it. It adds one geometry/render layer per outlined
preview. The foreground viewport stays at ZIndex 2 or higher and its mask stays one
layer below, preserving the colored model at low GUI layers. Small recipe tiles opt
out, and hidden/disposed previews hide or destroy their associated masks. No uploaded
outline texture or post-processing asset is required.

Score, coin, and restock arrivals pulse their counters. Launching spends a ball
directly in the reserve display; only restored balls use reward flights. Perk
highlights and counter pulses follow authoritative events and displayed arrivals,
so they do not change balances or trigger timing.
The score and restock panels retain their white base through count changes and
scale pulses. Wallet, reserve and trigger panels can remain blue; numerical state
does not recolor the white counter surfaces.

`ItemFeedback` defines 46 distinct motifs and visual signatures by stable ID,
including four-note motifs for the 13 evolutions. Item activations produce dense
native GUI bursts, swirls, multiple beams, impact rings and ribbons with per-item
shapes, colors and motion. Evolved activations use larger bursts and an evolution
purchase triggers its own celebration. Decorative effects stop at 184 active
entries within a 240-entry total budget, reserving capacity for 56 score/reward
arrivals. Reduced motion limits a burst to three particles with no orbiting path.
These visual limits are independent of the authoritative activation budget.
`SoundEffects` schedules their notes through bounded voice and note pools, limits
cue frequency, supports mute, and leaves gameplay functional if audio cannot load.
Targeted beams use explicit source/target IDs; restarts clear pending visual and
item-audio work. Asset IDs, creators, and restoration requirements live in
[Asset sources](ASSETS.md).

## Records across runs

Only best score, best round, and a set of catalog/level unlocks cross the run boundary.
Evolving records the result's catalog ID as a discovery for the hub collection.
Existing record data is retained; no currency or permanent scoring power is added.
`Profile` validates these fields and combines concurrent saves monotonically.
Coins, board values, items, perks, and scoring power are deliberately excluded.
`ProfileStore` uses `PopAPeg_Records_v1` only in a published non-Studio session;
Studio remains session-only. Failed loads/saves are reported as unavailable, and
updates combine stored records instead of replacing them with fallback data.
No external HTTP service or production credentials are required.

## Ownership and restoration

| Content | Authority and storage policy |
| --- | --- |
| Scripts | `src/` is authoritative. Rojo sends filesystem edits to Studio. Reviewed MCP `Source` capture or deliberate shared XML export can stage Studio edits before promoting them to files. |
| Mapped scene properties | `default.project.json` is authoritative. Translate intentional Studio changes into this mapping; do not expect automatic writeback. |
| Models | An intentionally adopted `.rbxm` or `.rbxmx` in `assets/` may be authoritative, mapped beneath `ReplicatedStorage.Assets`. Record ownership and any additional placement mapping; do not keep a competing authoritative Studio copy. |
| Terrain | Not represented by this starter's source. A later terrain task must choose a source place template or documented terrain export and prove restoration; a saved generated place alone is not source. |
| Place templates | Intentional `.rbxl`/`.rbxlx` source templates may be versioned outside `build/` when needed. Define how code is injected and how a fresh clone restores them before adopting one. |
| External asset IDs | Public audio dependencies and provenance are recorded in [Asset sources](ASSETS.md). Source control cannot supply asset access; verify loading in the target experience. Visual models require no external IDs, and missing audio does not block play. |
| Generated places / temporary exports | `build/` and `scratch/` are ignored. Regenerate builds; review exports before promoting intentional changes. |
| Tools | `.tools/` is ignored; `scripts/setup.ps1` restores pinned binaries. |

Extensions are not blanket-ignored: an intentional source model/place can be
tracked. Keep one authority for each subtree. Never map a generated place back
into the same project or silently replace Studio-only content through sync.

A fresh checkout restores the game using Git, PowerShell, internet access for
the pinned tools, and `setup.ps1` → `check.ps1` → `build.ps1`. Studio and a Roblox
account are prerequisites for runtime/sync checks. New private assets, terrain,
or templates must add their own explicit restoration steps.

## Development and publication

A local generated place is the default development target. Independent operators
use distinct local files/development places and ports, or one integration operator
tests branches sequentially. Record ownership in each task handoff.

The public Roblox experience, if later selected, is a separate target. Its source,
place ID, observed published version, verification, and rollback reference belong
in the release task and the current dashboard. Git commits, GitHub merges, build
artifacts, and Studio playtests do not publish an experience.
