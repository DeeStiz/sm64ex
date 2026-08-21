# Full Swift Twin Handoff — Phase 25 Route Alignment

Date: 2026-08-20

## Result

The next real manifest row was attempted without promotion. The C lifecycle
recorder and Swift engine context now independently emit the same schema-4
input receipt for oracle_hook|input
(0xd9446dfed10e189e). All five non-coverage identity fingerprints align and
the retained C/Swift files are byte-identical:

    pairing_audit admitted=0 c_records=1 swift_records=1 c_ticks=2 swift_ticks=2 blockers=coverage_deferred
    real_route_alignment_attempted=1 records=1 exact_bytes=1 common_fingerprints=5

The row remains explicitly non-admitted. The native lifecycle observes
additional domains outside this selected row, so its coverage fingerprint is
still deferred; the one retained receipt is not a complete multi-tick route
window. The bounded one-record contract probe remains separately reported as
contract evidence only.

## Before / after counters

Phase 20 compared the ordinary independent captures:

    c_records=3151 swift_records=1 c_ticks=5 swift_ticks=1
    blockers=build_fingerprint,configuration_fingerprint,content_fingerprint,
    coverage_deferred,initial_save_fingerprint,record_bytes,record_count,
    timebase_fingerprint,trace_bytes

Phase 25's route-scoped capture uses the manifest row's shard/input/save
identity, a native 60/30 timebase, one actual C owner tick, and the Swift
engine input normalizer. The result is one record on each side, tick 2 on
each side, exact record/file bytes, and five aligned fingerprints. Only
coverage_deferred remains.

## Admission boundary

SM64RouteShardPromotionTool now rejects a trace with a zero coverage
fingerprint and rejects a one-record trace that does not establish an
independent multi-tick window. script/test_live_route_promotion.sh verifies
that the existing synthetic input-only probe is rejected and cannot create a
report:

    current_route_shard_admitted=0 synthetic_one_record_rejected=1
    coverage_or_window_gate=1 fixture_only=0

No route ledger or manifest row was changed.

## Changed files

- script/test_c_swift_pairing.sh
- script/test_live_route_promotion.sh
- script/test_oracle_lifecycle_record.sh
- tests/sm64_modern_live_route_oracle_contract.c
- tests/sm64_modern_live_route_oracle_smoke.swift
- tests/sm64_modern_oracle_lifecycle_record.c
- tools/SM64RouteShardPromotionTool.swift
- .porting/porting-handoff-full-swift-twin-phase25-route-alignment.md

## Validation

Passed:

- ./script/test_c_swift_pairing.sh — strict native C build, strict Swift 6
  build, exact C/Swift route alignment, C replay of both files, Swift/C
  tamper rejection, and bounded-probe separation.
- ./script/test_live_route_promotion.sh — synthetic one-record rejection
  and no report mutation.
- ./script/test_route_shard_live_executor.sh — live range, fixture,
  missing-evidence, output-reuse, and fixture-marker rejection.
- ./script/test_route_shard_merge.sh — canonical merge, duplicate/unknown/
  missing/invalid-transition/fixture rejection, and shared fingerprints.
- ./script/test_route_shard_replay.sh — 14 fixture rows, C/Swift bytes,
  ledger transition and persistent-rerun rejection.
- env -u SM64_MODERN_PAIRING_ROUTE ./script/test_oracle_lifecycle_record.sh
  — ordinary 3,151-record lifecycle capture remains green.
- ./script/test_live_route_oracle.sh input-only — existing compatibility
  oracle smoke remains green.
- SM64_MODERN_PAIRING_ROUTE=1 ./script/test_live_route_oracle.sh input-only and
  SM64_MODERN_PAIRING_ROUTE=1 ./script/test_oracle_lifecycle_record.sh followed
  by cmp — focused route C/Swift receipt and file-byte match remains green.
- bash -n script/test_c_swift_pairing.sh script/test_oracle_lifecycle_record.sh
  script/test_live_route_oracle.sh script/test_live_route_promotion.sh
- git diff --check

## Concrete unblock

Record at least two independently captured C and Swift ticks for this row
from the same initialized save/config/content/build identity, retain the
complete row receipt set rather than filtering a single input receipt, and
compute a nonzero coverage fingerprint from the observed C coverage before
attempting promotion. Until that evidence exists, keep
current_route_shard_admitted=0; the one-record probe must not be used as a
route pass.
