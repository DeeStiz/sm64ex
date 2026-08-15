# Porting Handoff: SM64 Modern Full Swift Twin M14v

## Scope

M14v extracts `common_landing_action`, `common_landing_cancels`, and the
standard landing action descriptors into `MarioLandingAction.swift`.

- Jump, freefall, side-flip, held jump/freefall, long jump, double jump,
  triple jump, and backflip descriptors preserve frame counts, double-jump
  timer writes, end/air/slide actions, animation IDs, and action arguments.
- Cancel ordering preserves steep-floor, slide, first-person, animation-timer,
  A-press, off-floor, and held-object-drop priority.
- A-press selection preserves quicksand, steep-jump, double/triple/wing-cap,
  held, and ordinary jump action decisions; long-jump/triple/backflip A-edge
  clearing is explicit.
- Landing acceleration, slope deceleration, four-quarter ground stepping,
  dust/landing-sound admission, quicksand-depth updates, and side-flip floor
  orientation are returned as value results.

No animation controller, Mario pointer, held-object pointer, collision global,
sound device, or floor matrix crosses the boundary.

## Validation

- `script/test_mario_landing.sh` — matching Swift/C fingerprint
  `0x70ebcf34b93a0f6d`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Quicksand jump-land animation bodies, action installation, animation-frame
  advancement, sound-played flags, held-object delivery, and floor-orientation
  matrix application remain owner-thread seams.
- This slice does not yet extract airborne knockback, shell-air, or burning
  ground action bodies.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M14w should close quicksand jump-land and airborne knockback transitions, then
extract burning-ground and shell-air exits before M15 begins.
