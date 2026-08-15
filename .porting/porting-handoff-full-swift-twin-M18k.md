# Porting Handoff: SM64 Modern Full Swift Twin M18k

## Scope

M18k adds the small and large Bully families and their owner-thread bridge:

- `BullyEnemy.swift` carries size/subtype hitboxes, patrol/chase admission,
  startup and fast chase speeds, home-radius return, attack knockback,
  collision-flag fencing, backup recovery, activation/fall admission, coin or
  star/mist lava death, and death-plane deletion as a copied-POD kernel.
- `BullyObjectBridge.swift` binds both sizes to the live general-actor list,
  mirrors transforms, actions, timers, velocities, hitboxes, graph flags, and
  tangibility, and emits stable callback-ordered effects without C pointers.

## Validation

- `script/test_bully_object_bridge.sh` — Swift/C pass,
  `bullyObjectBridgeFingerprint=0x8d7dc5c6315293c4`.
- Strict Swift 6 focused compile uses complete concurrency checking.
- Focused regressions for Bird, Amp, Swoop, Bullet Bill, Lakitu, Spiny, and
  Goomba bridges pass.
- The full matrix passes with `runs=112 failures=0`; log:
  `/tmp/sm64-modern-m18k-matrix.log`.
- The generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18k-build.log`.
- `git diff --check` passes.

These gates cover deterministic source, contract, and owner-thread callback
behavior. They do not prove full collision dispatch, all enemy/projectile
families, physical/visual/audio review, distribution, clean-machine behavior,
or human acceptance.

## Next slice

M18l should close another high-reach enemy/projectile family and extend the
shared collision/effect admission matrix, then continue until the reachable
US behavior inventory has no unmigrated common-enemy callback.
