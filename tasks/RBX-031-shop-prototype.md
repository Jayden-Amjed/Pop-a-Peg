# RBX-031 — Desktop and landscape shop prototype

- Task ID: RBX-031
- Owner: Codex coordinator (sole Studio operator); read-only shop reviewer
- Status: IN PROGRESS
- Reservation / issue: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/31
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: 44762e38b5b4e3ad2f89c789ae6a7a6b6f6d4560
- Branch: task/RBX-031-shop-prototype
- Worktree / checkout: C:\Users\Amjedd\Documents\ChatGPT\Pop a Peg\.worktrees\shop-prototype
- PR: draft pending
- Implementation evidence SHA: NOT IMPLEMENTED
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Implement an original pearl/aqua cartoon shop close to the accepted visual
concepts, with real Blender model previews, desktop and landscape mobile layouts.
Preserve authoritative purchases, upgrades, evolutions, holds, rerolls, Supplies,
selling and rack management. Do not change frozen native art, run balance or
profiles. Provide an isolated local Studio build for immediate user testing.
No experience publication or merge requested.

## Acceptance criteria

- [ ] Four equipment offers and up to two horizontal Supplies remain readable.
- [ ] Models use the adopted Blender catalog and survive unrelated refreshes.
- [ ] Shop actions, inspection and rack management use existing game rules.
- [ ] Required source checks and representative Studio interactions pass.
- [ ] Desktop and landscape device layouts verified; limitations recorded.
- [ ] Reproducible opt-in fixture opens directly to the shop for user testing.

## Dependencies and overlapping paths

Based on accepted RBX-029 / State 15. No open PRs found at start.
Coordinator owns Presentation, ShopLayout, new shop styling, fixtures and tests.
Reviewer is read-only and has no Studio ownership. Root checkout and existing
Studio files remain preserved. No live Rojo connection belongs to this worktree.

## Checks actually run

Implementation and Studio checks: NOT RUN. Main/state, worktrees, remote branches,
reservations and open PRs inspected. Isolated checkout created from accepted main.

## Handoff

- Owner / next owner: Codex coordinator
- Objective / completed work: reservation and isolated checkout; implementation next
- Absolute checkout / branch / PR: as above; draft pending
- Main SHA inspected / accepted State Version: 44762e3 (full above), 15
- Evidence SHA / proposed State Version: none yet; 16 proposal at completion
- Checks and limitations: no new implementation evidence yet
- Studio target / operator: fresh local file to be built; coordinator only
- Sync worktree / endpoint / port: none; no live Rojo
- Published experience / place / observed version: no publication requested
- Preserved work: root outputs and all existing worktrees/Studio sessions
- Next smallest executable action: implement shop and deterministic test fixture
