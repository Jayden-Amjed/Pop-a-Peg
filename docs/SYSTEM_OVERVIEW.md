# System overview

Each player has a server-owned run and a locally rendered 3D board. The client
aims and requests actions; the server simulates every bounce, scores every pop,
and chooses all upgrade offers. Native parts and GUI elements restore the complete
presentation without external models, images, or avatar assets.

## Mapping and trust

| Source | Studio destination | Instance type / responsibility |
| --- | --- | --- |
| `src/server/Main.server.luau` | `ServerScriptService.Server.Main` | `Script`; authoritative server work. |
| `src/client/Main.client.luau` | `StarterPlayer.StarterPlayerScripts.Client.Main` | `LocalScript`; copied into each player's `PlayerScripts`. |
| `src/shared/` | `ReplicatedStorage.Shared` | Modules for board rules, deterministic physics, progression, catalog, profiles, and number formatting. |
| `src/client/Presentation.luau` | `StarterPlayer.StarterPlayerScripts.Client.Presentation` | Local camera, board, controls, counters, effects, and menus. |
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

## Run and persistence boundaries

`Board` owns the 21 values, quota calculation, single pop, refill, and disjoint
merge rules. `Simulation` uses a fixed 1/120-second step with swept collisions.
`Run` owns the phase machine, trigger queue, inventory, coins, retries, scheduled
shops/perks/events, and endless progression. Seeded RNG makes mechanics testable
without Studio. A shot's active values are separate from the next-round baseline.

The server advances each player's run independently. The presentation interpolates
snapshots and draws effects; it cannot settle a shot. Model instances and camera
state are local to each client, so boards do not collide or share progress.

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
| External asset IDs | Record IDs, purpose, ownership/access requirements, and restoration prerequisites with the adopting task. Source control cannot supply private asset access. None are required by the starter. |
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
