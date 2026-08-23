# Full Swift Twin Handoff — Phase 85f65 timebase fixture proposal

Date: 2026-08-23

## Verdict

**PROPOSAL ONLY / RETAINED AUDIT STILL FAILS CLOSED.** Starting from the
Phase 85f61 diagnosis, the current timebase inventory was compared with the
recorded source baseline `6f586de9`. The only category drift is the
intentional WDW/TTC receipt-field inventory: `object_timer` changes from 715
to 718 matches and the raw `random_calls` token count changes from 289 to
290. The retained fixture and audit script were not changed, and this handoff
does not claim that the retained audit passes.

The Phase 85f61 diagnosis commit is
`431bea5fdffc90ab97f3f4e47926e52bc4accd28`. The snapshot is branch
`nightly`, HEAD `ddcbf29ccc5125bb3733c096e47ec7f65a2da34a`. The retained
fixture hash remains
`b6869708bca3f3dc6b27754fc12d44ee427d2d7296a8f08013d0b9a35f15c4b2`; the
unchanged audit script hash is
`ec97ec4f9dcbd4a9fd3366c56708daaf82857059f4b7f49aa427b551491df7e3`.

## Isolated source comparison

The baseline/current inventory is:

| Category | Baseline | Current | Classification |
| --- | ---: | ---: | --- |
| `object_timer` | 166 files / 715 matches | 166 files / 718 matches | intentional WDW/TTC receipt fields |
| `mario_action_timer` | 8 / 206 | 8 / 206 | unchanged |
| `global_timer` | 33 / 46 | 33 / 46 | unchanged |
| `random_calls` | 79 / 289 | 79 / 290 | one TTC receipt-field token |
| `animation_sites` | 62 / 790 | 62 / 790 | unchanged |

The per-file deltas are limited to:

- `src/game/behaviors/express_elevator.inc.c:10` — WDW `oTimer` copy for
  the elevator receipt (`object_timer +1`).
- `src/game/behaviors/ttc_2d_rotator.inc.c:59` — TTC pre-update
  `timerBefore` copy (`object_timer +1`).
- `src/game/behaviors/ttc_2d_rotator.inc.c:120` — TTC `timer_after` receipt
  field (`object_timer +1`).
- `src/game/behaviors/ttc_2d_rotator.inc.c:132` — TTC `.random_u16` receipt
  field label (`random_calls +1`); this is not an additional RNG call.

The current raw `random_calls` inventory is 290. Excluding the one known
`.random_u16` receipt-field label leaves the actual RNG-call inventory at
289, equal to the baseline. No other timebase inventory category or source
file contributes drift.

## Proposed fixture diff (not applied)

The isolated proposal changes exactly these two rows:

```diff
--- tests/fixtures/sm64_modern_timebase_audit.tsv
+++ proposed-sm64_modern_timebase_audit.tsv
@@
-object_timer	166	715
+object_timer	166	718
@@
-random_calls	79	289
+random_calls	79	290
```

The proposed fixture is not the retained fixture and is not checked in. Its
SHA-256 is `cc39afb566d3876e5d1c8228fb6de8b10fc2daa031c171d6690036c368706d0e`;
the isolated diff SHA-256 is
`3fb37039e1366020651daf7561435384b69fdacf8883ef427efbd955b0d39d8e`.

## Validation

Read-only and isolated checks performed:

```text
bash script/test_timebase_audit.sh
  exit=1
  retained fixture mismatch: object_timer 715 -> 718; random_calls 289 -> 290
  Time-dependent gameplay inventory changed; classify the drift before updating the fixture.

temporary audit script using only the /tmp proposed fixture
  exit=0  SM64 Modern timebase audit passed
  (This is proposal validation only; the retained fixture was never replaced.)

bash -n script/test_timebase_audit.sh
  exit=0

git diff --quiet -- script/test_timebase_audit.sh \
  tests/fixtures/sm64_modern_timebase_audit.tsv
  exit=0  retained script and fixture unchanged

git diff --check
  exit=0

isolated proposal diff-shape assertion
  exact two intended row replacements
```

No source, retained fixture, manifest, report, route ledger, shared
documentation, build output, runtime state, commit, or publication was
modified by this phase. The only repository artifact is this handoff.

The isolated evidence directory is:

```text
/tmp/sm64-modern-timebase-fixture-proposal.buSh57/
```

It contains the proposed fixture, unified diff, baseline/current category
counts, per-file deltas, RNG-call check, temporary validation output, and the
consolidated `proposal-summary.txt`. Updating the retained fixture remains a
separate explicit decision.
