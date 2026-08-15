# Porting Handoff: SM64 Modern Full Swift Twin M15h

## Scope

M15h adds shared swimming control and six breaststroke/swimming-end/flutter-
kick callers in `MarioSwimmingAction.swift`.

- Shared yaw/pitch/speed preserves canonical stick response, roll, buoyancy,
  speed thresholds, and floor/ceiling/wall pitch responses.
- Light swimming preserves timer/strength progression, B/A/water-jump and
  flutter transitions, sound/noise/float-reset intents, and swim animations.
- Held swimming preserves drop/B/A/water-jump priority and held animation and
  transition IDs.

## Validation

- `script/test_mario_swimming.sh` — matching Swift/C fingerprint
  `0x6b05d39a586c56cd`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Water current/buoyancy/collision stepping, surface particles, object
  interaction, animation installation, and audio remain explicit owner-thread
  effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15i should extract water throw/punch/grab, water knockback, plunge/whirlpool,
and then metal-water standing/walking/falling/jump families.
