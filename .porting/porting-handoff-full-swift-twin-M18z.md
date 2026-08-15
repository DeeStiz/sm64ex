# Full Swift Twin M18z Handoff

## Scope

M18z ports the common Ghost Hunt Boo behavior into the owner-thread Swift
boundary. The slice covers initialization and 1,500-unit activation,
chase/vanish/appear opacity thresholds, 0x8000 interaction admission,
table-backed 32-frame bounce roll, lethal death/mist completion, copied
140/80 and 40/60 hitboxes, and scheduler-boundary deletion.

## Implementation

- `SM64Modern/BooEnemy.swift` contains the value-state Boo kernel with copied
  movement, opacity, oscillation, interaction, and death effect intents.
- `SM64Modern/BooObjectBridge.swift` owns general-actor Boo allocation,
  stable IDs, transform/opacity synchronization, hitbox fields, intangible
  state, and end-of-frame deletion.
- `tests/sm64_modern_boo_object_bridge_smoke.swift` and
  `tests/sm64_modern_boo_object_bridge_contract.c` independently produce and
  compare `booObjectBridgeFingerprint=0x7505d05143270ec7`.
- `script/test_boo_object_bridge.sh` runs the strict Swift 6 and C contract
  checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=127 failures=0`; log:
  `/tmp/sm64-modern-m18z-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18z-build.log`.
- `git diff --check` passes.

These checks establish deterministic value, owner-thread bridge, and build
contracts only. They do not establish exact full-game collision resolution,
runtime effect presentation, physical/visual/audio/controller acceptance,
distribution, clean-machine launch, or human gameplay acceptance.

## Next slice

Continue M18 with Chain Chomp or another remaining common-enemy/projectile
family, then close collision/effect delivery before beginning M19 platforms
and hazards.
