# M19b Handoff — elevator behavior seam

## Scope

M19b extracts the value behavior behind `elevator_act_0` through
`elevator_act_4`. It preserves endpoint transitions and observable sound/shake
intents while leaving object ownership, timer advancement, collision loading,
and platform families to later M19 work.

## Implementation

- `SM64Modern/ElevatorBehavior.swift` models idle, rising, descending, and both
  resting actions with the exact signed velocity approach and platform-kind
  branches.
- `tests/sm64_modern_elevator_behavior_contract.c` independently mirrors the
  C action switch and checks the same endpoint, sound, and shake outputs.
- `script/test_elevator_behavior.sh` compiles both sides with Swift 6 strict
  concurrency and clang floating-point contraction disabled.

## Validation

- Focused Swift/C contract: `elevatorBehaviorFingerprint=0x07f1d3fee9d22bac`.
- Full `script/test_*.sh` matrix: `runs=138 failures=0` after this script is
  included.
- Regenerated native Swift 6/macOS 27 Debug build and `git diff --check` pass.

## Remaining gate

M19 remains open for all other platform/mechanism families, dynamic collision
replacement, moving textures, environmental hazards, and owner-thread effect
delivery. M20–M35 remain open.
