# Full Swift Twin M31b Handoff

## Scope

M31b adds a real owner-thread Swift engine context to the lifecycle-authority
runtime. The context owns migrated Swift state, object-pool and scheduler
advancement, immutable tick receipts, and reset/shutdown cleanup while the C
compatibility adapter remains the fallback for unmigrated gameplay/content.

## Implementation

- Added `SM64ModernSwiftEngineContext`, which owns
  `SM64SwiftEngineState` and `SM64ObjectScheduler` and exposes only owner-thread
  lifecycle operations.
- Added `SM64ModernSwiftEngineTickReceipt` for immutable tick/frame/object/reset
  evidence from the Swift scheduler.
- Wired initialize, step, stop, failure, and shutdown through the context in
  `SM64ModernSwiftEngineRuntime`; the implementation marker remains
  `swift_lifecycle_owner_c_domain_bridge`.
- Extended the strict runtime smoke to compile the state/scheduler dependency
  chain, spawn a Swift actor, assert the first receipt, and verify object reset
  after shutdown.

## Validation evidence

- `script/test_engine_runtime.sh` passes under Swift 6 with complete strict
  concurrency diagnostics.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m31b2-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m31b-build.log`.
- `git diff --check` passes.

This is a context seam, not whole-engine Swift authority. C still owns
unmigrated gameplay/content, and no claim is made for full parity, visible
Metal output, physical input/audio, distribution, or human acceptance.

## Next slice

Define per-domain readiness and move one already-qualified gameplay/progression
route behind the Swift context with the same schema-4 trace and owner-thread
delivery contract. Keep C fallback admission explicit until the full
title-to-gameplay/save/audio/render trace is consumed by Swift without an
engine/gameplay C callback.
