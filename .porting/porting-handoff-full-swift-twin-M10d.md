# Porting Handoff — Full Swift Twin M10d

## Scope completed

M10d adds the Swift 6 value-type spatial partition boundary for collision
surfaces. `SM64SurfacePartitionGrid` mirrors the C loader's 16x16 cells,
boundary clamps, 50-unit edge expansion, floor/ceiling priority ordering,
wall insertion order, static versus dynamic storage, and dynamic reset.
Surface references remain IDs so this slice composes with the decoded
`SM64Surface` domain without introducing pointer ownership into Swift.

## Validation

- `script/test_surface_partition.sh`
  - Swift 6 strict-concurrency compile and smoke test passed.
  - C contract fingerprint matched:
    `surfacePartitionFingerprint=0x48925440f517858c`.
- `xcodegen generate --spec project.yml` completed.
- Unsigned macOS Debug build with Xcode completed successfully after project
  regeneration.
- `git diff --check` passed before checkpointing.

## Deliberate boundary

The partition grid is a tested storage and ordering boundary. M10 still needs
query integration against cell-local dynamic/static lists, dynamic object
surface reload/removal semantics, poison-gas and other environment edge
contracts, and production-level collision differential coverage. The local
fingerprint does not claim whole-game collision or visual acceptance.

## Next slice

M11 begins with the object scheduler: preserve the 13 C update-list values,
active-list ordering, spawn/despawn ownership, and per-tick callback boundary
before wiring gameplay behavior breadth.
