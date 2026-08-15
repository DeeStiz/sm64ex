# Full Swift Twin M18r Handoff

## Scope

M18r ports the Moneybag actor and hidden-coin level-list family into the
owner-thread Swift boundary. The slice covers the visible and hidden hitboxes,
appearance opacity ramp, move/return-home/disappear/death actions,
landing/prepare/jump/walk substates, attack bounce, hidden-coin transform
admission, and owner-thread loot/effect child records. It preserves the
five-yellow-coin and mist transient ordering and the persistent hidden-coin
level-list placeholder without passing C pointers through the Swift bridge.

## Implementation

- `SM64Modern/MoneybagEnemy.swift` contains the value-state action, jump, and
  hidden-transform kernels plus copied hitbox and timing constants.
- `SM64Modern/MoneybagObjectBridge.swift` owns the general-actor Moneybag
  record, hidden-coin level-list record, transient child allocation, and
  scheduler-boundary unload.
- `tests/sm64_modern_moneybag_object_bridge_smoke.swift` and
  `tests/sm64_modern_moneybag_object_bridge_contract.c` independently produce
  and compare `moneybagObjectBridgeFingerprint=0x3fc38246b5faee0f`.
- `script/test_moneybag_object_bridge.sh` runs the strict Swift 6 and C
  contract checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=119 failures=0`; log:
  `/tmp/sm64-modern-m18r-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18r-build.log`.
- `git diff --check` passes.

These checks establish deterministic value and build contracts only. Complete
runtime collision/effect delivery, the remaining enemy/projectile families,
physical/visual/audio/controller acceptance, distribution, clean-machine
launch, and human gameplay acceptance remain open.

## Next slice

Continue M18 with another bounded enemy/projectile family or close the common
enemy inventory from the C behavior declarations. Then begin M19 platforms and
hazards once the M18 inventory and owner-thread effect routes are closed.
