# RBX-003 — Peg-bounce roguelike run loop

Owner: Codex gameplay coordinator; module contributors integrated.
Status: READY FOR REVIEW — reward feedback and presentation revision verified
Objective: Build a complete aimed peg-bounce run with escalating score targets and synergistic upgrades.
Starting main: `9349530edb7eaf536ceabfed5e922ae5b65499a6` (README seed; fetched again 2026-11-07).
Dependency base: starter PR #2 at `608c273d9f31022d2f161584c4c92188bb4405cd`; unmerged.
Branch: `task/RBX-003-peg-run-loop`
Worktree: `C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\game`
PR: [#4](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/4), targets the starter branch until PR #2 is integrated.
Reservation: [issue #3](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/3).
Implementation evidence: `e4953887985930b08514ebcee2c0d392570a861e`.

## Scope and ownership

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

### Current revision

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

Owner: coordinator; revised implementation complete and ready for review.
Source: exact implementation SHA above; subsequent evidence-only commits may follow.
Status: version 2 proposal depends on the starter's unaccepted version 1. Main remains
README-only with no accepted ledger. Main's content and SHA were reconciled before push.
Blockers: no implementation blocker; PR #2 must be accepted before this dependent
PR can target accepted main. Neither PR is merged.
Next action: human playtest `build/peg-feedback.rbxlx` and review PR #4. Before a release,
select a development experience for multi-client/mobile/cloud-save verification;
record production targeting and publication as a separate authorized task.
