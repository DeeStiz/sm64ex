# Handoff: SM64 Modern Full Swift Twin — M4b Canonical Trigonometry

## What Was Done

M4b removes the platform-libm gap from the Swift primitive layer. A checked-in
Perl generator reads the retained US `include/trig_tables.inc.c` source and
produces `SM64Modern/GeneratedTrigTables.swift` with the 0x400 sine prefix,
0x1000 cosine table, and 0x401 arctangent table. Swift preserves the C
`AVOID_UB` contiguous sine indexing contract (`sinePrefix + cosine`) and exposes
table-backed `sins`, `coss`, `atan2s`, and `atan2f` functions with the same
quadrant branches and unsigned 16-bit wrap behavior.

The deterministic smoke checks table sizes, cardinal angles, all four `atan2s`
axes, a diagonal, and the generated-file drift contract. It also computes an
FNV fingerprint over every Swift table bit pattern. A C companion compiled
against the original table source computes the same fingerprint, so a green
test proves the generated Float/Int16 data matches the C source across the full
table rather than only at sampled angles.

## Validation

- `./script/generate_swift_trig_tables.sh include/trig_tables.inc.c
  SM64Modern/GeneratedTrigTables.swift` completed and
  `./script/test_swift_trig_tables.sh` passed regeneration/drift checking.
- `./script/test_deterministic_primitives.sh` passed Swift 6 strict
  concurrency, scalar/RNG/timebase/animation vectors, table/quadrant tests, and
  the Swift/C fingerprint comparison (`0xad313c4e4c2c495e`).
- `xcodegen generate --spec project.yml` and the isolated unsigned Swift 6 /
  macOS 27 arm64 Debug build passed with the generated table source included.
- `git diff --check` passed for the current checkpoint.

## Ground Truth Comparison

The C table source remains the authority. The Swift fingerprint iterates the
same contiguous 0x1400 sine storage, the separate 0x1000 cosine view, and all
0x401 arctangent entries using little-endian FNV byte order. This validates
data parity; the full gameplay call-site migration is still later M4/M5 scope.

## What's Deferred

- Port matrix/vector helpers and `Animation` attribute-index decoding, including
  no-loop, reverse, acceleration, translation, and negative-coordinate cases.
- Add route-shard C-vs-Swift primitive traces at every migrated gameplay call
  site; the current smoke is scalar/table-level evidence only.
- Connect `SM64CanonicalTrig` to Swift-owned engine state after M5 pools and M6
  content loading are complete. Do not promote Swift authority from this table
  test alone.

## Known Issues

- The generated file is intentionally checked in so a clean checkout builds
  without a generator step; `test_swift_trig_tables.sh` must remain in the
  pre-commit validation contract to prevent source drift.
- C's `atan2s` assumes the lookup ratio remains within [0, 1] at each branch;
  Swift retains a precondition for an out-of-contract table index.

## Watch For

- Never replace these tables with `sin`, `cos`, or `atan2` from platform libm.
- Preserve the 16-bit angle truncation before shifting by four and the C
  unsigned wrap in the negative `atan2s` quadrant.
- Keep the table fingerprint in the C-vs-Swift primitive smoke when changing
  generation format or source data.

## Key Decisions Made

- Trigonometry is generated from the existing legal US source data rather than
  re-derived numerically, preserving exact Float bits and the C contiguous-table
  layout.
- M4 remains in progress until matrices, vectors, and the complete animation
  VM have differential coverage.

## Skills Needed Next

- `porting-methodology`, `porting-start-milestone`, `porting-execute`,
  `porting-validate`, and `porting-handoff`.
- `spm-build-analysis`/Swift concurrency review as primitive values enter
  owner-thread engine state.
