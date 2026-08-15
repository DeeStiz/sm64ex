# Full Swift Twin M18u Handoff

## Scope

M18u ports the Mr. I eye, iris-body child, emitted purple particle, and
king-variant reward family into the owner-thread Swift boundary. The slice
covers the idle/tracking/turning/dying action table, proximity admission,
Mario-facing turn trigger, deterministic particle cadence, normal blue-coin and
king star death paths, shake/mist/body-delete effect intents, body animation
and relative placement, particle flight/burst/wall/room culling, stable parent
IDs, and scheduler-owned child insertion.

## Implementation

- `SM64Modern/MrIEnemy.swift` contains the value-state eye, body, and particle
  kernels with copied constants, action transitions, hitbox values, and effect
  intents.
- `SM64Modern/MrIObjectBridge.swift` owns general-actor eye allocation,
  default-list iris-body parenting, level-list particle/reward children,
  synchronization, and end-of-frame scheduler cleanup.
- `tests/sm64_modern_mr_i_object_bridge_smoke.swift` and
  `tests/sm64_modern_mr_i_object_bridge_contract.c` independently produce and
  compare `mrIObjectBridgeFingerprint=0x18b1a7bddb65a836`.
- `script/test_mr_i_object_bridge.sh` runs the strict Swift 6 and C contract
  checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=122 failures=0`; log:
  `/tmp/sm64-modern-m18u-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18u-build.log`.
- `git diff --check` passes.

These checks establish deterministic value, owner-thread bridge, and build
contracts only. They do not establish exact full-game collision resolution,
runtime effect presentation, physical/visual/audio/controller acceptance,
distribution, clean-machine launch, or human gameplay acceptance.

## Next slice

Continue M18 with another bounded common-enemy/projectile family such as Whomp,
Heave Ho, or a remaining course actor, while closing collision/effect delivery
and the reachable behavior inventory before beginning M19 platforms and
hazards.
