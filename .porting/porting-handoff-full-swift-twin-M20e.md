# M20e Handoff — Walking-penguin move-standard route

## Scope

M20e adds the scalar `cur_obj_move_standard(-78)` route for the walking
penguin and an explicit owner-thread bridge gate. It does not claim exact
wall-prepass ordering, race path/child ownership, effect/audio delivery, the
remaining NPC/puzzle inventory, or physical/visual/human acceptance.

## Implementation

- `SLWalkingPenguinMovement.swift` consumes the behavior candidate and selected
  floor facts, then reproduces canonical X/Z velocity, drag, edge/steep-slope
  admission, gravity/bounce, water transitions, and ground/air flags.
- `SLWalkingPenguinObjectBridge.swift` accepts `advanceMovement` only when the
  caller also supplies an immutable collision world; movement velocity and
  flags are then written to the owner-thread object record and effect.
- The earlier walking-penguin table now includes the source C's final idle
  entry before its sentinel; the long-cycle focused fingerprint is
  `0xc99ad9a0e7015251`.

## Validation

- Focused movement fingerprint:
  `slWalkingPenguinMovementFingerprint=0x06637c47225dd8a1`.
- Focused owner-thread movement fingerprint:
  `slWalkingPenguinMovementBridgeFingerprint=0x2c3d22136511755b`.
- Both independent C contracts match their Swift outputs.
- The current full matrix is `MATRIX_RESULT runs=159 failures=0` in
  `/tmp/sm64-modern-m20e-matrix.log`; the regenerated native Swift 6/macOS 27
  arm64 Debug build succeeds in `/tmp/sm64-modern-m20e-clean-build.log`, and
  `git diff --check` plus the zero unchecked-Sendable audit pass.

## Remaining gate

Reorder the owner bridge around the C wall/floor prepass so movement consumes
the exact pre-behavior floor and wall state, then bind path/finish-line child
objects and route sound, camera, dialog, star, wind, and smoke effects before
continuing the remaining NPC, puzzle, boss, save, frontend, audio,
display-list, qualification, Metal, and device/human gates.
