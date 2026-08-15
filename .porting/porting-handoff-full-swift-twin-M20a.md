# M20a Handoff — Snowman Land walking penguin

## Scope

M20a ports the deterministic bhv_sl_walking_penguin_loop state machine. It
does not claim floor/wall collision resolution, the object bridge, race/dialog
ownership, or the remaining NPC/puzzle inventory.

## Implementation

- `SM64SLWalkingPenguinBehavior` owns the exact five-step movement table,
  timer-zero initialization, step transition/wrap, X-boundary action changes,
  turn action/timer behavior, 16-bit yaw update, and animation/speed intents.
- The output includes canonical forward displacement so the owner-thread
  collision caller can apply cur_obj_move_standard(-78) semantics without
  sharing a C object.

## Validation

- Focused strict Swift 6/C output:
  `slWalkingPenguinFingerprint=0xf80b620bf18ccb4d`.
- Full `script/test_*.sh` matrix:
  `MATRIX_RESULT runs=153 failures=0` in
  `/tmp/sm64-modern-m20a-matrix.log`.
- `xcodegen generate`, regenerated native Swift 6/macOS 27 Debug build,
  and `git diff --check` pass.

## Remaining gate

Attach this kernel to a generation-safe NPC object bridge, supply floor/wall
resolution and audio/effect intents, then port dialog/race ownership and the
remaining M20 families.
