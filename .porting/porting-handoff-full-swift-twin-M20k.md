# Full Swift Twin Handoff — M20k

## Status

M20k is complete locally as a value-kernel seam. `TuxiesMotherBehavior.swift`
keeps the C controller's follow/carry/chase actions, one-frame dialog gates,
dialog IDs 57/58/59, held-child attachment, correct/wrong-child branches,
the `INT_SUBTYPE_DROP_IMMEDIATELY` mask, the original clear-boundary bug as an
explicit owner intent, walking/yell effects, and the US CCM reward-star target
and source Y offset. No C object pointer crosses the kernel boundary.

## Evidence

- Focused strict Swift 6/C value contract:
  `tuxiesMotherFingerprint=0x37983b7c17d00110`.
- The smoke covers initial dialog gating/completion, held-child attachment,
  correct-child reward and star target, wrong-child return-to-baby behavior,
  chase yaw/sub-action thresholds, walking audio, yell frame, and loop flags.
- The complete matrix passes with `MATRIX_RESULT runs=166 failures=0` in
  `/tmp/sm64-modern-m20k-matrix.log`.
- The regenerated native Swift 6/macOS 27 arm64 Debug build succeeds in
  `/tmp/sm64-modern-m20k-build.log`; `git diff --check` is clean and the
  unchecked-Sendable audit reports `0`.
- This handoff must not be read as an owner-object or physical/visual
  acceptance claim.

## Boundary

This closes the Tuxie's mother value route only. Owner-thread object wiring,
small-penguin behavior, collision/movement, geo eyes, dialog integration, and
remaining NPC/puzzle families remain open. M20l should attach this kernel to a
generation-safe mother/child bridge before proceeding to the next NPC family.

## Next command

```sh
./script/test_tuxies_mother.sh
```
