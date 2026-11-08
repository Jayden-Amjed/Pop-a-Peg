# RBX-017 — Restock wallet, hub chest market and weighted sound

- Task ID: RBX-017
- Owner: Codex coordinator (sole Studio operator); backend and audio contributors in isolated worktrees
- Status: IN PROGRESS
- Reservation / issue: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/17
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: a056cfc4773b69df2ef986d72c1c483ac3bd4c10
- Branch: task/RBX-017-restock-market
- Worktree / checkout: C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\restock-market
- PR: NOT OPENED
- Implementation evidence SHA: NOT COMMITTED
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Save extra restocks (all beyond the first earned per shot) as currency across runs.
Players choose chest tiers and spend this currency only in the hub. Common starts
at 100 and Uncommon at 250; tune higher prices using gameplay simulations and
Studio playtests. This supersedes the earlier automatic random-tier chest idea.
Play at most five restock refill/merge sequences without losing rewards. Give
selected old/new items more bass and thump while preserving light electronic tones.
Diagnose and resolve the whole-monitor yellow capture border. No monetization or
Roblox publication.

## Acceptance criteria

- [ ] Saved, server-owned wallet earns each shot's extra restocks exactly once.
- [ ] Hub displays wallet and four clearly priced chest choices; spending is validated and idempotent.
- [ ] Balancing evidence covers multiple ordinary play runs and high-restock cases.
- [ ] At most five full restock cycles play; skipped cycles preserve final board and totals.
- [ ] Light/heavy audio contrast covers old and new items with bounded resources.
- [x] Yellow border resolved: Node visual-testing runtime reset released capture helper; user confirmed disappearance.
- [ ] Checks, Studio evidence, documentation and authorized main integration recorded.

## Dependencies and overlapping paths

Root owns client UI, RewardTimeline, animation receipt storage, integration/docs and
Studio. Backend contributor owns Profile, ChestProgression, server session/remotes
and related tests; audio contributor owns SoundEffects, ItemFeedback, audio tests
and ASSETS audio notes. Both isolated worktrees start from the same accepted main.
No other open PRs or issues existed before reservation 17.

## Implementation evidence

Pending implementation. User's existing peg-progression.rbxlx is in Play and is
preserved; QA will use a separately generated place. Rojo remains disconnected.

## Checks actually run

| Command / action | Source SHA and environment | PASS / FAIL / NOT RUN | Result and limitation |
| --- | --- | --- | --- |
| Startup Git/remote/reservation inspection | a056cfc, Windows | PASS | Clean integration predecessor; fresh origin/main unchanged; issue17 reserved. |
| Capture shutdown | Windows, Node runtime | PASS | codex-computer-use.exe exited after reset; user confirmed entire-screen border gone. |
| Local checks | Pending | NOT RUN | |
| Studio checks | Pending | NOT RUN | |

## Limitations and blockers

No live Roblox publication. Production persistence/rejoin proof remains separate
from isolated Studio checks.

## Handoff

- Objective / completed work: reservation, scoped parallel ownership, capture issue resolved.
- Owner / next owner: Codex coordinator.
- Absolute checkout / branch / PR: checkout above; task/RBX-017-restock-market; draft pending.
- Main SHA inspected / accepted State Version: a056cfc4773b69df2ef986d72c1c483ac3bd4c10 / 8.
- Evidence SHA / proposed State Version: pending / 9 pending acceptance.
- Checks and remaining limitations: implementation and native checks pending.
- Studio version / development target / operator: user peg-progression preserved in Play; isolated QA target pending; root only.
- Sync worktree / endpoint / port / connected or stopped: Rojo disconnected; explicit generated build handoff.
- Published experience / place / observed version: NOT PUBLISHED.
- Preserved work / overlapping tasks: root bootstrap and previous task worktrees untouched.
- Next smallest executable action: implement currency UI and five-cycle timeline; integrate backend/audio contributions.
