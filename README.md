# Pop a Peg

A Roblox peg-bounce roguelike with a fixed front-view 3D board. Aim a ball through
numbered pegs, meet the round quota, grow the board, and build combinations of
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
| `src/client/` | Local board, responsive interface, generated models, reward animation, and sound. |
| `src/shared/` | Board, simulation, run rules, catalog and purchase rules, feedback signatures, reward timeline, number formatting, and profiles. |
| `tests/` | Numerical, progression, purchase, synergy, selection/layout, reward-sequencing, and profile contracts. |
| `default.project.json` | Rojo service mapping and development lighting. |
| `assets/` | Intentional source assets mapped to `ReplicatedStorage.Assets`. |
| `scripts/` | Setup, checks, build, sync, and bounded export import. |
| `build/`, `scratch/`, `.tools/` | Ignored generated output, staging, and local tools. |
| `tasks/` | Task specifications, detailed evidence, and latest handoffs. |

[System overview](docs/SYSTEM_OVERVIEW.md) explains boundaries and asset ownership.
[Asset sources](docs/ASSETS.md) records model provenance and public audio dependencies.
[Workflow](docs/WORKFLOW.md) covers task → isolated checkout → sync/test → evidence
→ PR/merge → handoff. [AGENTS](AGENTS.md) is the short operating contract.

## Play loop

Start with five total balls; launching spends one. Every pop scores the peg's
current value, then halves it. The ball passes through one-point pegs, removing
them, and bounces off higher values. Clearing the board doubles the shot score.
The timer shows elapsed shot time; there is no automatic shot timeout.

Each full quota earns a restock. After the shot ends, each restock awards one
coin and restores one ball, up to five. The board returns to its pre-shot values,
then each restock fills empty slots with falling pegs and merges equal pairs.
The reward sequence advances automatically into the next shot or upgrade choice;
there is no result confirmation button. A failed shot resets the score and board
for another attempt while balls remain.

Between shots, use one jumble to change the layout. Shops show four equipment
offers and, from round 11, up to two Supplies that take effect immediately without
using an inventory slot. All offers stay visible without scrolling; selecting an
offer shows its trigger, effects, tradeoff, and synergy partners in one inspection
area. Selling, reordering, rerolls, held offers, and extra slots shape the build.

Buying a duplicate level-1 item upgrades it to level 2, including when the rack is
full. Level 2 is the cap: an owned capped item cannot be bought again as another
copy. Perk choices can instead be declined for five coins. Run upgrades reset after
defeat; records and earned catalog unlocks remain.

Items can help one trigger family while costing another resource. Goldfish grows
the weakest peg; Fishbowl turns doubles into hits on the strongest peg. Gain Dial
raises the score but halves the strongest peg, feeding Pearl Scale's halve trigger.
Soft Current trims pegs before popping the weakest, while Burst Capsule doubles
a center peg, pops its neighbors, then halves the center. Direct item-to-item relay
chains have a depth limit so a circular arrangement can finish.

Shot statistics include pops, walls, doubles, halves, quotas, time, first hit,
drain, clear, and item/perk activations. They remain visible after automatic round
transitions until the next launch or a manual **Next Round** click in the shop.

| Control | Action |
| --- | --- |
| Pointer or touch on the board | Aim while held; release to launch. |
| Launch button / Space | Launch when aiming; end the shot during flight. |
| Jumble button / Q | Rearrange the board once before each shot. |
| End Shot button / E | Finish early without waiting for the ball to drain. |
| Inventory item | Select it; click again to clear, or another unlocked slot to swap and clear the selection. |
| 1×, 2×, 4× buttons | Change simulation speed. |
| Skip during rewards | Finish the reward animation and advance with the same earned rewards. |
| Sound toggle | Mute or unmute feedback sounds. |

Shops and perk/event choices use their own buttons. Equipment, currencies, and
rewards appear as source-generated 3D models, with individual activation motions,
targeted effects, score flights, layered quota feedback, and refill/merge motion.
Each catalog item and perk has a short musical signature; sound remains optional.

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
