# RBX-011 — Aquarium arcade and progression balance

- Owner: Codex coordinator; arcade_world, arcade_client and arcade_balance contributors.
- Status: READY FOR REVIEW
- Reviewed: 2026-11-08 (America/Los_Angeles)
- Starting main: ad313f065c14c23ba67b2223424a8670ce9d2dc0
- Branch: task/RBX-011-arcade-balance
- Reservation: [#11](https://github.com/Jayden-Amjed/Pop-a-Peg/issues/11)
- PR: [#12](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/12)
- Implementation evidence SHA: 131d04598e3162c747e7e3dc3a19fb34f0b05dc2
- Confirmed merge SHA: NOT MERGED

## Objective and scope

Build a complete aquarium arcade hub with eight personal stations, walking avatars,
instant independent runs, return/resume and retry, earned evolution collection and
records. Diagnose and fix early self-sustaining score/restock explosions without
removing meaningful combinations. No monetization or production publication.

## Acceptance criteria

- [x] Eight station assignments, independent runs and safe join/leave/mode transitions.
- [x] Detailed walkable hub, functional station prompts, collection and records UI.
- [x] Normal game controls and camera restored reliably through repeated transitions.
- [x] Reproduced runaway builds corrected with regressions and balance simulations.
- [x] Full checks and Studio gameplay pass; multiplayer observations recorded honestly.
- [ ] Current docs, playable build and verified main delivery (final integration pending).

## Implementation

The hub is an original 820-part pearl/aqua arcade with eight detailed cabinets,
an aquarium, seven fish, gardens, seating, arches, collection gallery and records
kiosk. Ten local animation groups move 65 fish/bubble parts while the hub is active.
Reduced motion disables ambient movement; disposal restores the original poses.

The server reserves one station before yielding, loads walking avatars, keeps
run state private, and anchors avatars during runs. Returning to the hub pauses
the same run between shots; resuming preserves its coins, items, round and identity.
Flight/settlement cannot be parked. A winning run retains its Endless choice.
Lost runs start fresh. Leaving saves records/discoveries and frees the station.
Client controls/camera, mute and completed receipt identity survive mode changes.
Collection/records and an eight-player roster are functional. New evolution
purchases record discoveries without introducing permanent power or paid content.

Quota Bonus could recursively reward its own quota crossings, and item-generated
natural events lost their activation ancestry. At quota 10, one L1 Quota Bonus
crossing produced 163,850 score, hit 10,000 restocks and exhausted 4,096 activations.
The same test now produces 10.5 score, one restock and one activation.

Causal traces now survive queued/coalesced operations. An item/perk cannot
reactivate through descendants of its own activation; new physical hits start
fresh chains, and evolved channels retain separate identities. The existing depth
and 4,096-activation safety bounds remain. Direct score items scale with round
quota per level: Shore Meter 8%, Landing Shell 15%, Dew Cell 3%, Quota Bonus 5%.
For example, first-round L1 Landing Shell changed from 150 points/15 restocks to
1.5 points/zero restocks. Rewards use successive costs of 1×, 2×, 4×, 8× quota
(cumulative 1×, 3×, 7×, 15×), with visible per-shot caps 6/8/10/12 across stages.
A successful shot still advances exactly one round.

## Dependencies and ownership

Root owns server Main/session policy, integration, docs and the sole Studio session.
Contributors used separate checkouts from accepted main:
world fb804036bf676f628b1c1004fe6b7487828590df;
client b1e38fa7c9e869e5c8f0a6a10fa780c45475c7c3 with lifecycle fixes
e14e5a81e98a7a414efc7bd89febe2139b68a77a and 5507624c075ec853b182fff049fcc4136463099c;
balance 2d7ba83b08d48d8b0e5665edccdf3242594c9c2b;
ambience 7e9670644f6e2cc14f90b4f5b82f1e7d97036faa.
Root integrated these and the final session/victory fixes at the implementation SHA.
No contributor operated Studio.

## Checks actually run

| Check | Result | Evidence |
| --- | --- | --- |
| Accepted main / reservation | PASS | Fetched ad313f0; reserved issue 11 and draft PR 12 before implementation |
| Full local checks | PASS | Windows PowerShell scripts/check.ps1; StyLua; Selene 0 errors/warnings; 17 suites; Rojo build; 27 exact source mappings; documentation checks |
| New balance regressions | PASS | 10 contracts for causal chains, quota feedback, independent evolved channels, stage limits, direct-point scaling, discoveries and one-round advance |
| Session regressions | PASS | Eight unique stations, overflow/duplicate rejection, run isolation, pause/resume, profile separation, reuse, and victory resume into Endless |
| Native Studio suites | PASS | Server Balance (10) and ArcadeSessions; client HubLayout and CounterProgress; updated victory regression rerun in Server |
| Live production gameplay | PASS | 120.3 seconds through ordinary remotes, 38 shots, three runs, three shops, four purchases, one perk; reached round 15; maximum one restock; no game errors |
| Seeded campaign simulation | PASS | 30 legal campaigns with 13 full-trajectory aim candidates per shot: 25 cleared round 40; five lost at 18/26/37/40/40; max early restocks 2, overall 3, max activations 79 |
| Eight native Studio clients | PASS | All eight unique stations; start, launch, in-flight return rejected, hub return and resume; camera/GUI/anchor checked; departing player frees station while other seven continue |
| Saved multiplayer harness rerun | PASS | Final implementation with victory fix: eight ready/start/launch/hub/resume entries, seven idle entries and station 8 freed; both temporary scripts removed afterward |
| Repeated UI transitions | PASS | Six hub/run changes preserve runId, round and coins; Custom walking vs Scriptable anchored camera states restored |
| Collection and visual inspection | PASS | Native collection/recipe clicks; white panels and modeled ingredient equation; 820 hub parts; arrival view moved inside boundary |
| Ambient motion | PASS | 120 sampled steps move 65 parts in ten groups; destroy restores each CFrame/transparency |
| Review | PASS | Read-only lifecycle review caught victory discard; fixed and regression passed; no additional findings |
| Main / CI | PENDING | Final branch push and verified merge receipt remain |
| Fresh tool setup / fallback | PASS | All four pinned tools downloaded in a clean scratch install; a second install forced primary URL failures and verified all four official API fallbacks and checksums |

Local evidence files in the original root scratch folder include
arcade-eight-pass.json, arcade-eight-final.json, arcade-playtest-final.json, arcade-transitions.json,
arcade-entry-capture.json.0.png and arcade-recipe-capture.json.0.png.
The contributor's scratch/balance-campaign-results.txt records 30 seeds.
These captures are local artifacts, not required source assets.
The reproducible opt-in multiplayer harness is in [tests/studio](../tests/studio/README.md)
and is excluded from generated game builds.

The live gameplay driver selected legal angles and normal actions at up to 4× speed;
it did not inject coins/items. It exercised no upgrade or Supply purchase in that
two-minute window. The 13-angle campaign driver is an optimistic aiming benchmark,
not a human difficulty estimate. Eight Studio clients do not establish eight-device
performance or real network conditions.

## Corrected QA observations and remaining limits

- Arrival was initially too close to the boundary for the camera; moved inside.
  Character positioning is reapplied after LoadCharacterAsync finishes.
- Sibling GUI layering darkened white hub panels; Global layering restores them.
- A fixed 300 ms readiness delay falsely failed client 8. Waiting for actual
  camera/GUI/character readiness made the eight-client test pass.
- A two-client-then-AddPlayers test stalled; launching eight clients directly passed.
- A temporary combined native suite wrapper failed to parse; individual factories
  ran all four affected suites successfully.
- A victory regression fixture initially used round 100 after victory; actual
  victory already advances to 101. Corrected the fixture and reran locally/in Studio.
- Standalone sandboxed Selene could not fetch its API dump; the full check with
  network access passed. No production code failure was hidden.
- Saving the smoke harness exposed an unused loop binding and Selene's missing
  EnumItem.Name type. Removed the binding and scoped a documented lint allowance
  to that already runtime-tested enum access.
- Documentation validation caught renamed required dashboard labels; restored
  Accepted source and Studio-tested source before final checks.
- Initial GitHub push/PR runs 42465310409 / 42465314592 and their second attempts
  failed before checks on HTTP 504 tool downloads. Setup now retries at most three
  times and uses locked official release-asset API URLs after failure. Fresh normal
  and forced-fallback installs pass; all tool versions and checksums are unchanged.
- Automatic review rejected opening QA through the unrelated user Studio window.
  No open-file action occurred; isolated MCP execution completed the work instead.
- Physical touch/gamepad, cloud persistence and production publication: NOT RUN.
  Live Rojo plugin propagation is not claimed; all source was explicitly installed
  in isolated QA. MCP captures may omit peg labels; unrelated asset 203785492 warning
  remains. Long-run human difficulty and device-specific performance need playtesting.
- Production Max Players must be set to 8 in Creator Dashboard when a target place
  is selected. Source enforces eight stations but cannot change that place setting.
- Existing player records are retained. There is no migration, wipe or monetization.

## Handoff

- Owner: Codex coordinator.
- Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/arcade.
- Accepted State Version: 5; proposed version: 6.
- Studio target: isolated peg-aero-qa (e848e7a7-b569-4600-b4e6-14ec13ecbaac), root only.
- Sync: Rojo disconnected; Edit mode, 32 normal sources, both temporary QA scripts removed.
- Published: NOT PUBLISHED; no production experience selected.
- Next action: push final evidence, confirm CI, merge PR 12 and record its actual receipt.
