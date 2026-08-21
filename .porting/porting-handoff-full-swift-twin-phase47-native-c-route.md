# Full Swift Twin Handoff — Phase 47 Native Decorative Pendulum C Route

Date: 2026-08-21

## Result

Phase 47 remains explicitly non-admitted. No C trace, C/Swift pairing, replay,
or route-ledger mutation was performed.

The exact bounded loader blocker is ownership, not missing source data:

- `data/behavior_data.c` is one monolithic translation unit. Its
  `bhvDecorativePendulum[]` declaration is a pointer-bearing `BehaviorScript`
  object surrounded by the other behavior declarations; the focused harness
  cannot safely treat the checkout source text as a schema-4 program without
  either compiling/linking that translation unit or introducing a new source
  extraction/relocation adapter.
- A native callback-only compile of
  `src/game/behaviors/decorative_pendulum.inc.c` still owns the legacy global
  `gCurrentObject`. `bhv_decorative_pendulum_init` calls `bhv_init_room`, whose
  real owner is the global level/surface loader (`gCurrLevelNum`, static
  surface partitions/pools, and `find_floor`), and the loop calls the global
  audio/effect owner through `cur_obj_play_sound_2`.
- The real Castle Inside area-2 collision and room streams are included by
  `levels/castle_inside/leveldata.c`; directly loading the two `.inc.c` files
  into a standalone C probe also carries the collision command stream's
  special-object macro/resource dependencies. The existing native-core
  archive supplies these globals only as part of the broad engine build and
  does not expose a pendulum-specific status-returning schema-4 owner sink.

Consequently, a bounded C probe would have to fabricate or override the
legacy floor/audio ownership boundary before it could emit lifecycle, script,
floor, effect, and object records. That would violate the route requirement
that the floor and effects come from the real native owner. The Phase 46 Swift
source recipe therefore remains diagnostic-only, and the canonical row stays
`admission=0`.

## Scope and validation

No Swift/public route files, route ledger, or full-game authority were
changed. No C harness or script was added because the source-loader boundary
above was not safely crossed in this bounded phase.

The handoff itself is the only change; run `git diff --check` before review.

## Exact unblock

Provide a narrow native owner adapter that can (1) retain the compiled
`bhvDecorativePendulum[]` declaration and callback identities without pulling
the monolithic behavior/resource graph, (2) load area-2 collision/room data
through the real level surface owner, and (3) route `bhv_init_room`,
`cur_obj_play_sound_2`, and object state through a status-returning schema-4
sink. Then capture at least two owner ticks and independently compare the C
trace with the Phase 46 Swift trace before any executor or promotion step.

No commit was created; the parent agent owns review and any later admission.
