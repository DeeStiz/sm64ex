# Porting Handoff: SM64 Modern Full Swift Twin M14k

## Scope

M14k extracts `mario_update_punch_sequence` into `SM64Modern/MarioPunchSequence.swift`.

The value boundary preserves first/second punch, fast-punch chaining, ground-kick, breakdance, moving/stationary end actions, animation frame flag windows, punch-state values, B continuation, and sound intents. It does not traverse Mario, body, animation, interaction, or audio objects.

## Validation

- `script/test_mario_punch_sequence.sh`
- Swift 6 strict-concurrency smoke and independent C contract fingerprint
- `git diff --check`
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build are required before commit.

## Boundary notes

- C's duplicate second-punch-fast animation call is represented once because the resulting state is identical.
- Object grabbing, interaction flags application, body-state delivery, audio playback, and action-state mutation remain owner-thread effects.
- This milestone is sequence-only; `act_move_punching` ground physics is the next slice.

## Next slice

M14l should compose the moving-punch body over the sequence, slope deceleration/acceleration, ground-step outcomes, jump-kick cancellation, and dust/freefall intents.
