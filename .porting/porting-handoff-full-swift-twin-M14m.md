# Porting Handoff: SM64 Modern Full Swift Twin M14m

## Scope

M14m extracts `act_braking`, `act_decelerating`, and `update_decelerating_speed` into `MarioBrakingAction.swift`, `MarioDeceleratingAction.swift`, and `MarioDeceleratingSpeed.swift`. The value boundaries preserve common-exit priority, C slope-deceleration coefficients, braking-stop and moving-punch exits, four-quarter ground-step handling, slide-bonk/backward-knockback selection, freefall, decelerating idle/dive/landing-jump/crouch/walking exits, floor-class animation intents, and very-slippery wall reflection.

Audio, rumble, body animation delivery, owner-thread action mutation, and interaction callbacks remain explicit effects rather than hidden C graph access.

## Validation

- `script/test_mario_braking_decelerating.sh` — matching Swift/C fingerprint `0xc8ba96a395b5467e`
- Swift 6 strict-concurrency focused compilation and independent C contract
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required before commit
- `git diff --check`

## Boundary notes

- `MarioSlopeDeceleration` is shared by moving punch, braking, and the upcoming turning/slide actions.
- Wall reflection consumes the immutable wall probe and returns reflected yaw/velocity; it does not mutate the collision graph.
- Local build/test evidence does not establish physical input feel, visual parity, haptics, or human acceptance.

## Next slice

M14n should extract `act_turning_around` and `act_finish_turning_around`, including common exits, slope deceleration, finish-turn walking handoff, animation/effect intents, and the 180-degree body-facing adjustment. Then continue through the common slide bodies before opening M15 airborne/submerged actions.
