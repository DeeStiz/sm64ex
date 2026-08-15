# SM64 Modern full-swift-twin M18q handoff

## Scope

M18q ports the Piranha Plant action table into the Swift owner-thread world.
The slice covers idle/sleeping/woken/biting/stopped-biting transitions,
sleeping and biting hitboxes, 0x400 bite turning and bite-sound frames,
metal-cap attack, intangible attack/shrink state, 0.04 shrink and 0.02
respawn scale steps, blue-coin wait/respawn gating, level-height hiding, and
twenty purple attack particles.

## Implementation

- `SM64Modern/PiranhaPlant.swift` contains the copied-value nine-action state
  table, hitbox selection, scale/opacity state, and effect masks.
- `SM64Modern/PiranhaPlantObjectBridge.swift` owns general-actor plant records,
  stable transforms/hitboxes, and unimportant particle/blue-coin children
  without C pointers.
- `tests/sm64_modern_piranha_plant_object_bridge_smoke.swift` and
  `tests/sm64_modern_piranha_plant_object_bridge_contract.c` provide the
  independent Swift/C contract.
- `script/test_piranha_plant_object_bridge.sh` compiles both sides with strict
  Swift 6 concurrency and compares
  `piranhaPlantObjectBridgeFingerprint=0x4202eefc24547aa0`.

## Validation

- Focused strict Swift 6/C contract: passed.
- Neighboring enemy regressions: passed.
- Full matrix: passed, `runs=118 failures=0`,
  `/tmp/sm64-modern-m18q-matrix.log`.
- Generated native Debug build: passed,
  `/tmp/sm64-modern-m18q-build.log`.
- `git diff --check`: passed.

## Evidence boundary

This handoff proves the bounded Swift/C state and owner-thread bridge contract
and a generated native build. It does not prove complete collision delivery,
full effect timing/visual parity, every remaining enemy/projectile family,
physical controller/audio behavior, distribution, clean-machine launch, or
human visual/gameplay acceptance.

## Next slice

M18r should close another reachable common enemy/projectile family or finish
the remaining enemy breadth inventory, then M19 should begin platforms and
hazards with the same copied-value, owner-thread, Swift/C-fingerprint, matrix,
and native-build gates.
