# Full Swift Twin Handoff — M20t

## Status

M20t is complete locally as the Yoshi value route. Swift now owns the
source-authored seven-action state machine, 120-star/dead save gate, castle
roof home selection and turning, NPC dialog/time-stop handoff, present/lives
cadence, roof jump/finish despawn, respawner request, and credits action.

## Evidence

- Focused Swift 6/C fingerprint: `0xbefae53394f56ace`.
- Focused script: `script/test_yoshi.sh`.
- Full matrix: `/tmp/sm64-modern-m20t-final-matrix.log`,
  `MATRIX_RESULT runs=175 failures=0`.
- Native Debug build: `/tmp/sm64-modern-m20t-build.log`,
  `** BUILD SUCCEEDED **`.
- `git diff --check` and zero unchecked-Sendable audit pass.

## Changed surface

- `SM64Modern/YoshiBehavior.swift` contains the value state/input/output
  contract with C action values idle `0`, walk `1`, talk `2`, roof jump `3`,
  finish/despawn `4`, give-present `5`, and credits `10`.
- `tests/sm64_modern_yoshi_smoke.swift` covers the save gate, four-home table,
  canonical yaw approach, interaction/dialog, time-stop cleanup, life cadence,
  roof jump and finish, and ending/credits transition.
- `tests/sm64_modern_yoshi_contract.c` is the independent C fingerprint
  oracle; `script/test_yoshi.sh` is the strict Swift 6/C runner.

## Boundaries

This closes the Yoshi value route only. Object-step collision ownership,
respawner/save mutation, real camera/dialog/audio presentation, remaining NPCs,
puzzles/secrets/rewards, Metal 4 production hardening, and device/visual/
physical/human acceptance gates remain open. No device, visual, controller,
audio, store, notarization, or clean-machine claim is made.

## Next

Add the generation-safe Yoshi owner/effect bridge, including record fields,
dialog/time-stop and sound/camera delivery, respawner/deactivation retirement,
and save/lives side effects. Commit locally without pushing.
