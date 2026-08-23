# Full Swift Twin Handoff — Phase 85f87 Documentation Refresh

Date: 2026-08-23

## Verdict

**DOCUMENTATION REFRESHED / FOUR FRESH REACHABILITY RECHECKS RECORDED.** The
six first-party status surfaces now record the Phase 85f83 WDW,
Phase 85f84 TTC, Phase 85f85 Bob, and Phase 85f86 Spindrift reachability
rechecks in order. All four authored routes remain fail-closed: each exited
77 from a fresh build root without creating a C or Swift trace, producing a
route record, or admitting a route. No source, behavior manifest, designated
or backup report, canonical route ledger, fixture, release artifact, or
unrelated worktree change was modified by this documentation phase.

## Fresh reachability rechecks

- **Phase 85f83 WDW** reran the committed `380f14ae` express-elevator seam.
  The authored Castle Inside painting route observed
  `level=11 area=2 dynamic=0 static=0` and exited 77. No trace was created,
  no dynamic receipt or route record was produced, and admission remained 0.
- **Phase 85f84 TTC** reran the committed `7651f380` 2D-rotator seam. The
  authored route observed `level=14 area=2 hands=0` and exited 77. The fresh
  root contains no C, ASan, Release, rerun, or Swift trace, and admission
  remained 0.
- **Phase 85f85 Bob** reran the committed
  `d06d84850bd0dd7e81e625b0ef23503d0c17c0c4` seesaw seam. The authored route
  observed `level=1 area=1 object=0` and exited 77. No C or Swift trace,
  route record, or admission was produced.
- **Phase 85f86 Spindrift** reran the committed `eb3fbf8a` seam. The authored
  route observed `level=1 area=1 spindrifts=0` and exited 77. The fresh root
  has no C or Swift trace (`trace=not-created`, `records=0`), and admission
  remained 0.

None of the four rechecks used a static sibling or variant substitution,
synthetic trace, direct level load, object injection, behavior-helper call,
coordinate match, or canonical mutation. Their dependent ASan, optimized,
persistent-rerun, Swift-pair, tamper, and negative-fixture gates therefore
remain deferred until a genuine source-authored owner-thread receipt exists.

## Designated local canonical evidence

The designated local canonical route report remains
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`
with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.
It contains 7,420 rows: 26 non-fixture terminal `passed` and 7,394
`planned`, or `26/7420 = 0.350404313%`.

The old retained report remains byte-identical as the write-once backup at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`
with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
It contains 25 terminal `passed` and 7,395 `planned`, or
`25/7420 = 0.336927224%`; it is historical backup evidence, not the
designated report. The generated source manifest remains unchanged at 7,420
rows with SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Behavior mapping remains 95.693%. Conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%.

## Ordered handoffs

- [Phase 85f81 serial canonical designation](porting-handoff-full-swift-twin-phase85f81-serial-canonical-designation.md)
- [Phase 85f82 canonical status transition](porting-handoff-full-swift-twin-phase85f82-docs-canonical-transition.md)
- [Phase 85f83 WDW reachability recheck](porting-handoff-full-swift-twin-phase85f83-wdw-reachability-recheck.md)
- [Phase 85f84 TTC reachability recheck](porting-handoff-full-swift-twin-phase85f84-ttc-reachability-recheck.md)
- [Phase 85f85 Bob reachability recheck](porting-handoff-full-swift-twin-phase85f85-bob-reachability-recheck.md)
- [Phase 85f86 Spindrift reachability recheck](porting-handoff-full-swift-twin-phase85f86-spindrift-reachability-recheck.md)
- this Phase 85f87 documentation refresh

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
Markdown local-link target audit for the seven scoped documents       passed
Trailing-whitespace audit for the seven scoped documents              passed
git diff --check on the six scoped tracked documents                  passed
git diff --no-index --check /dev/null on this added handoff           passed
  (added-file exit 1; no diagnostics)
```

No build, runtime, route-pair, sanitizer, manifest, report, M34, M35, or
human-acceptance test was rerun by this documentation-only phase. No staging,
commit, push, release, publication, or destructive cleanup was performed.
