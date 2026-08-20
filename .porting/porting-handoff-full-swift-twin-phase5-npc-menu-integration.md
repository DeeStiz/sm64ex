# Full Swift Twin Handoff — Continuation Phase 5 NPC/Menu Integration

Date: 2026-08-20

## Completed

- Promoted the NPC/menu family through grouped central routes:
  - route 260: `bhvUkiki`, `bhvMacroUkiki`;
  - route 261: `bhvUkikiCage`, `bhvUkikiCageStar`;
  - route 262: `bhvMips`;
  - route 263: `bhvToadMessage`;
  - route 264: `bhvMenuButton`, `bhvMenuButtonManager`.
- Added owner storage/init, identity mapping, reset/begin/update/prune/unload
  cleanup, spawn/effect aggregation, manifest rows, and explicit source lists.

## Evidence

- Focused NPC/menu C↔Swift contract: `0x4ff30b57a3db6922`.
- Manifest: 534 rows, 500 Swift owners, 34 explicit C adapters,
  fingerprint `0xaffa1724f93c6e44`.
- Passed `script/test_npc_menu.sh`, behavior manifest, coverage, dispatch
  bridge, and engine runtime tests.
- Passed live-route input-only C/Swift replay and source compilation.
- Regenerated strict arm64 Debug Xcode build reached `BUILD SUCCEEDED`.
- `git diff --check` passed.

## Remaining

- Squarish Path Moving, Pushable Metal Box, and Tilting Bowser Lava Platform
  remain focused/local-only route slices.
- LLL Bowser Puzzle, Snowman Bottom, and Treasure Chest remain local-only.
- Full 7,419-shard execution, sanitizer parity, M34 visual/device closure,
  release, and human acceptance remain open.

## Next phase

Promote the remaining platform routes in disjoint central batches, then close
the puzzle/Snowman/Treasure owners before starting full live shard orchestration.
