# Porting Handoff: SM64 Modern Full Swift Twin M14q

## Scope

M14q extracts the five moving slide-family variants that sit beside the M14p
common butt/stomach boundary:

- held-object butt slide, including drop-to-butt-slide and hold jump/air IDs;
- held-object stomach slide, including drop-to-stomach-slide and hold freefall;
- crouch slide, including the 30-frame timer, long-jump/punch/jump/braking
  priority, and common slide transition;
- slide-kick slide, including rollout rumble, animation-end stop, freefall
  argument, and unconditional wall reflection/backward knockback;
- dive slide, including rollout timing, stop-before-grab ordering, landing
  sound admission, and light-object grab placement.

All interaction, rumble, landing-sound, animation, dust, tilt, reflection, and
object-grab effects are returned as owner-thread intents. The value boundary
does not retain Mario/object pointers or mutate the collision/graphics graph.

## Validation

- `script/test_mario_slide_variants.sh` — matching Swift/C fingerprint
  `0xf6ebee68a8a803ff`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- The C source remains the differential oracle; this slice is a pure action
  decision/effect contract, not a claim that the live dispatcher applies every
  returned intent yet.
- Object-grab callbacks, physical rumble/audio delivery, and graphics/body
  mutation remain owner-thread work.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M14r should close the remaining stationary/moving action bodies and their
owner-thread effect seams, then M15 can begin the airborne, submerged,
automatic, pole, hanging, cannon, and other non-ground action families.
