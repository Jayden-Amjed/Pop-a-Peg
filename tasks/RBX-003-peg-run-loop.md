# RBX-003 — Peg-bounce roguelike run loop

Owner: Codex gameplay coordinator; module contributors integrated.
Status: MERGED — PR #4 accepted at 602e059c2c989c53fd71541a2388acdd21621127
Objective: Build a complete aimed peg-bounce run with escalating score targets and synergistic upgrades.
Starting main: `9349530edb7eaf536ceabfed5e922ae5b65499a6` (README seed; fetched again 2026-11-07).
Dependency base: starter PR #2 merged at `18f2b17c2e3daf00ee2edd30f7b0db4d5b88e17c`.
Branch: `task/RBX-003-peg-run-loop`
Worktree: `C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\game`
PR: [#4](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/4), MERGED into main.
Reservation: [issue #3](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/3).
Implementation evidence: `c1f524c321d7ebdeb8c6d9f9f2fbb2c21c264037`.

## Scope and ownership

### Current polish revision

Fix mouse-related scenery jitter and shop selection rebuilds; enlarge rack and purchase
controls; encapsulate four equipment and at most two Supplies; strengthen selection
contrast and white accents; show owned/active perks; add bounded figure-eight idle
motion with activation handoff; bounce coins/restocks and remove the launch reserve-icon
flight. Coordinator owns Feedback, integration, Studio, documentation and merge.
Isolated polish-ui and polish-motion contributors own UI/scene and item motion.
The user explicitly authorized main integration after this revision is playtested.
Earlier verification below remains historical.

### Previous interaction/theme revision

Implemented a blue/cyan glass and pearl interface, white peg numerals, a matching
board/background, a no-scroll shop with later-run Supplies, coin-icon prices,
explicit capped upgrades, tested select/deselect/swap behavior, persistent shot
trigger statistics, perk cash-out, distinct item motion/audio, and themed synergies.
Coordinator owns integration, feedback/audio, documentation, and Studio. Isolated
`aero-ui`, `aero-models`, and `aero-rules` worktrees own UI/scene, model motions,
and catalog/run contracts. All contributors are integrated; earlier evidence is historical.

### Reward and presentation revision

The revision adds a repeating layered quota meter, flying score/coin/ball rewards,
automatic restoration/refill/merge choreography, 37 original models, a large green
interface, and ten sound cues. Value-1 pegs pass through; five total balls are spent
on launch and restored at settlement. Ordinary result dialogs are removed.
The server remains authoritative; presentation consumes bounded settlement receipts.

Ownership: coordinator integrates and owns Studio; isolated `feedback-ui`,
`feedback-models`, and `feedback-rules` worktrees own presentation, item models,
and shared run/simulation contracts respectively. Contributors are integrated.

Fixed front-view 3D board; independent per-player runs; 21 numbered pegs, aimed
bouncing, score-before-halving, board-clear bonus, quota/restock growth, currency,
shops, perks, events, bosses, defeat/restart, and endless continuation after 80 rounds.
Twenty equipment items, eight perks, three consumables, duplicate upgrades, selling,
reordering, held offers, rerolls, and inventory expansion form the run economy.
Only records and earned catalog unlocks carry between runs; scoring power resets.
No production publication, monetization, or cooperative board is included.

Coordinator owns integration, documentation, verification, and Studio. Contributors
used separate worktrees for simulation, progression, and presentation. All source
is restored from Git and pinned tools; native parts/UI need no external geometry or
images. Public Roblox audio IDs and access requirements are in [ASSETS](../docs/ASSETS.md).

## Acceptance

- [x] Aim and launch a visible ball; reliable collisions pop numbered pegs.
- [x] Peg values, merges, replenishment, quotas, and bonus counters form a complete loop.
- [x] Purchases, random upgrades/perks, ordering, and duplicate upgrades affect play.
- [x] Loss, restart, transitions, bosses, and long-run progression are playable.
- [x] Fixed camera, 3D board, readable counters, effects, and responsive controls.
- [x] Server validates actions; separate Run objects own each player's state.
- [x] Records/unlocks survive run resets; storage availability is explicit.
- [x] Meaningful tests and Studio MCP playtests recorded below.
- [x] Review scope, evidence, and next task remain discoverable.

## Checks

### Shop, motion, and feedback polish

Source: `c1f524c321d7ebdeb8c6d9f9f2fbb2c21c264037`.
Main reconciliation: `644ba6327ce3a6dc84a2081883fa23e874e1a9be`; no source differences.

- PASS pinned check.ps1: formatting, Selene 0 errors/warnings, eight contract suites,
  28 progression cases, build, 15 exact source mappings, documentation links/fields.
- PASS all eight suites inside Studio with production modules; feedback regression
  covers guarded wallet/receipt arrivals, score/coin/restock pulses, perk cues, and
  removal of the reserve-to-ball launch flight.
- PASS all six shop inspections at 390x844, 844x390, 1046x524, 1280x720,
  1920x1080: text fits, buttons stay inside, no scrolling, centered number then coin.
  Five HUD layouts and additional 1280x850/900 detail cases pass with all eight perks.
- PASS actual shop/rack selection clicks retain the same 12 model previews with
  zero additions/removals. Actual seven-slot Seed Bank L1 purchase charges five
  coins (33 to 28), upgrades to L2, and shows the capped state afterward.
- PASS all eight owned perks plus duplicate First Spark display; actual perk click
  opens separate PERK details without moving/selecting equipment. Activation changes
  the status to ACTIVE. Score/coin/restock scale pulses rise and return exactly to 1.
- PASS 39 model IDs follow bounded figure-eight poses, stop ambient movement for
  triggers, and resume after retriggers; Reduced Motion/static opt-out checked.
  All 78 level variants retain exact static rest transforms after activation.
- PASS cloud/camera probe through mouse sweeps: 24 opaque, shadowless clouds;
  zero transform changes across 147 rendered frames. Nonoverlapping sky strips and
  shadowless aim markers remove the observed render-instability sources.
- PASS all 20 production sources restored exactly; normal server/client startup.
  An ordinary-action driver ran 134 seconds over two runs, observed four shops,
  two perk choices and highest round 15, with no action rejection or project error.
  It attempted 44 launches, seven new purchases and one upgrade; these driver counters
  are attempted actions, not separate per-action acknowledgment assertions.
  It never forced shot endings or edited authoritative state. Its immediate restart
  bypasses the terminal UI gate, so it is not terminal-menu timing evidence.
- PASS independent source review: shop caching/current callbacks, perk ordering,
  pulse guards, idle/activation handoff, and compact HUD capture; no material finding.
- PASS final [push CI](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42445007436)
  and [PR CI](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42445011935)
  at 329a68f0a140101703814c05b21b03738cef16b7.
- MERGED: GitHub returned merged=true and receipt
  602e059c2c989c53fd71541a2388acdd21621127 for PR #4 after PR #2 integration.
  Fetched origin/main confirms that receipt; source remains identical to Studio-tested c1f524c.

QA target: isolated peg-aero-qa.rbxlx, stopped with normal sources; Rojo disconnected.
Generated playable: build/peg-polished.rbxlx. User-owned play windows were untouched.
MCP captures omit BillboardGui text; the user previously confirmed actual peg numerals.
Unrelated 203785492 asset-type warning remains. Physical touch, two clients in one
server, published persistence, live plugin propagation, and publication remain NOT RUN.
This is bounded functional/play smoke coverage, not a human balance or sound-mix verdict.

### Aquatic presentation and hybrid-build revision

Source: `b1cf8886a2b5c7f79e3147984ff140cb55900fa1`.

- PASS pinned repository checks: formatting, Selene 0 errors/warnings, Board,
  Run (28), Profile, RewardTimeline, ItemFeedback, InventorySelection, ShopLayout,
  Rojo build, exact mappings, and documentation structure.
- PASS those seven suites inside Studio against the integrated modules.
- PASS no-scroll shop: all six offer inspections, text fits and button bounds at
  390x844, 844x390, 1046x524, 1280x720 and 1920x1080 (30 cases).
  These are forced layout fixtures, not physical-device tests.
- PASS actual input: select/deselect same rack item; swap two and clear selection;
  full seven-slot Seed Bank L1 upgrade charges exactly 5 coins (33 to 28) and becomes L2.
  L2 offers display MAX LEVEL; new items report RACK FULL. Shared client/server
  intent tests cover affordability, capacity, duplicate/capped requests and no spending on rejection.
- PASS pending move contracts: stale snapshots/notices cannot prematurely clear the
  gate; matching swaps, duplicate merges, rejection, phase changes and timeout release it.
- PASS perk decline through actual UI: 25 to 30 coins, choice consumed. Counts retain
  Pops 2 / Quotas 3 through the round-5 shop, then clear when Next Round is clicked.
- PASS white text on all 21 pegs; corrected glass rails and landscape proportions;
  new model gallery visually inspected, including Goldfish/Fishbowl glass sorting.
  The capture tool still omits BillboardGui text; color properties were checked directly.
- PASS all 39 model IDs at L1/L2 (78 constructions and mounts), finite poses,
  moving groups, 50 rapid retriggers and cleanup. All 78 restore bit-exact CFrames,
  sizes and colors. Prism targets align in four directions; spring compresses/rebounds;
  clock rotation accelerates then decelerates. An initial angle metric falsely
  flagged identical float32 matrices; direct component comparisons proved zero drift.
- PASS integrated effects: three prism rays plus hybrid growth/cost beams, distinct
  ×2 and ÷2 labels, score arrival at 100 and counter scale pulse above 1.
- PASS all 33 item motifs: started, nonzero playback signal, stopped by observation
  window and obeyed mute. Softer hit/launch asset also loaded and produced signal.
  These checks establish runtime playback, not human approval of the mix.
- PASS existing feedback state regression: settlement arrivals, wallet race protection,
  bounded batches/skip, terminal flow, repeated receipts and restart handling.
- PASS heuristic smoke: targeted first-contact aiming reached the first shop in
  47/50 runs and cleared boss 20 in 26/50; random aiming reached the shop in 17/50
  and cleared boss 20 in 3/50. A fish-priority policy also achieved 47/50 and 26/50.
  No forced endings; longest observed shot 16.67 simulated seconds. These are
  policy samples, not human win rates or proof of long-term balance.
- PASS 984 additional malformed, capped and replayed requests without rejected-state
  spending or offer mutation.
- PASS temporary QA fixture removed; all 20 production sources restored exactly.
  Normal server/client startup, keyboard input and ball flight checked separately. A successful
  shot produced seven pops, two walls and one quota, then advanced to round 2 with
  four balls and four coins; completed-shot counts remained visible. Generated deliverable: `build/peg-aero.rbxlx`.

Studio target: isolated `peg-aero-qa.rbxlx`; production sources restored; Rojo disconnected.
No unrelated place or existing user play window was modified. Only the known unrelated
203785492 asset-type warning appears. NOT RUN: physical touch, two clients in one server,
published persistence, live Rojo plugin propagation, merge or publication.

- PASS implementation [push CI](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42437549547)
  and [PR CI](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42437552545).

### Previous reward/presentation revision (historical)


Source: `e4953887985930b08514ebcee2c0d392570a861e`.

- PASS `scripts/check.ps1`: pinned tools, StyLua, Selene (0 errors/warnings), Board,
  18 Run cases, Profile, RewardTimeline, Rojo build, 11 explicit mapped source checks,
  documentation links, and essential status/task fields.
- PASS Board, Run (18), Profile, and RewardTimeline contracts inside the Studio server.
- PASS real server/client shot transitions: a failed shot returns to aiming without
  a dialog; a successful shot restores one ball, pays one coin, and advances round.
  Final restored-source startup and Q/Space keyboard play checked separately.
- PASS controlled client feedback: score arrivals precede counting; three restocks
  move wallet 25 to 28 and reserves 1 to 4, then open the shop once. Refilled pegs
  fall, disjoint matches travel/merge, and the final board stays through choices.
  Exact 10,000-restock batching completes with bounded effects; skip finishes with
  authoritative balances. Score labels from one simultaneous origin coalesce.
- PASS client state regression harness: no early settlement coins, stale wallet
  callbacks cannot undo purchases, rewards arrive before continuation at 4x,
  zero-life terminal flow, repeated receipts, and restart receipt IDs.
- PASS all 37 native models instantiated and visually reviewed in Studio; all 31
  catalog IDs covered, upgraded equipment faces visible, pulse returns exactly to
  scale 1. Static previews avoid idle geometry writes. All geometry is original.
- PASS five public audio assets loaded. Each of ten cues starts, has nonzero measured
  playback signal, stops after its bounded duration, and obeys mute. This is runtime
  signal verification, not a claim of a human-approved sound mix.
- PASS 25 menu bounds/text-fit cases: shop, perk, event, gameover, victory at
  390x844, 844x390, 1046x524, 1280x720, 1920x1080. Perk triggers are explicit;
  a 1e30 target fits the compact HUD. These are layout fixtures, not physical devices.
- PASS modeled shop upgrade clicked through MCP: wallet 25 to 21, matching equipment
  L1 to L2, offer SOLD, and model refreshed. Short landscape choices remain scrollable.
- PASS temporary fixtures removed; all 16 production scripts/modules compared
  exactly with files. Current generated deliverable: `build/peg-feedback.rbxlx`.
- PASS revised heuristic balance smoke: largest visible first-contact aiming reached
  the first shop in 47/50 runs and cleared the first boss in 25/50. Random aiming
  reached the first shop in 17/50. No forced shot endings. These samples supersede
  earlier physics balance figures and do not predict human win rates.
- PASS GitHub [push check](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42432165237)
  and [PR check](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42432168013)
  at the implementation SHA above.

Studio target: isolated `peg-feedback.rbxlx`; normal sources restored; Rojo disconnected.
No unrelated place or existing user play window was edited. Native fixture captures
omit BillboardGui text; the user previously confirmed peg numbers in actual Studio.
No project runtime errors; unrelated 203785492 asset-type warnings persist.
NOT RUN: physical touch, two clients in one server, published persistence, live Rojo
plugin propagation, merge, or publication. Human visual/audio review remains useful.

### Earlier implementation (historical)

The following evidence applies to `c73e29012c40053bab943d03d5412ae05b89ad7a`,
before the revised collisions, life timing, and presentation above.

- PASS `scripts/check.ps1` on Windows / PowerShell: pinned tool verification,
  StyLua, Selene (0 errors/warnings), Board contracts, 14 Run cases, Profile
  contracts, Rojo build, script class/source mapping, and documentation checks.
- PASS same Board, Run (14), and Profile tests executed inside the Studio server.
- PASS 704 malformed payload cases across eight phases and 60,000 progression
  steps with finite, serializable snapshots; additional numerical caps, settlement,
  frozen offers, and restart event serial checks.
- PASS natural-action balance samples: highest visible first-contact aiming reached
  the first shop in 48/50 runs and cleared the first boss in 31/50. A separate
  30-seed sample completed all 80 rounds for seeds 11, 27, and 29. No forced shot
  endings; longest natural shot 93.2 simulated seconds. These are heuristic balance
  samples, not a claim about a human win rate. Ignored exploratory harnesses were used.
- PASS Studio keyboard jumble/launch, visible ball/counters, retry button, first shop
  through ordinary server requests, item purchase, held-offer reroll, and inventory
  reorder. First shop reached with 10 coins. Invalid remote payloads left authoritative
  coins/score/phase unchanged.
- PASS reserve exhaustion and R-key restart: best score 64, best round 6, and the
  earned catalog unlock survived; equipment, perks, score, coins, reserves, and
  round reset. Studio reports session-only records.
- PASS expanded-shop and perk/event/result/gameover/victory UI fixtures. Fixed the
  parent-coordinate offset: all six panels have a 12-pixel inventory gap and fit
  the desktop viewport. QA fixtures were removed; all 11 Studio script sources
  then compared exactly with committed files.
- PASS user confirmed numbered pegs are visible in actual Studio. MCP image capture
  omits BillboardGui numbers; that image limitation is not a game label failure.
- PASS GitHub [PR check](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42428253853)
  and [push check](https://github.com/Jayden-Amjed/Pop-a-Peg/actions/runs/42428248885)
  at implementation `c73e29012c40053bab943d03d5412ae05b89ad7a`.

Studio version: Windows 0.746.0.7461269; Rojo/plugin 7.7.1.
Normal server/client play evidence: `d3e7556036925b9c6a09ff923abf52bbb93bde9e`.
Final layout and restored source equality: `c73e29012c40053bab943d03d5412ae05b89ad7a`.
Development targets: generated `build/peg-run.rbxlx` and separate `build/peg-run-qa.rbxlx`.
QA is stopped in Edit mode, with normal source restored; live Rojo sync is disconnected.
The user's separate play window was left available. No unrelated place was edited.

Known limitation: Studio Output still emits asset-type warnings for ID 203785492,
which is not referenced by project source. No game runtime errors remained.
NOT RUN: two clients in one live server, physical mobile/touch play, published
DataStore reads/writes, live Rojo plugin propagation, merge, or production publication.
Standalone and in-engine profile tests do not establish cloud persistence.
Publishing: NOT PUBLISHED; no production target selected.

## Handoff

Owner: coordinator; final polish implemented and verified.
Source: c1f524c321d7ebdeb8c6d9f9f2fbb2c21c264037; later commits reconcile main/docs only.
Status: State Version 2 accepted by PR #4 at 602e059c2c989c53fd71541a2388acdd21621127,
following accepted starter Version 1. Main was fetched and source equality rechecked.
Blockers: none. The user-authorized integration is complete.
Next action: human playtest build/peg-polished.rbxlx; reserve a new task for further changes.
Before publication, select a development experience for multi-client/mobile/cloud-save
verification. Publication is a separate task.
