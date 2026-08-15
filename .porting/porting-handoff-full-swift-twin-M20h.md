# M20h Handoff — Racing-penguin waypoint/path owner

## Scope

M20h closes the generic copied-path owner seam for the racing penguin. Swift
reproduces `cur_obj_follow_path(0)` and supplies its result before each race
behavior tick. It does not claim the complete course trajectory inventory,
effect/audio delivery, the remaining NPC/puzzle inventory, or
physical/visual/human acceptance.

## Implementation

- `RacingPenguinPath.swift` ports path initialization, source flags, target
  selection, canonical yaw/pitch, dot-product crossing, waypoint advancement,
  and end detection without exposing segmented pointers.
- `RacingPenguinObjectBridge.swift` stores copied waypoints and previous index/
  flags after `initializePath`, computes path output before behavior, and
  exposes the result in the immutable owner effect.
- Focused smoke routes cover an initial segment, a waypoint crossing, final
  end detection, start reset, and owner-thread race action transitions.

## Validation

- Value fingerprint: `racingPenguinPathFingerprint=0x8c9a21508357868f`.
- Owner bridge fingerprint:
  `racingPenguinPathObjectBridgeFingerprint=0x7063aa2d1b2dbf0a`.
- The complete matrix reports `MATRIX_RESULT runs=163 failures=0` in
  `/tmp/sm64-modern-m20h-matrix.log`; the regenerated native Swift 6/macOS 27
  arm64 Debug build succeeds in `/tmp/sm64-modern-m20h-build.log`; and
  `git diff --check` plus the zero unchecked-Sendable audit pass.

## Remaining gate

Inventory and bind every course trajectory consumed by the US race/NPC
behaviors, route sound/camera/dialog/star/smoke effects through the common
owner-thread sink, then continue the remaining NPC, puzzle, boss, save,
frontend, audio, display-list, qualification, Metal, and device/human gates.
