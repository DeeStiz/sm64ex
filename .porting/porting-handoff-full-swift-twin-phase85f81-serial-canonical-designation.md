# Full Swift Twin Handoff — Phase 85f81 Serial Canonical Designation

Date: 2026-08-23

## Verdict

**LOCAL WRITE-ONCE DESIGNATION PASSED / CANONICAL PUBLICATION DEFERRED.** The
authorized Phase 85f77 protocol was applied to the exact Phase 85f72 final
report. The old retained report and generated manifest were re-read and left
unchanged. A fresh local designation root now contains a write-once backup and
the designated 7,420-row route report. No first-party status document, source,
manifest, old retained report, release, store publication, or push was changed.

## Immutable input readback

```text
candidate=/private/tmp/sm64-modern-phase85f72-serial-publication-readiness/run.aPUvDC/canonical-route-ledger-final.tsv
candidate_sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
candidate_rows=7420 passed=26 planned=7394
canonical_row=0xca33981b30cb7815|passed|2|2|2|
authored_phase_id=0x9a0f7b4f7ecf6c41|absent

retained=build/sm64-modern-phase85f5-pendulum-canonical-merge/run.czR8zi/canonical-route-ledger.tsv
retained_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
retained_rows=7420 passed=25 planned=7395
retained_canonical_row=0xca33981b30cb7815|planned|0|0|0|

manifest=build/sm64-route-shards-smoke/route-shards.tsv
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
manifest_rows=7420
manifest_canonical_identity=0xca33981b30cb7815|level_script|levels/intro/script.c|levels/intro/script.c
manifest_phase_local_id=0x9a0f7b4f7ecf6c41|absent
```

The tool validates unique report IDs against the manifest, the canonical
source-identity row, six-field ledger rows, expected state/evidence counters,
the exact candidate/retained/manifest hashes, and the absence of the authored
phase-local ID before writing any destination.

## Fresh write-once designation

```text
run_root=build/sm64-modern-phase85f81-serial-publication/run.elhzBC
designated_report=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv
designated_sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
backup_root=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup
backup_report_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
backup_manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
hash_snapshot=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/hash-snapshot.tsv
```

The backup contains byte-identical copies of the old retained report and
manifest plus a hash/count snapshot. The designated report is copied from the
immutable Phase 85f72 candidate through an atomic temporary-file plus
no-clobber move. The tool verifies all three backup/destination hashes and
rechecks the old retained report and manifest after writing.

## Negative fences

The harness passed all required fail-closed fixtures without creating their
destination files:

```text
duplicate_input_rejected=1
output_collision_rejected=1
rerun_rejected=1
identity_rejected=1
count_rejected=1
old_retained_unchanged=1
old_manifest_unchanged=1
```

## Validation

```text
bash -n script/test_phase85f81_serial_canonical_designation.sh             passed
xcrun swiftc -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  tools/SM64SerialCanonicalDesignationTool.swift                            passed
bash script/test_phase85f81_serial_canonical_designation.sh                 passed
git -c core.fsmonitor=false diff --check                                  passed
```

Only these files are scoped to Phase 85f81:

- `tools/SM64SerialCanonicalDesignationTool.swift`
- `script/test_phase85f81_serial_canonical_designation.sh`
- this handoff

The designated report is a fresh local evidence artifact. Status-surface
updates and any fixed-path canonical replacement remain parent-owned follow-up
operations; this phase does not imply push, release, deployment, or store
publication.
