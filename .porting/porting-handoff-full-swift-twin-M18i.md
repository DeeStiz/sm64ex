# Porting Handoff: SM64 Modern Full Swift Twin M18i

## Scope

M18i adds the homing, circling, and fixed Amp families and their owner-thread
object bridge:

- `AmpEnemy.swift` carries the 800-unit homing reveal, 30-frame growth and
  91-frame admission, camera-facing and 15/10 lock-on/chase speeds,
  Mario-head vertical tracking, sinusoidal motion, 1,500-unit give-up/reset,
  90-frame interaction cooldown, fixed/circling radii and phase rates, and the
  shared shock hitbox as copied values.
- `AmpObjectBridge.swift` attaches each variant to `SM64ObjectScheduler`,
  mirrors position/scale/facing/action/phase/timer, graph invisibility,
  tangibility, and hitbox values into stable records, and emits value-only
  effects without exposing C pointers.

## Validation

- `script/test_amp_object_bridge.sh` — Swift/C pass,
  `ampObjectBridgeFingerprint=0x491f58d4bb2b3a92`.
- Strict Swift 6 focused compile uses complete concurrency checking.
- The full matrix passes with `runs=110 failures=0`; log:
  `/tmp/sm64-modern-m18i-matrix.log`.
- The generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18i-build.log`.
- `git diff --check` passes.

These gates cover deterministic source, contract, and owner-thread callback
behavior. They do not prove full collision dispatch, all enemy/projectile
families, physical/visual/audio review, distribution, clean-machine behavior,
or human acceptance.

## Next slice

M18j should add a compact flying or ground enemy (for example Bird, Bully, or
Skeeter), then continue closing collision/effect admission across all reachable
US courses.
