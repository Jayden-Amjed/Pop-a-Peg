# RBX-029 — Blender game adoption and grounded effects

- Owner: Codex coordinator; sole Studio operator
- Status: IN PROGRESS
- Starting main: 6ef9576dd038ff5f4efa998c4034a559e46d5dcf; accepted State Version14
- Branch: task/RBX-029-blender-game
- PR: pending reservation push
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
Implementation and new runtime checks NOT RUN.

## Handoff

Owner: Codex coordinator. Checkout: C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/blender-game.
Studio game target db4acb6d-7162-40f1-9d16-7a42008a07a1; gallery target9f7afcd3.
No live Rojo. User review gallery and saved experience preserved. Blockers:none.
Next action: integrate drop-in Blender adapter and physically grounded emitters,
then test all78 mounts and a real run/shop/hub flow. Proposed State Version15.
Merge:NOT MERGED. Experience publication:NOT RUN.
