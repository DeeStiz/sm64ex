# Full Swift Twin Handoff — Phase 85f45 Next Source-Route Discovery

Date: 2026-08-22

## Verdict

**DISCOVERY COMPLETE / RETAINED PLANNED / NO ADMISSION.** The next disjoint
source-owned candidate is the dynamic Wet-Dry World express elevator behavior.
It has a real C behavior callsite, an authored WDW area-1 object lifecycle,
and an existing Swift value/owner route. The proposed receipt can copy scalar
state and the Mario-platform boolean without exporting an object or surface
pointer. This phase changed no source, manifest, cumulative report, route
ledger, shared documentation, or canonical history.

## Retained route boundary

The isolated manifest regenerated from the current source tree remains:

```text
route_manifest_rows=7420
reachability_sha256=fa05f7bd3701c78a0b8a26d48cedc75f0473064a7ba285417ef92602c7cf4644
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
retained_canonical_terminal_passed=25
retained_canonical_planned=7395
retained_canonical_report_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3
behavior_rows=534
swift_value_owner_rows=511
explicit_c_adapter_rows=23
```

The selected generated row is:

```text
0x6e6c6a0fc1b92a45|behavior|bhvWdwExpressElevator|data/behavior_data.c|0x73776902d63209e9|0x4490d0bf72a4dab6|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The adjacent static-platform row is deliberately not selected:

```text
0xd52a32f6de0311da|behavior|bhvWdwExpressElevatorPlatform|data/behavior_data.c|0xd50f815812e49dd6|0x57eea3c39811e29f|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The dynamic and static identities share a Swift owner route but are distinct
source behaviors and distinct manifest rows. A future capture must reject the
static sibling as the wrong candidate rather than use its neighboring object
or coordinates as a substitute.

This candidate is disjoint from the recent DDD camera traversal, BBH nested
display-list, environment-particle, and generic water-query attempts. It is
also separate from the Castle pendulum, HMC elevator, and HMC controllable-
platform route attempts. M33bl established only the local WDW value contract,
dispatch route, and owner wiring; it did not qualify this live 7,420-row
shard.

## Source and authored lifecycle evidence

The source behavior program is `data/behavior_data.c:2557-2565`:

```text
BEGIN(OBJ_LIST_SURFACE)
LOAD_COLLISION_DATA(wdw_seg7_collision_express_elevator_platform)
SET_HOME()
CALL_NATIVE(bhv_wdw_express_elevator_loop)
CALL_NATIVE(load_object_collision_model)
```

The source owner callsite is
`src/game/behaviors/express_elevator.inc.c:3-26`. It owns the action/timer
machine, -20/+10 vertical movement, home clamp, and elevator sound intent.
The only relation that is pointer-backed internally is
`cur_obj_is_mario_on_platform()`; `src/game/object_helpers.c:2361-2366`
reduces `gMarioObject->platform == o` to a boolean. A source receipt may copy
that boolean, but must never publish either pointer.

WDW's authored `script_func_local_1` places the static sibling and dynamic
elevator at `levels/wdw/script.c:40-41`. Area 1 links that object list,
terrain, and normal level lifecycle at `levels/wdw/script.c:95-110`, then
starts `lvl_init_or_update` at lines 125-128. The ordinary authored route into
that area is present in the Castle Inside painting warp nodes at
`levels/castle_inside/script.c:102-104`, each targeting `LEVEL_WDW`, area 1.
This supplies a source-authored level/area recipe without direct level
registration, object injection, or helper invocation.

## Existing C/Swift owner hooks

The existing Swift owner is `WdwExpressElevatorObjectBridge`, backed by
`WdwExpressElevatorBehavior`. The dynamic and static source identities are
kept separate (`elevatorBehaviorIdentity` and
`staticPlatformBehaviorIdentity`), and `BehaviorDispatchBridge` already maps
them to route 66 (`SM64Modern/BehaviorDispatchBridge.swift:70,
1674-1676,6837-6838`). The value reducer accepts the same scalar inputs that
the C loop consumes: action, timer, position/home Y, velocity, and
`marioOnPlatform`.

The current C object snapshot path in
`src/pc/sm64_modern_gameplay_parity.c:1280-1360` is already fixed-width for
object state, position, velocity, and angles. However,
`behavior_identity()` does not yet source-map `bhvWdwExpressElevator`; the
current fallback can expose build-layout-dependent pointer deltas. That is an
implementation blocker to record explicitly, not a reason to normalize the
pointer value in a trace.

## Potential pointer-free receipt seam

The next implementation may add a private source-owned observer at the
`bhv_wdw_express_elevator_loop` boundary, immediately around the existing
source state machine. It should copy, as fixed-width values:

- the semantic source identity for `bhvWdwExpressElevator`, simulation tick,
  owner sequence, level/area, and the existing object subject;
- action and timer before the reducer, position Y, home Y, and velocity Y
  before/after the reducer;
- the scalar result of `cur_obj_is_mario_on_platform()` when the source branch
  evaluates it; and
- the source sound/effect receipt produced by the action-1/action-3 branches.

The observer must leave the C reducer, collision-model load, and sound call
authoritative. It must not call the helper from a probe, retain `o` or
`gMarioObject`, infer ownership from a generic record, or use the adjacent
static-platform row. The C side should add a semantic source-name identity
(or equivalent source-bound event) before any Debug/ASan/Release comparison;
the Swift side must decode copied values and run the existing value reducer,
not spawn an elevator through `spawnWdwExpressElevator`.

## Exact next evidence

1. Add the narrow C source observer and semantic behavior identity in an
   isolated implementation change. Run an ordinary Castle Inside painting to
   WDW area-1 lifecycle with real owner-thread input, and require a positive
   dynamic-elevator receipt. Do not direct-load WDW, register an object, force
   the platform relation, call `cur_obj_is_mario_on_platform`, or synthesize a
   trace record.
2. Build an independent value-only Swift schema-4 mirror for the selected
   row. Bind the authored dynamic object by source identity and lifecycle
   ordering; reject the static-platform identity and any pointer-derived
   behavior value.
3. Require exact C/Swift records and canonical hashes in fresh Debug,
   AddressSanitizer, optimized Release, and a fresh-root rerun. Cover the
   action-0 gate, action-1 descent/sound, action-2 wait, action-3 ascent/home
   clamp, and release/reset path if the authored input reaches them.
4. Require tamper, truncated/partial, single-artifact, wrong-sibling,
   fixture-only, duplicate, and persistent-rerun rejection before any
   isolated admission report. Only a separately authorized serial merge may
   alter the canonical 7,420-row report or ledger.

M34 display/cadence/thermal, M35 signing/notarization/Gatekeeper, physical
feel, and human acceptance remain independent gates.

## Validation performed

Read-only/static and isolated owner checks passed:

```text
isolated reachability/manifest generation: 7420 rows; hashes above
bash script/test_wdw_express_elevator.sh
  wdwExpressElevatorFingerprint=0x87df032d5fc88546
  Swift/C contract matched
source row, WDW area/object, Castle painting-warp, and owner-hook rg/awk checks
```

No native WDW lifecycle probe, source observer, schema-4 pair, sanitizer or
Release route rerun, admission, manifest mutation, canonical merge, staging,
commit, or push was performed. Existing dirty and untracked worktree changes
were preserved.
