# Full Swift Twin Handoff — Phase 85f72 Serial Publication Readiness

Date: 2026-08-23

## Verdict

**PUBLICATION-READY EVIDENCE / PUBLICATION DEFERRED.** The green Phase
85f69 two-stage dry-run was rerun from the fresh Phase 85f67 pendulum
admission root in an isolated Phase 85f72 run. The exact final report,
proof inputs, immutable-input hashes, and source-identity crosswalk are
consistent and sufficient for an explicitly authorized scoped canonical
promotion. No canonical report, manifest, ledger, source, or first-party
status document was promoted or overwritten by this audit.

## Exact isolated output

Fresh run root:

```text
/private/tmp/sm64-modern-phase85f72-serial-publication-readiness/run.aPUvDC
```

The first-stage output preserves the retained state:

```text
report=/private/tmp/sm64-modern-phase85f72-serial-publication-readiness/run.aPUvDC/canonical-route-ledger.tsv
rows=7420 passed=25 planned=7395
sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
```

The exact final phase-local output is:

```text
report=/private/tmp/sm64-modern-phase85f72-serial-publication-readiness/run.aPUvDC/canonical-route-ledger-final.tsv
rows=7420 passed=26 planned=7394
sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
canonical_row=0xca33981b30cb7815|passed|2|2|2|
authored_phase_id=0x9a0f7b4f7ecf6c41|absent
```

The second stage does not emit a separate cumulative proof sidecar. Its
proof authority is the immutable 26-input proof set, including the exact
intro proof below and the fresh pendulum proof below; the coordinator hashes
every referenced trace/report/log artifact before and after both stages.

The generated manifest has 7,420 rows and SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
The intro target report/proof inputs are the selected Phase 85f32 root:

```text
report=build/sm64-modern-intro-transition-route-admission/run.OachXR/intro-transition-isolated-report.tsv
report_sha256=6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
proof=build/sm64-modern-intro-transition-route-admission/run.OachXR/intro-transition-isolated-proof.tsv
proof_sha256=c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51
fixture_only=0 artifact_count=16
```

The fresh Phase 85f67 pendulum inputs consumed by the rerun are:

```text
root=/private/tmp/sm64-modern-phase85f67-pendulum-admission.PN4csC/run.T1MMol
report_sha256=6f66939fa025efb520cbeeffe04d6144c8dc099232de0e5b37dbc8d10127aaeb
proof_sha256=6522bc3e07ac384d287a3ebb6b4a382e874f6b31084788066a39ab095a7b2e7a
fixture_only=0 artifact_count=20
```

Independent proof readback covered all 26 report/proof inputs (23 retained
families, audio asset, pendulum, and intro) and all 236 referenced artifact
paths: every artifact was present, hash-valid, and unique.

## Source identity crosswalk

The admitted intro proof identifies the source-authored local row as:

```text
0x9a0f7b4f7ecf6c41|level_script|levels/intro/script.c|fixture_only=0
```

The regenerated manifest contains exactly one matching source identity:

```text
0xca33981b30cb7815|level_script|levels/intro/script.c|levels/intro/script.c|0xdaaafed747b604f9|0x0c89f4d300ff0986|global_state,script_events,transition|planned|deterministic route shard; execution remains an M33 gate
```

The guarded second stage therefore promotes only canonical ID
`0xca33981b30cb7815`; it does not append the phase-local ID, infer seed
equivalence, or replace the retained cumulative report with the isolated
intro report.

## Immutability and fences

The f72 coordinator reports:

```text
immutable_inputs_unchanged=1
retained_manifest_mutated=0 retained_reports_mutated=0 retained_proofs_mutated=0
canonical_ledger_overwrite=0
duplicate_target_rejected=1 conflicting_target_rejected=1 fixture_only_rejected=1
missing_proof_artifact_rejected=1 manifest_hash_mismatch_rejected=1
intro_report_hash_mismatch_rejected=1 output_collision_rejected=1
terminal_rerun_rejected=1 deterministic_output=1
```

The 53 immutable input files (manifest plus the 26 report/proof pairs) also
matched their preflight SHA-256 snapshot in independent readback. The
retained canonical report remains
`build/sm64-modern-phase85f5-pendulum-canonical-merge/run.czR8zi/canonical-route-ledger.tsv`
at 25 passed / 7,395 planned with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.

## Authorization boundary and exact remaining step

This evidence establishes readiness for the scoped route-ledger transition,
not publication. The final report is still an isolated `/private/tmp` output;
the retained canonical state and all first-party status surfaces still report
25 / 7,395. Permission to create this audit is not permission to promote
the ledger.

The parent must first obtain explicit authorization equivalent to:

```text
Authorize serial publication of the Phase 85f72 final report
4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4 as the
canonical 26-passed / 7,394-planned route ledger, update the six scoped
status surfaces, and make the scoped local commit.
```

Only after that authorization may the parent preserve/designate this exact
final output as retained canonical evidence, update `README.md`,
`docs/SM64Modern.md`, `.porting/goal-full-swift-twin.md`,
`.porting/goal-continuation-luna-max-2026-08-20.md`, `.porting/porting-memory.md`,
and `CHANGES`, rerun the consistency and `git diff --check` gates, stage the
authorized publication batch, and commit it. Push, release, and store
publication require separate authorization and are not implied here.

## Validation

```text
SM64_PHASE85F64_* overrides + script/test_phase85f64_serial_merge_dryrun.sh  passed (exit=0)
bash -n script/test_phase85f64_serial_merge_dryrun.sh                         passed
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete
  -module-cache-path /private/tmp/sm64-phase85f72-strict-module-cache       passed: serial, canonical, and intro merge tools
independent 53-file immutable SHA-256 readback                              passed
independent 26-proof / 236-artifact hash and uniqueness readback              passed
git -c core.fsmonitor=false diff --check                                    passed
```

No staging, commit, push, release, canonical promotion, documentation
update, source mutation, or destructive cleanup was performed.
