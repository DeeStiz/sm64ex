# M20b Handoff — Snowman Land walking penguin owner-thread bridge

## Scope

M20b attaches the M20a walking-penguin value kernel to the generation-safe
Swift object pool and owner-thread scheduler. It proves object-record
synchronization and end-of-frame retirement. It does not claim floor/wall
collision resolution, race/dialog ownership, effect/audio delivery, or the
remaining NPC and puzzle inventory.

## Implementation

- SLWalkingPenguinObjectBridge.swift owns the object ID registry and copied
  action/current-step/timer/move-yaw state.
- Each scheduler callback feeds the current object record into the M20a
  kernel, applies canonical next position and yaw, synchronizes transform
  flags, velocity, animation, angle velocity, action, previous action, and
  timer, and emits a value-only effect record.
- Marked objects remain in the scheduler list until its normal unload pass;
  bridge state is removed only from the returned unloaded IDs or stale
  generation checks.

## Validation

- Focused strict Swift 6/C output:
  slWalkingPenguinObjectBridgeFingerprint=0xaabb92f23fd8451a.
- Full script matrix:
  MATRIX_RESULT runs=154 failures=0 in
  /tmp/sm64-modern-m20b-matrix.log.
- xcodegen generate followed by the regenerated native Swift 6/macOS 27
  arm64 Debug build passed; log:
  /tmp/sm64-modern-m20b-clean-build.log.
- git diff --check passed and the Swift source audit still reports zero
  unchecked Sendable declarations.

## Remaining gate

Add caller-supplied floor/wall resolution and collision/effect intents, then
continue with race/dialog ownership and the remaining M20 NPC/puzzle routes.
Keep this bridge owner-thread-only and retain the C oracle until the route
shard emits complete schema-4 collision, camera, effect, render, audio, and
save domains.
