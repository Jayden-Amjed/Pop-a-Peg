# System overview

Each player has a server-owned run and a locally rendered 3D board. The client
aims and requests actions; the server simulates every bounce, scores every pop,
and chooses all upgrade offers. Native parts and GUI elements restore the complete
visual presentation without external models, images, or avatar assets. Short
sound cues use public Roblox audio IDs documented in [Asset sources](ASSETS.md).

## Mapping and trust

| Source | Studio destination | Instance type / responsibility |
| --- | --- | --- |
| `src/server/Main.server.luau` | `ServerScriptService.Server.Main` | `Script`; authoritative server work. |
| `src/client/Main.client.luau` | `StarterPlayer.StarterPlayerScripts.Client.Main` | `LocalScript`; copied into each player's `PlayerScripts`. |
| `src/shared/` | `ReplicatedStorage.Shared` | Modules for board rules, deterministic physics, progression, catalog, profiles, number formatting, and reward timelines. |
| `src/client/Presentation.luau` | `StarterPlayer.StarterPlayerScripts.Client.Presentation` | Local camera, board, responsive controls, counters, and menus. |
| `src/client/BoardArt.luau` | `StarterPlayer.StarterPlayerScripts.Client.BoardArt` | Original pearl/aqua enclosure and attached settlement monitor, separate from collision rules. |
| `src/client/HoverInspector.luau` | `StarterPlayer.StarterPlayerScripts.Client.HoverInspector` | Reusable hover, focus, and touch inspection with ordered effect rows and modeled partners. |
| `src/client/UiTheme.luau` | `StarterPlayer.StarterPlayerScripts.Client.UiTheme` | Shared interface colors and native GUI constructors. |
| `src/client/ItemModels.luau` | `StarterPlayer.StarterPlayerScripts.Client.ItemModels` | Original native equipment, perk, currency, and control models with viewport animation. |
| `src/client/ItemMotion.luau` | `StarterPlayer.StarterPlayerScripts.Client.ItemMotion` | Per-model moving groups, activation samples, and paused/resumed figure-eight idle motion. |
| `src/client/InventorySelection.luau` | `StarterPlayer.StarterPlayerScripts.Client.InventorySelection` | Pure select, deselect, swap-request, and invalid-phase rules. |
| `src/client/ShopLayout.luau` | `StarterPlayer.StarterPlayerScripts.Client.ShopLayout` | Fixed offer, synergy, and action regions for shops without scrolling. |
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

## Run rules

`Board` owns the 21 values, quota calculation, single pop, refill, and disjoint
merge rules. `Simulation` uses a fixed 1/120-second step with swept collisions;
value-1 pegs are pass-through, while higher values reflect the ball. The aim
preview uses the same rule without mutating live values.
`Run` owns the phase machine, trigger queue, inventory, coins, balls, scheduled
shops/perks/events, and endless progression. Seeded RNG makes mechanics testable
without Studio. A shot's active values are separate from the next-round baseline.

There are five total balls, with one spent on launch. Each full score quota earns
one restock; at shot end it awards a coin and restores one ball up to the five-ball
cap. Zero balls after settlement ends the run. Each attempt starts with zero score
and the baseline board. Successful settlement restores that baseline, fills empty
slots, and merges disjoint equal pairs once per earned restock. A board clear
doubles the score and ends the shot. Elapsed time is displayed without a normal
timeout; manual End Shot does not activate drain-only equipment.

The server advances each player's run independently. The presentation interpolates
snapshots and draws effects; it cannot award rewards or change board rules. Model
instances and camera state are local to each client, so boards do not collide or
share progress.

The front camera follows the viewport layout; pointer movement changes aim only.
Background clouds use opaque parts and sky bands meet without coplanar overlap.
Aim guides do not cast shadows, keeping moving controls from changing the scenery.
`BoardArt` constructs the decorative enclosure from 166 original native parts:
rounded pearl layers, opaque water-depth bands, curved aqua channels, leaf accents,
and a small monitor attached above the board's right corner. These parts are
anchored, noncolliding, nonqueryable and shadowless; they never alter peg positions
or simulated walls. The monitor supplies world-space screen corners, native status
lights and progress segments. `Presentation` projects status text onto that screen
and places Skip below it, with a larger legible panel at compact sizes.

## Equipment, purchases, and choices

`Catalog` supplies stable item IDs, display names, trigger thresholds, prices,
families, and suggested synergy partners. Hybrid items specify ordered operation
lists; `Run` executes the same pop, double, halve, score, and relay primitives used
by simpler items. A single activation context preserves targets between stages.
`Catalog.detail(id, level)` derives ordered typed effect rows from those operation
lists and supplies the trigger, kind, level, and suggested partner IDs. Level-1
details include the upgraded amount; level-2 details show the current capped
amount. `HoverInspector` renders the trigger in yellow, positive rows in green and
negative rows in red. It presents the numerical actions without an additional
paragraph interpreting the tradeoff. `Catalog.owns` checks the current inventory
for each partner's OWNED/NEED label; the label is not an account unlock indicator.

| Hybrid | Ordered effects and cost |
| --- | --- |
| Gain Dial | Increase score by 15% (30% upgraded), then halve the highest peg once. Immediate score costs future hit value and triggers halve synergies. |
| Soft Current | Halve two pegs (four upgraded), then pop the lowest once. Trimming reduces future value while feeding halve and pop triggers. |
| Burst Capsule | Double a random center, pop two nearest other pegs (four upgraded), then halve the center. The center scores nothing and retains no temporary growth. |

Goldfish doubles the lowest live peg every six pops; Fishbowl pops the highest peg
every three doubles. Their upgrades increase output. Fishbowl enters the catalog
pool through the round-10 growth unlock. Other families connect doubles to Reef
Chime, halves to Pearl Scale, and neighboring slots through Current Relay and Echo
Shell. The queue processes a bounded number of activations per slice. Direct relay
chains carry a depth budget tied to the unlocked slot count; queue coalescing keeps
different depths separate. Fresh gameplay triggers start new chains.

The client and server share `Catalog.purchaseState(inventory, slots, offer, coins)`.
It returns the purchase action, eligibility, target slot/level, price, and rejection
reason. `Catalog.MaxLevel` is 2. A matching level-1 copy upgrades in place even in a
full rack; it takes precedence over any matching level-2 copy. If only capped copies
exist, the offer is unavailable even with an empty slot. New items need capacity;
Supplies do not. Rejected purchases neither spend coins nor consume offers.

Each shop rolls four equipment offers. At round 11 and later it also rolls at most
two immediate-use Supplies, independently of rack size. Buying a slot never
refreshes these offers. `skipPerk` is valid only for an outstanding perk choice;
it consumes that choice for five coins without granting a perk. Shop and perk
interfaces display these server-owned rules rather than deriving separate prices
or upgrade eligibility.
Equipment offers display partner models in square tiles. Supplies can display
relevant equipment partners too, with **On purchase** as their trigger and **Use**
only on the purchase button. Partner ownership refreshes with authoritative
snapshots after purchases, upgrades and sales.

## Feedback and settlement

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
32 restocks per settlement slice and caps a shot at 10,000 restocks. Receipts keep
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

Idle motion follows a bounded 4.2-second figure-eight path with gentle tilt. Activations
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
preview. Small synergy tiles opt out, and hidden/disposed previews hide or destroy
their associated masks. No uploaded outline texture or post-processing asset is
required.

Score, coin, and restock arrivals pulse their counters. Launching spends a ball
directly in the reserve display; only restored balls use reward flights. Perk
highlights and counter pulses follow authoritative events and displayed arrivals,
so they do not change balances or trigger timing.
The score and restock panels retain their white base through count changes and
scale pulses. Wallet, reserve and trigger panels can remain blue; numerical state
does not recolor the white counter surfaces.

`ItemFeedback` defines short distinct motifs and visual signatures by stable ID.
`SoundEffects` schedules their notes through bounded voice and note pools, limits
cue frequency, supports mute, and leaves gameplay functional if audio cannot load.
Targeted beams use explicit source/target IDs; restarts clear pending visual and
item-audio work. Asset IDs, creators, and restoration requirements live in
[Asset sources](ASSETS.md).

## Records across runs

Only best score, best round, and a set of catalog unlocks cross the run boundary.
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
