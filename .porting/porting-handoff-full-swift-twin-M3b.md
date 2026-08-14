# Handoff: SM64 Modern Full Swift Twin — M3b Live Oracle Bridge

## What Was Done

M3's schema-4 oracle now crosses the real C gameplay parity seams. An oracle-only session can begin/end on the existing engine owner thread, advance a fixed simulation tick, mirror normalized input, global/Mario/interaction/camera/object snapshots, deterministic effects, and pre-device PCM checksums, and stop after a bounded tick count from Swift. The existing schema-3 parity session remains independent and can run alongside schema 4. The Swift file-backed session writes and reads the same fixed-width C header/records, fingerprints the executable/content/save/timebase/configuration, rejects configuration or record divergence, and closes the trace before C runtime shutdown. A native-core bridge smoke exercises this path against the real archive and proves a same-value replay and a value divergence. Live coverage records are marked at the observed C seam; a zero expected coverage fingerprint explicitly defers whole-inventory reachability closure until qualification.

## Validation

- `./script/test_oracle_trace.sh` passed the standalone C codec, deterministic C-vs-C trace, value/hash/coverage divergence, and deferred-coverage policy checks.
- `./script/test_oracle_trace_swift.sh` passed Swift fixed-width codec round trip, tamper rejection, and decoding of a raw C-produced trace.
- `./script/test_oracle_bridge.sh` passed the bridge against the native `libsm64core.a`, including record/replay and a deliberate value divergence.
- `xcodegen generate --spec project.yml` and an isolated unsigned Swift 6/macOS 27 arm64 Debug build passed (`** BUILD SUCCEEDED **`). The build includes `OracleTraceSession.swift` and the private timebase header import.
- `git diff --check` passed.
- The direct app bounded-run attempt was not accepted as runtime evidence: this managed/headless session aborts in AppKit `RegisterApplication` before the engine starts, and `/usr/bin/open` reports LaunchServices `kLSNoExecutableErr` for the unsigned Debug bundle. No gameplay or visual claim is made from that attempt.

## Ground Truth Comparison

This is a non-rendering trace/lifecycle slice. No external GPU, pixel, audio, or gameplay reference artifact was available or required. The C archive bridge and fixed-width C/Swift file codec are the applicable interop ground truth.

## What's Deferred

- Full file-backed app record/replay on a real GUI session; retry on a normal interactive macOS login or with a user-provided crash/log capture.
- Save-byte boundaries, render-packet records, script/behavior VM events, collision queries, RNG draw streams, audio sequencing, and complete title-to-gameplay transition hooks.
- Whole-engine coverage closure across every US level, behavior, audio sequence, display-list command, save mutation, and effect. `SM64_MODERN_ORACLE_REQUIRE_FULL_COVERAGE=1` is qualification-only and must remain off for bounded exploratory capture until the inventory is reachable.
- Swift consumption of schema-4 records and any authority promotion. The Swift runtime remains a lifecycle shell until M31 domain migrations qualify.

## Known Issues

- `OracleTraceSession` uses `@unchecked Sendable` because the owner-thread `FileHandle`/C callback context is intentionally serialized; M32 must replace or narrowly audit this boundary.
- The raw C inventory is a declared deterministic seed, not proof of reachability. An unknown observed record ID fails closed at the C seam.
- AppKit/LaunchServices runtime verification is environment-blocked here; build and native-core evidence remain valid but do not prove launch, visual output, feel, or human acceptance.

## Watch For

- Do not turn on full coverage for a trace until every declared entry is emitted or intentionally reclassified.
- Keep schema-3 parity record order and behavior unchanged when schema 4 is inactive.
- Keep all trace callbacks on the engine owner thread; never enter the AVAudioEngine render callback or expose C object pointers to Swift.
- Rebuild the normal native archive after any sanitizer run before using a trace fingerprint.
- Do not promote a Swift authority slice from an oracle trace alone; it needs the existing schema-3 candidate/finalization gate plus schema-4 domain closure.

## Key Decisions Made

- The live exploratory session uses `coverage_fingerprint = 0` to defer whole-inventory closure; non-zero fingerprints retain exact fail-closed coverage checks.
- Coverage is marked before each mirrored record, so an un-inventoried C field/effect fails immediately instead of silently producing an unqualified trace.
- The C compatibility selector remains permanent, and the current full-Swift goal remains in progress; this checkpoint does not mark M3 complete.

## Skills Needed Next

- `porting-methodology`, `porting-start-milestone`, `porting-execute`, and `porting-validate`.
- `spm-build-analysis`/Swift concurrency review when replacing the owner-thread session wrapper.
- `build-macos-apps:build-run-debug` for the interactive GUI bounded record/replay retry.
- Metal 4 skills only when render-packet capture is wired: `translating-metal4-api`, `managing-metal4-resources`, `managing-metal4-synchronization`, `presenting-metal-drawables`, `using-metal-validation`, `using-gpucapture`, and `using-gpudebug`.
