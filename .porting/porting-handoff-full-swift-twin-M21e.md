# Full Swift Twin Handoff — M21e

## Status

M21e is complete locally as the King Bob-omb return-home trajectory seam.
The owner bridge now performs the source `arc_to_goal_pos` launch setup after
the return-home action enters its flight phase, then advances the copied object
with `cur_obj_move_using_fvel_and_gravity`: canonical yaw toward the stored
home transform, a 49-frame launch for `100/-4`, and no terminal-velocity or
floor clamp in that movement path. The immutable collision world still owns
the preceding floor/wall query.

## Evidence

- Focused strict Swift 6/C home-motion fingerprint:
  `0x1640c0cb197a0aa5`.
- Focused script: `script/test_king_bobomb_home_movement.sh`.
- The Swift owner smoke proves helper parity, arc launch setup through the
  generation-safe bridge, home transform preservation, and the next-frame
  trajectory update. The independent C helper contract matches the Swift
  fingerprint.
- Full matrix after project regeneration:
  `/tmp/sm64-modern-m21e-final-matrix.log`,
  `MATRIX_RESULT runs=181 failures=0`.
- Native Debug build after project regeneration:
  `/tmp/sm64-modern-m21e-build.log`, `** BUILD SUCCEEDED **`.
- `git diff --check` passes; `rg "@unchecked Sendable" SM64Modern --glob
  '*.swift'` reports zero declarations.

## Changed surface

- `SM64Modern/KingBobombHomeMovement.swift` adds value-only launch and step
  counterparts for the source arc helpers.
- `SM64Modern/KingBobombObjectBridge.swift` accepts an explicit home transform,
  publishes the home-arc setup, and applies no-terminal-velocity steps while
  keeping standard collision movement separate.
- `script/test_king_bobomb_home_movement.sh` and its Swift/C fixtures cover the
  helper and owner route; the existing owner/collision contracts remain green.

## Boundaries

This closes only the return-home trajectory. The full boss arena still lacks
camera/cutscene authority, interaction dispatch, reward persistence, and real
audio/dialog/music consumers. Whomp King, Big Boo, Eyerok, Chief Chilly, and
Bowser arenas remain unported. Metal sustained stress and device/visual/human
acceptance remain separate gates.

## Next

Add the King Bob-omb arena camera/cutscene and reward transition owner seam,
then begin Whomp King with value, owner, and collision contracts. Keep the C
oracle independent and preserve separate physical/visual/human acceptance
evidence.
