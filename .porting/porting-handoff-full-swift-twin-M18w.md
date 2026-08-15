# Full Swift Twin M18w Handoff

## Scope

M18w ports the Heave Ho owner and stable Mario throw child into the
owner-thread Swift boundary. The slice covers the submerged/wake/wind-up/
chase/throw action boundary, 4000-unit water admission, 1000-unit home
correction, 10-unit chase speed, 150-frame slow-down and recovery, holdable and
grab-Mario interaction, 200/-50 parent-relative placement, throw-state-to-Mario
impulse handoff, collision budget, and water re-entry.

## Implementation

- `SM64Modern/HeaveHoEnemy.swift` contains the value-state owner and throw-child
  kernels with copied interaction/hitbox values, held-state transitions, and
  effect intents.
- `SM64Modern/HeaveHoObjectBridge.swift` owns general-actor parent/child
  allocation, stable IDs, relative transforms, held/tangible/hidden state,
  and scheduler-boundary cleanup.
- `tests/sm64_modern_heave_ho_object_bridge_smoke.swift` and
  `tests/sm64_modern_heave_ho_object_bridge_contract.c` independently produce
  and compare `heaveHoObjectBridgeFingerprint=0x9c4a7443f2c09281`.
- `script/test_heave_ho_object_bridge.sh` runs the strict Swift 6 and C
  contract checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=124 failures=0`; log:
  `/tmp/sm64-modern-m18w-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18w-build.log`.
- `git diff --check` passes.

These checks establish deterministic value, owner-thread bridge, and build
contracts only. They do not establish exact full-game collision resolution,
runtime effect presentation, physical/visual/audio/controller acceptance,
distribution, clean-machine launch, or human gameplay acceptance.

## Next slice

Continue M18 with another bounded common-enemy/projectile family or complete
the remaining holdable/course-actor inventory, while closing collision/effect
delivery before beginning M19 platforms and hazards.
