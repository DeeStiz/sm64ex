# Full Swift Twin Handoff — M21i

## Status

M21i is complete locally as a bounded Whomp owner collision/movement seam.
The owner route consumes an immutable surface world only when explicitly
enabled; the historical value and presentation gates remain unchanged by
default.

## Evidence

- Focused command: `script/test_whomp_object_movement_bridge.sh`
- Swift/C fingerprint: `whompObjectMovementBridgeFingerprint=0xf5bc6ef25b45cfac`
- Contract: source-order floor/wall prepass, Whomp action, and
  `cur_obj_move_standard(-20)` movement with source physics constants; copied
  wall/floor identity and landing/ground flags reach the owner record.
- Regression commands: `script/test_whomp_object_bridge.sh`,
  `script/test_whomp_boss_owner.sh`
- Full matrix: `/tmp/sm64-modern-m21i-final-matrix.log`,
  `MATRIX_RESULT runs=185 failures=0`
- Native build: `/tmp/sm64-modern-m21i-build.log`,
  `BUILD SUCCEEDED`
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

This checkpoint does not prove complete collision-mesh/content coverage,
durable progression/save mutation, real camera/cutscene consumption, audio
playback, renderer presentation, physical-device behavior, visual review, or
human acceptance.

## Next

Finish the shared collision authority inventory and progression/save owner,
then continue Big Boo, Eyerok, Chief Chilly, Bowser arena, and deterministic
boss-phase coverage.
