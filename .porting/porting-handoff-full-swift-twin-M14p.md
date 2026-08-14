# Porting Handoff: SM64 Modern Full Swift Twin M14p

## Scope

M14p extracts the scalar slide integrator (`update_sliding`/`update_sliding_angle`) and the common butt/stomach slide bodies into `MarioSliding.swift` and `MarioSlideAction.swift`. The value boundary preserves slipperiness-class acceleration/loss, canonical yaw/facing adjustment, stop-speed and signed-speed behavior, timer-gated jump/rollout exits, four-quarter ground stepping, non-slippery slide bonk, slippery-wall redirection, air/stop transitions, animation/dust/floor-alignment/tilt intents, and high-speed fall sound admission.

## Validation

- `script/test_mario_slide.sh` — matching Swift/C fingerprint `0xa0662a31fd5145ca`
- Swift 6 strict-concurrency focused compilation and independent C contract
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required before commit
- `git diff --check`

## Boundary notes

- Slide wall redirection consumes immutable wall probes and returns the redirected slide yaw/velocity; collision and graphics graphs remain owner-thread state.
- Hold-object slide variants and crouch/slide-kick/dive-slide action-specific effects are not silently treated as complete.
- Local build/test evidence does not establish physical input feel, visual parity, haptics, or human acceptance.

## Next slice

M14q should port hold-object slide variants and crouch/slide-kick/dive-slide bodies, including drop/rollout/rumble and object-grab effect intents, before closing M14 action coverage and opening M15 airborne/submerged actions.
