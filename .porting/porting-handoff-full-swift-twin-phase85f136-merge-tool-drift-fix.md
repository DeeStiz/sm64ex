# Full Swift Twin Handoff — Phase 85f136 Canonical Merge-Tool Drift Fix

Date: 2026-08-24

## Verdict

**ISOLATED 25-TARGET RECONCILIATION PASSED; CANONICAL STATE UNCHANGED.** The
default `script/test_canonical_route_ledger_merge.sh` entrypoint now dispatches
to the bounded Phase 85f136 harness. The harness copies the 23-row baseline
inputs into a fresh run root, adds the two existing isolated source-backed
admissions (`audio_asset` and `bhvDecorativePendulum`), and runs the current
25-target Swift merge tool without opening any retained path for write. The
isolated output is 7,420 rows with 25 passed and 7,395 planned rows, exactly
matching the retained backup SHA-256. The designated 26/7,394 report remains a
read-only counter/hash anchor; no serial publication or canonical replacement
was attempted.

## Contract reconciliation

| Surface | Reconciled contract |
| --- | ---: |
| Swift merge target set | 25 targets, including `0x03345fc560c65b75` audio asset and `0x0020d8a254a893a3` decorative pendulum |
| Isolated merge output | `manifest_rows=7420 qualified_rows=25 planned=7395 terminal=25` |
| Retained backup report | 25 passed / 7,395 planned; SHA-256 `aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d` |
| Designated report | 26 passed / 7,394 planned; SHA-256 `4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4` |
| Route manifest | 7,420 rows; SHA-256 `23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715` |

The Swift tool now derives the retained-stage planned/terminal counters from
the 25-target set, explicitly documents that the designated 26-row stage is a
separate authorization boundary, and rejects output aliases against every
report/proof before any write. After proof parsing it also rejects aliases to
any proof artifact.

## Focused negative fences

All fences ran against isolated paths and left their destination absent:

```text
duplicate_target_rejected=1
missing_target_rejected=1
output_collision_rejected=1
stale_report_rejected=1
terminal_rerun_rejected=1
```

The successful isolated output SHA-256 was
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The harness re-hashed the designated report, backup report, source manifest,
all source reports/proofs, and every proof-named evidence artifact after the
run; all matched their preflight values.

## Validation

```text
xcrun swiftc -typecheck -parse-as-library -swift-version 6 \
  -Xfrontend -strict-concurrency=complete \
  SM64Modern/OracleTrace.swift SM64Modern/RouteShardExecution.swift \
  tools/SM64CanonicalRouteLedgerMergeTool.swift                         passed
bash -n script/test_canonical_route_ledger_merge.sh \
  script/test_phase85f136_merge_tool_drift_fix.sh                        passed
git -c core.fsmonitor=false diff --check                                  passed
bash script/test_canonical_route_ledger_merge.sh                          passed
```

The final smoke output recorded `canonical_publication=0` and
`designated_mutated=0 backup_mutated=0 manifest_mutated=0
evidence_artifacts_mutated=0`. The run root is an ignored isolated build
product under `build/sm64-modern-phase85f136-merge-tool-drift-fix/`.

## Files changed

- `tools/SM64CanonicalRouteLedgerMergeTool.swift` — retained-stage counters,
  immutable output-collision fences, and dynamic target-count diagnostics.
- `script/test_phase85f136_merge_tool_drift_fix.sh` — isolated 25-target
  orchestrator and duplicate/missing/collision/stale/rerun fences.
- `script/test_canonical_route_ledger_merge.sh` — default entrypoint dispatches
  to the bounded reconciliation; its old 85bu body remains opt-in only through
  `SM64_PHASE85BU_LEGACY_FULL_SMOKE=1` and was not run.
- This handoff note.

No commit, staging, push, canonical ledger/report replacement, route-history
publication, manifest promotion, or external artifact mutation was performed.
Device, GPU, pixel, performance, thermal, physical, store, and human
acceptance remain outside this tooling-only phase.
