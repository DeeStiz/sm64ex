# M19n Handoff — dynamic platform collision ownership seam

## Scope

M19n establishes the owner-thread dynamic-surface registry needed by moving
platforms. It does not claim live platform object binding, collision-mesh
generation, or the remaining mechanism and hazard families.

## Implementation

- `SM64Modern/PlatformCollisionRegistry.swift` keys dynamic surfaces by full
  `SM64ObjectID` generation, retains first-seen owner order through replacement,
  rejects duplicate surface IDs, removes exact owner generations only, and
  applies a flattened list to `SM64SurfaceCollisionWorld`.
- `tests/sm64_modern_platform_collision_registry_contract.c` independently
  mirrors owner ordering, replacement, stale-generation rejection, and final
  flattened IDs.
- `script/test_platform_collision_registry.sh` compiles the registry with the
  strict Swift 6 object/collision value types and the C oracle with
  `-ffp-contract=off`, then requires matching fingerprints.

## Validation

- Focused Swift/C contract:
  `platformCollisionRegistryFingerprint=0x39662ad973b730dc`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=151 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for live platform-object binding and collision-mesh
generation, remaining mechanisms and environmental hazards, effect delivery,
and M20–M35.
