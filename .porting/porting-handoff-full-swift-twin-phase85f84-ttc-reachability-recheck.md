# Full Swift Twin Handoff — Phase 85f84 TTC Rotator Reachability Recheck

Date: 2026-08-23

## Verdict

**REACHABILITY REMAINS BLOCKED / FAIL CLOSED / NO ADMISSION.** The existing
TTC 2D rotator route-pair matrix was rerun from a fresh root against the
committed Phase 85f53 seam (`7651f380`). The owner-thread route still reports
`LEVEL_TTC` with `area=2` and zero authored clock hands, so no rotator receipt
or trace window is opened.

The authored Castle-to-TTC route remains the source painting family
`0x21`/`0x22`/`0x23` to TTC area 1 node `0x0A`. The run did not direct-load TTC,
inject a macro object, call a behavior helper, or substitute a cog/static
sibling.

## Runtime recheck

The matrix was run read-only with a caller-owned fresh build parent:

```text
SM64_TTC_ROTATOR_ROUTE_BUILD_PARENT=/tmp/phase85f84-ttc-reachability-rerun.lm22EB \
  bash script/test_ttc_2d_rotator_route_pair.sh
```

Fresh run root:

```text
/tmp/phase85f84-ttc-reachability-rerun.lm22EB/run.coe58Q
```

The native Debug runtime log produced:

```text
ttc_2d_rotator_route_unreachable level=14 area=2 hands=0
SM64 Modern TTC 2D rotator route pair blocked reachability=0
source_lifecycle=castle_inside_painting_nodes_0x21_0x22_0x23_to_ttc_area1
first_clock_hand_receipt=absent cog_substitution=0 fixture_only=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

The matrix process exit was `77`. The fresh root contains the Debug native
build and route log, but no `ttc-2d-rotator-c.trace`, ASan, Release, rerun, or
Swift trace artifact was created. Because the authored first clock hand was
not reachable, the matrix correctly stopped before cross-build parity,
Swift pairing, tamper/negative fences, and admission.

The script's source fences passed: the authored Castle painting nodes and TTC
clock-hand macro are present, the semantic `bhvTTC2DRotator` identity is
declared, and neither the route observer nor focused probe contains pointer,
level-load, object-spawn, or behavior-helper substitutions. The runtime line
`cog_substitution=0` confirms that no cog sibling was used.

## Validation and scope

- `7651f380` is an ancestor of the checked-out `444dcecb`; the committed seam
  remained unchanged during this recheck.
- Pre-existing worktree edits in `src/game/game_init.c` and
  `src/pc/sm64_modern_gameplay_parity.c` were left untouched.
- `git -c core.fsmonitor=false diff --check` passed after the run.
- No manifest, canonical ledger, retained/backup report, or other document
  was changed by the matrix. This handoff is the only artifact created by
  this phase.

The route remains blocked until the normal source-authored Castle Inside
painting lifecycle establishes TTC area 1 and keeps the first clock hand alive
long enough to emit its receipt. Do not bypass that lifecycle or use a cog
substitute as an unblock.
