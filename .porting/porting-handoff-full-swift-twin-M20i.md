# M20i Handoff — Snowman Land penguin trajectory inventory

## Scope

M20i adds the complete US Snowman Land racing-penguin trajectory as immutable
Swift value data. It preserves the source's intentional missing waypoint ID
27 and terminal sentinel, and proves the inventory against the C source. It
does not claim path selection for every other reachable trajectory,
effect/audio delivery, the remaining NPC/puzzle inventory, or
physical/visual/human acceptance.

## Implementation

- `RacingPenguinPath.ccmPenguinRace` copies all 52 operational entries from
  `ccm_seg7_trajectory_penguin_race` plus the `-1` sentinel.
- The Swift inventory smoke checks count, missing-ID placement, sentinel, and
  every f32 coordinate/flag bit pattern.
- The C contract includes the original trajectory source directly and hashes
  its raw values, so a source edit cannot silently drift from the Swift table.

## Validation

- Fingerprint: `racingPenguinTrajectoryFingerprint=0x3a936052c3cb2cd1`.
- The complete matrix reports `MATRIX_RESULT runs=164 failures=0` in
  `/tmp/sm64-modern-m20i-matrix.log`; the regenerated native Swift 6/macOS 27
  arm64 Debug build succeeds in `/tmp/sm64-modern-m20i-build.log`; and
  `git diff --check` plus the zero unchecked-Sendable audit pass.

## Remaining gate

Bind the canonical trajectory to the runtime's path-selection/content route,
inventory other reachable course trajectories, route sound/camera/dialog/star/
smoke effects through the common owner-thread sink, then continue the remaining
NPC, puzzle, boss, save, frontend, audio, display-list, qualification, Metal,
and device/human gates.
