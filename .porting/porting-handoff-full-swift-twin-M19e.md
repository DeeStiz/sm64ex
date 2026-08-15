# M19e Handoff — seesaw platform behavior seam

## Scope

M19e extracts seesaw-platform initialization and its per-tick pitch machine.
It does not claim platform object ownership, dynamic collision replacement,
surface reload, or the remaining platform and hazard families.

## Implementation

- `SM64Modern/SeesawPlatformBehavior.swift` preserves collision-model index
  selection, the BitS `2000.0f` collision-distance override, canonical table
  cosine, Mario-driven pitch rotation, signed pitch truncation, sound intent,
  velocity clamp, and the C `oscillate_toward` return path as value-only Swift.
- `tests/sm64_modern_seesaw_platform_contract.c` independently mirrors the C
  update and hashes float bits plus signed outputs.
- `script/test_seesaw_platform.sh` compiles Swift with complete strict
  concurrency and the C oracle with `-ffp-contract=off`, then requires matching
  fingerprints.

## Validation

- Focused Swift/C contract:
  `seesawPlatformFingerprint=0x84664f609b940e32`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=142 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for platform ownership, dynamic collision/surface reload,
pendulums/lifts and other mechanisms, environmental hazards, and effect
delivery. M20–M35 remain open.
