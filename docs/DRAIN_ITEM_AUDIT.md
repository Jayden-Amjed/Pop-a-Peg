# Natural-drain item audit — RBX-029

## Reproduced failure

Against the pre-fix RBX-029 gameplay implementation, a deterministic real
`Simulation.step` drain with only level-1 Seed Bank produced one drain signal,
one activation, four doubles, four changed live pegs, and zero score. Continuing
the failed round erased all four changes. The trigger was working: `_double`
mutated the current shot's `values`, while settlement restored and restocked
`baseline`, and `_resetShot` copied that baseline for the next ball.

Generic doubling remains temporary. Changing that rule globally would also make
every relay-fed growth item persistent and change the game's balance substantially.

## Audited drain behavior

| Item or channel | Outcome before settlement | Treatment |
| --- | --- | --- |
| Seed Bank | Four live doubles per level, usually too late for the ball to use | Keep live doubles for causal-chain partners; on natural drain also bank four next-shot seeds per level. |
| Rain Catcher | Lowest-peg doubles; 3% quota score per level; halve highest live peg | Bank one lowest next-shot seed per level. Preserve immediate score and the current-shot half cost. |
| Monsoon Loom | Four doubles per level; activate right neighbor; halve highest live peg | Bank four next-shot seeds per level. Preserve relay and current-shot half cost. |
| Pearl Diver | Pop highest; score from highest remaining value; halve highest live peg | Already earns score before settlement. Preserve all operations. |
| Landing Fund / Landing Shell | 15% quota score per level | Already useful at drain; unchanged. |
| Encore / Ocean Chorus | Activate every other occupied item | Queue resolves before settlement. Seed effects now carry useful growth; ordinary doubles remain available to other drain-chain scoring partners. |
| Eden Greenhouse | Seed Bank drain channel plus Growth Array pop channel | Inherits Seed Bank's level-5 bank; its ordinary Growth Array channel remains temporary. |
| Ocean Orchestra | Landing Fund drain score plus Encore activation channel | Both inherited drain channels already produce immediate outcomes; unchanged. |
| Last Word perk | Activate slot 3 twice at natural drain | Queue resolves before settlement; inherits the selected item's behavior. |

The half operations affect the **live shot**. They can reduce later queued pops or
highest-peg score effects, and can trigger half-dependent partners. They do not
penalize the next board. Drain tooltips explicitly say “highest live peg.” Their
cost may be small without a subsequent scoring partner; it is not represented as
a permanent cost.

## Bank rules and client contract

- Only the actual natural collision drain opens banking. Midflight timer/relay
  activations still double live values, and manual End Shot earns no seeds.
- Requests are bounded to the 21 board slots across the entire drain chain.
- After restoration and **all** restocks, requests select distinct positive,
  non-saturated baseline pegs. Rain selects the lowest eligible values; Seed Bank
  and Monsoon select random eligible pegs. A slot receives at most one ×2 seed.
- The next shot doubles those slots from the current baseline, capped by
  `Run.Config.maxPeg`. The seed benefit does not raise that shot's quota. Persistent
  Grow-event changes made between settlement and aim still apply, then seeds
  multiply the updated values. Nothing overwrites the baseline with stale values.
- Seeds survive failed-round retries, shop/perk/event choices, and selling their
  source item after earning them. They are consumed when the next board enters
  aim, last for that shot, and reset with a new run.
- `snapshot.pendingSeeds` is the prepared next-shot count;
  `snapshot.nextShotSeeds` lists `{pegId, old, new, slot, itemId}`;
  `snapshot.activeSeeds` lists the seeds applied when entering the current aim.
  Active entries describe the initial application, not tracking after a jumble.
- Settlement receipts add `nextShotSeeds` and `nextShotValues` for a seeded
  preview. Existing `finalValues` remains the actual persistent baseline.
- Assigned seeds emit ordinary item events with `action = "bank"`, source item,
  peg, old/new/value, and text “Seeded for next shot.” The next-shot application
  itself does not fire another double chain.

## Executed validation

`tests/SeedBank.spec.luau` runs through `tests/run.luau`. It exercises real natural
drain collision, failed retry, success/restocking, manual end, early activation,
shop sale/reroll, perk selection, Grow-event interaction, both discovery items,
Eden inheritance, direct-score drain items, generic temporary doubles, repeated
Encore activations, saturated/empty slots, receipt/snapshot isolation, and restart.
It checks actual next-shot values and unchanged quota, not just animation events.

These are deterministic gameplay contracts. Studio visual acceptance and gameplay
integration are recorded separately by the RBX-029 root operator.
