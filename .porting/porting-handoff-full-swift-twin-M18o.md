# SM64 Modern full-swift-twin M18o handoff

## Scope

M18o ports the Koopa shell family into the Swift owner-thread world. The
slice covers the level-list `bhvKoopaShell` shell, the general-actor
underwater shell, free/ridden/held/thrown/dropped state, shell hitbox and
damage/coin fields, wall bounce and gravity motion, Mario riding placement,
water wave/drop and floor-type flame effect intents, stop-riding deletion and
mist, plus scheduler-owned transient child allocation and unload.

## Implementation

- `SM64Modern/KoopaShell.swift` contains the copied-value shell and underwater
  state kernels and effect masks.
- `SM64Modern/KoopaShellObjectBridge.swift` owns live shell records, list
  ordering, parent/child IDs, bridge input, and end-of-frame cleanup without C
  pointers.
- `tests/sm64_modern_koopa_shell_object_bridge_smoke.swift` and
  `tests/sm64_modern_koopa_shell_object_bridge_contract.c` provide the
  independent Swift/C contract.
- `script/test_koopa_shell_object_bridge.sh` compiles both sides with strict
  Swift 6 concurrency and compares the fingerprint
  `koopaShellObjectBridgeFingerprint=0x3dee340d1e85a07e`.

## Validation

- Focused strict Swift 6/C contract: passed.
- Neighboring enemy regressions: passed.
- Full matrix: passed, `runs=116 failures=0`,
  `/tmp/sm64-modern-m18o-matrix.log`.
- Generated native Debug build: passed,
  `/tmp/sm64-modern-m18o-build.log`.
- `git diff --check`: passed.

## Evidence boundary

This handoff proves the bounded Swift/C state and owner-thread bridge contract
and a generated native build. It does not prove complete collision delivery,
full effect timing/visual parity, every remaining enemy/projectile family,
physical controller/audio behavior, distribution, clean-machine launch, or
human visual/gameplay acceptance.

## Next slice

M18p should close another reachable enemy/projectile family against the C
oracle, then M19 should begin the platform and hazard family with the same
copied-value, owner-thread, Swift/C fingerprint, matrix, and native-build
gates.
