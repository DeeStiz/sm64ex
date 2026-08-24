# Full Swift Twin Handoff — Phase 85f134 Canonical Merge Dry-Run

Date: 2026-08-24
Target HEAD: `65f0cc87ee953ce90368449b90328d7beaa013f6`
Shared checkout observation: `nightly` was later at `9cdf2f013cde6c425e17adac3c659937c60aecab` because of parent-owned documentation commits. The two merge inputs are byte-identical to target HEAD.

## Verdict

**NON-MUTATING RECONCILIATION DRY-RUN PASSED IN ISOLATED OUTPUT.** The shell
harness/tool drift is confirmed and the current 25-target Swift merge tool
was exercised with an isolated, reconciled 25-report input set. It produced a
temporary 7,420-row report with 25 terminal rows and 7,395 planned rows whose
SHA-256 is exactly the retained 25-row backup. No designated report, backup,
manifest, canonical ledger, route history, source file, or tracked code was
opened for write. No commit was made.

The passing run validates merge shape, report/proof hashes, source identities,
artifact hashes, output counters, and the terminal rerun fence. It does not
re-admit the three Phase 85f131 lanes or authorize replacing the designated
26-row report.

## Drift readback

The target-HEAD inputs are byte-identical to the checked-out files:

```text
script/test_canonical_route_ledger_merge.sh
  SHA-256 = 9fa12cd09273d4c816046a6237bda512a740a67d
tools/SM64CanonicalRouteLedgerMergeTool.swift
  SHA-256 = 747583bc6ffc0bbe258c2778fe4855d601e376c8
git diff 65f0cc87 -- script/test_canonical_route_ledger_merge.sh tools/SM64CanonicalRouteLedgerMergeTool.swift
  status = 0 (no diff)
```

The mismatch is structural:

| Input/contract | Targets | Terminal/planned assertion | Readback |
| --- | ---: | ---: | --- |
| `script/test_canonical_route_ledger_merge.sh` IDs and `merge_args` | 23 | 23 / 7,397 | `bash -n` passed; it omits `--audio-asset-*` and `--pendulum-*` |
| `SM64CanonicalRouteLedgerMergeTool.swift` `targetIDs` and parser | 25 | 25 / 7,395 | strict Swift 6 typecheck passed; parser requires 104 tokens |
| retained backup report | 25 | 25 / 7,395 | `aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d` |
| designated local report | 26 | 26 / 7,394 | `4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4` |

The script's stale 23-pair invocation against the current tool was reproduced
with isolated output and failed before reading reports:

```text
status=2
output_exists=0
sm64-canonical-route-ledger-merge: usage: ... --audio-asset-report REPORT --audio-asset-proof PROOF --pendulum-report REPORT --pendulum-proof PROOF --output REPORT
```

The old shell expectation of `qualified_rows=23 planned=7397 terminal=23`
therefore cannot be reached with the current 25-target tool.

## Three Phase 85f131 admissions

These rows were independently admitted at the target HEAD in isolated reports;
each report has 7,420 rows, exactly one passed row, and 7,419 planned rows.

```text
0x3951f0333dc3c5da | oracle_hook/effects                  | records=58 | report_sha256=0c3fa33cd0d219a0e5347d6131397301e48699f91ee17a82c0c029607115a93d
0x3e1cdaca08b21f54 | oracle_hook/interaction_state         | records=14 | report_sha256=2b8916452ceb54cf85fd18defcc883d211a5f1da41f04fd16c665d5dd5040457
0x00cab93b5dd94425 | display_list/door_seg3_dl_03014A20   | records=2  | report_sha256=9908da6bc5c86e2912601e85c713135ac8fa1622f5cb1d51ab0cc59fc9c44391
```

Admission logs independently report `fixture_only=0`, zero manifest/ledger/
history mutation, and `rerun_fence=1`. Device effects, GPU capture, pixel,
physical, and human acceptance remain unverified.

The two additional reports required by the current 25-target tool were read
from isolated historical admissions, not regenerated:

```text
0x03345fc560c65b75 | audio_asset | report_sha256=7c22c62f13e25c430069bdfe1c77840fd5f6751737a3c63b3ff6361e88bdb19d
0x0020d8a254a893a3 | behavior/bhvDecorativePendulum | report_sha256=6f66939fa025efb520cbeeffe04d6144c8dc099232de0e5b37dbc8d10127aaeb
```

## Isolated 25-target dry-run

Inputs were read from the existing isolated Phase 85h run, plus the two
additional report/proof pairs above. The audio-asset proof header and the
pendulum proof's four expired temporary Swift-trace paths were normalized only
in temporary files under `/tmp`; source reports, admission proofs, and their
artifacts were not modified.

```text
typecheck:
  xcrun swiftc -parse-as-library -swift-version 6 \
    -Xfrontend -strict-concurrency=complete \
    SM64Modern/OracleTrace.swift SM64Modern/RouteShardExecution.swift \
    tools/SM64CanonicalRouteLedgerMergeTool.swift
  status=0

unmodified-proof attempt:
  status=2
  error=invalid evidence proof .../audio-asset-proof.tsv: invalid header or row count

reconciled isolated run:
  output=/tmp/sm64-phase85f134-fences.KDO582/canonical-route-ledger.tsv
  status=0
  manifest_rows=7420
  qualified_rows=25
  planned=7395
  terminal=25
  fixture_only=0
  manifest_sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
  output_sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
```

The output hash exactly matches the retained backup, demonstrating that the
25-target set is the old 25/7,395 ledger rather than the designated 26/7,394
report. The three f131 report hashes appear in the tool's verified report hash
list; no new canonical state was published.

## Immutability and negative fences

The successful temporary output was rerun with the same 25-pair arguments:

```text
first_status=0
first_hash=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
rerun_status=2
error=cumulative ledger already exists; rerun rejected
rerun_hash=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
rerun_unchanged=1
```

Canonical anchors were re-read after the dry-run:

```text
designated=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv
  rows=7420 passed=26 planned=7394
  sha256=4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4
backup=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv
  rows=7420 passed=25 planned=7395
  sha256=aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d
manifest=build/sm64-route-shards-smoke/route-shards.tsv
  rows=7420 (7422 physical lines including two headers)
  sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
backup_manifest=build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/route-shards.tsv
  sha256=23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715
```

`git diff --check` passed and no tracked source/tool/canonical artifact was
changed by this phase. The shared branch already had four parent-owned commits
ahead of `origin/nightly`; this handoff is the only file added for Phase
85f134. No staging, commit, push, canonical replacement, or route-history
publication was performed.

## Next action

Reconcile the checked-in shell harness and Swift tool under an explicitly
authorized code-change phase, deciding whether the intended input is the
25-row retained backup or the designated 26-row report (which also requires
the canonical intro row). Keep the three f131 reports isolated until that
decision and separate serial-merge authorization are recorded.
