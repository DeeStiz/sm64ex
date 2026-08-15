# M20c Handoff — Snowman Land walking penguin collision route

## Scope

M20c connects the M20b owner-thread bridge to the value-typed surface collision
world. It proves wall projection, wall-facing admission, floor metadata, and
move-flag publication. It does not claim the complete cur_obj_move_standard
gravity/edge/steep-slope/water route, effect/audio delivery, race/dialog
ownership, or the remaining NPC and puzzle inventory.

## Implementation

- SLWalkingPenguinCollision.swift consumes an immutable collision world and
  returns resolved position, floor identity/height/type/normal, wall IDs, and
  C-compatible move flags.
- SurfaceCollisionWorld now exposes a stable surface lookup by ID so the
  collision route can calculate the wall normal and the legacy
  abs-angle-difference admission without sharing a surface pointer.
- SLWalkingPenguinObjectBridge.swift accepts an optional world per owner-thread
  tick, applies the collision result to the object record, preserves the
  spawn home position, and includes the collision result in its effect record.

## Validation

- Focused strict Swift 6/C output:
  slWalkingPenguinCollisionFingerprint=0xab2e63008759849f.
- Parent bridge output remains:
  slWalkingPenguinObjectBridgeFingerprint=0xaabb92f23fd8451a.
- Full script matrix:
  MATRIX_RESULT runs=155 failures=0 in
  /tmp/sm64-modern-m20c-matrix-chunks.log.
- xcodegen generate followed by the regenerated native Swift 6/macOS 27 arm64
  Debug build passed; log:
  /tmp/sm64-modern-m20c-clean-build.log.
- git diff --check and the zero unchecked-Sendable source audit pass.

## Remaining gate

Add gravity, water, edge, steep-slope, room-admission, and native-step
semantics to the collision route, then route sound/wind/effect intents before
continuing with races, dialog, and the remaining NPC/puzzle behaviors.
