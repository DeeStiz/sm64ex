# M19j Handoff — TTC spinner behavior seam

## Scope

M19j extracts the TTC spinner speed and pitch update. It does not claim the
global TTC RNG/speed owner, object ownership, dynamic collision replacement,
or remaining mechanism and hazard families.

## Implementation

- `SM64Modern/TTCSpinnerBehavior.swift` preserves speed-setting lookup, random
  direction-change ordering, five-frame stop window, signed pitch velocity,
  and 16-bit pitch wrapping as Swift 6 value state.
- `tests/sm64_modern_ttc_spinner_contract.c` independently mirrors the C
  update and hashes signed outputs.
- `script/test_ttc_spinner.sh` compiles Swift with complete strict concurrency
  and the C oracle with `-ffp-contract=off`, then requires matching
  fingerprints.

## Validation

- Focused Swift/C contract: `ttcSpinnerFingerprint=0x40d3eedffaef914d`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=147 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for global TTC speed/RNG ownership, platform collision/surface
reload, remaining mechanisms and environmental hazards, and effect delivery.
M20–M35 remain open.
