# Full Swift Twin Handoff — Phase 85f138 M34 timebase-gate design

Date: 2026-08-24 (EDT)

## Scope and verdict

**GATE DESIGN IMPLEMENTED / DEFAULT FAIL-CLOSED / M34 NOT RUN.** This phase
added a separate, source-attributed receipt-seam drift contract and an
approval-gated audit mode. The retained historical fixture
`tests/fixtures/sm64_modern_timebase_audit.tsv` was not rewritten. A normal
`script/test_timebase_audit.sh` invocation still fails on the intentional
`object_timer` and broad-token `random_calls` drift. Only the explicit mode
and exact named approval token can classify that drift for a production
preflight.

No C or Swift source was changed. The approved audit still validates the
existing cadence inventory's C/Swift source anchors. No M34 production
harness, Release build, app launch, GPU capture/replay, report/ledger/manifest
mutation, credential operation, commit, or push was performed.

## Repository and baseline anchors

```text
HEAD=fef3e8255c640ec9c2798b94590fa6fc65a58687
origin/nightly=65f0cc87ee953ce90368449b90328d7beaa013f6
receipt_baseline=6f586de9ba16024ff0463b6f24869a896a4eeb62
```

The retained fixture remains byte-identical to the last accepted source-era
baseline:

```text
tests/fixtures/sm64_modern_timebase_audit.tsv
  sha256=b6869708bca3f3dc6b27754fc12d44ee427d2d7296a8f08013d0b9a35f15c4b2
  object_timer=166/715
  random_calls=79/289
```

Current source still reads:

```text
object_timer=166/734 (+19)
random_calls=79/290 (+1 broad token)
callable_random_syntax=79/289 (unchanged)
```

## New contract and explicit approval gate

The new contract is
`tests/fixtures/sm64_modern_timebase_receipt_drift.tsv`. It has eight rows:
seven `object_timer` per-file deltas and one TTC `random_calls` lexical-field
delta. Each row requires all of the following before the mode can pass:

* exact baseline/current per-file counts and arithmetic delta;
* exact receipt-source token(s);
* the full source receipt commit as an ancestor of `HEAD`, with the expected
  subject and the source file touched by that commit;
* equality between the complete baseline/current per-file delta set and the
  eight allowlisted rows; and
* aggregate equality against the retained fixture plus the contract deltas.

The audit's callable RNG cross-check independently requires baseline and
current `79 files / 289 calls` using a call-site pattern that requires `(`.
Thus the broad-token `289 -> 290` classification cannot authorize an added
RNG draw or an unlisted source drift.

The only accepted approval pair is:

```text
SM64_MODERN_TIMEBASE_AUDIT_MODE=receipt-seam-drift
SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED=M34_TIMEBASE_RECEIPT_SEAM_V1
```

The default mode is `strict`. Supplying only the approval variable, using a
generic value such as `1`, omitting the token, selecting an unknown mode, or
changing any contract/source attribution fails closed. The M34 harness applies
the same pair check before invoking `m9_release.sh`; it does not manufacture
or inject the approval pair.

## Exact source attribution

| Category | Source | Baseline -> current | Delta | Receipt commit |
|---|---|---:|---:|---|
| `object_timer` | `src/game/behaviors/express_elevator.inc.c` | 2 -> 3 | +1 | `380f14ae` WDW elevator |
| `object_timer` | `src/game/behaviors/ttc_2d_rotator.inc.c` | 2 -> 4 | +2 | `7651f380` TTC rotator |
| `object_timer` | `src/game/behaviors/spindrift.inc.c` | 1 -> 3 | +2 | `eb3fbf8a` Spindrift |
| `object_timer` | `src/game/behaviors/spindel.inc.c` | 6 -> 8 | +2 | `91e53c7f` Spindel |
| `object_timer` | `src/game/behaviors/sl_snowman_wind.inc.c` | 1 -> 3 | +2 | `8e2ab88b` Snowman wind |
| `object_timer` | `src/game/behaviors/treasure_chest.inc.c` | 3 -> 11 | +8 | `904bffa3` JRB treasure |
| `object_timer` | `src/game/behaviors/whomp.inc.c` | 8 -> 10 | +2 | `66ca1911` Whomp King |
| `random_calls` | `src/game/behaviors/ttc_2d_rotator.inc.c` | 1 -> 2 | +1 broad token | `7651f380` TTC rotator `.random_u16` field |

The contract file hash is:

```text
39f64242b2071f274b277865ed0613c1a8157e7f863337f85f2f09f8c03ed67e  tests/fixtures/sm64_modern_timebase_receipt_drift.tsv
```

## Validation evidence

All checks were run from the shared checkout without changing the retained
fixture or canonical artifacts:

```text
env -u SM64_MODERN_TIMEBASE_AUDIT_MODE \
    -u SM64_MODERN_TIMEBASE_RECEIPT_SEAM_DRIFT_APPROVED \
    bash script/test_timebase_audit.sh
  exit=1
  emitted the exact 166/715 -> 166/734 and 79/289 -> 79/290 diff
  emitted: Time-dependent gameplay inventory changed; classify the drift before updating the fixture.

bash script/test_timebase_receipt_gate.sh
  exit=0
  default_fail_closed=1 approval_pair_required=1 attribution_contract=1

approved audit (invoked only by the focused gate smoke, not M34):
  mode=receipt-seam-drift
  approval=M34_TIMEBASE_RECEIPT_SEAM_V1
  exit=0
  timebase_receipt_drift_contract=pass rows=8 callable_rng=79/289

bash -n script/test_timebase_audit.sh script/test_timebase_receipt_gate.sh \
  script/test_metal4_production.sh script/m9_release.sh script/build_and_run.sh
  exit=0

git diff --check
  exit=0

bash script/test_metal4_contract.sh
  exit=0  (SM64 Modern Metal 4 source contract passed)

bash script/test_metal4_capture_archive_guard.sh
  exit=0  (SM64 Modern Metal 4 capture archive guard contract passed)
```

The focused gate's negative fences cover default mode, missing approval,
generic approval value `1`, and the exact approval-pair positive case. The
approved audit itself additionally rejects missing/changed baseline commits,
source files, receipt subjects, receipt commit touch sets, required tokens,
per-file deltas, aggregate counts, and callable RNG counts.

No C/Swift compile or runtime promotion was necessary for this shell/TSV-only
gate change. The approved audit did run `validate_cadence_manifest`, including
its required C and Swift source/symbol anchors; this is static contract
evidence and not C/Swift runtime or M34 acceptance.

## Changed files and boundaries

```text
script/test_timebase_audit.sh
  sha256=05e9dd6d7d0ebe28da700c79ceb076f335ae9ee2bd7b4c43857752008e884efe
script/test_metal4_production.sh
  sha256=57b90db107181be1ac973239e0615a93deed53c10a5c9e5b6577718def5a5de1
script/test_timebase_receipt_gate.sh
  sha256=c6bfc894ef23b47fb8a35d10ab38be3e1cf04c429f91ef891477acc1bdfa4824
tests/fixtures/sm64_modern_timebase_receipt_drift.tsv
  sha256=39f64242b2071f274b277865ed0613c1a8157e7f863337f85f2f09f8c03ed67e
```

The governing cadence manifest remains unchanged at
`8ad802dfffb412e61e4f6c63f0a871c748578044d00498c8d3fad09b2cf202eb`. No
route reports, canonical ledgers, route/behavior manifests, historical
fixture, source C, source Swift, or generated project was modified.

## Next gate

Parent review is required before any production attempt. If the owner accepts
this gate design, a later M34 run may explicitly provide the two approval
variables above to the unchanged host/production sequence. That later run must
still independently produce Release, runtime, Metal validation, GPU capture,
cadence, thermal, physical visual/feel, and human evidence; a passing audit
classification does not promote any of those gates.

This worker did not stage, commit, push, publish, mutate credentials, or run
M34 behind an unapproved bypass.
