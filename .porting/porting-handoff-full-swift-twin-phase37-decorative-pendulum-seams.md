# Full Swift Twin Handoff — Phase 37 Decorative Pendulum Trace Seams

Date: 2026-08-21

## Result

No second route was admitted and no implementation files were changed. The
canonical behavior row remains planned because its expected schema-4 domains
are:

    collision_queries,effects,object_state,script_events

The existing Swift owner path has real object-state and clock-sound effect
behavior, but it has no terrain/collision owner or behavior-script/lifecycle
owner from which the two remaining domains could be emitted. Adding records
with invented floor, surface, command, or lifecycle values would be synthetic
evidence, so this phase leaves the route inadmissible.

## Source boundary

The native C path does contain the missing transitions, but they belong to
engine-wide owners outside the decorative-pendulum Swift pair:

* `src/game/behaviors/decorative_pendulum.inc.c:6-12` calls `bhv_init_room()`.
  In the canonical castle level, `src/game/object_helpers.c:2456-2478`
  performs a real `find_floor()` query and mutates `oRoom`. The query reaches
  the shared collision seam in `src/engine/surface_collision.c:591-666`.
* `src/engine/behavior_script.c:997-1074` emits lifecycle and behavior-command
  events around `cur_obj_update()`. These are behavior-VM boundary records, not
  values produced by `SM64DecorativePendulumBehavior` or its Swift bridge.
* `cur_obj_play_sound_2()` reaches the existing sound effect seam through
  `src/game/spawn_sound.c:81-95` and `src/audio/external.c:786-797`.
  End-of-frame object snapshots are emitted by the shared capture path at
  `src/game/game_init.c:645-667`.

The Swift pair is intentionally narrower. `SM64Modern/DecorativePendulumBehavior.swift`
only reduces roll/angle velocity and reports the clock-sound predicate;
`SM64Modern/DecorativePendulumObjectBridge.swift` owns generation-safe pool
attachment, scheduler mutation, and owner-thread effect delivery. It has no
collision map/probe, floor query, script cursor, behavior VM, lifecycle event
source, or shared schema-4 sink. `attach`'s `room`/`floorHeight` defaults are
object storage state, not the result of an actual Swift collision query.

## Validation

The existing focused source contracts remain the only valid evidence for this
pair and pass without modification:

* `./script/test_decorative_pendulum.sh`
* `./script/test_decorative_pendulum_object_bridge.sh`
* `git diff --check`

These tests prove deterministic C/Swift value and owner-bridge behavior only;
they do not claim schema-4 route coverage. No manifest, route ledger, public
status document, or unrelated dispatch was changed.

## Follow-up

To make this route admissible, the Swift owner must first receive real,
owner-thread collision and behavior-VM/lifecycle boundaries (or the canonical
route recipe must be narrowed by a source-backed contract). Once those values
exist, independent two-tick C/Swift schema-4 traces still require exact
ordering, fixed-width records, complete nonzero coverage, replay/tamper
rejection, worker-result/merge, and persistent-rerun gates before any ledger
promotion.

No commit was created; the parent agent owns review and commit.
