# Porting Handoff: SM64 Modern Full Swift Twin M15b

## Scope

M15b adds value callers for the basic airborne family in
`MarioBasicAirAction.swift`.

- Jump, double-jump, triple-jump, backflip, freefall, held jump, and held
  freefall preserve their input-priority gates and animation descriptors.
- Special triple-jump, dive/ground-pound, held-object drop/throw, and
  holdable-NPC exceptions are explicit transitions.
- Jump sound variants, triple/backflip rumble, and flip-sound intents are
  returned around the shared common-air result.

## Validation

- `script/test_mario_basic_air.sh` — matching Swift/C fingerprint
  `0x2c04014e6d8dd2a0`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Shared collision/air-control decisions come from M15a; this layer does not
  install actions or traverse held-object pointers.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15c should add side-flip, wall-kick, long-jump, and shell/rollout callers, then
continue with dive, twirl, water-jump, and submerged action families.
