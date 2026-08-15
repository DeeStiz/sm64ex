# Full Swift Twin M18aa Handoff

## Scope

M18aa ports Chain Chomp and its pivot/four metallic-ball chain into the
owner-thread Swift boundary. The slice covers lazy 3,000-unit allocation,
4,000-unit unload fencing, turn/lunge sub-actions, 0x400/0x1000 yaw steps,
150/180-unit chain lengths, gravity and previous-segment distance caps,
attack-triggered stretch, the INTERACT_MR_BLIZZARD 80/160 hitbox, stable child
parent identity, and scheduler-boundary deletion.

## Implementation

- `SM64Modern/ChainChompEnemy.swift` contains the value-state parent and
  five-segment constraint kernel with copied movement and effect intents.
- `SM64Modern/ChainChompObjectBridge.swift` owns parent/pivot/segment
  allocation, stable IDs, parent-relative transforms, hitbox fields, and
  end-of-frame child deletion.
- `tests/sm64_modern_chain_chomp_object_bridge_smoke.swift` and
  `tests/sm64_modern_chain_chomp_object_bridge_contract.c` independently
  produce and compare `chainChompObjectBridgeFingerprint=0x89d7ec70d95560c8`.
- `script/test_chain_chomp_object_bridge.sh` runs the strict Swift 6 and C
  contract checks with isolated module/cache paths.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full script matrix passes with `runs=128 failures=0`; log:
  `/tmp/sm64-modern-m18aa-matrix.log`.
- Generated native Debug build succeeds; log:
  `/tmp/sm64-modern-m18aa-build.log`.
- `git diff --check` passes.

These checks establish deterministic value, owner-thread bridge, and build
contracts only. They do not establish exact full-game collision resolution,
runtime effect presentation, physical/visual/audio/controller acceptance,
distribution, clean-machine launch, or human gameplay acceptance.

## Next slice

Close additional enemy/effect ownership seams such as Chain Chomp's wooden
post/gate release path or remaining course enemies, then begin M19 platforms
and hazards after the M18 collision/effect gate is closed.
