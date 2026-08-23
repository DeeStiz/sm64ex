# Full Swift Twin Handoff — Phase 85f61 timebase fixture-drift diagnosis

Date: 2026-08-23

## Verdict

**DIAGNOSIS COMPLETE / FIXTURE UPDATE NOT AUTHORIZED.** The supporting
timebase audit still fails closed because its retained fixture is older than
the source-owned WDW express-elevator and TTC 2D-rotator receipt seams. The
fixture and audit script were not changed. No M34/M35, runtime, device, or
release evidence is claimed.

The Phase 85f60 checkpoint is commit `3c6d3185` (its recorded source snapshot
was `209a5407`). The retained fixture values match the last source baseline
at `6f586de9`:

```text
object_timer  166 files 715 matches
random_calls   79 files 289 matches
```

The current source audit reports:

```text
object_timer  166 files 718 matches
random_calls   79 files 290 matches
```

This same `715 -> 718` / `289 -> 290` mismatch was already recorded by the
Phase 85f60 audit; this diagnosis did not introduce it.

## Exact added matches

The per-file comparison against `6f586de9` found no category deltas outside
the two route-owner files:

| Category delta | Exact current source match | Attribution and classification |
| --- | --- | --- |
| `object_timer +1` | `src/game/behaviors/express_elevator.inc.c:10`: `const u32 timer = (u32) o->oTimer;` | Intentional scalar timer copy for the WDW elevator receipt seam, introduced by commit `380f14ae` (`feat: add WDW elevator receipt seam`). |
| `object_timer +1` | `src/game/behaviors/ttc_2d_rotator.inc.c:59`: `const s32 timerBefore = o->oTimer;` | Intentional pre-update timer copy for the TTC rotator receipt seam, introduced by commit `7651f380` (`feat: add TTC rotator receipt seam`). |
| `object_timer +1` | `src/game/behaviors/ttc_2d_rotator.inc.c:120`: `.timer_after = (u32) o->oTimer,` | Intentional post-update timer receipt field from the same TTC seam (`7651f380`). |
| `random_calls +1` | `src/game/behaviors/ttc_2d_rotator.inc.c:132`: `.random_u16 = randomU16,` | Intentional copied RNG receipt field from `7651f380`; it is not an added RNG call. The audit pattern counts the bare `random_u16` token anywhere in C, including this field label. |

The current WDW and TTC source blobs exactly match their authored seam
commits (`2c457add...` and `5e92af9a...`, respectively). Other dirty-worktree
paths do not contribute to either category delta. The source changes are
therefore intentional; the retained fixture is stale relative to them, and
the remaining dirty worktree is unrelated to this inventory drift.

## Evidence and boundaries

Read-only checks performed:

```text
bash script/test_timebase_audit.sh
  exit=1
  object_timer 166/715 -> 166/718
  random_calls 79/289 -> 79/290
  Time-dependent gameplay inventory changed; classify the drift before updating the fixture.

actual random-call syntax (`random_...(\s*\()`) against f60/current source:
  289 -> 289

git diff --quiet -- script/test_timebase_audit.sh tests/fixtures/sm64_modern_timebase_audit.tsv
  exit=0

git diff --check
  exit=0
```

At the diagnosis snapshot, the unchanged artifact hashes were:

```text
script/test_timebase_audit.sh       ec97ec4f9dcbd4a9fd3366c56708daaf82857059f4b7f49aa427b551491df7e3
tests/fixtures/sm64_modern_timebase_audit.tsv
                                    b6869708bca3f3dc6b27754fc12d44ee427d2d7296a8f08013d0b9a35f15c4b2
```

No fixture, source, manifest, report, shared documentation, commit, or
publication was changed by this diagnosis. Updating the fixture requires a
separate explicit decision after the route-source inventory is accepted.
