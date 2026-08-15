# Full Swift Twin M18t Handoff

## Scope

M18t ports the Scuttlebug ground enemy and proximity spawner into the
owner-thread Swift boundary. The slice covers the initialize/chase/turn/
knockback/recovery subaction table, home capture, 5/15-speed chase,
0x200/0x400 turn steps, 20-unit alert jump, edge/wall redirection, 30-frame
recovery window, bounce-top hitbox and three-coin attack response, plus the
500–1500 distance and 31-frame spawner gates. The spawner inserts a stable
general-actor child and re-arms after scheduler-boundary cleanup.

## Implementation

- `SM64Modern/ScuttlebugEnemy.swift` contains the value-state enemy and
  spawner kernels, copied constants, movement flags, and effect intents.
- `SM64Modern/ScuttlebugObjectBridge.swift` owns spawner/child records,
  stable parent IDs, allocation, synchronization, and end-of-frame unload.
- `tests/sm64_modern_scuttlebug_object_bridge_smoke.swift` and
  `tests/sm64_modern_scuttlebug_object_bridge_contract.c` independently
  produce and compare `scuttlebugObjectBridgeFingerprint=0x7204b63131e2054b`.
- `script/test_scuttlebug_object_bridge.sh` runs the strict Swift 6 and C
  contract checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=121 failures=0`; log:
  `/tmp/sm64-modern-m18t-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18t-build.log`.
- `git diff --check` passes.

These checks establish deterministic value and build contracts only. Complete
runtime collision/effect delivery, the remaining enemy/projectile families,
physical/visual/audio/controller acceptance, distribution, clean-machine
launch, and human gameplay acceptance remain open.

## Next slice

Continue M18 with Mr. I, Whomp, Heave Ho, or another bounded common-enemy
family. Close the common-enemy behavior inventory and owner-thread effect
routes before beginning M19 platforms and hazards.
