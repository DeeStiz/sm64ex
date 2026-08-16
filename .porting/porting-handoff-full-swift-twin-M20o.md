# Full Swift Twin Handoff — M20o

## Status

M20o is complete locally as the small-penguin collision/movement owner route.
The bridge now performs the C-order floor/wall prepass before the six-action
value kernel, applies the qualified `cur_obj_move_standard(-78)` scalar route,
publishes floor identity/height/move flags/velocity, preserves the spawn home
position, and disables physics on the held-state transition tick just as the C
`switch (oHeldState)` branch does.

## Evidence

- Focused Swift 6/C owner-bridge fingerprint: `0x28aab1645e2754e8`.
- Focused scripts:
  - `script/test_small_penguin.sh`
  - `script/test_small_penguin_object_bridge.sh`
  - `script/test_small_penguin_movement_bridge.sh`
- Full matrix: `/tmp/sm64-modern-m20o-final-matrix.log`,
  `MATRIX_RESULT runs=170 failures=0`.
- Native Debug build: `/tmp/sm64-modern-m20o-recheck-build.log`,
  `** BUILD SUCCEEDED **`.
- `git diff --check` and the strict Swift 6 unchecked-sendable audit pass.

## Changed surface

- `SM64Modern/SmallPenguinMovement.swift` gives the route explicit collision
  and movement façade names while reusing the qualified scalar implementation.
- `SM64Modern/SmallPenguinObjectBridge.swift` owns the prepass, candidate
  transform, movement result, floor publication, home preservation, and held
  branch fence.
- `tests/sm64_modern_small_penguin_movement_bridge_smoke.swift` and its C
  contract prove four deterministic owner ticks and ground flags.
- `script/test_small_penguin_object_bridge.sh` includes the new strict
  collision/movement dependencies; `project.yml` regeneration includes the
  new source automatically.

## Boundaries

This closes the small-penguin route only. Other reachable trajectories,
effect identity/geo presentation, dialog integration, and the remaining NPC,
puzzle, boss, save, audio, HUD, front-end, renderer, Metal 4 production, and
human acceptance gates remain open. No device, visual, physical controller,
audio, store, notarization, or clean-machine claim is made.

## Next

Continue M20 with the next bounded reachable NPC/puzzle route; retain the
value-kernel → owner-thread bridge → C fixture → full-matrix → native-build
sequence and commit locally without pushing.
