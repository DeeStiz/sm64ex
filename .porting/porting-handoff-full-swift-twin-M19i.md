# M19i Handoff — TTC pendulum behavior seam

## Scope

M19i extracts TTC pendulum initialization and the per-tick angle machine. It
does not claim the global TTC RNG/speed owner, object ownership, dynamic
collision replacement, or remaining mechanism and hazard families.

## Implementation

- `SM64Modern/TTCPendulumBehavior.swift` preserves speed-setting
  initialization, signed acceleration direction, delay and sound countdown,
  random zero-velocity acceleration/delay choices supplied as value inputs,
  angle accumulation, and face-roll truncation as Swift 6 value state.
- `tests/sm64_modern_ttc_pendulum_contract.c` independently mirrors the C
  update and hashes float bits, signed state, and sound intent.
- `script/test_ttc_pendulum.sh` compiles Swift with complete strict concurrency
  and the C oracle with `-ffp-contract=off`, then requires matching
  fingerprints.

## Validation

- Focused Swift/C contract: `ttcPendulumFingerprint=0x04a7d453b291ca30`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=146 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for global TTC speed/RNG ownership, platform collision/surface
reload, remaining mechanisms and environmental hazards, and effect delivery.
M20–M35 remain open.
