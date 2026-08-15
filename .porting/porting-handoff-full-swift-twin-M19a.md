# M19a Handoff — platform displacement seam

## Scope

M19a extracts the value boundary behind `apply_platform_displacement`. It is
the first M19 platform/hazard seam; it does not claim that all platform
behaviors, hazards, or dynamic collision are migrated.

## Implementation

- `SM64Modern/PlatformDisplacement.swift` owns native-step X/Z translation,
  previous/current platform ZXY rotation, platform-local offset conversion,
  signed 16-bit Mario yaw wrapping, and separate Mario/object outputs.
- `tests/sm64_modern_platform_displacement_contract.c` independently mirrors
  the legacy trig table and matrix operations; the Swift and C fingerprints
  must match before the seam is accepted.
- `script/test_platform_displacement.sh` compiles the kernel under Swift 6
  complete strict concurrency and the C contract with `-ffp-contract=off`.

## Validation

- Focused Swift/C contract: `platformDisplacementFingerprint=0xd981b07ed8324476`.
- Full `script/test_*.sh` matrix: `runs=137 failures=0` after this script is
  included.
- Regenerated native Swift 6/macOS 27 Debug build: no project Swift
  concurrency diagnostics.
- `git diff --check`: clean.

## Remaining gate

M19 remains open for platform behavior families, moving textures, surface
replacement, water/lava/snow/quicksand volumes, wind/fire/boulders, and
owner-thread collision/effect delivery. M20–M35 remain open.
