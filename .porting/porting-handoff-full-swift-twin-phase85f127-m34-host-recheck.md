# Full Swift Twin Handoff — Phase 85f127 M34 Host/Tool Recheck

Date: 2026-08-23
Audit timestamp: 2026-08-23T10:13:48-0400 (EDT)
Audited checkout: `/Users/derek/Developer/sm64ex`

## Scope and verdict

**COMPLETED / bounded read-only host and source-contract recheck; M34 remains
blocked and fail-closed.** The unchanged M34 host gate, independent display,
session, GPU-tool, and thermal queries, and safe Metal/source/parser contracts
were rerun against the current worktree. The host still has no online physical
display, the console session is locked, and no active GPU-tools session is
available. No Release launch, production harness, GPU capture/replay,
attachment fetch, screenshot, cadence/soak, direct-display interaction, or
power/display mutation was attempted behind the failed host gate.

No source, project, report, route ledger, manifest, goal, shared
documentation, credential, release/store state, or unrelated dirty edit was
changed. This handoff is the only repository artifact created by this phase;
no staging, commit, or push was performed.

## Repository snapshot

```text
branch=nightly
HEAD=7db21e2e626355cf5446858199d140a7ca928e51
status_count=446 pre-existing entries; preserved untouched
```

The worktree was already heavily dirty before this phase. The status count
includes the other agents' in-progress source, tests, scripts, and handoffs;
none were reverted or normalized.

## Fresh host gate

The unchanged gate was run from `2026-08-23T10:13:48-0400` through
`2026-08-23T10:13:48-0400`:

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

`display_count=1` is the Apple M5 Max GPU descriptor reported by
`system_profiler`; no physical display block reports `Online: Yes`. The host
is macOS 27.0 build `26A5416b`, with Apple M5 Max (40 cores, Metal supported).
IORegistry independently reports `IOConsoleLocked=Yes` and
`CGSSessionScreenIsLocked=Yes`; `user_active` was not exposed by the managed
read-only query.

## GPU tools and session state

Independent read-only enumeration at the same audit time reported:

```text
xcode-select --print-path=/Applications/Xcode-beta.app/Contents/Developer
xcrun --find metal=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
xcrun --find metallib=unavailable (xcrun could not resolve metallib)
gpucapture=/usr/bin/gpucapture
gpudebug=/usr/bin/gpudebug
gpucapture --version=2027.0.39
gpudebug --version=gpudebug 1.0
gpudebug --list-devices=ID 0 MacBook-Pro-3 / Mac17,6 / macOS 27.0
gpucapture --list-devices=ID 0 MacBook-Pro-3 / Mac17,6 / macOS 27.0
gpudebug --list-sessions=No active sessions.
```

`launchctl print gui/501/com.apple.gputoolsserviced` reports
`state=not running`, `active count=0`, program `/usr/libexec/gputoolsserviced`,
and service path `/System/Library/LaunchAgents/com.apple.gputoolsserviced.plist`.
The independent `pgrep` probe was managed-host limited (`sysmon request failed
with error: sysmond service not found`); it was not used to infer a running
service. The launchctl and no-active-session results are sufficient to keep
fresh capture/replay inadmissible. Local device enumeration is prerequisite
evidence only; it does not prove an application session, drawable, trace, or
presented pixels.

## Thermal and power result

`pmset -g therm` returned exit `0` but no thermal telemetry:

```text
Error:Failed to get thermal warning level with error code 0xe00002bc
Error: Failed to get performance warning level with error code 0xe00002bc
Error: No CPU power status with error code 0xe00002bc
```

Thermal state is **unknown (`0xe00002bc`)**, not nominal or passing.
`pmset -g batt` reported `AC Power` and an internal battery at `80%` with AC
attached/not charging/present. That is power-source evidence only and cannot
substitute for thermal or sustained-performance telemetry.

## Safe source/parser contract results

These checks ran without launching the game or touching the host display:

```text
bash script/test_metal4_contract.sh
  exit=0  SM64 Modern Metal 4 source contract passed

bash script/test_metal4_archive_presentation.sh
  exit=0  SM64 Modern Metal 4 archive/presentation diagnostic smoke passed
  healthy: archive=binary_archive_reuse scheduler=clear scheduler_dropped_steps=0 callbacks=120 presented=120
  baseline: archive=descriptor_cache_fallback scheduler=dropped scheduler_dropped_steps=58 callbacks=3 presented=3

bash script/test_metal4_capture_archive_guard.sh
  exit=0  SM64 Modern Metal 4 capture archive guard contract passed

bash script/test_m9_release_readiness.sh
  exit=0  SM64 Modern M9 release readiness contract passed

bash script/test_timebase_audit.sh
  exit=1  fixture drift; no fixture update performed
  object_timer       166 files 734 matches (fixture: 715)
  random_calls        79 files 290 matches (fixture: 289)

bash -n script/test_m34_host_readiness.sh script/test_metal4_production.sh \
  script/test_metal4_contract.sh script/test_metal4_archive_presentation.sh \
  script/test_metal4_capture_archive_guard.sh script/test_m9_release_readiness.sh \
  script/test_timebase_audit.sh script/m9_release.sh
  exit=0

git -c core.fsmonitor=false diff --check
  exit=0
```

The timebase result is source/fixture drift, not runtime presentation evidence
and not a reason to infer cadence, pixels, thermal state, or human acceptance.
The synthetic archive/presentation cases are parser-only contracts; their
`callbacks=120` and `presented=120` healthy case is not a native runtime
measurement.

## Fresh trace and runtime boundary

The expected current/recheck trace paths were absent:

```text
/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace|absent
/tmp/sm64-modern-m34-recheck.p8V35S/m34-recheck.gputrace|absent
/private/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace|absent
```

Because `m34_host_ready=0`, the following remain **not admissible/not run**:

```text
m34_release_launch=not_admissible
m34_production_harness=not_run
m34_gpu_capture=not_admissible (gputoolsserviced not running; no active session)
m34_gpudebug_replay=not_admissible (fresh trace absent)
m34_color_depth_attachments=not_measured
m34_reference_pixel_verdict=not_measured
m34_release_cadence=not_run
m34_scheduler_dropped_steps=not_measured
m34_audio_dropped_delta=not_measured
m34_presentation_callbacks=not_measured
m34_presented_frames=not_measured
m34_native_hz=not_measured
m34_gpu_rss_memory=not_measured
m34_10_minute_soak=not_run
m34_30_minute_soak=not_run
m34_direct_display_resize_pause_resume=not_run
m34_minimize_restore_post_resume=not_run
m34_physical_visual_or_feel=not_run
m34_human_acceptance=not_run
```

Static source/parser green results, local tool enumeration, AC power, and
historical traces cannot prove visual parity, drawable presentation, frame
cadence, memory, thermal behavior, direct-display behavior, or human review.

## Single next executable M34 gate

An authorized operator must unlock the console session and bring at least one
physical display online and awake. Rerun the unchanged host gate until it
returns `m34_host_ready=1`; a running `gputoolsserviced` and active capture
session are also required for fresh GPU capture/replay. Do not run the
production harness while the host gate is `0`.

After that external prerequisite passes, run the existing harness once into a
new isolated directory:

```sh
bash script/test_m34_host_readiness.sh

M34_OUTPUT_DIR="$(mktemp -d /private/tmp/sm64-modern-m34-phase85f127.XXXXXX)"
SM64_MODERN_M34_OUTPUT_DIR="$M34_OUTPUT_DIR" \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
bash script/test_metal4_production.sh
```

The harness is admissible only after the first command returns
`m34_host_ready=1`; it must then prove the 600-step validation profile, zero
scheduler/audio drops, resize/pause/resume and minimize/restore ordering,
post-resume presentation acknowledgements, clean Metal drain/status-0
shutdown, and a real MTL4 trace. Separate M34 closure still requires
declared-size attachment/reference-pixel comparison, independent 10-/30-minute
GPU/RSS/thermal telemetry, direct-display resize/pause/minimize/restore
evidence, and physical visual/feel review. None of those are closed by this
host recheck.

## Validation boundary

No app was launched, no GPU trace was captured or replayed, no display was
woken/unlocked, no power setting was changed, no credential or keychain state
was accessed for mutation, and no source/report/ledger/manifest/goal file was
edited. The parent owns any later documentation reconciliation and commit
decision.
