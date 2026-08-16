# Full Swift Twin Handoff — M21c

## Status

M21c is complete locally as the King Bob-omb collision/movement value seam.
The source `king_bobomb_move` prepass is represented without C pointers: a
10-unit wall probe and floor query produce copied surface identity and move
flags, and the qualified standard movement scalar handles edge/steep-slope
admission, gravity, terminal velocity, water boundary, and first-touch
landing transitions.

## Evidence

- Focused strict Swift 6/C collision fingerprint:
  `0x0fae8eeffa0db03b`.
- Focused script: `script/test_king_bobomb_collision.sh`.
- Full matrix after project regeneration:
  `/tmp/sm64-modern-m21c-final-matrix.log`,
  `MATRIX_RESULT runs=179 failures=0`.
- Native Debug build after project regeneration:
  `/tmp/sm64-modern-m21c-build.log`, `** BUILD SUCCEEDED **`.
- `git diff --check` passes; `rg "@unchecked Sendable" SM64Modern --glob
  '*.swift'` reports zero declarations.

## Changed surface

- `SM64Modern/KingBobombCollision.swift` adds copied collision and movement
  inputs/results, wall/floor identity publication, steep-floor admission, and
  the `cur_obj_move_standard(-78)` movement façade.
- `tests/sm64_modern_king_bobomb_collision_smoke.swift` covers wall
  projection, floor identity, wall-facing admission, gravity/ground response,
  speed retention, and landing flags.
- `tests/sm64_modern_king_bobomb_collision_contract.c` independently
  fingerprints the same bounded C semantics.
- `script/test_king_bobomb_collision.sh` compiles the strict Swift 6 and C
  contracts and checks their fingerprint.

## Boundaries

This is a value-only collision/movement proof. The M21b owner bridge still
receives collision facts from explicit environments by default; it does not
yet query the live `SM64SurfaceCollisionWorld` before every King Bob-omb tick.
Arena camera/cutscene ownership, actual C interaction dispatch, reward
persistence, real audio/dialog/music consumers, other bosses, Metal stress,
and device/visual/human acceptance remain open.

## Next

Feed `SM64KingBobombCollision.resolve` and `.move` through the generation-safe
owner bridge in source order (prepass → movement → action), publish floor/wall
fields into `SM64ObjectRecord`, and add an arena camera/cutscene seam before
moving to the next boss family. Keep the independent C contract and separate
physical/visual/human acceptance gates.
