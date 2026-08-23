# Full Swift Twin Handoff — Phase 85f64 Serial Canonical Merge Dry-Run

Date: 2026-08-23

## Verdict

**DRY-RUN IMPLEMENTATION COMPLETE / EXECUTION FAILS CLOSED.** The new
two-stage coordinator reconciles all 25 generated-target report/proof pairs,
then routes the fresh first-stage report through the guarded Phase85f33
intro-transition identity mapping. It refuses existing output paths, checks
proof-artifact existence and path separation before stage one, validates the
7420-row/25-to-26 transition and exact output hashes, and rechecks immutable
input hashes after both stages.

The current run did not produce a first-stage or final output. Preflight
stopped before writing because the retained Phase85f4 pendulum proof references
four missing artifacts:

```text
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.G61pBC/swift-source-route.trace
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.E46pr1/swift-source-route.trace
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.LvQEjk/swift-source-route.trace
/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-decorative-pendulum-route.oOjXuO/swift-source-route.trace
```

This is an intentional fail-closed boundary. No retained proof, report,
manifest, ledger, source, or public documentation was rewritten, and no
missing artifact was substituted or fabricated.

## Evidence and hashes

The fresh reachability/manifest regeneration completed before preflight:

```text
manifest_rows=7420
manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
```

The expected guarded inputs/outputs remain:

```text
retained_phase85f5_report_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
phase85f32_intro_report_sha256=6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2
phase85f32_intro_proof_sha256=c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51
expected_first_stage=25 passed / 7395 planned / aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
expected_final_stage=26 passed / 7394 planned / 4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
authored_intro_id=0x9a0f7b4f7ecf6c41
canonical_intro_id=0xca33981b30cb7815
```

## Validation

```text
bash -n script/test_phase85f64_serial_merge_dryrun.sh                         passed
xcrun swiftc -parse-as-library -swift-version 6 -Xfrontend -strict-concurrency=complete \
  tools/SM64SerialCanonicalMergeDryRunTool.swift                              passed
bash script/test_phase85f64_serial_merge_dryrun.sh                             exit=2, expected fail-closed missing retained artifact
git diff --no-index --check /dev/null tools/SM64SerialCanonicalMergeDryRunTool.swift  no whitespace errors
git diff --no-index --check /dev/null script/test_phase85f64_serial_merge_dryrun.sh no whitespace errors
```

The harness includes negative fences for duplicate/conflicting target rows,
fixture-only proof, missing proof artifacts, manifest/report hash mismatch,
output collision, terminal rerun, deterministic fresh outputs, and unchanged
retained inputs. The positive 26/7394 output remains inadmissible until the
four retained pendulum artifacts are restored by their owning admission
evidence; this handoff does not authorize publication or canonical-ledger
replacement.

## Files added

- `tools/SM64SerialCanonicalMergeDryRunTool.swift`
- `script/test_phase85f64_serial_merge_dryrun.sh`
- This handoff.
