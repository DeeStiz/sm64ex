# Full Swift Twin Handoff — M21d

## Status

M21d is complete locally as the King Bob-omb owner collision/movement bridge.
The owner tick can receive an immutable `SM64SurfaceCollisionWorld` and runs
the source order for free objects: wall/floor prepass, standard movement, then
the value action kernel. Held/thrown states retain their explicit non-physics
branches. Collision and movement results remain copied values; no C object
pointer crosses the owner boundary.

## Evidence

- Focused strict Swift 6/C owner-collision fingerprint:
  `0xeb8e1c6bee295d67`.
- Focused script:
  `script/test_king_bobomb_object_movement_bridge.sh`.
- The focused script proves floor/wall identity, projected wall position,
  gravity/bounce and landing flags, action-after-movement speed publication,
  record synchronization, and two-frame persistence. Its C contract matches
  the Swift fingerprint.
- Full matrix after project regeneration:
  `/tmp/sm64-modern-m21d-final-matrix.log`,
  `MATRIX_RESULT runs=180 failures=0`.
- Native Debug build after project regeneration:
  `/tmp/sm64-modern-m21d-build.log`, `** BUILD SUCCEEDED **`.
- `git diff --check` passes; `rg "@unchecked Sendable" SM64Modern --glob
  '*.swift'` reports zero declarations.

## Changed surface

- `SM64Modern/KingBobombObjectBridge.swift` now accepts an optional immutable
  collision world and movement flag, executes the prepass/movement/action
  order, publishes collision/movement results, and initializes the source
  physics defaults and position/home fields.
- `script/test_king_bobomb_object_bridge.sh` includes the collision dependencies
  so its strict owner contract remains independently buildable.
- `script/test_king_bobomb_object_movement_bridge.sh` and
  `tests/sm64_modern_king_bobomb_object_movement_bridge_smoke.swift` exercise
  the owner route; the paired C contract fingerprints the same bounded fields.

## Boundaries

This is an opt-in owner-world proof, not a claim that the full game has
switched collision authority. The King Bob-omb home arc path still lacks the
source `arc_to_goal_pos` trajectory in the value kernel. Arena camera/cutscene
state, actual interaction dispatch, reward persistence, real audio/dialog/music
consumers, other bosses, Metal sustained stress, and device/visual/human
acceptance remain open.

## Next

Close the King Bob-omb home trajectory and arena camera/cutscene seam, then
port the next boss family (Whomp King) through value, owner, and collision
contracts. Keep the C oracle contract independent and retain separate
physical/visual/human acceptance gates.
