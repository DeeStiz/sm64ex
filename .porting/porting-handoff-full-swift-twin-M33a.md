# Full Swift Twin M33a Handoff

## Scope

M33a establishes the deterministic route-shard inventory contract for full-game
qualification. It turns every row in the canonical reachability inventory into
one stable, independently seedable shard without claiming that the shard has
been replayed or that parity is complete.

## Implementation

- Added `tools/SM64RouteShardManifestTool.swift`, compiled with Swift 6
  complete strict-concurrency checking.
- Added `script/test_route_shards.sh`, which regenerates the reachability input
  and route manifest twice, compares bytes, checks canonical ordering, validates
  schema/ID uniqueness, and requires every tracked domain.
- Generated 7,419 planned shards with stable FNV-1a IDs, input seeds, save
  seeds, expected schema-4 trace domains, and explicit `planned` status.
- Kept execution state intentionally separate from inventory declaration; no
  shard is marked executed until the M33b C-vs-Swift replay runner produces
  complete records.

## Validation evidence

- Route-shard smoke passes with `inventory=7419 shards=7419`.
- Full `script/test_*.sh` matrix passes with `runs=133 failures=0`; log:
  `/tmp/sm64-modern-m33a-final-matrix.log`.
- Clean regenerated native macOS arm64 Debug build succeeds without project
  Swift concurrency diagnostics; log:
  `/tmp/sm64-modern-m33a-clean-build.log`.
- `git diff --check` passes.

This is an inventory contract only. M33 remains open for shard execution,
schema-4 C-vs-Swift byte comparison, first-divergence diagnostics, sanitizer
reruns, and the zero-unexecuted-reachable-ID gate.

## Next slice

Implement M33b's replay runner: consume one manifest shard, derive a fixed input
and initial-save fixture, run the C compatibility path and Swift authority path
for bounded ticks, compare schema-4 records by domain/tick/ID, and persist a
machine-readable `planned|passed|failed|blocked` result without allowing
unexecuted or missing rows to disappear.
