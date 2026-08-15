# Full Swift Twin M18x Handoff

## Scope

M18x ports the Chuckya owner and anchored Mario child into the owner-thread
Swift boundary. The slice covers patrol/approach/brake/return, grab/release/
throw, collision death, 2000/1900 home gates, 30/10/4 movement speeds,
0x400/0x800 yaw steps, grab-escape and animation-frame release, 40/40 and
10/10 throw impulses, five-coin mist death, holdable state, and parent-relative
anchor scheduling.

## Implementation

- `SM64Modern/ChuckyaEnemy.swift` contains the value-state owner and anchor
  kernels with copied holdable interaction values, movement, release, and
  collision effect intents.
- `SM64Modern/ChuckyaObjectBridge.swift` owns general-actor parent/anchor
  allocation, stable IDs, relative transforms, held/tangible/hidden state, and
  scheduler-boundary deletion.
- `tests/sm64_modern_chuckya_object_bridge_smoke.swift` and
  `tests/sm64_modern_chuckya_object_bridge_contract.c` independently produce
  and compare `chuckyaObjectBridgeFingerprint=0x1c7a7a54fd31996a`.
- `script/test_chuckya_object_bridge.sh` runs the strict Swift 6 and C contract
  checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=125 failures=0`; log:
  `/tmp/sm64-modern-m18x-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18x-build.log`.
- `git diff --check` passes.

These checks establish deterministic value, owner-thread bridge, and build
contracts only. They do not establish exact full-game collision resolution,
runtime effect presentation, physical/visual/audio/controller acceptance,
distribution, clean-machine launch, or human gameplay acceptance.

## Next slice

Continue M18 with another bounded common-enemy/projectile family such as Fly
Guy, Boo, or Chain Chomp, while closing collision/effect delivery before
beginning M19 platforms and hazards.
