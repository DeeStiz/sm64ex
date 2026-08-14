# Porting Handoff: SM64 Modern Full Swift Twin M14n

## Scope

M14n extracts `act_turning_around` into `MarioTurningAction.swift`. The value boundary preserves the C branch priority for slide, side flip, braking, and walking exits; the strict analog-back threshold; slope deceleration and `begin_walking_action` stop handoff; turning animation-part choice; four-quarter ground-step/freefall behavior; terrain sound/dust intents; and animation-end walking with reversed speed.

`act_finish_turning_around`, the body-facing 180-degree graphics mutation, and owner-thread application of animation/audio remain follow-on seams.

## Validation

- `script/test_mario_turning.sh` — matching Swift/C fingerprint `0xfc6d0710cd8a1492`
- Swift 6 strict-concurrency focused compilation and independent C contract
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required before commit
- `git diff --check`

## Boundary notes

- Canonical trig table values are used for the stop and finish-to-walking velocity projections; signed-zero bits are part of the contract.
- `terrainSound` and `particleDust` are immutable effect intents; no audio or graphics callback occurs in the kernel.
- Local build/test evidence does not establish physical input feel, visual parity, haptics, or human acceptance.

## Next slice

M14o should extract `act_finish_turning_around`, then port shared slide entry/common slide physics and remaining moving action bodies before starting M15 airborne/submerged actions.
