# Full Swift Twin M33b Handoff

## Scope

M33b converts the M33a route inventory into a fail-closed execution seam. The
ledger owns the only legal state transitions, and a bounded schema-4 fixture
runner proves that the C and Swift writers agree on the exact binary trace
contract before live engine routes are attached.

## Implementation

- `SM64Modern/RouteShardExecution.swift` parses the canonical nine-field
  manifest, validates expected domains and planned entry state, and stores
  value-only evidence. It permits only `planned -> running ->
  passed|failed|blocked`; a `passed` result requires non-zero expected records,
  exact actual/matched counts, and no divergence.
- `tools/SM64RouteShardReplayTool.swift` selects one shard by stable ID,
  derives its deterministic input/save seeds, emits fixed schema-4 fixture
  records, and writes a machine-readable report. It labels this lane
  `fixture_only=1` so it cannot be mistaken for live gameplay qualification.
- `tests/sm64_modern_route_shard_replay_contract.c` emits the same little-endian
  schema-4 header and records from C. The focused script compares fourteen
  oracle-hook rows byte-for-byte and runs the ledger transition smoke.

## Validation evidence

- Focused replay smoke: `sample_shards=14`,
  `c_swift_byte_match=1`, `ledger_transition_fence=1`.
- Full matrix: `runs=134 failures=0`,
  `/tmp/sm64-modern-m33b-matrix.log`.
- Clean regenerated native arm64 Debug build succeeds with no project Swift
  warning/error diagnostics, `/tmp/sm64-modern-m33b-clean-build.log`.
- `git diff --check` passes.

## Boundary

This is runner-contract evidence only. The 7,419 rows remain `planned` for
live execution; no gameplay, save, audio, collision, render, sanitizer,
Metal-production, distribution, physical, or human acceptance gate is closed.

## Next slice

M33c should connect one existing live route (the qualified Swift input/Mario/
progression/scheduler path) to the schema-4 C oracle, persist actual
record-by-record first-divergence evidence, and promote only those rows whose
live C-vs-Swift trace and coverage fingerprints match.
