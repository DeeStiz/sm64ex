# Full Swift Twin Handoff — Phase 45 Decorative Pendulum Central Dispatch

Date: 2026-08-21

## Result

Phase 45 wires the Phase 44 decorative-pendulum owner seam through the shared
owner-thread behavior dispatcher. `SM64BehaviorDispatchBridge` now exposes an
explicit configuration containing the immutable collision world, decoded
behavior program/target resolver/native callback source, and a status-returning
schema-4 sink. Configured pendulum spawns attach that source; dispatch passes
the scheduler's live simulation frame and configured collision world into each
owner update. Sink failures are surfaced as
`decorativePendulumTraceStatus` and fail the Swift engine-context step.

No configuration still means identity-only behavior: the existing default
pendulum route advances its value kernel but emits no script, collision, effect,
or lifecycle trace records. No content, collision world, program, or callback
was fabricated by the runtime path.

## Central route evidence

Yes, the focused central-dispatch smoke is now source-backed when the explicit
owner configuration is installed: it observes lifecycle/script, real floor,
clock-effect, and object-state records at the scheduler simulation tick, and
verifies the status-returning sink. The unconfigured identity-only route
remains trace-silent. This is bounded route evidence, not a claim that a live
level loader currently supplies the real collision/program content or that the
whole game is Swift-authoritative.

## Files

- `SM64Modern/BehaviorDispatchBridge.swift`
- `SM64Modern/EngineRuntime.swift`
- `tests/sm64_modern_behavior_dispatch_bridge_smoke.swift`
- `tests/sm64_modern_engine_runtime_smoke.swift`
- `.porting/porting-handoff-full-swift-twin-phase45-decorative-dispatch.md`

## Validation

Passed:

- `./script/test_behavior_dispatch_bridge.sh`
- `./script/test_engine_runtime.sh`
- `bash script/test_decorative_pendulum_owner.sh`
- `git diff --check`

The live-route oracle was not rerun in this bounded handoff; its existing
strict source list already contains the decorative owner, central dispatch,
surface-collision, and engine-runtime files. Whole live-level content loading
remains outside this phase.

No commit was created; the parent agent owns review and commit.
