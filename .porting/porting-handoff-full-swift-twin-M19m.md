# M19m Handoff — TTC rotating-solid behavior seam

## Scope

M19m extracts TTC rotating-solid initialization and its vertical/roll update.
It does not claim global TTC ownership, object/collision installation, dynamic
surface reload, or remaining mechanism and hazard families.

## Implementation

- `SM64Modern/TTCRotatingSolidBehavior.swift` preserves collision-model and
  side initialization, vertical dip/return, six-frame alert timer,
  symmetric roll approach, click/turn advance, and random delay reset as
  Swift 6 value state.
- `tests/sm64_modern_ttc_rotating_solid_contract.c` independently mirrors the C
  update and hashes float bits, signed state, and sound intents.
- `script/test_ttc_rotating_solid.sh` compiles Swift with complete strict
  concurrency and the C oracle with `-ffp-contract=off`, then requires
  matching fingerprints.

## Validation

- Focused Swift/C contract:
  `ttcRotatingSolidFingerprint=0xa75c9000a7214bb7`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=150 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for global TTC/object ownership, collision/surface reload,
remaining mechanisms and environmental hazards, and effect delivery. M20–M35
remain open.
