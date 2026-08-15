# Porting Handoff: SM64 Modern Full Swift Twin M18a

## Scope

M18a starts common-enemy migration with a bounded Goomba actor shadow:

- `SM64GoombaState` preserves the regular/huge/tiny size table, scale,
  death-sound class, draw distance, damage, gravity, hitbox/hurtbox constants,
  action state, target yaw, speed, timer, health, loot, and respawn flags.
- `SM64GoombaKernel` mirrors the C walk/chase branch, random turn timers,
  wall/edge turn fencing, close-Mario jump, airborne yaw turn, landing,
  attacked-Mario response, tiny death/coin/respawn route, and huge weak-attack
  jump route. Inputs and effects are copied POD values; no C object pointers or
  global object graph cross the boundary.
- The Swift smoke and independent C contract exercise the same regular/huge/
  tiny traces and stable effect bits.

This is not yet live object-list authority. C still owns scheduler traversal,
collision resolution, attack dispatch, animation/audio delivery, and spawner
behavior.

## Validation

- `script/test_goomba_enemy.sh` — Swift/C pass,
  `goombaEnemyFingerprint=0x0b1058cb88f78d06`.
- All `script/test_*.sh` scripts — `MATRIX_RESULT runs=103 failures=0`;
  log: `/tmp/sm64-modern-m18a-matrix.log`.
- Native Debug build after `xcodegen generate` — `** BUILD SUCCEEDED **`;
  log: `/tmp/sm64-modern-m18a-build.log`.
- `git diff --check` — pass.

These are deterministic kernel/source/build gates. They do not establish live
full-game enemy behavior, physical/visual/audio review, distribution,
clean-machine validation, or human acceptance.

## Next slice

M18b should bind the Goomba POD kernel to the owner-thread object scheduler and
collision/attack input snapshot, record effect ordering through schema-4, and
cover the triplet spawner/respawn flag route before adding Koopa or Boo.
