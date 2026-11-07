# System overview

This is a neutral Rojo starter. Its anchored baseplate and spawn are a disposable
development scene. The smoke example proves execution locations and use of a
shared module; it is not a gameplay architecture.

## Mapping and trust

| Source | Studio destination | Instance type / responsibility |
| --- | --- | --- |
| `src/server/Main.server.luau` | `ServerScriptService.Server.Main` | `Script`; authoritative server work. |
| `src/client/Main.client.luau` | `StarterPlayer.StarterPlayerScripts.Client.Main` | `LocalScript`; copied into each player's `PlayerScripts`. |
| `src/shared/Smoke.luau` | `ReplicatedStorage.Shared.Smoke` | `ModuleScript`; independently required by server and client. |
| `assets/` | `ReplicatedStorage.Assets` | Folder of intentional source assets, initially empty. |
| `default.project.json` | `Workspace` and service roots | Explicit scene properties and filesystem mapping. |

The project's `emitLegacyScripts: true` and Rojo filename suffixes determine
the script classes above. Keep these settings and suffixes intentional;
renaming a file can change its runtime behavior. Build checks inspect the generated
instances; Studio execution is a separate check.

The client is untrusted. Keep secrets and authoritative decisions on the server;
anything in `ReplicatedStorage` is available to clients. Future remote handlers
must validate client input and authority on the server. Shared modules are not
shared mutable memory across client and server. The starter has no remote API,
datastore, external HTTP service, or production credentials.

## Ownership and restoration

| Content | Authority and storage policy |
| --- | --- |
| Scripts | `src/` is authoritative. Rojo sends filesystem edits to Studio. Deliberate shared-script export may stage Studio edits for review before copying them back. |
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

A fresh checkout restores the starter using Git, PowerShell, internet access for
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
