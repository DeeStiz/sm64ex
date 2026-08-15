# Full Swift Twin M18ac Handoff

## Scope

M18ac establishes the common owner-thread effect delivery boundary for the
migrated Chain Chomp post/gate route. Typed bridge records become stable,
sequenced intents; pool mutation (gate deletion, transient coin allocation,
and respawn-bit writes) happens only at delivery, while sound, particle,
camera-shake, release, and position intents remain immutable records for the
future presentation owners.

## Implementation

- `SM64Modern/OwnerThreadEffectRouter.swift` defines the Sendable intent and
  delivery records, sequence ordering, stale-ID rejection, mutation handling,
  and Chain Chomp effect-record conversion.
- `SM64Modern/ChainChompReleaseObjectBridge.swift` no longer marks the gate
  directly; it emits the deletion intent for the owner-thread router.
- `tests/sm64_modern_owner_thread_effect_router_smoke.swift` and
  `tests/sm64_modern_owner_thread_effect_router_contract.c` independently
  produce and compare
  `ownerThreadEffectRouterFingerprint=0x6f4e529130b860b1`.
- `script/test_owner_thread_effect_router.sh` runs the strict Swift 6/C
  contract with an isolated module cache. The existing Chain Chomp release
  contract now exercises router delivery as well.

## Validation evidence

- Focused strict Swift 6/C validation passes, including the Chain Chomp
  release contract and the owner-thread router contract.
- Full script matrix passes with `runs=130 failures=0`; log:
  `/tmp/sm64-modern-m18ac-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native Debug build succeeds; log:
  `/tmp/sm64-modern-m18ac-build.log`.
- `git diff --check` passes.

These checks establish intent ordering and owner-thread mutation contracts
only. They do not establish every migrated bridge routing through the new
sink, full collision resolution, runtime audio/renderer/camera presentation,
physical device acceptance, distribution, or human gameplay acceptance.

## Next slice

Adopt the router across the existing enemy and Mario effect bridges, then
close the remaining M18 projectile/enemy inventory. M19 may start only after
the route inventory proves every spawned/despawned actor delivers collision,
sound, particle, reward, and deletion effects through this boundary.
