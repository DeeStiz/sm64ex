# Full Swift Twin M31d Handoff

## Scope

M31d moves the qualified controller normalizer into the owner-thread Swift
engine context. Native-step button edges are retained until the logical
boundary and exposed through an immutable receipt; camera/Mario action
composition, haptics, physical devices, and all other unmigrated domains stay
explicit fallback.

## Implementation

- Added `SM64ModernSwiftInputReceipt` and an owner-thread
  `SM64ControllerInputNormalizer` to `SM64ModernSwiftEngineContext`.
- Promoted the input domain in `SM64ModernSwiftEngineDomainReadiness` while
  keeping camera, audio, rendering, frontend, and save persistence fallback.
- Reset the normalizer and last input receipt at level initialization and
  shutdown.
- Extended the strict runtime smoke with retained-edge and logical-boundary
  assertions.

## Validation evidence

- `script/test_engine_runtime.sh` passes under Swift 6 with complete strict
  concurrency diagnostics.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m31d-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m31d-build.log`.
- `git diff --check` passes.

This is an input ownership seam, not full gameplay or whole-engine Swift
authority. Physical controller/haptic behavior, save persistence, visual and
audio parity, distribution, and human acceptance remain open.

## Next slice

Feed the input receipt into one already-qualified Mario input/action route,
connect domain receipts to the live schema-4 owner-thread trace, and keep
fallback admission per-domain until title-to-shutdown runs without an
engine/gameplay C callback.
