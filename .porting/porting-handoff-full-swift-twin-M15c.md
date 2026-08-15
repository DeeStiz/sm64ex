# Porting Handoff: SM64 Modern Full Swift Twin M15c

## Scope

M15c adds side-flip, wall-kick, and long-jump callers in
`MarioAirMovementAction.swift`.

- Side-flip B/Z exits, ledge-facing exception, frame-six sound, and slide-flip
  animation are explicit.
- Wall-kick B/Z exits, jump animation, landing descriptor, and jump-sound
  intent are explicit.
- Long-jump fast/slow animation, Yahoo sound, vertical-wind Here-We-Go gate,
  and landing rumble are preserved around common air stepping.

## Validation

- `script/test_mario_air_movement.sh` — matching Swift/C fingerprint
  `0x4bb9af493159b1ee`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Common collision, air-control, and action-result effects come from M15a;
  graphics-facing mutation and sound delivery remain owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15d should add dive, forward/backward rollout, air throw, and twirl callers,
then continue with water-jump and submerged families.
