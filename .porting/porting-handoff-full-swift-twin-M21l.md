# Full Swift Twin Handoff — M21l

## Status

M21l is complete locally as a bounded Big Boo owner collision/movement seam.
The value kernel remains the state authority; immutable-world collision and
movement are explicit, opt-in owner-thread inputs.

## Evidence

- Focused command: `script/test_big_boo_object_movement_bridge.sh`
- Swift/C fingerprint: `bigBooObjectMovementBridgeFingerprint=0xeab6afaa926f3d57`
- Contract: source wall-radius projection, floor/wall identity, action-before-
  movement ordering, drag/buoyancy constants, airborne flags, and
  generation-safe record publication.
- Full matrix: `/tmp/sm64-modern-m21l-final-matrix.log`,
  `MATRIX_RESULT runs=188 failures=0`
- Native build: `/tmp/sm64-modern-m21l-build.log`,
  `BUILD SUCCEEDED`
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

This checkpoint does not prove complete collision-mesh coverage, every Big Boo
edge/steep/water trajectory, durable progression/save mutation, real
camera/audio/renderer presentation, physical-device behavior, visual review,
or human acceptance.

## Next

Broaden the shared collision authority and remaining Big Boo trajectories,
then port Eyerok, Chief Chilly, Bowser arenas, and deterministic boss-phase
shards before closing M22 behavior coverage.
