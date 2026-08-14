# Handoff: SM64 Modern Full Swift Twin — M3c Reachability and Save Boundary

## What Was Done

M3c adds a deterministic Swift 6 reachability inventory and the first complete
schema-4 save-byte boundary. The inventory scans the checked-in US source tree
and emits canonical, byte-sorted rows for level scripts, geo/layout sources,
behavior declarations, display lists, audio assets, text sources, save
mutations, render callbacks, collision queries, RNG calls, transitions, and
oracle-hook status. Save mutations, persistence attempts, load completion, and
backup reload now hash the fixed C `SaveBuffer` before platform persistence and
emit schema-4 `save_bytes` records with file index, event identity, byte count,
content fingerprint, and modified flags. The save API remains a C-owned leaf;
Swift receives no mutable save-buffer pointer.

## Validation

- `./script/test_oracle_reachability.sh` passed deterministic regeneration,
  bytewise ordering, minimum source counts, and hook-contract checks.
- `./script/test_oracle_bridge.sh` passed against the rebuilt native archive,
  including Mario state replay, save-byte record shape, same-value replay, and
  independent Mario/save divergences.
- `./script/build_native_core.sh Debug` passed the native archive rebuild and
  timebase, cadence, world, oracle, and live bridge smokes.
- `./script/test_oracle_trace.sh` and `./script/test_oracle_trace_swift.sh`
  remain passing from the prior checkpoint.
- `git diff --check` passed.
- The prior isolated Swift 6/macOS 27 arm64 Xcode build passed. A GUI bounded
  run remains environment-blocked by AppKit registration in the managed
  headless session; no launch, visual, audio, or human acceptance claim is
  made from that attempt.

## Ground Truth Comparison

The save boundary is validated against the real C `SaveBuffer` layout and the
native archive bridge. The inventory is a declared/reachable-source contract,
not a claim that every row has executed in a fresh game. Exact C-vs-C replay
is the current oracle ground truth; Swift authority promotion remains gated.

## What's Deferred

- Full save closure: all boot/recovery and platform-write outcomes must be
  exercised and qualified, including byte-order and backup-repair branches.
- Immutable render packets, script/behavior VM events, collision queries, RNG
  draw streams, audio sequence/channel events, and complete transition hooks.
- Full-inventory execution in a normal GUI session; keep exploratory traces at
  `coverage_fingerprint = 0` until every declared row is emitted or explicitly
  reclassified.
- Swift consumption of schema-4 records and any authority promotion. The
  Swift runtime remains a lifecycle shell until domain migrations qualify.

## Known Issues

- `OracleTraceSession` still uses `@unchecked Sendable` for its serialized
  owner-thread file callback context; M32 must replace or narrowly audit it.
- Save hooks intentionally record post-mutation/pre-persistence bytes. The
  platform EEPROM/text write itself is not treated as a second mutable state.
- `save_file_set_cap_pos` currently records the nested flag mutation and the
  final cap-position state; preserve this order when implementing Swift save
  replay or refine both sides together.

## Watch For

- Never enable exact full coverage until the inventory and runtime emission
  set are reconciled; missing or extra save events must fail closed.
- Preserve schema-3 behavior and call order when schema 4 is inactive.
- Keep trace callbacks on the engine owner thread and do not expose C object or
  save-buffer pointers to Swift.
- Rebuild the normal native archive after sanitizer runs before using a trace
  fingerprint.

## Key Decisions Made

- The inventory is generated from source and is deterministic across repeated
  runs; it is checked in only as code/tooling, not as a generated mutable
  artifact.
- Save events use four stable event IDs: mutation, persist, load, and reload.
- The full-Swift goal remains in progress; this checkpoint does not mark M3
  complete.

## Skills Needed Next

- `porting-methodology`, `porting-start-milestone`, `porting-execute`, and
  `porting-validate`.
- `build-macos-apps:build-run-debug` for the interactive GUI bounded capture
  retry.
- Metal 4 skills when the immutable render-packet seam is wired:
  `translating-metal4-api`, `managing-metal4-resources`,
  `managing-metal4-synchronization`, `presenting-metal-drawables`,
  `using-metal-validation`, `using-gpucapture`, and `using-gpudebug`.
