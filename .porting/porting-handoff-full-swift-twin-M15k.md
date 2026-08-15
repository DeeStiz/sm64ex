# Porting Handoff: SM64 Modern Full Swift Twin M15k

## Scope

M15k adds whirlpool capture orbiting and delayed death-warp timing in
`MarioWhirlpoolAction.swift`.

- Orbit radius and angular-step branches preserve the near, middle, and
  distant whirlpool paths.
- Vertical offset settling, velocity, face-yaw rotation, fall animation,
  graphics synchronization, and rumble reset remain explicit outputs.
- The inner-radius timer preserves the C post-increment death-warp boundary.

## Validation

- `script/test_mario_whirlpool.sh` — matching Swift/C fingerprint
  `0x92c933d08604602a`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- Full `script/test_*.sh` matrix and native `SM64Modern` macOS build required
  before commit.
- `git diff --check`.

## Boundary notes

- Whirlpool object lookup, warp dispatch, animation installation, graphics
  object writes, and rumble delivery remain explicit owner-thread effects.
- Local build/test evidence does not establish physical input feel, visual
  parity, haptics, or human acceptance.

## Next slice

M15l should extract metal-water standing and held-standing transitions, then
continue through walking, falling, jump, and landing families.
