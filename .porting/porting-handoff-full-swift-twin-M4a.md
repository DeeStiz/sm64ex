# Handoff: SM64 Modern Full Swift Twin — M4a Deterministic Primitives

## What Was Done

M4a begins the Swift-owned deterministic primitive layer without changing the
shipping C authority. `DeterministicPrimitives.swift` provides strict Swift 6
counterparts for C's saturating approach helpers, IEEE-754 float-bit conversion,
round-to-s16 behavior, signed 16.16 arithmetic with explicit wrapping, the
legacy 16-bit pseudorandom generator (including float-bit and sign outputs),
the integral paired simulation/legacy timebase policy, and the integer/fixed
animation clock used by the audited cadence model.

The implementation is pure value-type Swift and marks cross-thread-safe scalar
types `Sendable`; it does not expose C pointers, use Foundation timers, or alter
the C compatibility selector. A dedicated Swift 6 smoke and the existing C
oracle bridge use the same RNG vectors, including float bits and sign threshold.

## Validation

- `./script/test_deterministic_primitives.sh` passed with Swift language mode 6
  and complete strict-concurrency checking.
- `./script/test_oracle_bridge.sh` passed the native 25-record schema-4 bridge
  and now asserts the C RNG vector (`0xfa53` first draw, `0x3eaf0e00` float
  bits, positive sign).
- `./script/build_native_core.sh Debug` and the forced full native-core rebuild
  passed the timebase, cadence, world, oracle, and bridge smokes at the prior
  checkpoint.
- `xcodegen generate --spec project.yml` and an isolated unsigned Swift 6 /
  macOS 27 arm64 Debug build passed with the new source included.
- `git diff --check` passed.

## Ground Truth Comparison

The C implementation remains the oracle. The RNG sequence and paired-timebase
state transitions are copied from `behavior_script.c` and
`sm64_modern_timebase.c`, with explicit Swift wrapping where C relies on
32/16-bit arithmetic. The current smoke proves representative vectors, not all
mathematical call sites or the full graph-animation decoder.

## What's Deferred

- Generate and freeze the canonical Swift sine/cosine/arctangent tables from
  `include/trig_tables.inc.c`; validate every indexed angle and `atan2s`
  quadrant against C bit-for-bit.
- Port the full fixed-point/matrix/vector helper surface and the graph/Mario
  animation decoder, then compare route-shard traces across negative angles,
  wraparound, acceleration, no-loop, and paired 60/30 cadence cases.
- Connect these pure primitives to Swift engine state (M5 onward); no Swift
  authority promotion is permitted from this standalone smoke.

## Known Issues

- C's historical overflow behavior is undefined at extreme `approach_s32`
  inputs; Swift uses wrapping arithmetic and needs explicit edge-vector policy
  before those callers are migrated.
- `SM64Fixed16_16` deliberately preconditions finite/in-range float conversion;
  the final content/physics codec must define fail-closed handling for invalid
  asset values.
- The animation clock is the audited integer/16.16 cadence model, not yet the
  full `Animation` attribute-index VM.

## Watch For

- Never substitute platform `sin`, `atan2`, or default rounding for the C
  tables/semantics; store canonical float bits in differential records.
- Keep all paired-boundary decisions in the timebase model; continuous native
  dynamics must not consume legacy RNG or one-shot events on held redraws.
- Add each migrated primitive to a C-vs-Swift vector test before using it from
  gameplay authority code.

## Key Decisions Made

- Deterministic primitives are isolated in value types first, so the Swift
  engine can adopt them domain-by-domain without sharing the C object graph.
- The M4 goal remains in progress; this checkpoint deliberately does not claim
  trig-table or full animation parity.

## Skills Needed Next

- `porting-methodology`, `porting-start-milestone`, `porting-execute`,
  `porting-validate`, and `porting-handoff`.
- `spm-build-analysis`/Swift concurrency review as these value types become
  owner-thread engine state.
