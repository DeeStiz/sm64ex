# Porting Handoff: SM64 Modern Full Swift Twin M15i

## Scope

M15i adds water interaction state machines in
`MarioWaterInteractionAction.swift`.

- Water throw preserves timer-five held-object throw, animation-end idle,
  and throw rumble.
- Water punch preserves three animation/grab phases, object-grab placement,
  action-end routing, shell pickup, and held-object action argument.
- Water shell swimming preserves drop/B/timeout priority, speed approach,
  flutter-kick dismount, shell music stop, and swimming noise intent.

## Validation

- `script/test_mario_water_interaction.sh` — matching Swift/C fingerprint
  `0x321a3ca5ba42561f`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Shared water stepping, object lookup/grab/throw, animation/audio
  installation, shell ownership, and surface effects remain explicit
  owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15j should extract water knockback, plunge, whirlpool, and remaining water
transition effects before metal-water standing/walking/falling/jump families.
