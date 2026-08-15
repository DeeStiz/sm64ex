# Full Swift Twin M18s Handoff

## Scope

M18s ports the Snufit and bowling-ball projectile family into the owner-thread
Swift boundary. The slice covers the two Snufit actions, canonical orbit and
body-scale/recoil cadence, three-shot emission, Snufit/projectile hitboxes,
metal-Mario bounce and gravity, wall/ground death, room/distance culling, and
relative child placement through the scheduler. The projectile remains a
value-only general-actor child; allocation and unload are owned by the bridge.

## Implementation

- `SM64Modern/SnufitEnemy.swift` contains the copied Snufit and projectile
  state machines, canonical trig orbit, hitboxes, scale targets, and effect
  intents.
- `SM64Modern/SnufitObjectBridge.swift` owns general-actor Snufit/bullet
  records, three-shot child allocation, parent-relative placement, and
  scheduler-boundary cleanup.
- `tests/sm64_modern_snufit_object_bridge_smoke.swift` and
  `tests/sm64_modern_snufit_object_bridge_contract.c` independently produce
  and compare `snufitObjectBridgeFingerprint=0xa388cd46139be059`.
- `script/test_snufit_object_bridge.sh` runs the strict Swift 6 and C
  contract checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=120 failures=0`; log:
  `/tmp/sm64-modern-m18s-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18s-build.log`.
- `git diff --check` passes.

These checks establish deterministic value and build contracts only. Complete
runtime collision/effect delivery, the remaining enemy/projectile families,
physical/visual/audio/controller acceptance, distribution, clean-machine
launch, and human gameplay acceptance remain open.

## Next slice

Continue M18 with Mr. I, Scuttlebug, Whomp, Heave Ho, or another bounded
common-enemy family, then close the M18 behavior inventory before beginning M19
platforms and hazards. Preserve the same independent Swift/C fingerprint and
owner-thread allocation gates for every family.
