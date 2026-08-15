# Full Swift Twin M32h Handoff

## Scope

M32h closes both progression persistence unchecked-sendability escapes. The
legacy bundle and normalized EEPROM adapters are immutable descriptors with
explicit owner checks; external file state is still accessed only from the
engine construction thread.

## Implementation

- Converted `SM64OwnerThreadPersistenceAdapter` and
  `SM64OwnerThreadEEPROMAdapter` to explicit `Sendable` classes.
- Removed retained `FileManager` references; adapters keep only URLs, the
  expected engine token, and a construction pthread identity.
- Added token plus pthread assertions to every commit/load/reload operation,
  including legacy-image recovery and route replay use.
- Preserved atomic writes, checksum recovery, four-slot EEPROM layout, and the
  176-byte legacy-bundle upgrade path.

## Validation evidence

- The regenerated native macOS arm64 Debug build succeeds under Swift 6
  complete strict-concurrency checking; log:
  `/tmp/sm64-modern-m32h-build.log`.
- Full `script/test_*.sh` matrix passes with `runs=132 failures=0`; log:
  `/tmp/sm64-modern-m32h-matrix.log`.
- `git diff --check` passes.
- The post-slice audit reports three remaining `@unchecked Sendable` classes:
  `MetalShaderCompiler`, `MetalRenderer`, and `EngineHost`.

This is a persistence ownership closure, not proof of injected filesystem
failures, renderer/display-link stress, whole-engine Swift authority, Metal 4
production qualification, distribution, or human acceptance.

## Next slice

Audit `MetalShaderCompiler` first. Separate immutable source/configuration from
the asynchronous compilation task and cache handles, then replace its
unchecked annotation with a value-only request/result boundary or explicit
compiler-queue ownership before touching `MetalRenderer` and `EngineHost`.
