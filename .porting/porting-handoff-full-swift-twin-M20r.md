# Full Swift Twin Handoff — M20r

## Status

M20r is complete locally as the Bob-omb Buddy value route. The reducer owns
the C action 0/1/2 idle/turn/talk transitions, symmetric yaw increments,
interaction admission, advice dialog completion, cannon unopened/opening/
opened/stop phases, course-specific dialog IDs, prepare-cannon camera intent,
visibility distance, blink input, and typed time-stop/interaction cleanup.

## Evidence

- Focused Swift 6/C fingerprint: `0xdc0f36c0b93e7920`.
- Focused script: `script/test_bobomb_buddy.sh`.
- Full matrix: `/tmp/sm64-modern-m20r-final-matrix.log`, `MATRIX_RESULT runs=173 failures=0`.
- Native Debug build: `/tmp/sm64-modern-m20r-build.log`, `** BUILD SUCCEEDED **`.
- `git diff --check` and zero unchecked-Sendable audit pass.

## Changed surface

- `SM64Modern/BobombBuddyBehavior.swift` contains the value state/input/output
  contract and the Bob-omb Buddy action/cannon reducer.
- `tests/sm64_modern_bobomb_buddy_smoke.swift` covers interaction/turn,
  advice completion, cannon opening/camera/ready/stop phases, and blink input.
- `tests/sm64_modern_bobomb_buddy_contract.c` is the independent C fingerprint
  oracle; `script/test_bobomb_buddy.sh` is the strict Swift 6/C runner.

## Boundaries

This closes the value route only. Object-pool ownership, sound/dialog/camera
effect delivery, live cannon object lookup, and remaining NPC/puzzle/boss,
save, audio, HUD, front-end, Metal 4 production, and human acceptance gates
remain open. No device, visual, physical controller, audio, store,
notarization, or clean-machine claim is made.

## Next

The value route is validated and ready for a local commit. Next, add the
generation-safe Bob-omb Buddy owner/effect bridge before moving to the next
NPC/puzzle family. Commit locally without pushing.

The action constants were corrected to the source-authored C values (`0`,
`2`, and `3`) before owner wiring; the refreshed focused contract is the
fingerprint above.
