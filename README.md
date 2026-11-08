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
git clone --branch main https://github.com/Jayden-Amjed/Pop-a-Peg.git
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
| `src/client/` | Sculpted board and attached status screen, responsive interface and hover cards, generated models, reward animation, and sound. |
| `src/shared/` | Board, simulation, run rules, stages, catalog and evolution rules, feedback signatures, reward timeline, number formatting, and profiles. |
| `tests/` | Numerical, progression, purchase/evolution, stage, selection/layout, reward-sequencing, and profile contracts. |
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

Levels are consecutive goals within the same run: clear round **15**, then **40**,
**65**, and **100**. Each goal round has a boss modifier. Clearing round 100 opens
the victory screen and an optional endless continuation with goals every 50 rounds.
Reaching a target round without meeting its quota does not complete the level.
The round panel shows the current level and goal; four lights on the board monitor
track campaign progress.

Between shots, use one jumble to change the layout. Shops group four equipment
offers separately from up to two Supplies, available from round 11, that take
effect immediately without using an inventory slot. All offers stay visible
without scrolling. Equipment cards show **EVOLUTIONS** as modeled equations:
ingredient + ingredient = evolved item. Ingredient boxes show **NEED**,
**L1/5** through **L4/5**, or **READY** against the current rack. Hover, focus, or tap an item
to inspect its yellow trigger followed by ordered green benefits and red costs;
levels below 5 show the next upgrade amount, while level 5 shows its current power.
Recipe models appear beneath the effect list for base equipment. Evolved items,
perks, and Supplies have no recipe panel. The shop has no bottom description bar, leaving more room for
large item models and text. Cards stay mounted while selection and purchase state
change. Supplies use an **On purchase** trigger and a single **Use** purchase label.
Selling, reordering, rerolls, held offers, and extra slots shape the build.

Equipment upgrades one level at a time, up to **level 5**, including when the rack
is full. Supplies and upgrade events also add one level. An owned capped item
cannot be bought again as another copy. Moving equal-level uncapped copies together merges
them into one item one level higher; unequal levels swap positions.

When both recipe ingredients reach level 5, their evolution appears among the
shop's four equipment offers. **EVOLVE** costs no coins: it consumes both ingredients,
places one level-5 evolved item in the first ingredient's slot, and frees the other
slot. The evolved item keeps both ingredients' max-level abilities and triggers.
Thirteen recipes cover all 22 base equipment types, with alternatives for some
builds. If more evolutions are ready than fit, cycle the evolution offers for free.
Evolved items never appear as random drops and cannot evolve or upgrade further.
Perk choices can instead be declined for five coins. Run upgrades reset after
defeat; records and earned catalog and level unlocks remain.

Items can help one trigger family while costing another resource. Goldfish grows
the weakest peg; Fishbowl turns doubles into hits on the strongest peg. Gain Dial
raises the score but halves the strongest peg, feeding Pearl Scale's halve trigger.
Soft Current trims pegs before popping the weakest, while Burst Capsule doubles
a center peg, pops its neighbors, then halves the center. Direct item-to-item relay
chains have a depth limit. A shared limit of 4,096 item/perk activations per shot
ends runaway cascades with **OVERDRIVE COMPLETE**, allowing the shot to settle.

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
| Item/perk hover or UI focus | Inspect triggers, ordered effect rows, and any modeled evolution recipes. Touch opens a pinned inspection card with a close button. |
| 1×, 2×, 4× buttons | Change simulation speed. |
| Skip during rewards | Finish the reward animation and advance with the same earned rewards. |
| Sound toggle | Mute or unmute feedback sounds. |

Shops and perk/event choices use their own buttons. An owned-perk strip keeps
chosen perks visible and highlights their activations. The rack expands during
play and shrinks for shops and choices. White panel surfaces, larger choice models
and text, and gold selection outlines carry through the interface. Both perk/event
choices and their action buttons fit without scrolling, including short windows.
Score and restock panels retain their white base as the counters update and bounce;
blue wallet, ball and trigger panels remain part of the palette.

Equipment, currencies, and rewards appear as 52 source-generated 3D models, including
13 distinct evolved models. Equipment gains visible accents through five levels. Perks
keep their white display circles; equipment, coins and Supplies stand without
those circles. Primary previews use a black silhouette layer. Idle models cycle
through a gentle figure eight every 4.2 seconds, pause for their activation, then
smoothly resume after the last queued activation. Dense item bursts, swirling particles,
beams, impact rings, and ribbons connect activations to their targets. Evolving gets
its own celebration. Visual work is bounded, with capacity reserved for score and
reward arrivals, and reduced motion simplifies the particles. Score flights,
counter pulses, and refill/merge motion show the reward sequence. A decorated physical
screen attached to the board's upper-right frame displays settlement progress.
Launching updates the remaining balls directly; replenished balls fly to their
counter during rewards. Each catalog item and perk has a short musical signature;
sound remains optional.

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
