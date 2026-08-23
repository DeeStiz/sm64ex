# Full Swift Twin Handoff — Phase 85f111 M34 Metal 4 production audit

Date: 2026-08-23 08:45 EDT

## Scope and verdict

This phase performed a fresh, bounded, read-only M34 production audit against
the current worktree and host. It read the current full-Swift-twin goal and
M34 handoffs, inspected `build/` artifacts, checked host/GPU-tool readiness,
and reran source/parser contracts. No source, manifest, report, route ledger,
goal, memory file, release/store state, credential, display/power setting, or
unrelated dirty edit was changed. No Simulator was used or substituted.

**M34 remains blocked and fail-closed.** The current host gate reports
`m34_host_ready=0` because the only detected display is offline and the
console session is locked. `gputoolsserviced` is not running and no GPU session
is active. Consequently, no current Release launch, two-pass validation run,
GPU capture/replay, attachment fetch, pixel comparison, cadence/soak,
direct-display interaction, or physical/human acceptance was admissible.

The current goal document is `.porting/goal-full-swift-twin.md` (latest status
Phase 85f107). The latest M34-specific evidence remains the M34c warm-pipeline
handoff and the Phase 85f2/85f20/85f41/85f46/85f60 read-only audits. No
`build/.porting` directory exists; M34 build/audit artifacts are under
`build/` and historical scratch paths outside the repository.

## Repository snapshot

```text
branch=nightly
HEAD=abb5d06c86c8dfdcafc3112c468ca5adc5398b14
pre-existing_status_count=445
```

The worktree was already heavily dirty with unrelated source, test, script,
and handoff changes. Those changes were preserved. This file is the only
repository artifact created by this phase; the parent owns the automatic
commit decision.

## Fresh host and tooling evidence

The unchanged host gate was run at `2026-08-23T08:43 EDT`:

```sh
bash script/test_m34_host_readiness.sh
```

It returned exit `1`:

```text
m34_host_os=27.0
m34_host_metal_tool=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
m34_host_gpucapture=/usr/bin/gpucapture
m34_host_gpudebug=/usr/bin/gpudebug
m34_host_display_count=1 online=0 asleep=0
m34_host_console_locked=Yes session_locked=Yes user_active=unknown
m34_host_thermal=unknown
m34_host_ready=0 blockers=one or more displays are offline/asleep;console session is locked
```

Independent read-only queries corroborated the boundary:

```text
macOS 27.0 / build 26A5416b
GPU=Apple M5 Max, 40 cores; Metal supported; no online physical-display record
IOConsoleLocked=Yes; CGSSessionScreenIsLocked=Yes
gputoolsserviced=state not running; active count=0; program=/usr/libexec/gputoolsserviced
gpudebug --list-devices=local MacBook-Pro-3 / Mac17,6 / macOS 27.0
gpudebug --list-sessions=No active sessions.
gpucapture --list-devices=local MacBook-Pro-3 / Mac17,6 / macOS 27.0
gpudebug=1.0; gpucapture=2027.0.39
pmset -g therm=all three thermal/power queries returned error 0xe00002bc
pmset -g batt=AC Power; internal battery 80% (power source only, not thermal evidence)
```

Tool/device enumeration is prerequisite evidence only. It does not prove an
app session, drawable presentation, trace replay, pixels, or thermal state.
The thermal state is **unknown**, not nominal or passing.

## Static and local validation results

These checks were safe to run without launching the app:

```text
bash script/test_metal4_contract.sh
  exit=0  SM64 Modern Metal 4 source contract passed

bash script/test_metal4_archive_presentation.sh
  exit=0  synthetic healthy/baseline archive-presentation cases passed
  healthy: archive=binary_archive_reuse scheduler=clear dropped=0 callbacks=120 presented=120
  baseline: archive=descriptor_cache_fallback scheduler=dropped dropped=58 callbacks=3 presented=3

bash script/test_metal4_capture_archive_guard.sh
  exit=0  SM64 Modern Metal 4 capture archive guard contract passed

bash script/test_m9_release_readiness.sh
  exit=0  SM64 Modern M9 release readiness contract passed

bash -n script/test_m34_host_readiness.sh script/test_metal4_production.sh \
  script/test_metal4_contract.sh script/test_metal4_archive_presentation.sh \
  script/test_metal4_capture_archive_guard.sh script/test_m9_release_readiness.sh \
  script/test_timebase_audit.sh script/m9_release.sh
  exit=0

git -c core.fsmonitor=false diff --check
  exit=0
```

The source/parser contracts prove API and diagnostic seams only. They do not
prove runtime presentation, pixels, cadence, memory, thermal behavior, or
physical/human acceptance.

The auxiliary timebase audit was rerun and failed closed without changing its
fixture:

```text
object_timer       166 files 715 matches (fixture) -> 166 files 734 matches (current)
random_calls        79 files 289 matches (fixture) -> 79 files 290 matches (current)
Time-dependent gameplay inventory changed; classify the drift before updating the fixture.
```

This is source/fixture drift, not M34 presentation evidence and not a reason
to infer a renderer result.

## Evidence matrix

| Evidence domain | Current state | Evidence and boundary |
|---|---|---|
| Source/API contract | **PASS** | Metal 4 source, archive/presentation, and capture-archive guard contracts pass. This is static/API evidence only. |
| Build/shell contract | **PASS** | M9 release-readiness and all M34 script syntax checks pass. No current M34 production harness was run. |
| Current Release artifact | **UNKNOWN / NOT RUN** | The current two-pass harness was inadmissible behind `m34_host_ready=0`. The old `build/sm64-modern-m34c-after-m33h/` artifact is dated 2026-08-17, ad-hoc signed arm64, has `get-task-allow=true`, and `spctl` reports a Code Signing subsystem error; it is historical development output, not current production evidence. |
| GPU capture structure | **UNKNOWN / NOT ADMISSIBLE** | Current expected traces `/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace` and `/tmp/sm64-modern-m34-recheck.p8V35S/m34-recheck.gputrace` are absent. Historical capture presence and old `gpudebug` logs were not replayed or substituted. |
| Attachment pixels / visual parity | **UNKNOWN / NOT MEASURED** | No current color/depth attachment fetch, PNG, declared-size reference comparison, or screenshot exists. Prior M34c notes reported clear-only black attachments; that remains historical, not a current pixel verdict. |
| Runtime presentation/callbacks | **UNKNOWN / NOT RUN** | No current app session, drawable, callback count, or post-resume acknowledgement was observed. Prior M34c host runs stopped at three presents under compositor pressure; this is not a current pass. |
| Sustained cadence / GPU time | **UNKNOWN / NOT RUN** | No current 600-step Release validation profile or 10/30-minute soak. The synthetic parser's `dropped=0` case is not runtime cadence evidence. |
| Memory / RSS / GPU memory | **UNKNOWN / NOT MEASURED** | No current Metal HUD, RSS, Instruments, memgraph, or GPU-memory trend artifact. |
| Thermal / power | **UNKNOWN** | `pmset -g therm` returns `0xe00002bc`; AC power and battery percentage do not establish thermal acceptance. |
| Direct-display resize/pause/minimize/restore | **UNKNOWN / NOT RUN** | No online physical display is available and the console is locked. No wake/unlock/power/display mutation was attempted. |
| Physical visual/feel | **UNKNOWN / NOT RUN** | No physical display observation, controller/audio interaction, latency/feel review, or device run was performed. |
| Human acceptance | **UNKNOWN / NOT RUN** | No signed/stapled distribution artifact, clean-machine run, or human review exists. |

## Historical `build/` artifacts inspected

The following artifacts are retained for provenance only and do not promote a
current M34 gate:

- `build/sm64-modern-m34c-after-m33h/release-build.log` and
  `release-sign-inspect.log` (2026-08-17) describe an old ad-hoc arm64
  development bundle; its `get-task-allow=true` entitlement and failed
  `spctl` result exclude distribution/acceptance claims.
- `build/phase85aq-m34-capture-triage-20260821/phase85aq-gpudebug-retry.log`
  records a historical trace directory but `Cannot connect to
  gputoolsserviced`; it is not a current replay or pixel result.
- `build/phase85ba-m34-event-retry-20260821/host-readiness.log` records the
  same offline-display/locked-console boundary, with capture, soak, and
  direct-display explicitly not run.
- `build/phase85at-direct-display-20260821/screencapture.log` records
  `could not create image from display`; it supplies no physical screenshot.

## Single next executable M34 closure gate

The next executable automated gate is the unchanged M34 two-pass production
harness. It must not be attempted until an authorized operator has unlocked
the GUI session, brought at least one physical display online and awake, and
the host gate returns `m34_host_ready=1`. A running GPU-tools service and an
active capture-capable GPU session are also required for the capture half.

After that external prerequisite is satisfied, use a fresh isolated output
directory, no existing `SM64 Modern` process, and the repository's legal
runtime content:

```sh
bash script/test_m34_host_readiness.sh

M34_OUTPUT_DIR="$(mktemp -d /private/tmp/sm64-modern-m34-phase85f111.XXXXXX)"
SM64_MODERN_M34_OUTPUT_DIR="$M34_OUTPUT_DIR" \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
bash script/test_metal4_production.sh
```

The harness itself builds and ad-hoc-signs an isolated Release bundle, runs
the API/shader-validation pass, repeats the same bounded workload with
capture enabled, starts `gpucapture`, and inspects the resulting trace with
`gpudebug`. Retain these exact outputs from `$M34_OUTPUT_DIR`:

```text
release-build.log
release-sign-inspect.log
validation.log
capture.log
gpucapture-boundaries.txt
gpucapture-start.txt
m34b.gputrace/
gpudebug.txt
local-runtime/SM64 Modern.app
save/
```

The automated gate is only admissible as a pass when `validation.log` proves
the 600-step warm profile, zero scheduler/audio drops, repeated resize and
pause/resume plus minimize/restore observations, at least two post-resume
`metal_presentation_resize_ack` events, no Metal validation/frame failures,
and clean `metal_shutdown_drained`, `engine_thread_finished status=0`, and
`application_stopped` ordering. `capture.log` and `gpudebug.txt` must then
prove a real CAMetalLayer drawable, BGRA8Unorm color, Depth32Float depth,
MTL4 render encoder draw, and the expected `sm64_vertex / sm64_fragment`
two-triangle structure.

That command is the single next executable M34 gate; it still does not by
itself close reference-pixel parity, sustained 10/30-minute FPS/GPU/RSS and
thermal evidence, direct-display behavior, or physical/human acceptance.
Those require their own retained measurements after the automated gate passes.

## Validation boundary

No staging, commit, push, release, store operation, credential access,
display/power mutation, source edit, manifest/report/ledger mutation, or
destructive operation was performed by this phase. The parent should retain
this handoff while preserving the pre-existing dirty worktree.
