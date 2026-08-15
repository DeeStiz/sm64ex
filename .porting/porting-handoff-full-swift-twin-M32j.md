# Full Swift Twin M32j Handoff

## Scope

M32j closes the Metal renderer's unchecked-sendability escape. The renderer is
an owner-thread AppKit/Metal object; engine-facing calls are already fenced by
`EngineHost.isCurrentEngineThread`, and the CAMetalDisplayLink callback drops
foreign-thread delivery before touching mutable state.

## Implementation

- Converted `MetalRenderer` to a plain `NSObject`/`CAMetalDisplayLinkDelegate`.
- Retained owner-thread preconditions on every `EngineHost` rendering entry
  point, including initialization, scene recording, texture uploads,
  presentation, status, and shutdown.
- Retained the display-link callback's owner predicate and failure pause path.
- Preserved immutable scene packets, frame-slot completion waits, texture
  residency retirement, Metal 4 barriers, and GPU-drained shutdown.

## Validation evidence

- The regenerated native macOS arm64 Debug build succeeds under Swift 6
  complete strict-concurrency checking; log:
  `/tmp/sm64-modern-m32j-build.log`.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32j-matrix.log`.
- `git diff --check` passes.
- The post-slice audit reports one remaining `@unchecked Sendable` class:
  `EngineHost`.

This is a renderer ownership closure, not proof of callback/GPU stress,
physical display behavior, whole-engine Swift authority, distribution, or
human acceptance.

## Next slice

Audit `EngineHost` last. Split its AppKit/main-queue lifecycle state from the
engine-owner-thread state, replace cross-thread captures with value messages or
explicit locks, and keep C `Unmanaged` callbacks as narrow unsafe leaves. The
M32 Swift 6 safety phase is complete only after that audit and a strict build
show zero unchecked-sendability annotations.
