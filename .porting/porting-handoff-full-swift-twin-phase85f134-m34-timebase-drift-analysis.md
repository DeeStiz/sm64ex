# Full Swift Twin Handoff — Phase 85f134 M34 timebase-drift analysis

Date: 2026-08-24 (EDT)

## Scope and verdict

**ANALYSIS COMPLETE / RETAINED FIXTURE NOT UPDATED / M34 GUARD REMAINS
BLOCKED.** This phase read the unchanged timebase audit script, retained
fixture, governing cadence inventory, source history, and the Phase 85f133
M34 production-run handoff. It did not run the M34 production harness, change
source or fixture files, or commit.

The `object_timer` mismatch is fully attributable to intentional source-owned
route-receipt instrumentation added after the fixture baseline. The
`random_calls` mismatch is one lexical receipt-field label in the TTC receipt
packet, not an additional RNG draw: callable random syntax remains 289 in both
the baseline and current source. This is a classified source/fixture drift,
not evidence of a timebase semantic regression. Static attribution alone does
not prove runtime behavior, C/Swift route pairing, M34 presentation, cadence,
thermal, physical, or human acceptance.

The retained fixture remains the last accepted value and the audit still
fails closed until its owner separately approves a fixture decision:

```text
object_timer       fixture 166 files / 715 matches -> current 166 / 734
random_calls       fixture  79 files / 289 matches -> current  79 / 290
```

## Repository and baseline anchors

The source/fixture baseline is commit `6f586de9` (`Advance Full Swift twin
through M33nk route batch`), which is also the fixture's last source-era
baseline. The read-only analysis ran at:

```text
HEAD=9cdf2f013cde6c425e17adac3c659937c60aecab
HEAD_time=2026-08-24 08:26:12 -0400
fixture_baseline=6f586de9ba16024ff0463b6f24869a896a4eeb62
```

The Phase 85f133 handoff records that the unchanged production command
stopped at its mandatory Release-build preflight when this same audit found
the mismatch. It produced no Release bundle, runtime, trace, attachment,
cadence, or thermal evidence. This phase did not retry that production
command.

## Audit contract and exact guard result

`script/test_timebase_audit.sh` counts source tokens in `src/game` and
`src/engine` with these patterns:

```text
object_timer       \boTimer\b
mario_action_timer \bactionTimer\b
global_timer       \bgGlobalTimer\b
random_calls       \brandom_(u16|float|sign|fixed_seed)\b
animation_sites    anim(Frame|Accel)|AnimFrame|set_mario_anim|cur_obj_init_animation|cur_obj_check_if_near_animation_end
```

It writes a temporary actual inventory, compares it byte-for-byte to
`tests/fixtures/sm64_modern_timebase_audit.tsv`, and emits
`Time-dependent gameplay inventory changed; classify the drift before updating the fixture.`
before returning exit `1` on a mismatch. The cadence-manifest validation is
after that comparison, so this run stopped at the expected drift guard.

Exact command and result:

```sh
set +e
bash script/test_timebase_audit.sh > /tmp/sm64-modern-phase85f134-timebase-audit.out 2>&1
rc=$?
set -e
cat /tmp/sm64-modern-phase85f134-timebase-audit.out
echo "exit=$rc"
```

```text
--- /Users/derek/Developer/sm64ex/tests/fixtures/sm64_modern_timebase_audit.tsv
+++ /var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T//sm64-modern-timebase-audit.kn6ARy
@@ -1,6 +1,6 @@
 category	files	matches
-object_timer	166	715
+object_timer	166	734
 mario_action_timer	8	206
 global_timer	33	46
-random_calls	79	289
+random_calls	79	290
 animation_sites	62	790
Time-dependent gameplay inventory changed; classify the drift before updating the fixture.
exit=1
```

The guard therefore shows exactly two changed rows; the other three aggregate
categories remain identical. The retained fixture itself remains:

```text
category	files	matches
object_timer	166	715
mario_action_timer	8	206
global_timer	33	46
random_calls	79	289
animation_sites	62	790
```

## Exact source attribution of `object_timer` +19

A per-file comparison of the current source against the baseline commit found
no category delta outside these seven source-owned behavior files. The added
tokens are timer snapshots copied into route-receipt inputs (`timerBefore`,
`timer`, or `.timer_before`/`.timer_after`), not new timer storage or an
additional timer-update site:

| Receipt commit | Source file and current lines | Baseline -> current | Classification |
| --- | --- | ---: | --- |
| `380f14ae` — `feat: add WDW elevator receipt seam` | `src/game/behaviors/express_elevator.inc.c:10` (`timer`) | 2 -> 3 (+1) | WDW express-elevator receipt snapshot |
| `7651f380` — `feat: add TTC rotator receipt seam` | `src/game/behaviors/ttc_2d_rotator.inc.c:59,120` (`timerBefore`, `.timer_after`) | 2 -> 4 (+2) | TTC rotator receipt before/after fields |
| `eb3fbf8a` — `feat: add Spindrift receipt seam` | `src/game/behaviors/spindrift.inc.c:28,74` (`timerBefore`, `.timer_after`) | 1 -> 3 (+2) | Spindrift receipt before/after fields |
| `91e53c7f` — `feat: add Spindel receipt seam` | `src/game/behaviors/spindel.inc.c:23,125` (`timerBefore`, `.timer_after`) | 6 -> 8 (+2) | Spindel receipt before/after fields |
| `8e2ab88b` — `feat: add Snowman wind receipt seam` | `src/game/behaviors/sl_snowman_wind.inc.c:19,94` (`timerBefore`, `.timer_after`) | 1 -> 3 (+2) | Snowman-wind receipt before/after fields |
| `904bffa3` — `feat: add JRB treasure receipt seam` | `src/game/behaviors/treasure_chest.inc.c:88,155,173,247,326,327,348,388` | 3 -> 11 (+8) | JRB treasure root/top/bottom receipt timer fields |
| `66ca1911` — `feat: add Whomp King receipt seam` | `src/game/behaviors/whomp.inc.c:256,354` (`timerBefore`, `.timer_after`) | 8 -> 10 (+2) | Whomp King receipt before/after fields |
| **Total** | **seven files** | **23 -> 42 (+19)** | **receipt instrumentation only** |

The total row is the sum of category occurrences in the seven files; the
fixture-wide inventory is `166 files / 715 -> 166 / 734` because the other 159
files are unchanged for this category.

The exact read-only per-file command and result were:

```sh
for f in $(rg -l -g '*.c' '\boTimer\b' src/game src/engine | sort); do
  old=$(git show 6f586de9:$f 2>/dev/null | rg -o '\boTimer\b' | wc -l | tr -d ' ')
  new=$(rg -o '\boTimer\b' "$f" | wc -l | tr -d ' ')
  if [[ "$old" != "$new" ]]; then
    printf 'object_timer\t%s\t%s\t%s\t%s\n' "$f" "$old" "$new" "$((new-old))"
  fi
done
```

```text
object_timer\tsrc/game/behaviors/express_elevator.inc.c\t2\t3\t1
object_timer\tsrc/game/behaviors/sl_snowman_wind.inc.c\t1\t3\t2
object_timer\tsrc/game/behaviors/spindel.inc.c\t6\t8\t2
object_timer\tsrc/game/behaviors/spindrift.inc.c\t1\t3\t2
object_timer\tsrc/game/behaviors/treasure_chest.inc.c\t3\t11\t8
object_timer\tsrc/game/behaviors/ttc_2d_rotator.inc.c\t2\t4\t2
object_timer\tsrc/game/behaviors/whomp.inc.c\t8\t10\t2
```

## Exact source attribution of `random_calls` +1

The only raw-token delta is in the TTC rotator receipt seam:

```text
src/game/behaviors/ttc_2d_rotator.inc.c:82   randomU16 = random_u16();
src/game/behaviors/ttc_2d_rotator.inc.c:132  .random_u16 = randomU16,
```

At the fixture baseline the source had the one direct call:

```text
src/game/behaviors/ttc_2d_rotator.inc.c:70   if (random_u16() & 0x3) {
```

The receipt commit moved that same call into a local so the random result could
be copied into the fixed-width packet, then added the `.random_u16` field.
The broad audit pattern counts both the function token and the field label,
so the raw category changes `289 -> 290`; it does not represent a second RNG
draw.

Exact callable-syntax cross-check:

```text
current:  random_(u16|float|sign|fixed_seed)\s*\(  -> 79 files / 289 matches
baseline: random_(u16|float|sign|fixed_seed)\s*\(  -> 79 files / 289 matches
```

The raw-token per-file comparison was:

```text
random_calls\tsrc/game/behaviors/ttc_2d_rotator.inc.c\t1\t2\t1
```

This is therefore instrumentation vocabulary drift under the existing broad
audit pattern, not a real random-sequence/timebase semantic drift. Changing
the audit pattern to count calls only would itself be a separate script
change and is not authorized by this phase.

## Commands and invariant checks

The retained inputs were syntax-checked and hashed without modification:

```text
bash -n script/test_timebase_audit.sh
  bash_n_exit=0

ec97ec4f9dcbd4a9fd3366c56708daaf82857059f4b7f49aa427b551491df7e3  script/test_timebase_audit.sh
b6869708bca3f3dc6b27754fc12d44ee427d2d7296a8f08013d0b9a35f15c4b2  tests/fixtures/sm64_modern_timebase_audit.tsv

git -c core.fsmonitor=false diff --check
  diff_check_exit=0

git diff --quiet -- script/test_timebase_audit.sh tests/fixtures/sm64_modern_timebase_audit.tsv
  retained_audit_inputs_unchanged_exit=0
```

No production harness, Release build, app launch, GPU capture/replay, route
runtime, or host/display mutation was performed by this phase. Before this
handoff was created, the worktree was clean; the only new repository artifact
is this handoff. No source, fixture, cadence manifest, route ledger, report,
credential, or build artifact was changed.

## Evidence and approval required before any fixture update

The static classification is sufficient to explain the mismatch, but not to
silently rewrite the retained contract. Before changing
`tests/fixtures/sm64_modern_timebase_audit.tsv`, the next owner must obtain
all of the following:

1. **Explicit fixture authorization.** Approve the exact two-row update
   (`object_timer 166/715 -> 166/734` and `random_calls 79/289 -> 79/290`),
   or explicitly authorize a separately reviewed audit-pattern change. No
   fixture edit is implied by this analysis or by the failed M34 preflight.
2. **Fresh source-inventory confirmation.** From a stable target checkout,
   rerun the aggregate audit and per-file attribution, confirm that only the
   seven named receipt-seam files contribute `object_timer +19`, and confirm
   callable RNG syntax remains `79/289`. Any additional delta must stop the
   update and be classified independently.
3. **Receipt-seam evidence boundary.** Preserve the source commit subjects,
   source-owned route identities, and focused C/Swift contract/harness
   results as provenance. The route execute handoffs currently report strict
   compile/contract coverage but fail closed at real route reachability
   (exit 77) for the new seams; no positive receipt or route admission may be
   inferred from the static instrumentation. A positive runtime route is not
   required to call the lexical tokens intentional, but it remains required
   for route admission and parity claims.
4. **Post-update validation.** After and only after approval, apply the
   allowlisted two-row fixture edit, rerun `bash script/test_timebase_audit.sh`,
   validate the cadence manifest and focused timebase/route contracts, then
   review the exact diff. Keep the fixture update separate from any M34
   production or release commit decision.

## Next gate

Immediate next gate: parent/owner review of this attribution and explicit
approval for (or rejection of) the two-row fixture update. Until then, retain
the old fixture and accept the audit's exit `1` as the correct fail-closed
result.

If the update is approved and independently validated, the next M34 gate is
the unchanged host/production sequence from a stable checkout:

```sh
bash script/test_m34_host_readiness.sh

M34_OUTPUT_DIR="$(mktemp -d /private/tmp/sm64-modern-m34-phase85f134.XXXXXX)"
SM64_MODERN_M34_OUTPUT_DIR="$M34_OUTPUT_DIR" \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
bash script/test_metal4_production.sh
```

That later run must independently produce Release/runtime/GPU/cadence and
thermal evidence; a passing audit or updated fixture does not promote any of
those M34 gates. Parent owns the approval and any later fixture/source
decision. This worker did not commit or push.
