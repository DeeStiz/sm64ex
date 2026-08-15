# M19p Handoff — collision mesh decode and live binding

## Scope

M19p converts the retained `COL_*` collision stream into Swift-owned dynamic
surfaces and binds them through the owner-generation registry and engine-state
lease. It does not claim that every platform behavior dispatch or every
content-pack collision resource has migrated.

## Implementation

- `SM64CollisionMeshDecoder` is bounds checked and reproduces C's transform
  truncation, integer cross-product, normal, force, flags, room, and Y-bound
  sequencing.
- `SM64PlatformCollisionRuntime` decodes a platform's stream, applies a
  candidate registry to a candidate collision world, then commits both plus
  `SM64SwiftEngineState` surface-ID lease state. A decode/registry/world
  failure cannot partially replace the previous binding.
- `SM64EngineStateSnapshot` now carries owner order and surface-ID leases;
  reset and remove clear the lease metadata.

## Validation

- Focused strict Swift 6/C output:
  `collisionMeshFingerprint=0x266b6fef37fcfa11`.
- Full `script/test_*.sh` matrix:
  `MATRIX_RESULT runs=152 failures=0`.
- `xcodegen generate`, regenerated native Swift 6/macOS 27 Debug build, and
  `git diff --check` pass.

## Remaining gate

M19 still needs behavior-dispatch coverage for every collision-bearing
platform, collision resource inventory from the content pack, environmental
hazards, and effect delivery. M20–M35 remain open.
