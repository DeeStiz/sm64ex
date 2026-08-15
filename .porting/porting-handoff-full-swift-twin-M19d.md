# M19d Handoff — swing platform behavior seam

## Scope

M19d extracts the swing-platform initialization and per-tick accumulator. It
does not claim platform object ownership, dynamic collision replacement,
surface reload, or the remaining platform and hazard families.

## Implementation

- `SM64Modern/SwingPlatformBehavior.swift` preserves the sign-selected
  `+4.0f`/`-4.0f` acceleration, f32 angle accumulation, signed object-roll
  truncation, and roll-velocity delta as a value-only Swift 6 boundary.
- `tests/sm64_modern_swing_platform_contract.c` independently mirrors the C
  update and hashes float bits plus signed outputs.
- `script/test_swing_platform.sh` compiles Swift with complete strict
  concurrency and the C oracle with `-ffp-contract=off`, then requires matching
  fingerprints.

## Validation

- Focused Swift/C contract:
  `swingPlatformFingerprint=0xc38755874141aa35`.
- Full `script/test_*.sh` matrix: `runs=141 failures=0` in
  `/tmp/sm64-modern-m19d-matrix.log`.
- Regenerated native Swift 6/macOS 27 Debug build succeeds in
  `/tmp/sm64-modern-m19d-clean-build.log`.
- `git diff --check` passes and the native source audit still reports zero
  `@unchecked Sendable` declarations under `SM64Modern`.

## Remaining gate

M19 remains open for platform ownership, dynamic collision/surface reload,
seesaws/pendulums/lifts, environmental hazards, and effect delivery. M20–M35
remain open.
