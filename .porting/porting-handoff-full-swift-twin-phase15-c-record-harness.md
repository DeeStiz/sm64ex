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
liveOracleTraceRecords=3151
liveOracleTraceTicks=5
liveOracleTraceDomains=0x00001ff7
liveOracleAudioCallbacks=4
liveOracleRenderRecords=300
liveOracleRenderDraws=288
SM64 Modern live oracle lifecycle smoke passed
```

The trace is independent native-C record evidence, not a fixture. The initial
run exposed a core ordering fault: `render_finish` occurred after the oracle
tick closed. Commit `f5fed499` moves `gfx_end_frame()` inside the open tick;
rendering-enabled C recording now remains status-0.

## Remaining boundary

This phase does not qualify a canonical route shard yet: a matching Swift trace
with the same content/save/timebase/configuration and selected records must be
recorded and compared byte-for-byte. The 7,418 planned shards remain open.
