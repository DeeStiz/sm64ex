# Porting Handoff: SM64 Modern Full Swift Twin M18d

## Scope

M18d adds the bounded Spiny common-enemy family:

- `SM64SpinyKernel` preserves the C action IDs for walking, Lakitu-held,
  thrown, and attacked-Mario states; parent-distance deletion; held-to-thrown
  velocity projection; landing and wall reflection; walk-turn timing; and the
  fixed hitbox values.
- `SM64SpinyAttackTable` preserves the C walking rows: punch, kick/trip,
  fast-attack, and from-below use reduced knockback; from-above and ground
  pound are no-op interactions.
- `SM64SpinyObjectBridge` runs the copied state through the owner-thread
  scheduler, derives parent motion/previous-object inputs from stable records,
  synchronizes action, velocity, hitbox, yaw, graph offset, and move flags, and
  records callback-ordered effects before end-of-frame unload.

This is a bounded shadow. The retained C behavior remains authoritative for
Lakitu production callbacks, full interaction/collision resolution, and
effects.

## Validation

- `script/test_spiny_enemy.sh` — Swift/C pass,
  `spinyEnemyFingerprint=0x416df13a812fe31f`.
- `script/test_goomba_enemy.sh` and `script/test_goomba_object_bridge.sh` —
  Swift/C passes remain green.
- All `script/test_*.sh` scripts — `MATRIX_RESULT runs=105 failures=0`;
  log: `/tmp/sm64-modern-m18d-matrix.log`.
- Native Debug build after `xcodegen generate` — `** BUILD SUCCEEDED **`;
  log: `/tmp/sm64-modern-m18d-build.log`.
- `git diff --check` — pass.

These are deterministic source, contract, and build gates. They do not prove
full-game enemy behavior, physical/visual/audio review, distribution,
clean-machine behavior, or human acceptance.

## Next slice

M18e should cover Lakitu's production spawn/count boundary and then add a
second projectile/common-enemy family through the same scheduler/effect schema
before promoting any enemy Swift authority.
