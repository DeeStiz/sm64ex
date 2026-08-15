# M33f Handoff — live route shard promotion

## Scope

M33f promotes the first real Swift route trace into the canonical route-shard
ledger. It is deliberately separate from the M33b fixture runner: the trace is
emitted by `SM64ModernSwiftEngineContext`, replayed through the real C oracle,
then selected by the manifest-aware promoter before it can become `passed`.

## Implementation

- `tests/sm64_modern_live_route_oracle_smoke.swift` accepts `--input-only` and
  emits the one-record `oracle_hook|input` route used for promotion; the
  existing seven-record full route remains the regression path.
- `tests/sm64_modern_live_route_oracle_contract.c` accepts both full and
  input-only traces and keeps the deliberate full-route first-divergence test.
- `tools/SM64RouteShardPromotionTool.swift` restores any prior report, begins
  the selected row, requires a record-mode trace and exact expected-domain
  coverage, then writes terminal evidence with `fixture_only=0`.
- `script/test_live_route_promotion.sh` regenerates the 7,419-row manifest,
  runs the real Swift/C input-only route, promotes the canonical input shard,
  and proves a second process is rejected by the persisted terminal report.

## Validation

- `script/test_live_route_oracle.sh full` — seven records, C replay match,
  deliberate `first_divergence=3`.
- `script/test_live_route_oracle.sh input-only` — one record, C replay match.
- `script/test_live_route_promotion.sh` — exact coverage and persistent
  rerun rejection, `fixture_only=0`.
- Full `script/test_*.sh` matrix: `runs=136 failures=0`.
- Regenerated native Swift 6/macOS 27 Debug build: clean project diagnostics.
- `git diff --check`: clean.

## Remaining gate

This closes one live input shard only. M33 still requires live Swift routes for
all reachable level, behavior, actor, camera, audio, render, save, transition,
and front-end rows, followed by sanitizer reruns and a zero-unexecuted report.
M34 Metal 4 production evidence and M35 distribution/human acceptance remain
open and are not implied by this handoff.
