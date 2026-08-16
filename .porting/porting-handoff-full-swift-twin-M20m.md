# Full Swift Twin Handoff — M20m

## Status

M20m is complete locally as the standalone value route for
`bhv_small_penguin_loop`. `SmallPenguinBehavior.swift` reproduces the six
free actions, random idle thresholds supplied by the owner, mother-follow
handoff, dive/recover timing, far-away home reset, held/thrown/dropped
branches, and walking/dive/held-yell sound decisions without retaining C
objects or pointers.

## Evidence

- Focused strict Swift 6/C value contract:
  `smallPenguinFingerprint=0x9638684db48d51c6`.
- The smoke covers idle threshold initialization, move-away and move-toward
  gates/yaw, dive and recovery timing, mother follow/link behavior, held and
  thrown/dropped paths, far-away reset, and sound cadence.
- The complete matrix passes with `MATRIX_RESULT runs=169 failures=0` in
  `/tmp/sm64-modern-m20n-matrix.log`.
- The regenerated native Swift 6/macOS 27 arm64 Debug build succeeds in
  `/tmp/sm64-modern-m20n-build.log`; `git diff --check` is clean and the
  unchecked-Sendable audit reports `0`.

## Boundary

This closes the small-penguin value route only. Owner-thread object
publication, collision/movement integration, scene/geo behavior, and
remaining NPC/puzzle families remain open to M20n and later milestones.

## Next command

```sh
./script/test_small_penguin.sh
```
