# Full Swift Twin Handoff — Phase 40 Decorative Pendulum Seams

Date: 2026-08-21

## Result

No implementation files were changed and no second route was admitted. The
decorative-pendulum row still requires the schema-4 domains
`collision_queries,effects,object_state,script_events`; the existing Swift
pair owns only the fixed-point roll/object mutation and the clock-sound
effect. The remaining collision and behavior-script/lifecycle values cannot
be added without crossing a broader owner boundary.

## C authority traced

The source path has real values, but they are produced by shared engine owners:

* `src/game/behaviors/decorative_pendulum.inc.c:6-9` initializes the roll and
  calls `bhv_init_room()`.
* `src/game/object_helpers.c:2456-2479` gates roomed levels, calls
  `find_floor()` at the object's position, optionally calls it again at
  `floorHeight - 100`, and writes `oRoom` from the returned surface.
* `src/engine/surface_collision.c:591-667` owns the floor query and its
  collision trace payload (`x`, `y`, `z`, height, surface type, flags, and
  normal Y).
* `src/engine/behavior_script.c:997-1074` owns the lifecycle and behavior
  command events around `cur_obj_update()`. The held native path at
  `:421-458` has a separate native-behavior event.
* `src/game/game_init.c:645-667` owns the end-of-frame object snapshot
  capture. These events flow through the C parity/oracle sink, not through
  the decorative Swift bridge.

## Swift boundary and why it remains closed

`SM64Modern/DecorativePendulumBehavior.swift:19-39` only accepts roll and
angular velocity and returns the next roll plus the sound predicate. It has
no collision-world, level/room, behavior-program, script-PC, or lifecycle
input.

`SM64Modern/DecorativePendulumObjectBridge.swift:86-105` attaches position,
home position, face roll, initial velocity, and the update-gfx flag. Its
update path at `:124-150` reads/writes those object fields and routes the
clock sound; it does not receive a `SM64SurfaceCollisionWorld`, query a
floor, own a `SM64BehaviorVM`, or publish a behavior/lifecycle trace or
schema-4 snapshot. The pool's attachment defaults (`room = -1` and
`floorHeight = 0`) are storage defaults, not collision results. The default
behavior identity/current-command identity is not a script cursor.

The shared Swift APIs are real but not connected to this owner: the immutable
`SM64SurfaceCollisionWorld.findFloor`/`surface(withID:)` API is available in
`SM64Modern/SurfaceCollision.swift:119-190,296-304`, while
`SM64SwiftEngineState` has no collision-world binding (`EngineState.swift:39-47`);
other movement bridges receive an explicit optional world. Likewise,
`SM64BehaviorVM` has command traces and snapshots (`BehaviorScriptVM.swift:100-180`),
but no decorative-pendulum VM instance or source behavior program is owned by
the bridge. `SM64ObjectSnapshotV4` is a real pool snapshot boundary
(`ObjectSnapshot.swift:15-80`), but the decorative tick does not publish it
to a shared schema-4 sink.

Adding a floor record from the attach defaults, manufacturing command events
from the behavior identity, or hashing a local fixture as a live route would
therefore be synthetic evidence. The minimum legitimate follow-up requires
broader owner plumbing outside this delegation: an owner-thread collision
world/level binding for `bhv_init_room`, a per-object behavior-VM/script-PC
and lifecycle event source, and a shared schema-4 snapshot/trace sink wired
into central dispatch. Those changes belong in engine state/dispatch/oracle
ownership and are intentionally not made here.

## Validation

The unchanged focused source contracts pass:

* `./script/test_decorative_pendulum.sh`
* `./script/test_decorative_pendulum_object_bridge.sh`
* `./script/test_behavior_script.sh`
* `./script/test_behavior_script_content.sh`
* `git diff --check`

These checks prove the existing C/Swift value kernel, owner bridge, and
standalone behavior-VM fixtures only. They do not claim collision or
script/lifecycle schema-4 coverage, route promotion, or full-game parity.

No commit was created; the parent agent owns review and the automatic phase
commit.
