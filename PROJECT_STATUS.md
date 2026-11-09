# Current project state

State Version: 16 (RBX-031 proposal; accepted predecessor remains 15).
Reviewed: 2026-11-08, America/Los_Angeles
Objective: Annotated UI retouch complete and ready for user playtesting.

Active proposal: [RBX-031](tasks/RBX-031-shop-prototype.md), Codex coordinator,
branch task/RBX-031-shop-prototype, [draft PR32](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/32).
Main re-fetched at 44762e38b5b4e3ad2f89c789ae6a7a6b6f6d4560; accepted State15 unchanged.
Implementation and Studio-tested source: 05f1d16deda43a0721a51e318990a9e4503678ae.
Retouch audit: 997988317ea859ec56f5cc31be3e40d29bef7de9.
Source checks PASS at the audit commit; preview build PASS at implementation.

The shared pearl/aqua UI covers gameplay and arcade panels. This retouch adds
complete inline inspection/evolutions, inset model windows, larger trailing coins,
structured Supplies, name-first perk/event cards, a stable larger rack, lower
desktop HUD stacks, boxed controls and a music toggle. Misaligned white highlight
strips are removed. Results/victory and collection gallery retain their layouts;
workshop only moves its name above the model.

Fresh Studio cdcbb509-40c9-42ce-98d6-6d5cc363469f verified all 15 screens at HD1080,
iPhone13 landscape and iPhone7 landscape; actual safe areas 1919x1022, 749x331,
666x316. Retouch checks PASS with 242/230/229 Blender Ready samples; full-flow
checks PASS with all eight actions, including chest animation/reveal and research.
All 34 normalized client/fixture fingerprints match the local source.
[Retouch evidence](docs/evidence/RBX-031/retouch-desktop.json) and
[flow evidence](docs/evidence/RBX-031/retouch-flow-desktop.json); other presets
and exact results are linked in the task.

Actual pointer checks PASS for Recipe back to Gallery, music slash, normal Play,
Launch, Arcade and Resume. The normal shot settled back to aim in round1;
Resume preserved the run and mute state. Unmuting restored volume0.7.
No game-script errors in the final normal-play console; existing203785492
asset-type warning remains. Physical-device and multiplayer checks NOT RUN.
An initial flow audit was interrupted by the operator changing screens; the
complete untouched rerun passed. No unresolved retouch blocker.

User files at the repository root:
- Screen selector: `build/Pop-a-Peg-UI-RETOUCH.rbxlx`.
- Normal game: `build/Pop-a-Peg-FULL-UI-RETOUCH.rbxlx`.

The fresh preview session is stopped in Edit with preview flags restored and
device simulation reset. Press Play, then use **UI PREVIEW**. Coordinator is sole
Studio operator; no live Rojo/port. Synthetic fixture resources do not save.
Historical sessions/files and unrelated root outputs are preserved. Exact build
hashes and earlier test history are in the task. Local/Studio results above are
independent of CI; the draft PR tracks checks on the pushed branch.

Accepted source: 212c76260a5a6ce44dfd8ba5d10bd3ab77a25c4e.
Accepted task: [RBX-029](tasks/RBX-029-blender-game.md), merged through
[PR30](https://github.com/Jayden-Amjed/Pop-a-Peg/pull/30).
Its Blender/model/drain/resume evidence remains in
[RBX-029 review](docs/evidence/RBX-029/REVIEW.md).
Published: no experience update. RBX-031 is not merged; accepted State15 is unchanged.
Next action: user playtests the retouch selector or normal-game build.
Repository administration: main unprotected; temporary default remains starter.
