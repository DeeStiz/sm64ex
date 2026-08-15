# Full Swift Twin M31a Handoff

## Scope

M31a hardens the Swift runtime authority seam. `SM64ModernSwiftEngineRuntime`
now owns lifecycle phase transitions and invalid-order rejection while the
remaining gameplay/content domains are still explicitly bridged to the C
compatibility adapter.

## Implementation

- Added `SM64ModernSwiftRuntimePhase` with cold, initialized, stopping, failed,
  and stopped states.
- Swift rejects duplicate initialization, stepping before initialization,
  stepping after a stop request, and shutdown outside an initialized/stopping/
  failed state with the ABI invalid-state status.
- Callback failures fence the runtime in `.failed`; successful shutdown is the
  only path to `.stopped`; the C stop-requested status is accepted as a normal
  transition to `.stopping`.
- Renamed the implementation marker to
  `swift_lifecycle_owner_c_domain_bridge` so logs and qualification reports
  cannot confuse this seam with a complete Swift engine.
- The runtime smoke now builds with Swift 6 and complete strict concurrency
  diagnostics and exercises the full lifecycle state matrix.

## Validation evidence

- `script/test_engine_runtime.sh` passes under `-swift-version 6` and
  `-Xfrontend -strict-concurrency=complete`.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m31a-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m31a-build.log`.
- `git diff --check` passes.

This is a lifecycle/authority seam only. It does not establish Swift-owned
gameplay, save, audio synthesis, display-list translation, Metal content
parity, physical device behavior, distribution, or human acceptance.

## Next slice

Introduce an owner-thread Swift engine context into this runtime, move the live
schema-4 trace and already-qualified progression/input slices behind it, and
make C fallback admission a per-domain readiness decision. Do not remove the C
selector until the end-to-end Swift path can replay the same title-to-gameplay
trace with no C engine callback.
