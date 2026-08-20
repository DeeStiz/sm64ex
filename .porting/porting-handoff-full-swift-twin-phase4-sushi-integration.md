# Full Swift Twin Handoff — Continuation Phase 4 Sushi Integration

Date: 2026-08-20

## Completed

- Promoted `bhvSushiShark` and `bhvSushiSharkCollisionChild` through central
  dispatch route 259.
- Added generation-safe owner storage, reset/unload/prune cleanup, the public
  Sushi spawn API, water-level propagation, and wave-trail child spawning.
- Added both identities to the behavior coverage manifest and updated the
  explicit live-route/dispatch/runtime source lists.
- Updated the manifest contract to fingerprint `0xa610f82db91e28f6`.

## Evidence

- Focused Sushi Shark C↔Swift contract: `0x829e2dcf1c565b1a`.
- Manifest: 534 rows, 492 Swift owners, 42 explicit C adapters.
- Passed `script/test_sushi_shark.sh`.
- Passed `script/test_behavior_manifest.sh` and coverage inventory.
- Passed `script/test_behavior_dispatch_bridge.sh` and
  `script/test_engine_runtime.sh`.
- Passed live-route input-only source compilation, strict Debug Xcode build,
  and `git diff --check`.

## Remaining

- Central promotion remains for NPC/menu, Squarish Path Moving, Pushable Metal
  Box, Tilting Bowser Lava Platform, LLL Bowser Puzzle, Snowman Bottom, and
  Treasure Chest.
- The 7,419-shard inventory and worker-result protocol are validated, but the
  full live execution/merge closure is not complete.
- M34 visual/device acceptance remains open: the M34c harness stopped after
  three initial display-link presents without a post-resume acknowledgement;
  archive reuse was not proven in that run.
- M35 distribution, notarization/Gatekeeper, physical/device, audio/effect,
  performance/thermal, and human 120-star acceptance remain open.

## Next phase

Promote the NPC/menu family through the same central route/effect/manifest
pattern, run the full focused and aggregate gates, update the goal ledger, and
commit that bounded phase locally before continuing.
