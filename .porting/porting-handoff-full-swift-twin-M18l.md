# Porting Handoff: SM64 Modern Full Swift Twin M18l

## Scope

M18l adds the Skeeter water-surface family and transient wave children:

- `SkeeterEnemy.swift` carries the bounce-top hitbox, idle/walk/lunge action
  boundary, water-surface timing, smooth turning/wait gates, lunge and wall
  reflection values, walk target speeds, random target/idle decisions, and
  attacked coin deletion as a copied-POD kernel.
- `SkeeterObjectBridge.swift` allocates four stable wave children at the C
  offsets, preserves owner-thread general-actor ordering, mirrors hitbox and
  transform fields, decays wave scale/animation state, and unloads transient
  children through copied effect records.

## Validation

- `script/test_skeeter_object_bridge.sh` — Swift/C pass,
  `skeeterObjectBridgeFingerprint=0x171e3016f6b728d2`.
- Strict Swift 6 focused compile uses complete concurrency checking.
- Focused regressions for Bully, Bird, Amp, Swoop, Bullet Bill, Lakitu, Spiny,
  and Goomba bridges pass.
- The full matrix passes with `runs=113 failures=0`; log:
  `/tmp/sm64-modern-m18l-matrix.log`.
- The generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18l-build.log`.
- `git diff --check` passes.

These gates cover deterministic source, contract, and owner-thread callback
behavior. They do not prove full collision dispatch, all enemy/projectile
families, physical/visual/audio review, distribution, clean-machine behavior,
or human acceptance.

## Next slice

M18m should add another multi-state common enemy or projectile (for example
Pokey body-part ownership or Koopa/shell transitions) and extend shared attack,
collision, and spawn/despawn route coverage until the reachable common-enemy
inventory is exhausted.
