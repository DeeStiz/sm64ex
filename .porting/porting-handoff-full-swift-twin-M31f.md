# Full Swift Twin M31f Handoff

## Scope

M31f enters the first qualified Mario action-selection route. The owner-thread
context consumes the Mario input receipt, runs the idle cancel decision, applies
`setAction`, and emits the decision/mutation receipt. Movement, collision,
effects, complete action dispatch, and physical acceptance remain open.

## Implementation

- Added `SM64ModernSwiftMarioActionReceipt` and owner-thread
  `SM64MarioState` storage to `SM64ModernSwiftEngineContext`.
- Added `resolveIdleAction` using `SM64MarioActionCancels.idle` and
  `SM64MarioState.dropAndSetAction`.
- Promoted the `marioAction` readiness domain and reset action state on level
  initialization and shutdown.
- Extended the strict runtime smoke with the A-to-jump decision and mutation
  assertions.

## Validation evidence

- `script/test_engine_runtime.sh` passes under Swift 6 with complete strict
  concurrency diagnostics.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m31f-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m31f-build.log`.
- `git diff --check` passes.

This is an action-selection seam, not full Mario or whole-engine authority.
Collision, movement, action bodies, save persistence, audio, rendering,
distribution, physical behavior, and human acceptance remain open.

## Next slice

Emit these context receipts into the live schema-4 owner-thread trace and
define one domain-level cutover policy that can replay the same input/action
sequence through C and Swift before promoting additional action bodies.
