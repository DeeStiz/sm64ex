# Full Swift Twin M32i Handoff

## Scope

M32i closes the Metal shader compiler's unchecked-sendability escape. The
compiler keeps its mutable pipeline cache synchronized and confines actual
Metal 4 MSL/pipeline compilation to its dedicated queue.

## Implementation

- Converted `MetalShaderCompiler` to a plain final class.
- Kept cache, pending, and failure state behind the existing `NSLock`.
- Preserved the dedicated compilation queue and synchronized completion path;
  renderer reads only completed pipeline results.
- Preserved Metal 4 archive loading/flushing, descriptor serialization, and
  renderer shutdown behavior.

## Validation evidence

- The regenerated native macOS arm64 Debug build succeeds under Swift 6
  complete strict-concurrency checking; log:
  `/tmp/sm64-modern-m32i-build.log`.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32i-matrix.log`.
- `git diff --check` passes.
- The post-slice audit reports two remaining `@unchecked Sendable` classes:
  `MetalRenderer` and `EngineHost`.

This is a compiler-cache ownership closure, not proof of asynchronous Metal
compiler stress, display-link behavior, GPU validation, whole-engine Swift
authority, distribution, or human acceptance.

## Next slice

Audit `MetalRenderer` as the larger remaining boundary. Separate display-link
callback ownership from engine-thread scene mutation, then replace its blanket
annotation with explicit owner-thread/display-thread contracts and a value
packet handoff before changing `EngineHost`.
