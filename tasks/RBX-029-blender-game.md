# RBX-029 — Blender gameplay and useful drain growth

- Owner: Codex coordinator; sole Studio operator
- Status: IN PROGRESS
- Starting main: 6ef9576dd038ff5f4efa998c4034a559e46d5dcf; accepted State Version14
- Branch: task/RBX-029-blender-game
- PR: https://github.com/Jayden-Amjed/Pop-a-Peg/pull/30
- Reservation: https://github.com/Jayden-Amjed/Pop-a-Peg/issues/29
- Implementation:7eb6c18a971e4f33cb0a2896c23d4ce7fe816897

## Scope and authorization

User requests Synth/Relay body pop, Quota impact on its plate, all-item physical
emitter audit and Blender gameplay adoption. Follow-ups request useful drain
effects, larger readable previews and all-content access for their Roblox ID.
Original native builders/choreography stay frozen. No monetization or experience
publication. Existing authorization permits pushing the finished version to main.

## Implementation

- All78 reviewed Blender IDs enter normal rack/shop/perk/recipe/hub/feedback
  previews through GameItemModels. A four-worker/15-second bounded loader
  preloads typed model instances and verifies fetch statuses; native fallback
  is explicit and preserves reference source.
- Synth/Relay gain anticipation, whole-body pop and recoil. Quota holds plate
  contact at phases.25–.29; its effect follows the plate. All78 emitters bind to
  meaningful moving parts/surfaces or documented ambient origins.
- Game cameras stay fixed and fit full sampled model movement. Decorative burst
  tips can crop at card edges; gallery framing still includes effects.
- Shop and choices use full preview rectangles; owned perks use occupied rows;
  desktop hub expands to1280×800; hover recipes grow on taller displays.
- Seed Bank, Rain Catcher and Monsoon retain live growth, then bank capped natural-
  drain growth for the next shot. Every peg gets at most one saved double; no
  quota/baseline inflation. Seeds survive routes and source-item sale. Manual
  End Shot earns none. Eden inherits Seed Bank. All other drain channels audited.
- Feedback labels saved growth, previews the next board, and restores completed
  seeded/restocked boards on hub resume. A completed result retries continue.
- Account583716264 (bulkyamyed, verified from Studio) has temporary all40 equipment
  and13 evolution-preview access. Normal level5 recipes, currency, chests and
  records remain intact. Grants are filtered out of saves. Disable PlaytestAccess
  and restart when the user requests ordinary progression.

## Ownership and checks

Root: mappings, game call sites/audio, docs, Studio. Separate contributor worktrees
own adapter/UI, motion/contact, emitter/drain and owner-access/resume fixes.

Required local check.ps1 PASS at7eb6c18: format/lint, gameplay/layout/profile/seed/
access/resume tests, all78 motion,12792 effect samples, audio, playback/loader/
framing tests, three builds, source mappings and docs. Catalog78/477/127664triangles,
12archives; frozen eight-source guard, game mapping, hub reveal and468 affine
placement contracts PASS. See [runtime evidence](../docs/evidence/RBX-029/REVIEW.md).

## Handoff

Owner/next owner: Codex coordinator.
Checkout:C:/Users/Amjedd/Documents/ChatGPT/Pop a Peg/.worktrees/blender-game.
Actual game target:c35ab669-2eca-4659-b7dd-8f6bf966b3ca, Pop-a-Peg-PLAYTEST.rbxlx.
All71 current built scripts match that Edit session before Play. Background game
and isolated tests are running; final presentation fixture is pending. No live Rojo.
Gallery9f7afcd3 is also coordinator-owned; old gameQA db4acb6d is partial staging.

Earlier automatic approval rejected overwriting native ItemModels in old gameQA;
no retry/bypass occurred. Fresh generated build preserves frozen source by design.
Studio launch encountered12-instance warning. User opened two older files, then
the correctly named build. Those old files/experience were not changed.
Computer Use stopped on physical Escape; subsequent tests use background MCP only.

Deliverable: repository-root build/Pop-a-Peg-PLAYTEST.rbxlx, exact integration
build copy. SHA256:A3378DA49F64BA4C9DD481B5E754F56A73B02861C6468E27287C8A83D6D785E6.
Next: finish background presentation fixture, push/check CI, merge PR30, record
GitHub-confirmed acceptance once from14 to15. Merge:NOT MERGED. Publication:NOT RUN.
