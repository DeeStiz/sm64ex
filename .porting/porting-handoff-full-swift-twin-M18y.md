# Full Swift Twin M18y Handoff

## Scope

M18y ports the Fly Guy action family and its transient flame child into the
owner-thread Swift boundary. The slice covers idle/approach/lunge/shoot-fire
transitions, scale grow/shrink cadence, oscillation, wall reflection, water
lift, bounce-top hitbox values, flame spawn/placement/decay, stable parent
identity, and scheduler-boundary cleanup.

## Implementation

- `SM64Modern/FlyGuyEnemy.swift` contains the value-state Fly Guy and flame
  kernels with copied movement, hitbox, animation, and effect intents.
- `SM64Modern/FlyGuyObjectBridge.swift` owns general-actor Fly Guy allocation,
  unimportant flame children, parent-relative transforms, interaction fields,
  and end-of-frame deletion.
- `tests/sm64_modern_fly_guy_object_bridge_smoke.swift` and
  `tests/sm64_modern_fly_guy_object_bridge_contract.c` independently produce
  and compare `flyGuyObjectBridgeFingerprint=0x2fbf98eca64a5496`.
- `script/test_fly_guy_object_bridge.sh` runs the strict Swift 6 and C
  contract checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=126 failures=0`; log:
  `/tmp/sm64-modern-m18y-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18y-build.log`.
- `git diff --check` passes.

These checks establish deterministic value, owner-thread bridge, and build
contracts only. They do not establish exact full-game collision resolution,
runtime effect presentation, physical/visual/audio/controller acceptance,
distribution, clean-machine launch, or human gameplay acceptance.

## Next slice

Continue M18 with another bounded common-enemy/projectile family such as Boo
or Chain Chomp, while closing collision/effect delivery before beginning M19
platforms and hazards.
