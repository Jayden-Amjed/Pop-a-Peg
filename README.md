# Pop a Peg

A Roblox peg-bounce roguelike with a fixed front-view 3D board. Aim a ball through
numbered pegs, meet the round quota, grow the board, and build combinations of
run upgrades. Up to eight players meet in an aquarium arcade, with an independent
board and run for each player.

Sources build reproducibly through Rojo. Roblox Studio MCP supports inspection
and playtests; Git records reviewed implementation and verification evidence.

## Project purpose

| Decision | Pop a Peg |
| --- | --- |
| Vision | Turn one carefully aimed shot into satisfying chains of rising numbers. |
| Intended player experience | Read the board, choose an angle, watch the bounce, then shape the next run upgrade. |
| Milestone | Play an independent run, earn tiered chests, open them in the arcade, and expand the equipment available in later runs. |
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
| `src/server/` | Station ownership, hub world, authoritative runs, leased profile storage, and global leaderboards. |
| `src/client/` | Sculpted board and attached status screen, responsive interface and hover cards, generated models, reward animation, and sound. |
| `src/shared/` | Board, simulation, run rules, stages, tiered catalog, chest/research progression, evolution rules, feedback, and profiles. |
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

Enter the aquarium arcade first. Walk among eight personal cabinets, the animated
fish tank, gardens, benches, collection gallery, chest pavilion and leaderboard
displays. Press **PLAY**
or use your cabinet's prompt to start. The roster shows occupied stations and run
progress. Collection cards show discovered evolutions and their modeled recipes;
records show personal bests and completed level goals.
Pearl paths and numbered cabinet signs lead around the lagoon. Your cabinet has
a gold guide and outline; other cabinets do not offer an unusable Play prompt.
Use **How to Play** for a short introduction. Opening a hub panel pauses walking
controls, and closing it returns control without turning the camera.

Use **ARCADE** between shots to return to the hub. **RESUME** restores the same
build, coins and round, including a victory waiting for its Endless choice.
Shots and settlement must finish before returning. A lost run starts fresh, while
records and discoveries remain. A parked run is paused only for this server session;
leaving the server retains records, not the unfinished run.
A connection card covers initial loading, and Play/Arcade show request progress
instead of accepting repeated transition clicks. The Arcade button respects the
screen's safe inset.

### Chests, equipment discoveries and records

New profiles start with eight equipment blueprints: Tap Driver, Sun Prism, Shore
Meter, Landing Shell, Survey Lens, Reef Chime, Compass and Seed Bank. The catalog
contains 40 base equipment types, including 18 new designs. Equipment is Common,
Uncommon, Rare or Legendary. Shops can roll only the blueprints owned when that
run began; opening a chest while a run is paused expands the pool for the next
new run, without changing the parked run's offers. Old equipment discoveries and
earned workshop/growth/relay access migrate into ownership.

Extra restocks beyond the first earned by each completed shot are saved as a
separate **Restocks** currency. The hub wallet shows the balance and opens the
chest market. Choose a tier, buy a chest to store it, then open it when ready.
This currency carries across runs; spending it does not remove board refills,
coins, or restored balls. The market is available only in the hub.

| Chest tier | Saved restocks |
| --- | ---: |
| Common | 100 |
| Uncommon | 250 |
| Rare | 500 |
| Legendary | 1,000 |

These are optional longer-term savings targets. First-hit aiming bots earned no
extras in 12 sampled runs; a future-best-shot upper-bound cohort earned 0–540 in
12 runs. Those simulations do not establish human earning pace. The free chest
rewards below remain the early discovery path; see the reproducible balance
evidence in [RBX-017](tasks/RBX-017-restock-market.md).

Earned and purchased chests open at the hub pavilion or through **CHESTS**. Each opening unlocks
an unowned item of the chest's exact tier while any remain. The reward schedule is:

| Earned condition | Chest |
| --- | --- |
| Defeat after successfully clearing at least 3 rounds | Meadow/Common below 15 clears; Lagoon/Uncommon at 15–39; Aurora/Rare at 40–99; Celestial/Legendary at 100+ |
| Clear round 15 | Lagoon/Uncommon |
| Clear round 40 or 65 | Aurora/Rare |
| Clear round 100 | Celestial/Legendary |
| Clear each additional 50-round Endless milestone | Celestial/Legendary |

Milestones award once each per run; the qualifying defeat reward awards once at
the end of that run. Returning to the hub or resuming never awards another chest.
When a tier is fully discovered, its chest gives **1 / 3 / 6 / 10 research** from
Common through Legendary. In the workshop, select a locked blueprint and spend
**6 / 12 / 24 / 40 research** for its tier to unlock that specific item. These are
earned rewards; there are no paid chests, purchase prompts or active Robux products.

The hub leaderboards show total time in this experience, the highest round reached
after entering **Endless**, and recorded Robux spent **in this experience**. Time
includes both hub and run play. Campaign progress is separate from the Endless
record. Published servers use global rankings; Studio clearly labels its local
session rankings. The Robux board shows an empty state while purchases are disabled,
and unavailable cloud rankings are not presented as confirmed global results.

Start with five total balls; launching spends one. Every pop scores the peg's
current value, then halves it. The ball passes through one-point pegs, removing
them, and bounces off higher values. Clearing the board doubles the shot score.
The timer shows elapsed shot time; there is no automatic shot timeout.

Meeting the round quota earns the first restock. Each additional restock costs
twice the previous one: total score thresholds are 1×, 3×, 7×, 15× the round quota,
and so on. Shots can earn up to **6 / 8 / 10 / 12 restocks** across the four campaign
levels; the meter shows the next cost and current cap. After the shot ends, each restock awards one
coin and restores one ball, up to five. The board returns to its pre-shot values,
then each restock fills empty slots with falling pegs and merges equal pairs.
Playback shows at most five full refill/merge sequences. For larger rewards,
the first three and final two play, with a short batch transition between them;
every earned restock still applies to the board and rewards.
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

With a full rack, shop openings and rerolls reserve the first two equipment cards
for owned items that can still upgrade. They prefer different items; the other
two cards roll normally. Ready evolutions use unreserved cards. If fewer than two
upgrade levels remain in the rack, only those useful upgrades are guaranteed.
Held cards keep their price and may move to preserve these reserved positions.

Equipment upgrades one level at a time, up to **level 5**, including when the rack
is full. Supplies and upgrade events also add one level. An owned capped item
cannot be bought again as another copy. Moving equal-level uncapped copies together merges
them into one item one level higher; unequal levels swap positions.

When both recipe ingredients reach level 5, their evolution appears among the
shop's four equipment offers. **EVOLVE** costs no coins: it consumes both ingredients,
places one level-5 evolved item in the first ingredient's slot, and frees the other
slot. The evolved item keeps both ingredients' max-level abilities and triggers.
Thirteen recipes connect the original equipment set, with alternatives for some
builds; the new equipment adds distinct trigger combinations without placeholder
evolution recipes. If more evolutions are ready than fit, cycle the offers for free.
Evolved items never appear as random drops and cannot evolve or upgrade further.
Perk choices can instead be declined for five coins. Run upgrades reset after
defeat; records and earned catalog and level unlocks remain.

Items can help one trigger family while costing another resource. Goldfish grows
the weakest peg; Fishbowl turns doubles into hits on the strongest peg. Gain Dial
raises the score but halves the strongest peg, feeding Pearl Scale's halve trigger.
Soft Current trims pegs before popping the weakest, while Burst Capsule doubles
a center peg, pops its neighbors, then halves the center. Direct item-to-item relay
chains have a depth limit. An activation cannot trigger itself again through its
own descendants, including score-to-quota and pop/double feedback. Fresh ball hits
can start new chains, and evolved trigger channels remain independent. A shared
4,096-activation safety limit still bounds exceptional cascades. Shore Meter,
Landing Shell, Dew Cell and Quota Bonus scale their direct points with the current
round quota, so early flat bonuses cannot generate thousands of restocks.

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

Small screens use a core-safe layout that accounts for Roblox controls and device
insets. **STATS** opens shot statistics and owned perks; short landscape layouts
switch between those views. During compact shops and choices, **RACK / SELL**
opens the equipment rack without permanently squeezing the cards. Compact evolution
summaries open the full recipe inspector. Chest, workshop and leaderboard panels
adapt their model, text and pagination regions to the available safe area.

Equipment, perks, currencies and rewards appear as **78 distinct source-generated
3D models**: 40 base equipment, 13 evolutions, eight perks, three Supplies and 14
utility/reward models. Perks have their own geometry; chest tiers have distinct
hinged lids and opening motions, and event prompts use dedicated emblems instead
of borrowed equipment. Authored upgrade details and UI level badges identify levels. Perks
keep their white display circles; equipment, coins and Supplies stand without
those circles. Previews render each model once; enlarged black clone layers and
bounds-based floating upgrade rails/nodes were removed. Remounting a preview
disposes its previous model and camera. Follow the [model style guide](docs/MODEL_STYLE_GUIDE.md)
and [Blender pilot workflow](docs/MODELING_WORKFLOW.md) for future modeling.
Idle models cycle
through a gentle figure eight every 4.2 seconds across shops, perk choices and hub
previews, pause for their activation, then
smoothly resume after the last queued activation. Dense item bursts, swirling particles,
beams, impact rings, and ribbons connect activations to their targets. Evolving gets
its own celebration. Visual work is bounded, with capacity reserved for score and
reward arrivals, and reduced motion simplifies the particles. Score flights,
counter pulses, and refill/merge motion show the reward sequence. A decorated physical
screen attached to the board's upper-right frame displays settlement progress.
Launching updates the remaining balls directly; replenished balls fly to their
counter during rewards. Each catalog item and perk has a short musical signature;
sound remains optional.

Studio uses **session progress** so local testing does not touch live player data.
Published sessions save records, ownership, earned chests and research together
under an exclusive profile lease. The newest 64 chest/research request receipts
survive reconnects, preventing retries from spending again or changing the original
request's target. A failed profile load refuses entry instead of overwriting real
progress with defaults. The interface reports unavailable saving honestly.
The server allocates eight stations and rejects overflow. When a production place
is selected, set its **Max Players to 8** in Creator Dashboard before publishing;
the local source does not change that account-level place setting.

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
