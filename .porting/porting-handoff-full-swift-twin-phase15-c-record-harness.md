# Full Swift Twin Handoff — Phase 15 Independent C Record Harness

Date: 2026-08-20

## Completed

- Added `tests/sm64_modern_oracle_lifecycle_record.c` and
  `script/test_oracle_lifecycle_record.sh`.
- The harness installs native C platform/input/audio/rendering callbacks,
  opens schema-4 record mode with file callbacks, opens an initialization tick
  before lifecycle initialization, closes it, then runs four real C lifecycle
  steps and shutdown.
- It rereads the serialized file and validates record headers, canonical hashes,
  per-domain sequence/tick ordering, coverage, and lifecycle callback counts.

## Evidence

```text
liveOracleTraceRecords=2839
liveOracleTraceTicks=5
liveOracleTraceDomains=0x000017f7
liveOracleAudioCallbacks=4
liveOracleRenderDraws=0
SM64 Modern live oracle lifecycle smoke passed
```

The trace is independent native-C record evidence, not a fixture. The current
platform capability intentionally disables C rendering frame dispatch because
the core emits `render_finish` after closing the oracle tick; that unresolved
ordering still returns status 4 if rendering is enabled.

## Remaining boundary

This phase does not qualify a canonical route shard yet: a matching Swift trace
with the same content/save/timebase/configuration and selected records must be
recorded and compared byte-for-byte. The 7,418 planned shards remain open.
