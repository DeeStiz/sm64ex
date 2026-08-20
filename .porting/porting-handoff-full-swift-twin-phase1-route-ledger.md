# SM64 Modern Full Swift Twin — Phase 1 Route Ledger Handoff

## What was done

The continuation checkpoint is `da4fa9ae`. The current arm64 Debug bundle built,
was ad-hoc signed, launched through LaunchServices, presented Metal 4 frame one,
and shut down cleanly with `application_stopped`. The prior
`kLSNoExecutableErr (-10827)` result is retained as historical/transient host
evidence; no source-local AppKit fix was justified. The real input-only promotion
shard `0xd9446dfed10e189e` passed with `fixture_only=0`, exact C/Swift replay,
coverage, and persistent rerun rejection.

The serial `SM64RouteShardMergeTool` accepts isolated worker-result files and
emits the existing six-field ledger report plus an optional metadata sidecar. It
rejects duplicate or unknown IDs, missing rows, invalid transitions, fixture-only
evidence, malformed terminal evidence, inconsistent shared fingerprints, and
non-canonical output ordering. Its strict Swift 6 smoke is
`script/test_route_shard_merge.sh`.

## Ground-truth checks

Passed:

- `./script/test_route_shards.sh` — inventory `7419`, manifest `7419`,
  deterministic/canonical, status `planned`.
- `./script/test_route_shard_replay.sh` — 14 C/Swift fixture shards,
  byte-identical traces, ledger fences, and persistent rerun rejection.
- `./script/test_route_shard_merge.sh` — canonical merge, duplicate/unknown/
  missing/transition/fixture/fingerprint rejection, terminal evidence checks.
- `./script/test_live_route_promotion.sh` — live shard
  `0xd9446dfed10e189e`, `fixture_only=0`, C/Swift replay and coverage.
- Focused host Debug build and launch — `application_ready`,
  `metal_scene_presented frame=1`, status-0 engine shutdown, and
  `application_stopped`.
- `git diff --check` and local Markdown-link checks.

These checks do not close the 7,419-row live route ledger, sanitizer parity,
visual/physical Metal acceptance, release packaging, or human acceptance.

## What's deferred

- Existing route workers do not yet emit the new worker-result schema; the next
  orchestration phase must produce one isolated result file per worker before
  invoking the merge tool.
- All canonical route rows remain `planned` until real C/Swift schema-4 replay
  evidence is persisted; fixture replay never counts as live qualification.
- Remaining C-adapter rows require disjoint family migration or an explicit
  compatibility/fallback classification before final Swift-authority closure.

## Known issues and watch-for

- Only one app launch may run at a time; use isolated save/trace/derived-data
  directories and do not let workers write the consolidated report concurrently.
- Do not commit raw ROM-derived traces or generated asset payloads.
- The old LaunchServices `-10827` log must remain labeled historical; a future
  recurrence is a host blocker, not a gameplay or Metal failure.
- M34 still needs warmed post-resume presentation, archive reuse, visual/device
  evidence, and the separate physical performance/thermal gates.

## Key decisions

- The coordinator owns central dispatch, manifest, build, project, goal, memory,
  and handoff files; workers own isolated result files and route-local tools or
  tests only.
- Workers never commit. The coordinator stages an explicit phase allowlist,
  verifies the exact commit SHA, reports the evidence, and does not push.
- The next route wave should use immutable manifest ranges of 256 rows, unique
  temporary output directories, and serial ledger integration.

## Skills needed next

`porting-methodology`, `porting-start-milestone`, `porting-execute`,
`porting-validate`, `porting-handoff`, `using-metal-validation`,
`using-gpucapture`, `using-gpudebug`, and the relevant Swift/macOS build and
concurrency skills.
