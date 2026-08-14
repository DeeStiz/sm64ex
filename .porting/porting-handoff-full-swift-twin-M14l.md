# Porting Handoff: SM64 Modern Full Swift Twin M14l

## Scope

M14l extracts `act_move_punching` into `SM64Modern/MarioMovePunchAction.swift`. The value boundary preserves the C branch order for above-slide and held-A jump-kick exits, shared moving punch-sequence dispatch, positive-speed slope deceleration, negative-speed recovery followed by slope acceleration, four-quarter ground stepping, freefall transition, and the ground dust intent. `MarioSlopeDeceleration.swift` is reusable for the subsequent braking/decelerating actions.

Object-grab interaction, body-state flag delivery, action-entry mutation, and owner-thread effect/audio application remain explicit seams; the migrated boundary does not traverse C object pointers.

## Validation

- `script/test_mario_move_punch.sh` — matching Swift/C fingerprint `0x56b66785eb36860a`
- Swift 6 strict-concurrency focused compilation and independent C contract
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required before commit
- `git diff --check`

## Boundary notes

- `SM64MarioPunchSequenceResult` remains an intent; it does not perform object grabs or mutate the Mario body state.
- The moving action returns the sequence transition action while preserving the C post-sequence slope/ground-step ordering.
- Focused/native build evidence does not establish physical input feel, visual parity, haptics, or human acceptance.

## Next slice

M14m should extract `act_braking` and `act_decelerating`, sharing slope deceleration and preserving wall/ground/freefall transitions. M14n can then cover turning-around and slide-entry/slide bodies.
