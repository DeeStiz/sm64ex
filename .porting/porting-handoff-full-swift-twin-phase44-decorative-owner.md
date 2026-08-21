# Full Swift Twin Handoff — Phase 44 Decorative Pendulum Owner Seam

Date: 2026-08-21

## Result

Phase 44 adds a bounded, source-backed owner seam for
`bhvDecorativePendulum`. `SM64DecorativePendulumObjectBridge` can now bind an
immutable `SM64SurfaceCollisionWorld`, attach a decoded
`SM64BehaviorScriptProgram` to a generation-safe object ID, and publish the
real floor, lifecycle, behavior-command, sound-effect, and actor-state values
through a fixed-width schema-4 record sink. No floor, script, or lifecycle
record is inferred from `room`, `floorHeight`, or behavior identity defaults.

The bridge runs the attached VM only when the caller supplies the decoded
program. The first source-backed owner tick emits lifecycle, performs the
real floor query used by `bhv_init_room` (including room fallback behavior),
then preserves the native effect-before-command ordering and emits the 14
actor-state records in C field order. Records carry the live object's
one-based trace subject only after generation-checked pool lookup.

`EngineState.swift` was not changed: the immutable collision world is an
explicit owner-thread binding on the decorative bridge, avoiding a broader
state/ABI change.

## Central boundary retained

The shared `BehaviorDispatchBridge` and `SM64ModernSwiftEngineContext` still
construct and invoke this bridge without a decoded decorative behavior
program, collision-world binding, or schema-4 adapter. This delegation did
not change that central dispatch plumbing, C/ABI headers, global state,
public docs, or the route ledger. Consequently this handoff proves the
owner seam and its strict contract, but does not claim that the live central
dispatch path now produces the complete decorative-pendulum route. A later
central owner must pass the real level collision world, decoded behavior
program/native callback source, and existing status-returning schema-4 sink
adapter into this seam before route admission.

## Files

- `SM64Modern/DecorativePendulumObjectBridge.swift`
- `script/test_decorative_pendulum_object_bridge.sh` (strict source list)
- `script/test_behavior_dispatch_bridge.sh` (strict source list)
- `script/test_engine_runtime.sh` (strict source list)
- `script/test_live_route_oracle.sh` (strict source list)
- `script/test_decorative_pendulum_owner.sh`
- `tests/sm64_modern_decorative_pendulum_owner_smoke.swift`
- `tests/sm64_modern_decorative_pendulum_owner_contract.c`

## Validation

Passed:

- `./script/test_decorative_pendulum_object_bridge.sh`
  - `decorativePendulumObjectBridgeFingerprint=0xb45d1c83aa454dc3`
  - Swift/C object bridge contract matched.
- `bash script/test_decorative_pendulum_owner.sh`
  - `decorativePendulumOwnerFingerprint=0x96257c7747b29c14`
  - `decorativePendulumOwnerSchemaFingerprint=0x7bc7399e456c19b5`
  - strict Swift 6 owner/VM/collision compile and C11 schema contract passed.
- `git diff --check`

The broad `test_engine_runtime.sh` compile was not used as acceptance evidence
and was not rerun after the focused owner contract passed. No commit was
created; the parent agent owns review and commit.
