# Handoff: SM64 Modern Full Swift Twin — M5 Qualification

## Qualification Result

M5 is complete for its engine-state contract. Swift now owns a bounded,
owner-thread-only object pool and arena/state substrate that does not traverse
the retained C object graph. The pool and arenas reject stale generations and
resource exhaustion; the engine snapshot is immutable value data.

## Evidence

- `./script/test_object_pool.sh` matched C for the 240-slot default, all 13
  object-list values, update order, active/unimportant flags, initialization
  float bits, allocation/reuse, unimportant eviction, deactivation, reset, and
  stale references.
- `./script/test_engine_state.sh` matched C `LEVEL_MIN`, object/effects arena
  capacities, the complete time-stop mask, initial globals, C `AllocOnlyPool`
  four-byte rounding, and C `MemoryPool` first-fit/header/coalescing behavior.
- `./script/test_object_snapshot.sh` matched a C `struct Object` fixture for
  the 20-value actor snapshot (behavior, flags, action/subaction/timer,
  position, velocity, move angles, movement, interaction, held state, object
  flags, forward velocity, and graph flags) plus seven relation slot subjects.
  Actor, relation, and combined FNV fingerprints all match:
  `0xbb4010b8979f4e8d`, `0x28d9376b27c7f2e0`, and `0x2213176ccd4fb828`.
- `xcodegen generate --spec project.yml` and the isolated unsigned Swift 6 /
  macOS 27 arm64 Debug build passed with all M5 sources included.
- The existing primitive, reachability, timebase, and runtime regressions pass.

## Scope Boundary

This closes common engine-state identity and allocation semantics. It does not
claim the object-specific `rawData` union, behavior VM, surface/graph state,
full Mario interaction state, or live Swift authority; those are M6 onward.
AppKit/visual/human, physical-device, distribution, and full-save gates remain
external acceptance evidence.

## Next Milestone

M6 will load every generated content-pack section and resolve segmented/resource
references into Swift-owned immutable data, with C-vs-Swift section hashes and
invalid-reference rejection before level-script execution begins.

