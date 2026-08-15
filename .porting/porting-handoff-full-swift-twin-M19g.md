# M19g Handoff — arrow lift behavior seam

## Scope

M19g extracts the WDW arrow-lift action machine and its two movement helpers.
It does not claim Mario platform ownership, dynamic collision replacement,
surface reload, or the remaining platform and hazard families.

## Implementation

- `SM64Modern/ArrowLiftBehavior.swift` preserves idle/away/back action gates,
  61-frame waits, perpendicular yaw, 12-unit motion, 384-unit displacement
  clamp, action transitions, and canonical-table X/Z movement as a value-only
  Swift 6 boundary.
- `tests/sm64_modern_arrow_lift_contract.c` independently mirrors the C state
  machine and hashes float bits plus signed outputs.
- `script/test_arrow_lift.sh` compiles Swift with complete strict concurrency
  and the C oracle with `-ffp-contract=off`, then requires matching
  fingerprints.

## Validation

- Focused Swift/C contract: `arrowLiftFingerprint=0xcff4edab50dbc7ed`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=144 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for platform object ownership, dynamic collision/surface
reload, remaining mechanisms and environmental hazards, and effect delivery.
M20–M35 remain open.
