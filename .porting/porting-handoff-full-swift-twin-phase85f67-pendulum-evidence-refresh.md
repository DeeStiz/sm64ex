# Full Swift Twin Handoff — Phase 85f67 Pendulum Evidence Refresh

Date: 2026-08-23

## Verdict

**FRESH FOUR-WAY MATRIX AND ISOLATED ADMISSION PASSED.** Phase 85f3 was
rerun in a new build root, followed by Phase 85f4 against that matrix and the
existing canonical manifest. Debug, ASan, Release, and independent rerun
captures remain byte-identical at the pair-report level. Canonical merge was
not attempted.

## Fresh run roots

```text
phase85f3_matrix_root=/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p
phase85f4_admission_root=/private/tmp/sm64-modern-phase85f67-pendulum-admission.PN4csC/run.T1MMol
canonical_manifest=build/sm64-modern-phase85h-canonical-ledger/run.ACmfTD/route-shards.tsv
```

The matrix command was:

```text
SM64_PHASE85F3_BUILD_ROOT=/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq \
  bash script/test_phase85f3_pendulum_matrix.sh
```

The admission command was:

```text
SM64_PHASE85F3_MATRIX_ROOT=/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p \
SM64_PHASE85F4_BUILD_ROOT=/private/tmp/sm64-modern-phase85f67-pendulum-admission.PN4csC \
SM64_PHASE85F4_MANIFEST=build/sm64-modern-phase85h-canonical-ledger/run.ACmfTD/route-shards.tsv \
  bash script/test_phase85f4_pendulum_admission.sh
```

## Results and hashes

```text
records_each=1056
matched_each=1056
semantic_identity=0x6268765f647065
coverage=0x680ff75430bf24ff
header_parity=1
pair_reports_byte_identical=1
tamper_rejected=1
schema4_replay_round_trip=1
persistent_rerun_rejected=1
artifact_paths_distinct=1
fixture_marker_absent=1
output_freshness_guard=1

debug_trace_sha256=0e27c4232d1895425555cd0d7e0e4dbe38a1d8e2a368c77ade81508dc607057d
pair_report_sha256=9a71e388901d1b6991782941e634852dbcbb98838d7b2d4b7736e4124f1afc1a
isolated_report_sha256=6f66939fa025efb520cbeeffe04d6144c8dc099232de0e5b37dbc8d10127aaeb
proof_sha256=6522bc3e07ac384d287a3ebb6b4a382e874f6b31084788066a39ab095a7b2e7a
manifest_sha256_before=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
manifest_sha256_after=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
```

The isolated report has 7,420 rows with exactly one `passed` row for target
`0x0020d8a254a893a3`. The proof records 20 distinct artifacts and declares
`fixture_only=0` for `bhvDecorativePendulum`.

## Proof artifact paths

The Phase 85f4 proof records these immutable input/output paths:

```text
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/debug-pair.report
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/asan-pair.report
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/release-pair.report
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/rerun-pair.report
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/native-debug/native.trace
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/native-asan/native.trace
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/native-release/native.trace
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/native-rerun/native.trace
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.qs7dVX/swift-source-route.trace
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.pij1jI/swift-source-route.trace
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.IEH4ay/swift-source-route.trace
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.CQyun1/swift-source-route.trace
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/native-debug/run.log
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/native-asan/run.log
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/native-release/run.log
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/native-rerun/run.log
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/swift-debug.log
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/swift-asan.log
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/swift-release.log
/private/tmp/sm64-modern-phase85f67-pendulum-matrix.cMrLGq/run.xcqy9p/swift-rerun.log
```

## Immutability boundary

The canonical manifest was read at its retained path and its SHA-256 was the
same before and after admission. Phase 85f4 emitted
`canonical_manifest_mutated=0 canonical_report_mutated=0
canonical_merge=deferred`; no canonical report, manifest, or ledger was
copied, rewritten, or promoted. Fresh report/proof outputs were written only
under the new Phase 85f4 admission root.

## Validation

```text
bash script/test_phase85f3_pendulum_matrix.sh  exit=0
bash script/test_phase85f4_pendulum_admission.sh exit=0
git -c core.fsmonitor=false diff --check -- script/test_phase85f3_pendulum_matrix.sh \
  script/test_phase85f4_pendulum_admission.sh  passed (both harnesses)
```

The next serial dry-run may consume the fresh roots through explicit
environment overrides. This handoff does not run or authorize that merge.
