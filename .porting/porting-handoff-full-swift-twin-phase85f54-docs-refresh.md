# Full Swift Twin Handoff — Phase 85f54 Documentation Refresh

Date: 2026-08-23

## Verdict

**DOCUMENTATION REFRESHED / RETAINED CANONICAL STATE PRESERVED.** The
first-party status surfaces now record the actual Phase 85f49 WDW area-2
reachability blocker, the Phase 85f50/f51 documentation correction history,
and the Phase 85f52 authored TTC 2D rotator discovery. Phase 85f53 is marked
pending because no completed handoff or route evidence is present at this
refresh. No source, code, manifest, retained report, canonical route ledger,
or vendored provenance was changed.

## Retained canonical boundary

- Behavior inventory remains 534 rows: 511 Swift value/owner rows and 23
  explicit C adapters; behavior mapping remains 95.693%.
- Retained checked-in route inventory remains 7,420 rows with manifest SHA-256
  `23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
- Retained checked-in cumulative evidence remains exactly 25 terminal `passed`
  and 7,395 `planned`, with report SHA-256
  `aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
- Retained live-route qualification remains `25/7420 = 0.336927224%`.
- The Phase 85f33 isolated, phase-local result remains 26 terminal / 7,394
  planned (`26/7420 = 0.350404313%`) and is not checked-in canonical state;
  its local-to-canonical mapping remains
  `0x9a0f7b4f7ecf6c41 -> 0xca33981b30cb7815`.
- Conservative M34, M35, human-acceptance, and full-goal floors remain 0%.

## Phase 85f49 actual WDW result

The authored Castle-to-WDW painting route targets warp node `0x0A`, but the
normal owner-thread lifecycle lands in WDW area 2 before the dynamic
`bhvWdwExpressElevator` can tick. The bounded matrix fails closed with
`dynamic=0`, `static=0`, `admission=0`, `canonical_ledger_mutation=0`,
`manifest_mutation=0`, and exit 77. No C or Swift trace was created
(`trace=not-created`, `records=0`); no route record or admission was produced,
and the static sibling was not substituted. Canonical counters and all
external acceptance floors remain unchanged.

## Phase 85f50/f51 correction history

Phase 85f50 refreshed the first-party status surfaces while preserving the
retained canonical state. Phase 85f51 corrected the f49 ordering and status
wording so the actual f49 reachability blocker supersedes the earlier f47-
pending description. Neither documentation correction changed a manifest,
report, route ledger, or acceptance state.

## Phase 85f52 TTC discovery

Phase 85f52 selected the next disjoint source-owned candidate,
`bhvTTC2DRotator`, at route row `0x1af5669b06931d93`. The selected authored
subject is the first TTC area-1 clock hand (`MODEL_TTC_CLOCK_HAND`,
`oBehParams2ndByte=0`) reached through the normal Castle Inside TTC painting
nodes `0x21`–`0x23`. The existing Swift value owner and isolated C contract
are present, but no native TTC lifecycle probe, schema-4 pair, admission, or
canonical mutation was performed; the candidate remains planned.

Phase 85f53 is explicitly pending. No completed handoff, native TTC lifecycle
probe, route pair, admission, or canonical mutation is recorded for it.

## Documentation files changed

- `README.md`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md`
- `.porting/goal-continuation-luna-max-2026-08-20.md`
- `.porting/porting-memory.md`
- `CHANGES`
- `.porting/porting-handoff-full-swift-twin-phase85f54-docs-refresh.md`

Unrelated dirty and untracked worktree edits, source/configuration files,
manifests, retained reports, prior handoffs, and build artifacts were left
untouched.

## Validation

Documentation-only checks performed after the refresh:

```text
Markdown local-link target audit for the seven scoped documents
Trailing-whitespace audit for the same seven files
git diff --check on the six scoped tracked documents
git diff --no-index --check /dev/null on this added handoff
  (added-file exit 1; no diagnostics)
```

No build, runtime, route-pair, sanitizer, manifest, report, M34, M35, or
human-acceptance test was rerun by this documentation-only phase. No staging,
commit, push, release, or destructive cleanup was performed.
