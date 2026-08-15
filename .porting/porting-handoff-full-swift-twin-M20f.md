# M20f Handoff — Walking-penguin C-order prepass route

## Scope

M20f closes the C-order wall/floor prepass for the opt-in walking-penguin
movement route. The bridge resolves the current collision state before the
behavior kernel, feeds the projected position and selected floor facts into
movement, and preserves the historical collision-only path for existing
callers. It does not claim path/finish-line child ownership, effect/audio
delivery, the remaining NPC/puzzle inventory, or physical/visual/human
acceptance.

## Implementation

- `SLWalkingPenguinObjectBridge.swift` performs the prepass at the owner
  record's current position when `advanceMovement` is enabled, uses that
  result for behavior and movement inputs, and publishes movement velocity,
  forward speed, and wall/ground flags back to the record.
- The collision-only route remains post-behavior and is therefore backward
  compatible with the M20b/M20c callers.
- The focused bridge smoke includes a wall at `x=300`; it proves that the
  projected `x=320` position is visible to behavior, that the wall surface ID
  survives, and that movement stops within the projected wall boundary.

## Validation

- Focused owner-thread movement fingerprint:
  `slWalkingPenguinMovementBridgeFingerprint=0xc1e522003a32dd59`.
- The independent Swift and C contracts match.
- The complete matrix reports `MATRIX_RESULT runs=159 failures=0` in
  `/tmp/sm64-modern-m20f-matrix.log`; the regenerated native Swift 6/macOS 27
  arm64 Debug build succeeds in `/tmp/sm64-modern-m20f-build.log`; and
  `git diff --check` plus the zero unchecked-Sendable audit pass.

## Remaining gate

Bind path and finish-line child objects, route sound/camera/dialog/star/wind/
smoke effects through the common owner-thread sink, then continue the
remaining NPC, puzzle, boss, save, frontend, audio, display-list,
qualification, Metal, and device/human gates.
