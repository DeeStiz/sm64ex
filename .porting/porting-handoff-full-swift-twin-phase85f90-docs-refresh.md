# Full Swift Twin Handoff — Phase 85f90 Documentation Refresh

Date: 2026-08-23

## Verdict

**DOCUMENTATION REFRESHED / PHASE 85f88 SNOWMAN WIND DISCOVERY RECORDED /
PHASE 85f89 SEAM IMPLEMENTED WITH FAIL-CLOSED REACHABILITY.** The six
first-party status surfaces now record the Phase 85f88 source-route discovery
and committed Phase 85f89 source-owned Snowman wind receipt seam. The seam is
implemented in commit `8e2ab88b`, but the authored Castle Inside Snowman's
Land route remained at `level=1 area=1 wind=0`; the route-pair matrix exited
`77` before creating a trace or admitting a route (`trace=not-created`,
`records=0`, `admission=0`). No source, behavior manifest, designated or
backup report, canonical route ledger, fixture, release artifact, or
unrelated worktree change was modified by this documentation refresh.

## Phase 85f89 Snowman wind seam result

The generated source route row `0xa98dae7d4d4559ab` resolves exactly once to
the authored `bhvSLSnowmanWind` program in `data/behavior_data.c`. Its direct
subject is the area-1 `MODEL_NONE` Snowman wind object in
`levels/sl/script.c`'s `script_func_local_3`, source order 1, with position
`(700,3428,700)`, face yaw `30`, and behavior parameter `0`. The normal
Castle Inside Snowman's Land painting route reaches Snowman's Land area 1.

The existing pointer-free Swift `SnowmanWindBehavior`/
`SnowmanWindObjectBridge` value owner is mapped exactly once in the behavior
manifest. Its isolated value contract fingerprint is
`0x0bb6ba5b32436749`; this is static owner evidence, not source-authored
lifecycle or route admission evidence.

The source-owned receipt seam is present for the selected row, but this phase
did not direct-load Snowman's Land, inject an object, call the behavior helper,
substitute a sibling or generic wind record, synthesize a trace, mutate the
behavior manifest, update either canonical report, or publish a route. The
selected row remains planned.

## Retained canonical boundary

The designated local canonical route report remains
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`
with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.
It contains 7,420 rows, 26 non-fixture terminal `passed`, and 7,394
`planned`, or `26/7420 = 0.350404313%`.

The historical write-once backup remains byte-identical at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`
with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
It contains 25 terminal `passed` and 7,395 `planned`, or
`25/7420 = 0.336927224%`; it remains backup evidence, not the designated
report. The source manifest remains 7,420 rows with SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
The behavior inventory remains 534 rows, 511 Swift value/owner rows, and 23
explicit C adapters, with behavior mapping at 95.693%. Conservative M34,
M35, human-acceptance, implementation, and full-goal floors remain 0%.

## Ordered handoffs

- [Phase 85f81 serial canonical designation](porting-handoff-full-swift-twin-phase85f81-serial-canonical-designation.md)
- [Phase 85f82 canonical status transition](porting-handoff-full-swift-twin-phase85f82-docs-canonical-transition.md)
- [Phase 85f83 WDW reachability recheck](porting-handoff-full-swift-twin-phase85f83-wdw-reachability-recheck.md)
- [Phase 85f84 TTC reachability recheck](porting-handoff-full-swift-twin-phase85f84-ttc-reachability-recheck.md)
- [Phase 85f85 Bob reachability recheck](porting-handoff-full-swift-twin-phase85f85-bob-reachability-recheck.md)
- [Phase 85f86 Spindrift reachability recheck](porting-handoff-full-swift-twin-phase85f86-spindrift-reachability-recheck.md)
- [Phase 85f87 documentation refresh](porting-handoff-full-swift-twin-phase85f87-docs-refresh.md)
- [Phase 85f88 Snowman wind discovery](porting-handoff-full-swift-twin-phase85f88-next-route-discovery.md)
- [Phase 85f89 Snowman wind seam execute](porting-handoff-full-swift-twin-phase85f89-snowman-wind-seam-execute.md)
- this Phase 85f90 documentation refresh
- [Phase 85f91 Snowman wind documentation correction](porting-handoff-full-swift-twin-phase85f91-docs-snowman-wind-correction.md)

## Documentation files changed

- `README.md`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md`
- `.porting/goal-continuation-luna-max-2026-08-20.md`
- `.porting/porting-memory.md`
- `CHANGES`
- this handoff

No source, behavior manifest, designated or backup report, canonical route
ledger, fixture, release artifact, or unrelated handoff was changed.

## Validation

Documentation-only checks performed after the refresh:

```text
Markdown local-link target audit for the seven scoped documents              passed
Trailing-whitespace audit for the seven scoped documents                     passed
git diff --check on the six scoped tracked documents                         passed
git diff --no-index --check /dev/null on this added handoff                  passed
  (added-file exit 1; no diagnostics)
```

No build, runtime, route-pair, sanitizer, manifest, report, M34, M35, or
human-acceptance test was rerun by this documentation-only phase. No staging,
commit, push, release, publication, or destructive cleanup was performed.
