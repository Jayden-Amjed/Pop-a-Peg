# RBX-029 — Blender game adoption and grounded effects

- Owner: Codex coordinator; sole Studio operator
- Status: IN PROGRESS
- Starting main: 6ef9576dd038ff5f4efa998c4034a559e46d5dcf; accepted State Version14
- Branch: task/RBX-029-blender-game
- PR: https://github.com/Jayden-Amjed/Pop-a-Peg/pull/30
- Reservation: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/29

## Objective and authorization

User explicitly requests body resizing/pop for Lagoon Synth and Current Relay,
Quota Bonus impact at its press plate, crosschecking every model's effect emitter
placement, and adopting all Blender models into the actual game. This authorizes
new game adapters and call-site/mapping changes. Original native geometry and
animation remain frozen references. No balance or experience publication.

## Acceptance

- Synth and Relay have visible, bounded squash/pop and exact restoration.
- Press effects land on the contact plate; every catalog emitter is audited
  against its physical part/pivot and moving pose.
- All78 Blender IDs appear in game rack/shop/perks/recipes/hub/feedback as relevant,
  with correct loading, motion, sound, lifetime, camera fit and cleanup.
- Game builds, existing rules tests and focused integration checks pass; Studio
  playtest and visual evidence are distinct from source/CI checks.
- Native builders/choreography remain byte-identical to their frozen baseline.

## Ownership

Root owns game call sites, project mappings, audio integration, docs and Studio.
game_adapter owns new GameItemModels module and lifecycle tests.
game_motion owns BlenderChoreography and existing motion contracts.
game_anchors owns CatalogEffects/CatalogEffectProfiles and new placement tests.
Contributors have separate accepted-main worktrees; none operate Studio.

## Checks

Startup/current main/reservations checked. Both integration targets in Edit.
Implementation integrated: shared 78-model game adapter, bounded loader, authored
audio wrapper, Synth/Relay body pop, Quota contact stroke, and physical emitter
bindings. Required local checks PASS. Initial generated game: all78 gameplay
mounts/lifecycle/camera checks PASS (171168 projected corners); all78 physical
placement checks PASS (702 poses). Final camera refinement is pending.

Follow-up scope: inspect ineffective Seed Bank/drain actions, improve icon framing
and screen use, and enable all-content test access for confirmed account
bulkyamyed (583716264), preserving ordinary player progression.

## Handoff

Owner: Codex coordinator. Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/blender-game.
Studio gallery target9f7afcd3 is coordinator-owned. The user opened the generated
game and played through round10; session db9453ec subsequently closed. No live
Rojo. User review gallery and saved experience preserved. Old gameQA db4acb6d is
partial staging and must not be used as a playable handoff. Automatic approval
review rejected native ItemModels Source replacement there; it was preserved.
Use build/dev.rbxlx for the actual game. Blockers:none.
Next action: finish camera/drain/access changes, rebuild and verify the final
game in a fresh QA session. Proposed State Version15.
Merge:NOT MERGED. Experience publication:NOT RUN.
