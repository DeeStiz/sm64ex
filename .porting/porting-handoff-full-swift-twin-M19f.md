# M19f Handoff — decorative pendulum behavior seam

## Scope

M19f extracts the Tick Tock Clock decorative pendulum initializer and loop. It
does not claim the room/collision object bridge or the remaining platform and
hazard families.

## Implementation

- `SM64Modern/DecorativePendulumBehavior.swift` preserves the `0x100` initial
  roll velocity, room-init intent, signed `0x08` acceleration, roll update,
  and exact ±`0x10` clock-sound event as value-only Swift 6 state.
- `tests/sm64_modern_decorative_pendulum_contract.c` independently mirrors the
  integer C update and hashes signed outputs and sound intent.
- `script/test_decorative_pendulum.sh` compiles Swift with complete strict
  concurrency and the C oracle with `-ffp-contract=off`, then requires matching
  fingerprints.

## Validation

- Focused Swift/C contract:
  `decorativePendulumFingerprint=0xd9bba67deb7b6398`.
- Full `script/test_*.sh` matrix target after this script is included:
  `runs=143 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for object ownership, dynamic collision/surface reload,
remaining mechanisms and environmental hazards, and effect delivery. M20–M35
remain open.
