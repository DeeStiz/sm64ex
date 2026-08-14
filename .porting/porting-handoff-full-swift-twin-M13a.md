# Porting Handoff — Full Swift Twin M13a

## Scope completed

M13a adds `SM64MarioState`, a Swift 6 `Sendable` value counterpart for the
portable POD portion of `struct MarioState`. It preserves C action constants,
save cap-loss bit positions, save-backed stars/lives/health defaults, initial
edge timers, cap-on-head initialization, spawn floor clamping, water-versus-
idle action selection, terrain and surface IDs, and stable object references.
No raw C pointers or mutable C state are retained.

## Validation

- `script/test_mario_state.sh` passed under Swift 6 strict concurrency with
  `marioStateFingerprint=0xf7ee192140fa2f9e` matching the independent C
  contract.
- Spawn below the floor clamps to the C floor height, lost-cap save flags keep
  cap state empty, normal saves restore `MARIO_NORMAL_CAP | MARIO_CAP_ON_HEAD`,
  and the water/idle action branch is asserted.
- The generated Xcode project includes `SM64Modern/MarioState.swift` after
  `xcodegen generate --spec project.yml`.

## Deliberate boundary

This is initialization/state parity, not action execution. The Mario action
families, interaction dispatch, hitboxes, effects, held/ridden object
transitions, save codec integration, and live Swift runtime wiring remain
unmigrated. Build/test success does not establish normal gameplay or human
acceptance.

## Next slice

Add the Mario terrain/health/cap mutation kernel and explicit effect intents,
then feed those state transitions from the owner-thread gameplay tick while
keeping C as the differential oracle.
