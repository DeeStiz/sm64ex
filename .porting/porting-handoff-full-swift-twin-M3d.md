# Handoff: SM64 Modern Full Swift Twin — M3d Oracle Domain Seams

## What Was Done

M3d closes the native schema-4 seam inventory that was still deferred at the
save-boundary checkpoint. The retained C engine now emits fail-closed,
owner-thread records for deterministic RNG draws (u16, float, and sign), floor,
ceiling, wall, and environment collision queries, level/behavior VM commands
and lifecycle events, audio tick/sequence/queue/secondary requests, and render
frame/draw/finish packets. Save mutation, persistence, load, and backup reload
remain byte-boundary records over the fixed C `SaveBuffer`. Render draw records
carry canonical vertex and viewport/scissor hashes rather than raw pointers;
audio records stop at the owner-thread sequencing boundary and never enter the
realtime synthesis callback.

The deterministic reachability tool now reports all schema-4 oracle domains as
hooked. It remains a source/inventory contract: a hooked row is not proof that
every declared level, behavior, display-list, audio, text, collision, or save
entry has executed in a normal fresh game.

## Validation

- `./script/test_oracle_reachability.sh` passed deterministic regeneration,
  bytewise ordering, minimum source counts, and all 14 oracle-hook contract
  rows, including render packets and audio sequencing.
- `./script/test_oracle_bridge.sh` passed a rebuilt native bridge trace with 25
  ordered records: Mario, save bytes, five RNG events, five collision events,
  five script events, four audio events, and four render events. Same-value
  replay and independent Mario/save divergences remain covered.
- `./script/build_native_core.sh Debug` passed the native archive and timebase,
  cadence, world, oracle, and bridge smokes.
- `./script/test_timebase_audit.sh` passed after recording the three intentional
  `oTimer` reads used only to serialize script lifecycle/command telemetry.
- `git diff --check` passed.
- The prior isolated Swift 6/macOS 27 arm64 Xcode build passed. A GUI bounded
  run remains environment-blocked by AppKit registration in the managed
  headless session; no launch, visual, audio, or human acceptance claim is
  made from that attempt.

## Ground Truth Comparison

The C archive is still the exact behavioral oracle. New records are emitted at
semantic boundaries using fixed-width integer values and stable event IDs;
pointer identity and host addresses are deliberately excluded. The bridge
proves C record/replay ordering and divergence detection, but it is not yet a
full-game reference trace.

## What's Deferred

- File-backed record/replay from a normal GUI session, with a non-zero coverage
  fingerprint after every inventory row is executed or explicitly reclassified.
- Full save closure across boot, checksum validation, atomic replacement,
  backup repair, invalid-slot recovery, and C↔Swift byte-identical round trips.
- Render packet aggregation and Metal-side packet comparison for every display
  list; the current hook records per-draw canonical hashes plus frame markers.
- Swift consumption of schema-4 records, domain migrations, and any authority
  promotion. Swift remains a lifecycle shell until each migrated domain passes
  C differential tests.

## Known Issues

- `OracleTraceSession` still uses `@unchecked Sendable` for the serialized
  owner-thread file callback context; M32 must replace or narrowly audit it.
- `save_file_set_cap_pos` intentionally records nested flag mutation followed by
  final cap state; preserve this order when implementing Swift save replay.
- Audio hooks describe owner-thread requests and queue state, not realtime PCM;
  synthesis remains M28 scope.
- A draw packet currently carries a vertex hash and state hashes, not an
  immutable retained packet object; M29 must define the Swift packet schema and
  compare aggregate ordering before Metal authority switches.

## Watch For

- Keep `SM64_MODERN_ORACLE_REQUIRE_FULL_COVERAGE=1` off for exploratory traces;
  missing or extra inventory records must fail closed during qualification.
- Preserve schema-3 behavior and call order when schema 4 is inactive.
- Keep callbacks on the engine owner thread and never expose C object, surface,
  audio-buffer, or save-buffer pointers to Swift.
- Rebuild the normal native archive after sanitizer runs before using a trace
  fingerprint.

## Key Decisions Made

- All remaining M3 native seams use explicit event IDs and domain-specific
  functions instead of one raw-pointer callback.
- Collision values serialize IEEE-754 float bits; render values serialize
  canonical hashes; audio is captured before device delivery.
- The full-Swift goal remains in progress; this checkpoint does not mark M3
  complete.

## Skills Needed Next

- `porting-methodology`, `porting-start-milestone`, `porting-execute`,
  `porting-validate`, and `porting-handoff`.
- `build-macos-apps:build-run-debug` for the interactive GUI bounded capture
  retry.
- `translating-to-metal4-api`, `managing-metal4-resources`,
  `managing-metal4-synchronization`, `presenting-metal-drawables`,
  `using-metal-validation`, `using-gpucapture`, and `using-gpudebug` when the
  Swift render packet and Metal 4 path becomes active.
