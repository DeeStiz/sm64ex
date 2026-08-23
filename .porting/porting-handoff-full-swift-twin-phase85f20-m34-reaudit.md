# Full Swift Twin Handoff — Phase 85f20 M34 Production Re-audit Retry

Date: 2026-08-22

## Scope and verdict

**COMPLETED / bounded read-only retry; M34 remains blocked and fail-closed.**
This retry rechecked the visible-host gate, display/GPU tooling and session
state, retained-trace availability, screenshot/pixel access, and the existing
Metal/timebase/release contract smokes. The console is no longer reported as
locked, but the only detected display remains offline (`online=0`), and
`gputoolsserviced` is not running. No app launch, replay attachment, fresh GPU
capture, pixel fetch, cadence/thermal soak, or direct-display interaction was
admissible after the host gate failed.

No source, route/canonical ledger, goal, or shared documentation was changed.
The only repository artifact created by this phase is this handoff. No
commit, push, credential, display/power setting, or external state operation
was attempted.

Diagnostic logs are retained outside the repository at:

```text
/private/tmp/sm64-m34-reaudit-retry.Fh5eGE/
```

The final timestamped command ledger is:

```text
/private/tmp/sm64-m34-reaudit-retry.Fh5eGE/command-ledger-final.log
```

## Fresh host and tool evidence

The final host gate was run at `2026-08-22T20:37:00-0400`:

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
m34_host_console_locked=No session_locked=unknown user_active=unknown
m34_host_thermal=unknown
m34_host_ready=0 blockers=one or more displays are offline/asleep
```

The host identification at `2026-08-22T20:37:11-0400` was collected with
`sw_vers` and `xcrun --find metal`:

```text
ProductName:    macOS
ProductVersion: 27.0
BuildVersion:   26A5416b
/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
```

`system_profiler SPDisplaysDataType` at `20:37:01-0400` reports only the
Apple M5 Max GPU (40 cores, Metal supported) and no `Online: Yes` display
record. The independent `ioreg -n Root -d 1` filter at the same time reports
`IOConsoleLocked = No`; the session/user-active fields are not exposed in the
managed read-only query. The gate therefore remains blocked solely by the
offline/asleep display result.

The GPU tooling is installed but not in an admissible runtime state:

```text
2026-08-22T20:37:01-0400  launchctl print "gui/$(id -u)/com.apple.gputoolsserviced"
state = not running
program = /usr/libexec/gputoolsserviced

2026-08-22T20:37:01-0400  gpudebug --list-devices
ID 0 MacBook-Pro-3 Mac17,6 macOS 27.0

2026-08-22T20:37:01-0400  gpudebug --list-sessions
No active sessions.

2026-08-22T20:37:01-0400  gpucapture --list-devices
ID 0 MacBook-Pro-3 Mac17,6 macOS 27.0
```

The tool versions at `20:37:11-0400` were `gpudebug 1.0` and
`gpucapture 2027.0.39`. Device enumeration is only tooling readiness; it does
not prove an app session, trace replay, or display presentation.

`pmset -g therm` at `20:37:01-0400` returned exit `0` but no telemetry:

```text
Error:Failed to get thermal warning level with error code 0xe00002bc
Error: Failed to get performance warning level with error code 0xe00002bc
Error: No CPU power status with error code 0xe00002bc
```

Thermal state is therefore **unknown**, not nominal or passing. `pmset -g
batt` reported AC power and a 100% charged internal battery; this is power
state only and is not thermal evidence.

## Bounded contract checks

The following existing checks ran without launching the game:

```text
2026-08-22T20:36:07-0400  bash script/test_metal4_contract.sh
  exit=0  SM64 Modern Metal 4 source contract passed

2026-08-22T20:36:08-0400  bash script/test_metal4_archive_presentation.sh
  exit=0  archive/presentation diagnostic smoke passed
  synthetic healthy case: scheduler_dropped_steps=0 callbacks=120 presented=120

2026-08-22T20:36:08-0400  bash script/test_metal4_capture_archive_guard.sh
  exit=0  SM64 Modern Metal 4 capture archive guard contract passed

2026-08-22T20:36:08-0400  bash script/test_m9_release_readiness.sh
  exit=0  SM64 Modern M9 release readiness contract passed

2026-08-22T20:36:11-0400  bash script/test_timebase_audit.sh
  exit=0  SM64 Modern timebase audit passed

2026-08-22T20:36:13-0400  bash -n script/test_m34_host_readiness.sh script/test_metal4_production.sh script/test_metal4_archive_presentation.sh script/test_metal4_capture_archive_guard.sh script/test_m9_release_readiness.sh
  exit=0
```

The archive/presentation output is a parser-only synthetic smoke. It does not
measure native cadence, GPU time, RSS, thermal state, or physical presentation.

## Launch, replay, screenshot, and pixel gates

Because `m34_host_ready=0`, the following runtime operations were deliberately
not attempted:

```text
m34_release_launch=not_admissible (offline display host gate)
m34_gpu_capture=not_admissible (offline display; gputoolsserviced not running)
m34_gpudebug_replay=not_admissible (no trace and no active session)
m34_attachment_color=not_measured
m34_attachment_depth=not_measured
m34_reference_pixel_verdict=not_measured
```

The direct screenshot attempt was made at `2026-08-22T20:37:01-0400`:

```sh
/usr/sbin/screencapture -x -T 1 \
  /private/tmp/sm64-m34-reaudit-retry.Fh5eGE/final-visible-screen.png
```

It returned exit `1` with `could not create image from display`; no PNG was
produced. The previously cited retained path
`/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace` was also absent
when checked with `stat`, and `find /tmp -maxdepth 3 -type d -name '*.gputrace'`
at `20:37:02-0400` found no trace bundle. Static tool enumeration and historical
trace references cannot establish fresh replay or pixel contents.

The process-list probes were also blocked by managed host permissions:
`pgrep -x "SM64 Modern"` returned the `sysmond service not found` error, and a
read-only `ps -ax` fallback returned `Operation not permitted`. No launch was
performed, so this does not alter the host-gate verdict.

## Cadence, thermal soak, and direct-display gates

The source timebase contract passed, but no runtime cadence was measured:

```text
m34_release_cadence=not_run
m34_scheduler_dropped_steps=not_measured
m34_audio_dropped_delta=not_measured
m34_presentation_callbacks=not_measured
m34_presented_frames=not_measured
m34_native_hz=not_measured
m34_rss_gpu_memory=not_measured
m34_10_minute_soak=not_run
m34_30_minute_soak=not_run
m34_thermal=unknown (pmset 0xe00002bc)
m34_direct_display_resize_pause_resume=not_run
m34_minimize_restore_post_resume=not_run
m34_physical_visual_or_feel=not_run
m34_human_acceptance=not_run
```

No Simulator was used or substituted. The production harness
`script/test_metal4_production.sh` was not run because it launches the Release
app and requires the failed visible-host gate; static contracts are not a
replacement for that runtime evidence.

## Acceptance matrix

```text
m34_host_ready=0
m34_display_online=0
m34_console_locked=No (session_locked/user_active=unknown)
m34_gputoolsserviced=not_running
m34_gpu_device_enumeration=verified_local_only
m34_gpu_session=none
m34_trace_bundle=fresh_absent
m34_launch_replay=not_admissible
m34_color_depth_pixels=not_measured
m34_reference_pixel_verdict=not_measured
m34_release_cadence=not_run
m34_long_soak=not_run
m34_thermal=unknown (0xe00002bc)
m34_direct_display=not_run
m34_physical_visual_feel=not_run
m34_human_acceptance=not_run
```

## Required unblock and next evidence

An authorized operator must bring at least one physical display online and
awake, then rerun the unchanged `bash script/test_m34_host_readiness.sh` until
it returns `m34_host_ready=1`. A running `gputoolsserviced` and an active
session are still required for fresh capture/replay. Only after that gate
passes should the existing Release production harness and bounded
`gpudebug` attachment fetch be run, followed by actual color/depth PNGs and an
explicit reference-pixel comparison. M34 closeout additionally requires a
zero-drop Release cadence run, independent 10-/30-minute soak and GPU/RSS/
thermal telemetry, direct-display resize/pause/minimize/restore evidence, and
physical visual/feel review. None of those claims can be inferred from the
green source/parser contracts or local device enumeration.

## Validation boundary

After this handoff was written, the repository check ran at
`2026-08-22T20:38:52-0400`:

```text
git diff --check
exit=0
```

The new untracked handoff was separately checked for trailing whitespace at
the same timestamp and also returned `exit=0`. No staging, commit, push,
publish, or destructive operation was performed by this worker.
