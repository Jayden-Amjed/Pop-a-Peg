# Pop a Peg

A small, reusable Roblox starter for **Studio ↔ local files ↔ GitHub**. It provides
server, client, and shared smoke scripts, a reproducible Rojo build, and task
records that let people and agents resume work without guessing. It does not
define a game genre or gameplay framework.

## Project purpose

| Decision | This starter |
| --- | --- |
| Vision | Make a Roblox project easy to restore, inspect, and continue. |
| Intended player experience | Not selected; the development place is a smoke-test scene. |
| Milestone | Establish the source/build/sync and collaborative handoff workflow. |
| Success criteria | Build from a clean checkout; verify script mappings; demonstrate Studio sync and explicit export; preserve exact evidence and ownership. |
| Non-goals | Gameplay systems, monetization, production deployment, or full-place round-tripping. |

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
.\scripts\serve.ps1 -Port 34872
```

If Windows blocks local scripts, invoke the individual script with
`powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\setup.ps1`
(and likewise for the other scripts). This does not change the machine policy.
Setup downloads checksum-locked tools from `tools.lock.json` into ignored
`.tools/`; no global tool manager is required. Restart Studio after plugin
installation. Open `build/dev.rbxlx`, then use the **Rojo 7.7.1** plugin to connect to
`localhost:34872`. Inspect the incoming changes before accepting them. See the
[Studio workflow](docs/WORKFLOW.md#studio-sync-and-explicit-return) for the build
output, smoke checks, and deliberate Studio-to-file return path.

| Command | Purpose |
| --- | --- |
| `.\scripts\setup.ps1` | Install Rojo 7.7.1, StyLua 2.6.0, and Selene 0.32.0 locally. |
| `.\scripts\check.ps1` | Run the repository's formatting, lint, build, and documentation checks. |
| `.\scripts\build.ps1` | Generate a development place from source. |
| `.\scripts\serve.ps1 -Port 34872` | Serve this checkout to one Studio operator. |
| `& .\.tools\stylua.exe src` | Format Luau intentionally. |
| `.\scripts\import-shared.ps1 -InputModel .\scratch\Shared.rbxmx` | Stage an explicit shared-script export for review; never overwrite source automatically. |

## Source layout

| Path | Responsibility |
| --- | --- |
| `src/server/` | Server-only scripts. |
| `src/client/` | Per-player client scripts. |
| `src/shared/` | Modules replicated to server and clients; no secrets. |
| `default.project.json` | Rojo service mapping and minimal development scene. |
| `assets/` | Intentional source assets mapped to `ReplicatedStorage.Assets`. |
| `scripts/` | Setup, checks, build, sync, and bounded export import. |
| `build/`, `scratch/`, `.tools/` | Ignored generated output, staging, and local tools. |
| `tasks/` | Task specifications, detailed evidence, and latest handoffs. |

[System overview](docs/SYSTEM_OVERVIEW.md) explains boundaries and asset ownership.
[Workflow](docs/WORKFLOW.md) covers task → isolated checkout → sync/test → evidence
→ PR/merge → handoff. [AGENTS](AGENTS.md) is the short operating contract.

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
