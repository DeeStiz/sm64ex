# Porting Handoff: SM64 Modern Full Swift Twin M18g

## Scope

M18g adds the Bullet Bill projectile state and owner-thread object bridge:

- `BulletBill.swift` carries reset/wait/launch/end/return actions as copied
  values. The launch gate matches C's strict 400–1500 distance and 0x2000 yaw
  window; prelaunch velocity alternates at timers 40–49; timer 50 emits smoke,
  sound, and shake; flight approaches yaw by 0x100 at 30 units; wall/timer
  termination emits mist; and action 4 performs intangible −30 return motion.
- `BulletBillObjectBridge.swift` attaches the kernel to
  `SM64ObjectScheduler`, mirrors action/timer/velocity/yaw/pitch/position into
  the object record, and allocates a transient smoke child in the live
  general-actor list. The smoke is marked for end-of-frame unload while its
  effect identity remains in the value-only record.

## Validation

- `script/test_bullet_bill_object_bridge.sh` — Swift/C pass,
  `bulletBillObjectBridgeFingerprint=0x95be3d7fa671c885`.
- Strict Swift 6 focused compile uses complete concurrency checking.
- The full matrix passes with `runs=108 failures=0`; log:
  `/tmp/sm64-modern-m18g-matrix.log`.
- The generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18g-build.log`.
- `git diff --check` passes.

These gates cover deterministic source, contract, and owner-thread callback
behavior. They do not prove full collision dispatch, all enemy/projectile
families, physical/visual/audio review, distribution, clean-machine behavior,
or human acceptance.

## Next slice

M18h should add another enemy/projectile family (preferably a hitbox-bearing
ground enemy) and extend collision/effect admission without moving C pointers
across the Swift boundary.
