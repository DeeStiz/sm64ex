# Full Swift Twin Handoff — M20p

## Status

M20p is complete locally as the Tuxie mother geo eye-switch value route.
`TuxiesMotherEyes.swift` reproduces the C callback's run gate, 50-frame
blink cadence (cases 0, 1, and 2), behavior-identity match, strict
`forwardVelocity > 5` angry case 3 override, and previous-case preservation
when the graph callback is not running.

## Evidence

- Focused Swift 6/C fingerprint: `0x4b5a7e6b3afb43a3`.
- Focused script: `script/test_tuxies_mother_eyes.sh`.
- Full matrix: `/tmp/sm64-modern-m20p-final-matrix.log`,
  `MATRIX_RESULT runs=171 failures=0`.
- Regenerated native Debug build: `/tmp/sm64-modern-m20p-build.log`,
  `** BUILD SUCCEEDED **`.
- `git diff --check` and zero unchecked-Sendable audit pass.

## Changed surface

- `SM64Modern/TuxiesMotherEyes.swift` contains the value input/output contract
  and callback-equivalent blink/angry-eye reducer.
- `tests/sm64_modern_tuxies_mother_eyes_smoke.swift` exercises run gating,
  every blink boundary, identity mismatch, and the strict velocity threshold.
- `tests/sm64_modern_tuxies_mother_eyes_contract.c` is the independent C
  fingerprint oracle.
- `script/test_tuxies_mother_eyes.sh` is the strict Swift 6/C focused runner;
  `project.yml` source discovery includes the new implementation.

## Boundaries

This closes only the deterministic geo callback. Graph-node switch-case
presentation wiring, renderer/display-list identity, other Tuxie effects and
dialog integration, and the remaining NPC, puzzle, boss, save, audio, HUD,
front-end, Metal 4 production, and human acceptance gates remain open. No
device, visual, physical controller, audio, store, notarization, or
clean-machine claim is made.

## Next

Continue M20 with the next reachable NPC/puzzle/geo owner seam. Commit locally
without pushing.
