# Full Swift Twin Handoff — Phase 85f36 Documentation Refresh

Date: 2026-08-22

## Verdict

**DOCUMENTATION REFRESHED / RETAINED CANONICAL STATE PRESERVED.** The
first-party status surfaces now record committed [Phase 85f35 DDD camera
reachability](porting-handoff-full-swift-twin-phase85f35-ddd-camera-reachability.md)
and its fail-closed boundary. No source, code, manifest, retained report,
canonical ledger, or vendored provenance was changed.

## Retained canonical counters and hashes

- Behavior inventory: 534 rows, 511 Swift value/owner rows, and 23 explicit C
  adapters; behavior mapping remains 95.693%.
- Retained checked-in route inventory: 7,420 rows with manifest SHA-256
  `23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
- Retained checked-in cumulative evidence: 25 terminal `passed`, 7,395
  `planned`, with report SHA-256
  `aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
- Retained live-route qualification: `25/7420 = 0.336927224%`.
- Conservative M34, M35, human-acceptance, and full-goal floors remain 0%.
- Phase 85f33's isolated intro result remains 26 terminal / 7,394 planned,
  report SHA-256
  `4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, with
  phase-local mapping `0x9a0f7b4f7ecf6c41 -> 0xca33981b30cb7815`; it is not
  checked-in canonical state.

## Phase 85f35 evidence surfaced

- The authored target is DDD area 1, reached through the real Castle area 3
  DDD painting route. The selected source observer is the owner-thread
  camera-water call after native `find_water_level`; no direct helper call or
  synthetic route was used.
- The bounded existing lifecycle probe returned exit status `77` and retained
  zero event-307 route records (`retained=0`), with no non-recipe records and
  no admission. The Swift one-record witness and tamper/partial/single-artifact
  checks are negative-fence machinery only, not native DDD evidence.
- The C trace and blocked rerun are both header-only 72-byte files with the
  identical SHA-256
  `a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512`.
  The exact artifact paths are retained outside the repository under
  `/private/tmp/phase85f35-ddd-camera-reachability.dhImgD/`.
- The exact unblock is a normal source-authored owner-thread traversal from an
  existing startup route into Castle area 3's DDD painting and then the DDD
  area-1 entry, with no direct level register/load, forced camera mode, Sushi
  injection, coordinate reuse, or direct `find_water_level` helper call.
  Until that recipe exists, the camera-water row remains planned and no
  manifest, cumulative report, route ledger, or canonical documentation may be
  mutated by an admission attempt.

## Documentation files changed

- `README.md`
- `docs/SM64Modern.md`
- `.porting/goal-full-swift-twin.md`
- `.porting/goal-continuation-luna-max-2026-08-20.md`
- `.porting/porting-memory.md`
- `CHANGES`
- `.porting/porting-handoff-full-swift-twin-phase85f36-docs-refresh.md`

Unrelated worktree edits, source/configuration changes, manifests, retained
canonical build reports, and prior handoffs remain untouched.

## Validation

The following documentation checks were run after the refresh:

```text
Markdown local-link target audit for the six scoped documents and this handoff
Trailing-whitespace audit for the same seven files
git -c core.fsmonitor=false diff --check -- README.md docs/SM64Modern.md \
  .porting/goal-full-swift-twin.md \
  .porting/goal-continuation-luna-max-2026-08-20.md \
  .porting/porting-memory.md CHANGES
```

No build, runtime, route-pair, sanitizer, manifest, report, M34, M35, or
human-acceptance test was rerun by this documentation-only phase.

## Commit boundary

No staging, commit, push, release, or destructive cleanup was performed. The
parent agent owns final verification and the scoped commit.
