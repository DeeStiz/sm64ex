# M20g Handoff — Racing-penguin child ownership

## Scope

M20g closes the two child callbacks attached by the racing-penguin behavior:
the finish-line child that awards a non-bottom crossing and the shortcut child
that records a cheat. The owner bridge allocates both children only after the
race proposal is accepted, evaluates their copied world facts before the
parent behavior tick, and removes them with the parent generation. It does not
claim path waypoint traversal, effect/audio delivery, the remaining NPC/puzzle
inventory, or physical/visual/human acceptance.

## Implementation

- `RacingPenguinRaceChildren.swift` is a strict value kernel for the exact C
  predicates: finish distance `< 1000` plus negative Mario delta-Z, and
  shortcut distance `< 500`.
- `RacingPenguinObjectBridge.swift` adds generation-safe finish-line and
  shortcut child IDs to the owner effect, applies child outputs before the
  parent tick, and fences child cleanup when the parent unloads.
- The bridge smoke proves parent links, propagated win/cheat state, and child
  cleanup; direct and owner-thread C contracts independently match Swift.

## Validation

- Value fingerprint:
  `racingPenguinRaceChildrenFingerprint=0x87b61e16494da173`.
- Owner bridge fingerprint:
  `racingPenguinRaceChildrenObjectBridgeFingerprint=0x5fcb16697e344061`.
- The complete matrix reports `MATRIX_RESULT runs=161 failures=0` in
  `/tmp/sm64-modern-m20g-matrix.log`; the regenerated native Swift 6/macOS 27
  arm64 Debug build succeeds in `/tmp/sm64-modern-m20g-build.log`; and
  `git diff --check` plus the zero unchecked-Sendable audit pass.

## Remaining gate

Bind the real race waypoint/path owner, route sound/camera/dialog/star/smoke
effects through the common owner-thread sink, then continue the remaining NPC,
puzzle, boss, save, frontend, audio, display-list, qualification, Metal, and
device/human gates.
