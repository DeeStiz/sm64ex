# Porting Handoff: SM64 Modern Full Swift Twin M18e

## Scope

M18e defines the Evil Lakitu spawn/control event boundary:

- `SM64EnemyLakituKernel` preserves the uninitialized reveal/cloud gate,
  distance- and Mario-speed-based horizontal steering, vertical approach,
  face/move yaw turn limits, and wall reflection.
- The sub-action state preserves no-Spiny, hold-Spiny, and throw-Spiny
  transitions; the three-Spiny cap; 30-frame cooldown; distance/facing throw
  admission; animation-frame parent-link clear; and randomized 100–199 frame
  rearm cooldown.
- Results are copied state/effect values (`spawnSpiny`, `beginHold`,
  `beginThrow`, `clearPreviousSpiny`, and throw/attack effects). No C object
  pointer or global object list crosses the boundary.

This is intentionally an event kernel, not yet the live allocator. C remains
authoritative for Lakitu behavior callbacks, Spiny object allocation/parent
wiring, collision resolution, and effect sinks.

## Validation

- `script/test_enemy_lakitu.sh` — Swift/C pass,
  `enemyLakituFingerprint=0x4021eec4cfdb5938`.
- `script/test_spiny_enemy.sh`, `script/test_goomba_enemy.sh`, and
  `script/test_goomba_object_bridge.sh` — Swift/C passes remain green.
- All `script/test_*.sh` scripts — `MATRIX_RESULT runs=106 failures=0`;
  log: `/tmp/sm64-modern-m18e-matrix.log`.
- Native Debug build after `xcodegen generate` — `** BUILD SUCCEEDED **`;
  log: `/tmp/sm64-modern-m18e-build.log`.
- `git diff --check` — pass.

These gates cover deterministic source, contract, and build behavior. They do
not prove live Lakitu allocation, full-game enemy coverage, physical/visual/
audio review, distribution, clean-machine behavior, or human acceptance.

## Next slice

M18f should connect Lakitu spawn/throw events to `SM64ObjectPool` and the Spiny
bridge with owner-thread parent/previous-object identities, then add one
projectile/common-enemy family through the same schema-4 effect boundary.
