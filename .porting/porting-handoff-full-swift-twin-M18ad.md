# Full Swift Twin M18ad Handoff

## Scope

M18ad adds the bouncing-fireball parent and transient flame child bridge. The
parent remains a finite Swift value kernel while the owner-thread bridge owns
default/general-actor scheduling, stable parent-child identities, transform
placement, record synchronization, and end-of-frame deletion.

## Implementation

- `SM64Modern/BouncingFireball.swift` mirrors the parent activation, flame
  emission/scale decay, rising/cycling velocity, surface-contact deletion,
  timeout, and reset branches from `bhv_bouncing_fireball_loop`, plus the
  rising/bouncing flame loop from `bhv_bouncing_fireball_flame_loop`.
- `SM64Modern/BouncingFireballObjectBridge.swift` allocates parent objects in
  `.default`, transient flames in `.generalActor`, preserves parent-relative
  placement and stable IDs, and mutates pool records only on the scheduler's
  owner thread.
- `tests/sm64_modern_bouncing_fireball_smoke.swift` and
  `tests/sm64_modern_bouncing_fireball_contract.c` independently produce and
  compare `bouncingFireballFingerprint=0x473a69850a182475`.
- `script/test_bouncing_fireball.sh` runs the focused strict Swift 6/C
  contract with an isolated module cache.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18ad-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18ad-build.log`.
- `git diff --check` passes.

These checks establish the bounded parent/flame state and owner-thread bridge
contracts. They do not establish whole-engine effect-router adoption, full
collision resolution, runtime audio/renderer/camera presentation, physical
device acceptance, distribution, or human gameplay acceptance.

## Next slice

Extend the common owner-thread effect router across the existing enemy and
projectile bridges, then finish the remaining M18 behavior inventory and
collision/effect route audit. M19 may start only after every spawned/despawned
actor has a verified Swift-owned collision, sound, particle, reward, and
deletion delivery path.
