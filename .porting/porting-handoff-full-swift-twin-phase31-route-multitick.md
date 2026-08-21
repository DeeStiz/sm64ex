# Full Swift Twin Handoff — Phase 31 Route Multi-Tick Window

Date: 2026-08-20

## Result

The Phase 25 route attempt is now a complete independent two-tick C/Swift
window for the real oracle_hook|input row
(0xd9446dfed10e189e). The C lifecycle still runs the complete native owner
tick, but the retained route artifact keeps every observed input-row receipt
instead of selecting one receipt. The Swift engine context independently
normalizes the same two input samples and advances its owner tick between
receipts.

The retained artifacts are byte-identical (328 bytes), have identical
build/content/timebase/configuration/save/coverage fingerprints, and carry
input records at simulation ticks 2 and 3:

    pairing_audit admitted=1 c_records=2 swift_records=2 c_ticks=3 swift_ticks=3 blockers=none
    real_route_alignment_attempted=1 records=2 window_ticks=2 exact_bytes=1 common_fingerprints=6 coverage=1
    current_route_shard_admitted=1

The nonzero route coverage fingerprint is derived from the retained observed
row, not hard-coded:

    coverage_fingerprint=0x41c653762e1112a2 coverage_entries=1

The native oracle internally observes unrelated owner domains during the same
lifecycle (observed_coverage_entries=63), but those domains are not part of
the selected manifest row. The route artifact and its coverage fingerprint
are computed only from the retained input row. No generated manifest or
canonical route ledger file was changed; the existing one-row live-qualified
counter remains 1/7,419.

## Admission and promotion

The route promotion gate now requires both at least two records and at least
two distinct simulation ticks, a nonzero coverage fingerprint, and complete
row-domain coverage. The isolated promotion and executor gates both passed:

    promotion records=2 status=passed fixture_only=0
    worker expected_records=2 actual_records=2 matched_records=2 fixture_only=0
    persistent_rerun_rejected=1

The route worker-result merge smoke also passed canonical ordering,
fingerprint sharing, duplicate/unknown/missing-row rejection, invalid
transition rejection, and fixture-only rejection. This confirms the existing
row's complete evidence without promoting a second manifest row.

## Changed files

- SM64Modern/RouteShardExecution.swift
- script/test_c_swift_pairing.sh
- script/test_live_route_oracle.sh
- script/test_live_route_promotion.sh
- script/test_live_route_shard_batch.sh
- tests/sm64_modern_live_route_oracle_contract.c
- tests/sm64_modern_live_route_oracle_smoke.swift
- tests/sm64_modern_oracle_lifecycle_record.c
- tests/sm64_modern_route_shard_live_executor_smoke.swift
- tools/SM64RouteShardLiveExecutorTool.swift
- tools/SM64RouteShardPromotionTool.swift
- .porting/porting-handoff-full-swift-twin-phase31-route-multitick.md

## Validation

Passed:

- strict C lifecycle build/run with SM64_MODERN_PAIRING_ROUTE=1: two input
  records, ticks 2–3, retained coverage entries 1, nonzero coverage.
- strict Swift 6 route build/run with SM64_MODERN_PAIRING_ROUTE=1: two
  matching input records at ticks 2–3.
- independent route pairing_audit, cmp, and C route replay: admitted,
  byte-identical, replay matched 2 records.
- route tamper replay rejection and explicit C divergence probe
  (first_divergence=1).
- isolated live promotion: passed 2-record/two-tick route; persisted rerun
  rejected.
- isolated live executor: worker result expected=2 actual=2 matched=2.
- ./script/test_route_shard_merge.sh.
- ./script/test_route_shard_replay.sh.
- git diff --check.

No commit was created; the parent agent owns review and the local phase
commit. The broader full-Swift objective, physical/runtime acceptance, and
other 7,418 route rows remain outside this bounded route closure.
