# Handoff: SM64 Modern Full Swift Twin — M5b Arenas and Engine State

## What Was Done

M5b adds deterministic Swift memory and global-state boundaries around the M5a
object pool. `SM64LinearArena` models the retained C `AllocOnlyPool`: four-byte
rounding, bounded allocation, owner-thread marks/rewind, and generation-fenced
allocations. `SM64FreeListArena` models the 64-bit macOS `MemoryPool`: first-fit
allocation, 16-byte `MemoryBlock` overhead, four-byte payload rounding,
arbitrary-order free, adjacent coalescing, and reset generations.

`SM64EngineArenas` gives level, object, and effects domains with the C defaults
(1 MiB level staging, `0x800` object memory, and `0x4000` effects memory). The
new `SM64SwiftEngineState` owns the object pool and arenas on the engine thread
and exposes only `SM64EngineStateSnapshot` value data for later trace,
renderer, and audio boundaries. It carries level/area/course/act, time-stop
flags, object counters, Mario/current-object IDs, frame, and reset epoch, with
explicit level/area/reset/frame transitions.

## Validation

- `./script/test_engine_state.sh` passed strict Swift 6 allocator/state vectors
  and the C header contract for `LEVEL_MIN`, arena capacities, time-stop mask,
  and initial globals.
- `./script/test_object_pool.sh` passed unchanged after this slice.
- `xcodegen generate --spec project.yml` and the isolated unsigned macOS 27
  arm64 Debug build passed with the new sources included.
- Existing deterministic primitive, oracle reachability, timebase, and runtime
  smokes passed in the M5a regression set.
- AppKit launch, visual capture, physical-device, and human acceptance remain
  unavailable in the managed headless environment and are not claimed.

## Ground Truth Comparison

The C companion includes `game/memory.h`, `game/object_list_processor.h`, and
`level_table.h` rather than duplicating those constants in a Swift-only test.
The Swift arena vectors additionally exercise C's alignment, header-overhead,
first-fit, small-remainder, free, coalesce, and reset behavior using logical
offsets so no raw pointer crosses the Swift boundary.

## What's Deferred

- Port the full `struct Object` field union, collision/interaction references,
  behavior stack, respawn metadata, surfaces, and graph-node arenas.
- Add schema-4 actor/object snapshots and C-vs-Swift route traces over real
  level transitions; current snapshots are local value-boundary evidence only.
- Wire these state boundaries into the Swift level/behavior VMs; Swift authority
  still uses the C runtime shell until those migrations are complete.

## Watch For

- Keep the 16-byte free-list header tied to the 64-bit macOS target; do not
  silently use 32-bit assumptions in the native product.
- Preserve C's four-byte allocation rounding and first-fit/coalescing order.
- Generation and reset-epoch metadata are Swift safety fences, not C trace
  subjects or serialized save bytes.
- Do not add `@unchecked Sendable` to the mutable state container; snapshots
  are the only cross-thread contract.

## Key Decisions Made

- The Swift `reset()` is a full engine-state reset and increments an epoch;
  `beginArea` is a lighter transition that keeps objects but clears area-owned
  time-stop/current-object latches.
- Pool exhaustion and arena exhaustion fail closed with typed errors instead of
  reproducing C's hangs or null-pointer continuation.

