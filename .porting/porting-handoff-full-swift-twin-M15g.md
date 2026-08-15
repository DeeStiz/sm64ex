# Porting Handoff: SM64 Modern Full Swift Twin M15g

## Scope

M15g adds the first submerged dispatch boundary in
`MarioSubmergedAction.swift`.

- Water and held-water idle preserve metal-cap, drop-object, B, and A
  priority plus water-idle animation/acceleration intents.
- Water action-end variants preserve metal/drop/B/A priority, held grab-end
  animation selection, and animation-end return to idle.
- Drowning, water-death, and shocked states preserve animation phases, eye
  state, death-frame warp, invincibility, metal-shock, sound, and camera-shake
  intents.

## Validation

- `script/test_mario_submerged.sh` — matching Swift/C fingerprint
  `0x2b82d869f97cf0de`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Water collision/current/buoyancy stepping, object lookup/grab/throw, camera,
  audio, particles, eye state, and warp remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15h should extract swimming/breaststroke/flutter-kick control and water
throw/punch/grab callers, then add water knockback/plunge/whirlpool and the
metal-water movement families.
