# RBX-013 — Arcade presentation and interaction polish

- Owner: Codex coordinator; separate world/UI contributors and read-only audit.
- Status: READY FOR REVIEW
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: 3f54f7a1b04c813831a1d6d1394bead5d7e24d62
- Branch: task/RBX-013-arcade-polish
- Reservation: [#13](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/13)
- PR: [#14](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/14)
- Implementation evidence SHA: 2d4f8fb4eab23dc8b1f62f31ea886d10cadb6fe5
- Confirmed merge SHA: NOT MERGED

## Objective and Acceptance

Polish the eight-player arcade after a visual/interaction audit. Preserve balance,
independent runs and records. No payments or Roblox publication. Existing user
authorization to deliver tested changes to main continues.

- [x] Architectural depth, readable signs and cabinet wayfinding.
- [x] Clear controls, collection/records hierarchy and responsive feedback.
- [x] Fix concrete input/transition issues found in native playtesting.
- [x] Full local checks, isolated Studio playtest and updated documentation.
- [ ] Verified main delivery; CI/merge pending.

## Implementation and ownership

World contributor owned HubWorld in a separate accepted-main worktree. Source
8ed71ffdcd983ad3a9200caca0de7f4921c1bee2 was integrated as 2fcd926.
UI contributor owned HubPresentation/HubLayout/layout tests; source
d1b59b0655a657c297f094d1060f68fd420c0bf0 was integrated as b9431f0.
Root owned Main, HubGuide, navigation geometry, integration, checks and docs,
and was the sole Studio operator. Read-only final review found no blocking defects.

- Pearl paths, seafoam fields, cabinet sectors, large numbered signs, layered
  lagoon plinth/reef, stone arch and canopy. 978 BaseParts, up from 820; station
  coordinates/collisions and ten ambient groups retained.
- Local gold cabinet beacon/outline and one enabled owned Play prompt. Modal
  panels hide it; disposal restores prompts. Server ownership stays authoritative.
- Four-action dock, clearer player/station labels, discovery progress, larger
  recipes and three-step How to Play. Compact STATS/MODELS and BESTS/LEVELS views
  preserve content. Nine viewport/safe-area layout cases.
- Modal walking/jump blocking survives respawn; closing restores controls without
  resetting camera orientation. Ambient motion reads GuiService.ReducedMotionEnabled
  as well as the explicit player override.
- Connection card, guarded transitions, pending feedback and eight-second retry
  timeout. Arcade return occupies its own rack-hint-strip region.
- No scoring, economy, profile or monetization mechanics changed.

## Checks actually run

Final checks apply to the source tree committed as
2d4f8fb4eab23dc8b1f62f31ea886d10cadb6fe5; subsequent edits are documentation only.

- PASS: Windows PowerShell scripts/check.ps1: 17 suites, StyLua, Selene 0 errors/
  warnings/parse errors, Rojo build, 28 exact mappings and documentation checks.
  Includes 800 full-rack rolls, balance, causal-chain and independent-session cases.
- PASS: git diff --check; fetched main remains 3f54f7a1b04c813831a1d6d1394bead5d7e24d62,
  accepted State Version 6.
- PASS: Studio 0.746.0.7461269, isolated peg-polish-qa.rbxlx, exact-source handoff
  while Rojo disconnected. No Studio-authored source needed returning.
- PASS: native hub/help/recipe/compact-stats/records/board captures; 978 hub parts,
  own beacon and exactly one of eight cabinet prompts enabled.
- PASS: all three help steps and Backspace dismissal. W with panel open: 0 studs;
  W for 0.6 seconds after closing: 9.60 studs. Collection stays open after avatar
  death/respawn; movement remains blocked (0 studs).
- PASS: native 390x280 panel fixture exposes all four recipe effect rows through
  STATS/MODELS; original dimensions restored afterward.
- PASS: reduced-motion override: fish moved 0 studs over 0.45 seconds; clearing
  override restored motion (0.528 studs over 0.9 seconds). Actual Roblox setting
  was read but not changed during QA.
- PASS: native E starts own cabinet run; Arcade click restores hub, beacon and
  own prompt. Native bounds assert no navigation/hint/rack overlap.
- PASS: saved ArcadeSmoke harness on eight native Studio clients: eight entries
  each for ready/start/launch/hub/resume, independent stations and runs, in-flight
  return rejection, correct camera/avatar states, seven clients after departure,
  station 8 freed. New guide/prompt checks pass on join and return.
  Ignored raw report: root scratch/polish-eight-final.json.
- PASS: console has normal startup and no game errors; existing unrelated
  203785492 asset-type warning remains.
- PASS: cleanup leaves Edit mode, 33 normal sources, both temporary QA scripts removed.
- Build: build/peg-polished.rbxlx equals build/dev.rbxlx.
  SHA256: 8757afc43ec6687fa457a5350b3aaa6cf7489fe21e0f738ba507da7fd5d17269.
- NOT RUN: physical touch/gamepad, eight-device performance, production networking/
  cloud persistence, live Rojo propagation, publication. Previous RBX-011 38-shot/
  30-campaign balance samples are historical; this pass tested targeted interactions
  and eight multiplayer shots.

## Resolved check issues

Restricted-network Selene could not fetch Roblox API definitions. The full check
passed with network-enabled execution; lint was not bypassed. An earlier task-field
capitalization issue was corrected. Native play exposed Arcade return overlapping
the rack hint; the final separate navigation region passes bounds assertions.
No unresolved implementation failures.

## Handoff

- Owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/arcade-polish.
- Accepted State Version: 6; proposed version: 7; fetched main reconciled.
- Studio: 47b8ff46-9f49-43de-9f9e-8fb2198ecb09, peg-polish-qa.rbxlx.
- Sync: root sole operator; Rojo disconnected/no serve port; Play stopped.
- Source evidence: 2d4f8fb4eab23dc8b1f62f31ea886d10cadb6fe5.
- Blockers: none; remote CI/merge pending.
- Published: NOT PUBLISHED.
- Next action: push PR #14, verify CI, merge under existing authorization and
  record the observed merge receipt with State Version 7 acceptance.
