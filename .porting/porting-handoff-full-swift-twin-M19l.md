# M19l Handoff — TTC moving-bar behavior seam

## Scope

M19l extracts TTC moving-bar initialization and its wait/pull/extend/retract
state machine. It does not claim global TTC RNG ownership, object position
operation delivery, dynamic collision replacement, or remaining mechanism and
hazard families.

## Implementation

- `SM64Modern/TTCMovingBarBehavior.swift` preserves initialization, action
  gates, threshold crossing, acceleration/deceleration, random delay/fake-out
  inputs, and reset semantics as Swift 6 value state.
- `tests/sm64_modern_ttc_moving_bar_contract.c` independently mirrors the C
  update and hashes float bits plus signed state.
- `script/test_ttc_moving_bar.sh` compiles Swift with complete strict
  concurrency and the C oracle with `-ffp-contract=off`, then requires
  matching fingerprints.

## Validation

- Focused Swift/C contract: `ttcMovingBarFingerprint=0x189e979eb38062a6`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=149 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for global TTC RNG ownership, position-operation/object
ownership, platform collision/surface reload, remaining mechanisms and
environmental hazards, and effect delivery. M20–M35 remain open.
