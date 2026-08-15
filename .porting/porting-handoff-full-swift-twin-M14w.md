# Porting Handoff: SM64 Modern Full Swift Twin M14w

## Scope

M14w extracts `quicksand_jump_land_action` for light and held-object Mario
landings into `MarioQuicksandLandingAction.swift`.

- The post-increment timer boundary preserves the first seven jump-animation
  frames, the land-animation window, and the frame-13 end-action transition.
- Quicksand depth recovery uses the original `(7 - actionTimer) * 0.8`
  decrement and 1.1 minimum clamp.
- Light and held variants preserve jump sound admission, animation IDs,
  end-action IDs, air-action IDs, landing acceleration, and four-quarter
  ground-step/freefall behavior.

## Validation

- `script/test_mario_quicksand_landing.sh` — matching Swift/C fingerprint
  `0x0b128f16ca14b1a2`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Animation frame advancement, sound-played flags, quicksand terrain lookup,
  action installation, and physical jump-sound delivery remain owner-thread
  seams.
- Airborne knockback, shell-air, and burning-ground bodies remain open.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M14x should extract common airborne knockback step/air-action transitions and
their ground-action selection before shell-air and burning-ground closure.
