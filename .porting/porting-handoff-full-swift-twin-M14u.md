# Porting Handoff: SM64 Modern Full Swift Twin M14u

## Scope

M14u extracts `common_ground_knockback_action` and all seven grounded
knockback action bodies into `MarioGroundKnockbackAction.swift`.

- Hard backward/forward, backward/forward, soft backward/forward, and ground
  bonk variants preserve their animation IDs, thresholds, heavy-landing gates,
  attacked/ooof sound choice, and variant-specific landing cues.
- Slope acceleration and flat-floor 0.9 friction preserve the common velocity
  update before the four-quarter ground-step query.
- Leaving the floor selects forward/backward air knockback with the original
  action argument; animation-end selects standing death or idle and admits the
  30-frame invincibility timer only for the surviving attacked path.
- Hard knockback death-on-back/death-on-stomach overrides and the special
  death-exit Mama-Mia sound remain explicit effect intents.

No raw Mario object, animation controller, sound device, or global flag crosses
the boundary; owner-thread code applies the returned action/effect values.

## Validation

- `script/test_mario_ground_knockback.sh` — matching Swift/C fingerprint
  `0x97cc82eaf0a450f9`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Animation frame advancement, sound-played flag suppression, health mutation,
  action installation, and physical sound delivery remain owner-thread seams.
- This slice does not yet extract common landing actions or airborne knockback
  bodies; those are required before M14 can close.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M14v should extract common landing action/cancel sequencing and the standard
landing variants, then close burning-ground and shell-air exits before M15.
