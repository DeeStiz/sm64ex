# Full Swift Twin Handoff — M20n

## Status

M20n is complete locally as the owner-thread bridge for the standalone small
penguin. `SmallPenguinObjectBridge.swift` attaches the M20m kernel to
generation-safe IDs, publishes action/timer/held/transform fields, places a
held child at the supplied Mario position, switches a baby behavior identity
back to `bhvSmallPenguin`, routes walking/dive/yell intents through the shared
effect sink, and clears state at the scheduler unload boundary.

## Evidence

- Focused strict Swift 6/C owner-thread contract:
  `smallPenguinObjectBridgeFingerprint=0x23028a8ee48f283b`.
- The smoke covers action/timer/yaw publication, mother-follow state, held
  placement and behavior identity transition, owner-thread sound delivery,
  release, and generation-safe unload cleanup.
- The complete matrix passes with `MATRIX_RESULT runs=169 failures=0` in
  `/tmp/sm64-modern-m20n-matrix.log`.
- The regenerated native Swift 6/macOS 27 arm64 Debug build succeeds in
  `/tmp/sm64-modern-m20n-build.log`; `git diff --check` is clean and the
  unchecked-Sendable audit reports `0`.
- This is local milestone evidence only; no push or physical/visual/human
  acceptance is implied.

## Boundary

This closes the small-penguin owner-thread route only. Collision/movement
integration, richer audio/effect identity, geo eyes, broader dialog routes,
remaining NPC/puzzle families, and physical/visual/human acceptance remain
open.

## Next command

```sh
./script/test_small_penguin_object_bridge.sh
```
