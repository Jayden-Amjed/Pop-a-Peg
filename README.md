# Pop a Peg

A Roblox peg-bounce roguelike with a fixed front-view 3D board. Aim a ball through
numbered pegs, exceed the round quota, grow the board, and build combinations of
run upgrades. Each player has an independent board and run.

Sources build reproducibly through Rojo. Roblox Studio MCP supports inspection
and playtests; Git records reviewed implementation and verification evidence.

## Project purpose

| Decision | Pop a Peg |
| --- | --- |
| Vision | Turn one carefully aimed shot into satisfying chains of rising numbers. |
| Intended player experience | Read the board, choose an angle, watch the bounce, then shape the next run upgrade. |
| Milestone | Complete the round, shop, perk, loss, restart, and endless loop in Roblox. |
| Success criteria | Playable 3D board with meaningful upgrade combinations, readable counters, reliable collisions, and isolated player state. |
| Non-goals | Monetization, cooperative boards, production publishing, and permanent power purchases. |

See [PROJECT_STATUS](PROJECT_STATUS.md) for the **only current dashboard**, including
what has actually passed, active ownership, and the next task.

## Quick start (Windows)

Install Git, Windows PowerShell 5.1 or PowerShell 7, and Roblox Studio. A Roblox
account is needed for Studio; no experience ID is needed for a local development
place. In PowerShell, from a fresh clone of this repository:

```powershell
git clone https://github.com/Jayden-Amjed/Pop-a-Peg.git
Set-Location .\Pop-a-Peg
.\scripts\setup.ps1
.\scripts\check.ps1
.\scripts\build.ps1
& .\.tools\rojo.exe plugin install
.\scripts\serve.ps1 -Port 34873
```

If Windows blocks local scripts, invoke the individual script with
`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1`
(and likewise for the other scripts). This does not change the machine policy.
Setup downloads checksum-locked tools from `tools.lock.json` into ignored
`.tools/`; no global tool manager is required. Restart Studio after plugin
installation. Open `build/dev.rbxlx`, then use the **Rojo 7.7.1** plugin to connect to
`localhost:34873`. Inspect the incoming changes before accepting them. See the
[Studio workflow](docs/WORKFLOW.md#studio-sync-and-explicit-return) for the build
output, runtime checks, and deliberate Studio-to-file return path.

| Command | Purpose |
| --- | --- |
| `.\scripts\setup.ps1` | Install pinned Rojo, StyLua, Selene, and Luau tools locally. |
| `.\scripts\check.ps1` | Run formatting, lint, simulation/progression tests, build, and documentation checks. |
| `.\scripts\build.ps1` | Generate a development place from source. |
| `.\scripts\serve.ps1 -Port 34873` | Serve this checkout to one Studio operator. |
| `& .\.tools\stylua.exe src` | Format Luau intentionally. |
| `.\scripts\import-shared.ps1 -InputModel .\scratch\Shared.rbxmx` | Stage an explicit shared-script export for review; never overwrite source automatically. |

## Source layout

| Path | Responsibility |
| --- | --- |
| `src/server/` | Server-only scripts. |
| `src/client/` | Per-player client scripts. |
| `src/shared/` | Board, simulation, run rules, upgrade catalog, number formatting, and profile contract. |
| `tests/` | Numerical, progression, input-validation, and profile invariants. |
| `default.project.json` | Rojo service mapping and development lighting. |
| `assets/` | Intentional source assets mapped to `ReplicatedStorage.Assets`. |
| `scripts/` | Setup, checks, build, sync, and bounded export import. |
| `build/`, `scratch/`, `.tools/` | Ignored generated output, staging, and local tools. |
| `tasks/` | Task specifications, detailed evidence, and latest handoffs. |

[System overview](docs/SYSTEM_OVERVIEW.md) explains boundaries and asset ownership.
[Workflow](docs/WORKFLOW.md) covers task → isolated checkout → sync/test → evidence
→ PR/merge → handoff. [AGENTS](AGENTS.md) is the short operating contract.

## Play loop

Aim with the pointer and launch through the board. Every pop scores the peg's
current value, then halves it; a one-point peg disappears. Clearing the whole
board doubles the shot score. Every quota earned gives a restock and a coin.
Restocks replenish empty slots and merge equal values for the next round.

Between shots, use one jumble to change the layout. Shops offer items, duplicate
upgrades, selling, reordering, and extra inventory slots. Perks and events add
new ways to trigger combinations. Choose a faster simulation speed when desired.
Run upgrades reset after defeat; records and earned catalog unlocks remain.

Studio uses **session records** so local testing does not touch live player data.
Published sessions use a versioned DataStore for records/unlocks. The interface
reports unavailable saving instead of claiming a cloud save succeeded.

## Reuse for another project

- Create a new repository from these starter files and set its own `origin`.
  Do not carry over this repository's task history or claim its test evidence.
- Replace the purpose table above with that game's vision, player experience,
  milestone, measurable success criteria, and non-goals. A name alone is not a design.
- Customize the project name and development scene; retain explicit service mappings.
- Start a new status ledger and task reservation. Record actual tool/Studio checks.
- Record development and production place IDs only when chosen, plus external
  asset prerequisites and ownership. Keep credentials out of Git.
- Recheck GitHub settings and protections in the new repository; copied workflow
  files do not transfer repository settings or publish a Roblox experience.
