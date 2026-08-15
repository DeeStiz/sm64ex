# Full Swift Twin M32k Handoff

## Scope

M32k closes the final Swift 6 unchecked-sendability escape in `EngineHost`.
The host remains an owner-thread facade with a narrow unmanaged bootstrap leaf;
AppKit resize delivery stays in the main-actor view and Metal callbacks remain
owner-thread closures.

## Implementation

- Converted `EngineHost` to a plain final class.
- Changed `Thread` startup to capture only an integer context address and
  recover the host through `Unmanaged` on the newly created engine thread.
- Kept `GameView` drawable-size handlers main-actor-local rather than sending a
  host reference through a `@Sendable` closure.
- Made `MetalRenderer` owner-thread callback parameters ordinary closures;
  `EngineHost` continues to precondition every engine-facing rendering call.
- Removed the unrelated mutable `values` warning in the Swift oracle sidecar.

## Validation evidence

- The regenerated native macOS arm64 Debug build succeeds under Swift 6
  complete strict-concurrency checking with no project Swift concurrency
  diagnostics; log:
  `/tmp/sm64-modern-m32k-build.log`.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32k-matrix.log`.
- `git diff --check` passes.
- `rg -n "@unchecked Sendable" SM64Modern --glob '*.swift'` returns no
  declarations.

M32 is now complete locally as a strict Swift 6 ownership closure. This does
not prove adversarial callback stress, sanitizer qualification, complete Swift
gameplay authority, Metal 4 production qualification, distribution, or human
acceptance.

## Next slice

Start M33 automated full-game qualification: build the route/content inventory,
generate deterministic shards, replay each shard through C and Swift, and
close missing/extra schema-4 records before claiming any whole-game parity.
