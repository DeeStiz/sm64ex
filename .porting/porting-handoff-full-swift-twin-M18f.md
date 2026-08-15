# Porting Handoff: SM64 Modern Full Swift Twin M18f

## Scope

M18f connects the Evil Lakitu event kernel to live owner-thread allocation:

- `EnemyLakituObjectBridge.swift` runs Lakitu and Spiny through one
  `SM64ObjectScheduler` pass. Lakitu remains in the spawner list; a spawn event
  allocates a general-actor Spiny that is appended and updated in the same
  frame.
- Parent identity is explicit and generation-safe through `SM64ObjectID`.
  Lakitu's `previousObject` points at the held child until the throw animation
  frame clears it; the Spiny then transitions to thrown state and carries its
  copied parent ID in the effect record.
- Held Spiny relative transform (`-50, 35, -100`), object-record action,
  hitbox, velocity, graph offset, and interaction flags are synchronized on the
  owner thread. Thrown attacks and parent-distance deletion decrement the
  Lakitu count through value effects, including the end-of-frame unload case.

## Validation

- `script/test_enemy_lakitu_object_bridge.sh` — Swift/C pass,
  `enemyLakituObjectBridgeFingerprint=0xb2fd32a3d8fda71f`.
- `script/test_enemy_lakitu.sh`, `script/test_spiny_enemy.sh`, and
  `script/test_goomba_object_bridge.sh` — Swift/C regression passes remain
  green.
- The source uses Swift 6 mode with complete strict-concurrency checking in
  the focused script; `git diff --check` passes.
- The full matrix passes with `runs=107 failures=0`; log:
  `/tmp/sm64-modern-m18f-matrix.log`.
- The generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18f-build.log`.
- `git diff --check` passes.

These gates cover deterministic source, contract, and owner-thread callback
behavior. They do not prove full collision dispatch, all enemy/projectile
families, physical/visual/audio review, distribution, clean-machine behavior,
or human acceptance.

## Next slice

M18g should add one additional common enemy or projectile family through the
same copied-POD kernel and object-list bridge, while expanding collision
admission and effect delivery without moving C pointers across the Swift
boundary.
