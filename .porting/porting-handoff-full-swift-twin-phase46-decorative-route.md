# Full Swift Twin Handoff — Phase 46 Decorative Pendulum Route Attempt

Date: 2026-08-21

## Result

Phase 46 remains explicitly non-admitted. The real source inputs are present:

- `data/behavior_data.c` contains the canonical `bhvDecorativePendulum[]`
  program and its `bhv_decorative_pendulum_init`/
  `bhv_decorative_pendulum_loop` native callbacks.
- `levels/castle_inside/script.c` places the pendulum in area 2 at
  `(-205, 2611, 7140)`.
- `levels/castle_inside/areas/2/collision.inc.c` and `room.inc.c` provide the
  corresponding collision and room streams.

The focused route recipe was added in
`script/test_decorative_pendulum_route.sh` and
`tests/sm64_modern_decorative_pendulum_route_smoke.swift`. It builds a
source-only content pack, verifies the packed behavior/collision bytes against
the checkout, decodes the real behavior declaration, resolves the real area-2
collision/room stream, and is prepared to capture a bounded Swift owner trace
through the Phase 44 seam. It rejects the hand-built owner fixture and the
default floor as route inputs.

The canonical C/Swift pair was not captured or promoted. The native C route
still has no source-backed Castle Inside area-2 object loader/owner and no
pendulum-specific schema-4 adapter that emits the required
`collision_queries,effects,object_state,script_events` records. The existing C
live-route contract is an input/full generic oracle contract and cannot be
reused as pendulum evidence. Therefore there is no defensible common C/Swift
trace, exact-byte comparison, cross-side replay/tamper result,
worker-result/merge result, or persistent rerun fence for this row.

No promotion tool was invoked, no route report or ledger was mutated, and the
canonical route remains `admission=0`.

## Validation

Passed:

- `bash -n script/test_decorative_pendulum_route.sh`
- `xcrun swiftc -parse -swift-version 6 tests/sm64_modern_decorative_pendulum_route_smoke.swift`
- `git -c core.fsmonitor=false diff --check`

The strict end-to-end route compile/capture was started but intentionally
stopped before completion at the parent agent's bounded no-admission cutoff;
no runtime capture is claimed from that interrupted attempt. Existing Phase
44/45 focused owner and dispatch contracts remain the source-backed seam
evidence.

## Exact unblock

Add a native C owner recipe that loads the Castle Inside area-2 collision and
room streams, instantiates the level-script pendulum object at its canonical
source position, emits the same schema-4 lifecycle/script/floor/effect/object
records, and exposes a status-returning trace sink. Then rerun the new source
recipe for independent C and Swift multi-tick traces before invoking the
existing executor, replay/tamper, worker/merge, and promotion fences.

No commit was created; the parent agent owns review and commit.
