# Full Swift Twin Handoff — M20l

## Status

M20l is complete locally as the owner-thread object bridge for Tuxie's mother
and her small penguin. `TuxiesMotherObjectBridge.swift` keeps the M20k value
kernel free of C pointers while attaching generation-safe object IDs, routing
dialog/audio/star intents through `SM64OwnerThreadEffectRouter`, synchronizing
behavior/interaction/transform fields, preserving the US CCM reward-star
source and home target, and retiring the owned child at the scheduler unload
boundary.

## Evidence

- Focused strict Swift 6/C owner-thread contract:
  `tuxiesMotherObjectBridgeFingerprint=0xbe32e199efb473f8`.
- The smoke covers initial dialog gating and presentation, accepted dialog
  state, held-child linkage, correct-child dialog and interaction mask, reward
  star spawn/source/home fields, child behavior mutation and clear boundary,
  owner-thread effect delivery, and generation-safe parent/child retirement.
- The complete matrix passes with `MATRIX_RESULT runs=167 failures=0` in
  `/tmp/sm64-modern-m20l-matrix.log`.
- The regenerated native Swift 6/macOS 27 arm64 Debug build succeeds in
  `/tmp/sm64-modern-m20l-build.log`; `git diff --check` is clean and the
  unchecked-Sendable audit reports `0`.
- Local commit is required before starting the next milestone; no remote push
  or physical/visual/human acceptance is implied.

## Boundary

This closes the Tuxie's mother owner-thread bridge only. The standalone
small-penguin behavior route, full collision/movement integration, broader
dialog/effect/audio identity, other trajectories, remaining NPC/puzzle
families, and physical/visual/human acceptance remain open.

## Next command

```sh
./script/test_tuxies_mother_object_bridge.sh
```
