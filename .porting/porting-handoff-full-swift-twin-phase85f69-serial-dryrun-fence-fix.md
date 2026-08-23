# Full Swift Twin Handoff — Phase 85f69 Serial Dry-Run Fence Fix

Date: 2026-08-23

## Verdict

**SERIAL DRY-RUN NEGATIVE FENCES PASSED.** The f64 fixture-only assertion was
malformed because its `awk` command used whitespace fields against a
pipe-delimited proof row. It appended a fifth field, so the canonical merge
correctly rejected the malformed proof as `invalid artifact SHA-256` before it
could reach the intended `fixture_only` fence. The adjacent missing-artifact
fixture had the same delimiter defect.

The harness now edits both proof rows with `-F'|'` and `OFS='|'`. The serial
tool also checks immutable/proof-artifact output collisions before its existing
output rerun fence, matching the intended collision class without changing
positive merge behavior.

## Fresh validation

The retained f64 positive inputs were read from the existing canonical/audio
roots, and the fresh Phase 85f67 pendulum admission root was used:

```text
pendulum_root=/private/tmp/sm64-modern-phase85f67-pendulum-admission.PN4csC/run.T1MMol
run_root=/private/tmp/sm64-modern-phase85f69-serial-dryrun-fence-fix-final/run.CMKswq
```

```text
first_stage_passed=25 first_stage_planned=7395
first_stage_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
final_stage_passed=26 final_stage_planned=7394
final_stage_sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
```

The harness summary reports:

```text
duplicate_target_rejected=1 conflicting_target_rejected=1 fixture_only_rejected=1
missing_proof_artifact_rejected=1 manifest_hash_mismatch_rejected=1 intro_report_hash_mismatch_rejected=1
output_collision_rejected=1 terminal_rerun_rejected=1 deterministic_output=1
retained_manifest_mutated=0 retained_reports_mutated=0 retained_proofs_mutated=0 canonical_ledger_overwrite=0
```

The fixture log contains `fixture_only evidence is not allowed`; the missing
artifact log contains `missing retained proof artifact`; and the output
collision log contains `output path collides with an immutable input or proof
artifact`. No retained artifact or canonical ledger was overwritten.

## Validation commands

```text
bash -n script/test_phase85f64_serial_merge_dryrun.sh                         passed
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
  -module-cache-path /private/tmp/sm64-serial-merge-dryrun-fence-fix-module-cache \
  tools/SM64SerialCanonicalMergeDryRunTool.swift                              passed
git diff --check -- script/test_phase85f64_serial_merge_dryrun.sh \
  tools/SM64SerialCanonicalMergeDryRunTool.swift                              passed
serial dry-run harness with the explicit retained/fresh roots above          exit=0
```

## Scoped files

- `script/test_phase85f64_serial_merge_dryrun.sh` — preserve pipe-delimited
  proof fields in fixture-only and missing-artifact negatives.
- `tools/SM64SerialCanonicalMergeDryRunTool.swift` — classify immutable output
  collisions before existing-output reruns.
- This handoff.

Canonical publication and ledger replacement remain deferred.
