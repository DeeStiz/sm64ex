# Full Swift Twin M33e Handoff

## Scope

M33e adds the expected-domain coverage gate. A route shard can no longer be
marked passed solely because its aggregate record counts agree; the emitted
schema-4 domain/kind pairs must cover the manifest expectation exactly.

## Implementation

- `SM64RouteShardFixture.coverage(for:records:)` computes expected and observed
  `(domain, record_kind)` keys, missing expected domain names, unexpected keys,
  and record-count equality.
- `SM64RouteShardReplayTool` runs this gate before writing a `passed` report.
- The ledger smoke supplies an empty trace and proves the expected input domain
  is reported missing; the fourteen fixture rows still pass with exact keys.

## Validation evidence

- Focused replay: `coverage_missing_rejected=1`,
  `sample_shards=14 c_swift_byte_match=1`.
- Full matrix: `runs=135 failures=0`,
  `/tmp/sm64-modern-m33e-matrix.log`.
- Clean regenerated native Debug build succeeds,
  `/tmp/sm64-modern-m33e-clean-build.log`.
- `git diff --check` passes.

## Boundary

This is a coverage-quality gate for runner evidence. It does not claim that
fixture rows exercise live gameplay, nor does it close whole-inventory parity,
save/audio/render migration, sanitizers, Metal 4 production, distribution,
physical, or human acceptance.

## Next slice

M33f should bind this exact coverage gate to the seven-record live Swift route
and then promote the corresponding manifest oracle-hook row only after C
replay, coverage, and persistent report restoration all pass together.
