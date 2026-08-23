# Full Swift Twin Handoff — Phase 85f51 Documentation Correction

Date: 2026-08-23

## Verdict

**DOCUMENTATION CORRECTED / RETAINED CANONICAL STATE PRESERVED.** The six
first-party status surfaces had left an outdated Phase 85f49 boundary even
though its committed reachability handoff is present. They now record the
authored WDW area-1 reachability result and link the f49 handoff between the
f48 refresh and the f50 refresh, followed by this correction. No source, code,
manifest, retained report, canonical route ledger, or vendored provenance was
changed.

## Retained canonical boundary

- Behavior inventory remains 534 rows: 511 Swift value/owner rows and 23
  explicit C adapters; behavior mapping remains 95.693%.
- Retained checked-in route inventory remains 7,420 rows with manifest SHA-256
  `23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
- Retained checked-in cumulative evidence remains exactly 25 terminal
  `passed` and 7,395 `planned`, with report SHA-256
  `aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
- Retained live-route qualification remains `25/7420 = 0.336927224%`.
- The Phase 85f33 isolated, phase-local result remains 26 terminal / 7,394
  planned (`26/7420 = 0.350404313%`) and is not checked-in canonical state.
- M34, M35, human-acceptance, and full-goal floors remain 0%.

## Phase 85f49 actual result

The authored Castle-to-WDW painting route targets warp node `0x0A`. The normal
owner-thread lifecycle lands in WDW area 2 before the dynamic
`bhvWdwExpressElevator` can tick. The bounded matrix therefore fails closed
with `dynamic=0`, `static=0`, `admission=0`,
`canonical_ledger_mutation=0`, `manifest_mutation=0`, and exit 77. No C or
Swift trace was created (`trace=not-created`, `records=0`), no route record or
admission was produced, and the static sibling was not substituted. The
retained canonical 25/7,395 and isolated 26/7,394 facts are unchanged; no
M34, M35, human-acceptance, or full-goal floor moved from 0%.

## Documentation files changed

- `README.md`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md`
- `.porting/goal-continuation-luna-max-2026-08-20.md`
- `.porting/porting-memory.md`
- `CHANGES`
- `.porting/porting-handoff-full-swift-twin-phase85f50-docs-refresh.md`
- `.porting/porting-handoff-full-swift-twin-phase85f51-docs-f49-correction.md`

Unrelated dirty and untracked worktree edits, source/configuration files,
manifests, retained reports, prior handoffs, and build artifacts were left
untouched.

## Validation

Documentation-only checks performed after the correction:

```text
Markdown local-link target audit for the eight scoped documents
Trailing-whitespace audit for the same eight files
git diff --check on the six scoped tracked documents
git diff --no-index --check /dev/null on this added handoff
  (added-file exit 1; no diagnostics)
```

No build, runtime, route-pair, sanitizer, manifest, report, M34, M35, or
human-acceptance test was rerun by this documentation-only phase. No staging,
commit, push, release, or destructive cleanup was performed.
