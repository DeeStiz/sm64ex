# Handoff: SM64 Modern Full Swift Twin — M5a Object Identity and Pool

## What Was Done

M5a establishes the first Swift-owned engine-state substrate without sharing
raw C pointers. `SM64Modern/ObjectPool.swift` mirrors the retained C object
pool's 240-slot default, 13 object-list values, deterministic update order,
ascending initial free list, append-to-list allocation, head-prepend slot reuse,
unimportant-object eviction, deactivation/unload split, and C trace slot+1
identity. `SM64ObjectID` adds a non-zero generation fence so stale references
fail closed after unload or area reset.

Object initialization follows `allocate_object` defaults: active/unknown-8
flags, unimportant flag, self parent, hidden graphics origin, interaction
defaults, distances, room, and an identity transform. The pool is deliberately
not `Sendable`; mutation is reserved for the dedicated engine owner thread and
records are copied as value snapshots for later render/audio boundaries.

## Validation

- `./script/test_object_pool.sh` passed strict Swift 6 smoke coverage and the
  C contract comparison for capacity, list values/order, flags, float-bit
  defaults, slot allocation/reuse, eviction, reset, deactivation, and stale
  reference rejection.
- `xcodegen generate --spec project.yml` passed and included the new Swift
  source in `SM64Modern.xcodeproj`.
- The isolated unsigned macOS 27 arm64 Debug build passed with
  `xcodebuild ... -derivedDataPath /tmp/sm64-modern-m5a ... build`.
- The managed headless environment still cannot provide AppKit launch or
  visual/human acceptance evidence; no such claim is made here.

## Ground Truth Comparison

The C companion includes the real C headers and constants rather than a second
Swift-only fixture. It emits the same contract line as the Swift smoke for
`OBJECT_POOL_CAPACITY`, `NUM_OBJ_LISTS`, `sObjectListUpdateOrder`, active flags,
and the float initialization bits. The Swift lifecycle vectors then exercise
the C allocation topology and explicitly fence pointer-like references.

## What's Deferred

- Add arenas for level/script/geo allocations and deterministic owner-thread
  engine-global state around the object pool.
- Port the full object field union, parent/interaction references, behavior
  stack, respawn metadata, and C-vs-Swift schema-4 actor snapshots.
- Connect pool allocation to the Swift behavior and level VMs; the live app
  still uses the C runtime shell in Swift authority mode.

## Watch For

- Preserve C trace subjects as slot+1 while never using them as Swift handles.
- Do not make the pool `@unchecked Sendable` or expose C object pointers.
- Keep deactivated nodes linked until the ordered unload pass; immediate
  despawn is only for explicit teardown/eviction.
- A full M5 qualification requires arena and whole-engine state differential
  traces, not this bounded pool contract alone.

## Key Decisions Made

- Generation counters are Swift safety metadata and are not serialized into
  schema-4 C slot subjects.
- Pool exhaustion throws a deterministic Swift error instead of reproducing C's
  intentional infinite loop; the eventual full-game route must treat that as a
  hard parity failure.

