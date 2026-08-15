# M19h Handoff — TTC elevator behavior seam

## Scope

M19h extracts TTC elevator initialization and the per-tick vertical machine.
It does not claim the global TTC speed-setting owner, Mario platform
ownership, dynamic collision replacement, surface reload, or remaining
mechanism families.

## Implementation

- `SM64Modern/TTCElevatorBehavior.swift` preserves behavior-parameter peak
  selection, slow/fast/random/stopped speed lookup, the C random pause/change
  ordering, gravity-before-position update, endpoint clamp, and direction flip
  as a value-only Swift 6 boundary.
- `tests/sm64_modern_ttc_elevator_contract.c` independently mirrors the C
  update and hashes float bits plus signed outputs.
- `script/test_ttc_elevator.sh` compiles Swift with complete strict concurrency
  and the C oracle with `-ffp-contract=off`, then requires matching
  fingerprints.

## Validation

- Focused Swift/C contract: `ttcElevatorFingerprint=0xf5fec77dc56be959`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=145 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for TTC/global-speed ownership, platform collision/surface
reload, remaining mechanisms and environmental hazards, and effect delivery.
M20–M35 remain open.
