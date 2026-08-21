# Full Swift Twin Handoff — Continuation Phase 10 First Live Shard

Date: 2026-08-20

## Completed

- Added `script/test_live_route_shard_batch.sh` and included the live executor
  smoke in `script/build_and_run.sh`.
- Generated the canonical 7,419-row manifest and selected the real
  `oracle_hook|input` shard `0xd9446dfed10e189e`.
- Launched the existing input-only C/Swift oracle, then fed its record trace
  through `SM64RouteShardLiveExecutorTool` and validated the isolated worker
  result with `fixture_only=0`.

## Evidence

```text
manifest_rows=7419
live_rows=1
planned_rows=7418
c_swift_replay=1
isolated_worker_result=1
fixture_only=0
```

The runner rejects missing traces, fixture markers, output reuse, and invalid
worker-result evidence. This is the first real live shard closure; it is not a
claim that the remaining 7,418 rows executed.

## Next phase

Add real route recipes/traces for the remaining domains and batch them through
the same executor/result/merge gates. Keep unavailable hardware or route
recipes explicitly planned/blocked rather than synthesizing passes.
