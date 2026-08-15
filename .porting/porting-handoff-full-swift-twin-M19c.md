# M19c Handoff — rotating platform behavior seam

## Scope

M19c extracts the rotating-wooden platform action gate and the common rotating
platform yaw update. It does not claim collision-data selection, scaling, or
the other platform/mechanism families.

## Implementation

- `SM64Modern/RotatingPlatformBehavior.swift` preserves the timer thresholds,
  signed high behavior-byte conversion, 16-bit yaw wrapping, action reset, and
  loop-sound intent.
- `tests/sm64_modern_rotating_platform_contract.c` independently mirrors the
  C action and yaw arithmetic.
- `script/test_rotating_platform.sh` compiles both sides with Swift 6 strict
  concurrency and clang floating-point contraction disabled.

## Validation

- Focused Swift/C contract: `rotatingPlatformFingerprint=0x8d77ef02524f8933`.
- Full `script/test_*.sh` matrix: `runs=139 failures=0` after this script is
  included.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for platform initialization/collision, dynamic surface
replacement, hazards, and the remaining mechanisms. M20–M35 remain open.
