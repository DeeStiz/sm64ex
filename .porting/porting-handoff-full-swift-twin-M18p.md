# SM64 Modern full-swift-twin M18p handoff

## Scope

M18p ports the generic and stationary Bob-omb family into the Swift
owner-thread world. The slice covers the 65-by-113 grabbable/kickable hitbox,
patrol/chase admission and turning, launched gravity/bounce movement,
held/thrown/dropped release transitions, fuse lighting and smoke cadence,
blink state, five-frame explosion scale, explosion/coin/respawn/mist intents,
and scheduler-owned transient child allocation and unload.

## Implementation

- `SM64Modern/BobombEnemy.swift` contains the copied-value generic/stationary
  state kernels, held-state transitions, fuse/blink logic, and effect masks.
- `SM64Modern/BobombObjectBridge.swift` owns general-actor Bob-omb records,
  input, stable transforms/hitboxes, and unimportant explosion/smoke/coin
  children without C pointers.
- `tests/sm64_modern_bobomb_object_bridge_smoke.swift` and
  `tests/sm64_modern_bobomb_object_bridge_contract.c` provide the independent
  Swift/C contract.
- `script/test_bobomb_object_bridge.sh` compiles both sides with strict Swift
  6 concurrency and compares
  `bobombObjectBridgeFingerprint=0x9e25e782f40ffdd0`.

## Validation

- Focused strict Swift 6/C contract: passed.
- Neighboring enemy regressions: passed.
- Full matrix: passed, `runs=117 failures=0`,
  `/tmp/sm64-modern-m18p-matrix.log`.
- Generated native Debug build: passed,
  `/tmp/sm64-modern-m18p-build.log`.
- `git diff --check`: passed.

## Evidence boundary

This handoff proves the bounded Swift/C state and owner-thread bridge contract
and a generated native build. It does not prove complete collision delivery,
full effect timing/visual parity, every remaining enemy/projectile family,
physical controller/audio behavior, distribution, clean-machine launch, or
human visual/gameplay acceptance.

## Next slice

M18q should close another reachable enemy/projectile family against the C
oracle or finish the remaining common enemy breadth inventory, then M19 should
begin platforms and hazards with the same copied-value, owner-thread,
Swift/C-fingerprint, matrix, and native-build gates.
