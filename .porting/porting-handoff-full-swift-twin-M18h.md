# Porting Handoff: SM64 Modern Full Swift Twin M18h

## Scope

M18h adds the Swoop enemy kernel and owner-thread object bridge:

- `SwoopEnemy.swift` carries idle scaling and distance admission, move-to-dive
  timing, vertical approach and speed-up, wall reflection with bonk cooldown,
  far-away home reset, animation/effect timing, and attacked deletion as copied
  values. The standard hitbox is damage 1, one loot coin, radius 100, height
  80, and hurtbox height 70.
- `SwoopObjectBridge.swift` attaches the kernel to the owner-thread
  `SM64ObjectScheduler`, mirrors scale/position/velocity/facing/action/timer and
  hitbox values into the live general-actor record, and unloads attacked
  instances through copied effect records without exposing C pointers.

## Validation

- `script/test_swoop_object_bridge.sh` — Swift/C pass,
  `swoopObjectBridgeFingerprint=0x322da26bf68945a6`.
- Strict Swift 6 focused compile uses complete concurrency checking.
- Focused Bullet Bill, Lakitu, Spiny, and Goomba bridge regressions pass.
- The full matrix passes with `runs=109 failures=0`; log:
  `/tmp/sm64-modern-m18h-matrix.log`.
- The generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18h-build.log`.
- `git diff --check` passes.

These gates cover deterministic source, contract, and owner-thread callback
behavior. They do not prove full collision dispatch, all enemy/projectile
families, physical/visual/audio review, distribution, clean-machine behavior,
or human acceptance.

## Next slice

M18i should add another common enemy/projectile family (preferably a compact
hitbox-bearing family) and extend collision/effect admission without moving C
pointers across the Swift boundary.
