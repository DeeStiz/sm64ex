# Full Swift Twin Handoff — M21o

## Status

M21o is complete locally as a bounded Eyerok boss/hand owner bridge. The
source-model hand children are created under a generation-safe boss record in
live scheduler order; hand ticks feed parent counters back to the boss; and
records preserve transforms, hitbox identity, action, health, animation, and
timing fields.

## Evidence

- Focused command: `script/test_eyerok_object_bridge.sh`
- Swift/C owner fingerprint: `eyerokObjectBridgeFingerprint=0xcc5a9ee16597604f`
- Contract: boss hand spawning, parent generation/list identity, source hand
  models, hitbox admission, open-to-eye action synchronization, lethal attack
  parent counter decrement, and shared sound presentation delivery.
- Full matrix: `/tmp/sm64-modern-m21o-final-matrix.log`,
  `MATRIX_RESULT runs=191 failures=0`
- Native build: `/tmp/sm64-modern-m21o-build.log`,
  `BUILD SUCCEEDED`
- `git diff --check` passes.
- `rg -l '@unchecked Sendable' SM64Modern --glob '*.swift' | wc -l` reports 0.

## Boundaries

This checkpoint does not prove immutable-world floor/wall collision movement,
real camera/audio/dialog/renderer consumers, durable reward progression/save
mutation, Chief Chilly or Bowser breadth, physical-device behavior, visual
review, or human acceptance.

## Next

Add Eyerok's source floor/wall prepass and `cur_obj_move_standard(-78)` owner
movement behind an explicit immutable-world gate, then continue Chief Chilly
and Bowser arena breadth before the M22 reachability closure.
