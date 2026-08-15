# Full Swift Twin M18v Handoff

## Scope

M18v ports the Whomp and King Whomp surface actors into the owner-thread
Swift boundary. The slice covers initialize/chase/turn/pound/fall/land/
on-ground/return/death actions, 500/600 proximity admission, 700/200 home
limits, 0x200/0x400 yaw and pitch steps, landing shake, normal five-coin
defeat, the king three-pound health loop, king star/dialog cleanup, boss-music
stop, the breakable hitbox, and surface-list scheduling.

## Implementation

- `SM64Modern/WhompEnemy.swift` contains the normal/king value-state kernel,
  copied hitbox values, movement, action transitions, and effect intents.
- `SM64Modern/WhompObjectBridge.swift` owns surface-list allocation, stable
  object identity, collision/health synchronization, scale/hidden state, and
  scheduler-boundary deletion.
- `tests/sm64_modern_whomp_object_bridge_smoke.swift` and
  `tests/sm64_modern_whomp_object_bridge_contract.c` independently produce and
  compare `whompObjectBridgeFingerprint=0x672073b350af199a`.
- `script/test_whomp_object_bridge.sh` runs the strict Swift 6 and C contract
  checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=123 failures=0`; log:
  `/tmp/sm64-modern-m18v-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18v-build.log`.
- `git diff --check` passes.

These checks establish deterministic value, owner-thread bridge, and build
contracts only. They do not establish exact full-game collision resolution,
runtime effect presentation, physical/visual/audio/controller acceptance,
distribution, clean-machine launch, or human gameplay acceptance.

## Next slice

Continue M18 with another bounded common-enemy/projectile family such as Heave
Ho, Thwomp, or a remaining course actor, while closing collision/effect
delivery and the reachable behavior inventory before beginning M19 platforms
and hazards.
