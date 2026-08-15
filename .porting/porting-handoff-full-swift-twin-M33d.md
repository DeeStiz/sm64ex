# Full Swift Twin M33d Handoff

## Scope

M33d makes route-shard evidence durable across runner invocations. A report
must cover every manifest row, and restored terminal evidence remains subject
to the same transition and exact-match rules as an in-memory run.

## Implementation

- `SM64RouteShardExecutionLedger` accepts an optional prior report, validates
  every row/ID/count/state, reconstructs terminal evidence, and rejects missing,
  duplicate, invalid, or persisted-running rows.
- `SM64RouteShardReplayTool` loads the report before selecting a shard, so a
  prior `passed` row cannot be rerun or overwritten.
- `script/test_route_shard_replay.sh` uses a fresh temporary build directory,
  executes fourteen C/Swift fixture rows, restores each report, and attempts a
  second-process rerun of the first row.

## Validation evidence

- Ledger smoke: transition fence, partial-pass rejection, and persistent report
  fence all pass.
- Replay smoke: `sample_shards=14 c_swift_byte_match=1
  persistent_rerun_rejected=1 fixture_only=1`.
- Full matrix remains `runs=135 failures=0` after the M33d source change.
- Clean regenerated native arm64 Debug build succeeds without project Swift
  diagnostics, `/tmp/sm64-modern-m33d-clean-build.log`.
- `git diff --check` passes.

## Boundary

This closes report durability, not live route coverage. The 7,419-route
inventory still contains unexecuted gameplay/content rows; save/audio/render
parity, sanitizer qualification, Metal 4 production, distribution, physical,
and human acceptance remain open.

## Next slice

M33e should bind the manifest's expected-domain set to live trace coverage and
promote only rows whose C and Swift records plus coverage fingerprint match.
