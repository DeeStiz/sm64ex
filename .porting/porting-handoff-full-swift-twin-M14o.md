# Porting Handoff: SM64 Modern Full Swift Twin M14o

## Scope

M14o extracts `act_finish_turning_around` into `MarioFinishTurningAction.swift`. The value boundary preserves above-slide and side-flip exits, the C walking-speed callback followed by optional slope acceleration, four-quarter ground stepping, animation-part ordering, freefall-versus-animation-end action precedence, and the `gfx.angle[1] += 0x8000` owner-thread intent.

## Validation

- `script/test_mario_finish_turning.sh` — matching Swift/C fingerprint `0x16a3c0ee1fd71a36`
- Swift 6 strict-concurrency focused compilation and independent C contract
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required before commit
- `git diff --check`

## Boundary notes

- The graphics yaw change is returned as `graphicsYawDelta`; the pure action kernel does not mutate a render object.
- The slope input remains optional while the owner-thread collision caller is migrated; populated inputs follow C callback/slope order.
- Local build/test evidence does not establish physical input feel, visual parity, haptics, or human acceptance.

## Next slice

M14p should extract shared slide-entry/common-slide physics (`begin_sliding`, `common_slide_action`, and the first butt/stomach slide bodies), then continue through crouch/crawl and remaining moving action families before M15.
