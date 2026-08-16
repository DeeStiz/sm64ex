# Full Swift Twin Handoff — M20s

## Status

M20s is complete locally as the generation-safe Bob-omb Buddy owner/effect
bridge. The bridge owns object-pool attachment, C action values, record
synchronization, live cannon-ID validation, dialog/sound/camera intent
delivery, NPC time-stop flags, interaction reset, and scheduler retirement.

## Evidence

- Value fingerprint: `0xdc0f36c0b93e7920`.
- Owner/effect fingerprint: `0xba317f5f6079097e`.
- Focused script: `script/test_bobomb_buddy_object_bridge.sh`.
- Full matrix: `/tmp/sm64-modern-m20s-final-matrix.log`,
  `MATRIX_RESULT runs=174 failures=0`.
- Native Debug build: `/tmp/sm64-modern-m20s-build.log`,
  `** BUILD SUCCEEDED **`.
- `git diff --check` and zero unchecked-Sendable audit pass.

## Changed surface

- `SM64Modern/BobombBuddyBehavior.swift` now uses the source-authored C
  action constants: idle `0`, turn-to-talk `2`, talk `3`.
- `SM64Modern/BobombBuddyObjectBridge.swift` attaches generation-safe IDs,
  derives nearest-cannon existence from the live pool when an ID is supplied,
  synchronizes action/role/cannon status/visibility/physics/NPC fields, and
  routes typed sound, dialog, and prepare-cannon camera intents through the
  owner-thread effect sink.
- `tests/sm64_modern_bobomb_buddy_object_bridge_smoke.swift` covers advice and
  cannon phases, time-stop admission/cleanup, stale-safe pool ownership, and
  unload retirement; its C contract is an independent fingerprint oracle.

## Boundaries

This closes the Bob-omb Buddy value-plus-owner slice only. Camera cutscene
execution, real dialog/audio presentation, save-file cannon unlock persistence,
remaining NPCs/puzzles/secrets/rewards, Metal 4 production hardening, and
device/visual/physical/human acceptance gates remain open. No device, visual,
controller, audio, store, notarization, or clean-machine claim is made.

## Next

Continue M20 with the next reachable NPC/puzzle family, preserving the value
kernel → owner bridge → effect sink → C differential contract pattern. Commit
locally without pushing.
