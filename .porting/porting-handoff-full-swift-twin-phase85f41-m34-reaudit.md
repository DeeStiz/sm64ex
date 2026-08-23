# Full Swift Twin Handoff — Phase 85f41 M34 host/production re-audit

Date: 2026-08-22

## Scope and verdict

**COMPLETED / bounded read-only re-audit; M34 remains blocked and fail-closed.**
This phase rechecked the visible physical-host gate, display/session state,
GPU-tools service and sessions, thermal telemetry, retained/fresh trace
availability, screenshot access, and the existing M34 source/parser
contracts. The host never became admissible, so no app launch, Release
production profile, GPU replay/capture, attachment fetch, pixel comparison,
cadence/soak, or direct-display interaction was attempted. No Simulator was
used or substituted.

No source, route/canonical ledger, goal, shared documentation, credentials,
display/power settings, or release artifact was changed. The only repository
artifact created by this phase is this handoff. No commit, push, publish, or
destructive operation was performed.

Complete read-only command output and timestamps are retained at:

```text
/private/tmp/sm64-modern-phase85f41-m34-reaudit.TPcWqU/
```

The final command ledger is
`/private/tmp/sm64-modern-phase85f41-m34-reaudit.TPcWqU/command-ledger-final.log`
(SHA-256 `1899840500893a2143a87823905d3ef5655f833ff120ad24e5e8aa31daba8117`).
The artifact manifest is
`/private/tmp/sm64-modern-phase85f41-m34-reaudit.TPcWqU/artifact-sha256.txt`
(SHA-256 `d1f950a6240833164738ce68f3e96c6206f32ea33d3a5e781d7f6c9a11815a8e`).

## Repository and script identity

The read-only baseline at `2026-08-22T22:50:38-0400` was:

```text
branch=nightly
HEAD=186720d6ffa5660502bdc7952e4feebc680e5648
status_count=444 pre-existing entries; left untouched
```

Relevant script SHA-256 values from the same snapshot:

```text
script/test_m34_host_readiness.sh       0cdf8083e6741268fb7080f134ba29f93bf706b2e7811445dbc804bc42c4b4d6
script/test_metal4_production.sh        869a56780d9fae2f2603e2c4e901e50d60a7f7c2028da1966ad88f3424cb6d1d
script/test_metal4_contract.sh          fa72e9f3f12d5589cccaa84525d241888dd389015ba0a901346593d70f85c2bf
script/test_metal4_archive_presentation.sh 08b32f3aa3f1cdf97946943e7796161035c58ee0934b89ed359b44a9da8abb0a
script/test_metal4_capture_archive_guard.sh 9b0b49f691b923d3a6ef0b5c41b72bd3aeabe0f5202dd41c245aaa268ae3df3a
script/test_m9_release_readiness.sh     4ad90aa1283f84e8c6acfbc8d09a98455c5fdb56b4e208ca31285d3ea3a83d4f
script/test_timebase_audit.sh           ec97ec4f9dcbd4a9fd3366c56708daaf82857059f4b7f49aa427b551491df7e3
script/m9_release.sh                    8de9ecc04cc54d9e6e9ec8cca10518ddfad920c5edaac1cf7ad80d74ba2a8945
```

## Fresh host/device evidence

The unchanged host gate was run first at `2026-08-22T22:48:26-0400` and
again as the final gate at `2026-08-22T22:51:42-0400`:

```sh
bash script/test_m34_host_readiness.sh
```

The final invocation returned exit `1`:

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

Independent snapshots at `2026-08-22T22:48:49-0400` through
`2026-08-22T22:48:50-0400` corroborate the gate:

```sh
/usr/sbin/system_profiler SPDisplaysDataType
/usr/sbin/ioreg -n Root -d 1
/usr/bin/who
/bin/launchctl print "gui/$(id -u)/com.apple.gputoolsserviced"
/usr/bin/gpudebug --list-devices
/usr/bin/gpudebug --list-sessions
/usr/bin/gpucapture --list-devices
/usr/bin/gpudebug --version
/usr/bin/gpucapture --version
/usr/bin/pmset -g therm
/usr/bin/pmset -g batt
```

`system_profiler` exit `0` (log SHA-256
`c502f766a1a312c72d307ec6acf858b0477427fb4d5561ffb4ae6410db45bd80`) reports
only the built-in Apple M5 Max GPU (40 cores, Metal supported) and no
`Online: Yes` display record. `ioreg` exit `0` (log SHA-256
`4233f3fa897692a3b96a07ad5eb09bfa49d75f44116577e14528eb29b3dbafa0`) reports
`IOConsoleLocked = Yes` and the `derek` console session with
`CGSSessionScreenIsLocked = Yes`. `who` reports a `derek` console login and a
terminal session; login presence is not an unlocked visible GUI.

`launchctl print gui/501/com.apple.gputoolsserviced` exit `0` (log SHA-256
`e5d74acde83f0d7f6589f5d8bd140b90231989db1d4bbdfb4b7d577262aeb8d4`) reports
`state = not running`, `active count = 0`, and program
`/usr/libexec/gputoolsserviced`. GPU tooling is installed but not in an
admissible runtime state:

```text
gpudebug --list-devices: ID 0 MacBook-Pro-3 / Mac17,6 / macOS 27.0
gpudebug --list-sessions: No active sessions.
gpucapture --list-devices: ID 0 MacBook-Pro-3 / Mac17,6 / macOS 27.0
gpudebug --version: gpudebug 1.0
gpucapture --version: 2027.0.39
```

Enumeration is tooling readiness only; it does not prove a live app session,
trace replay, drawable presentation, or pixels.

`pmset -g therm` exit `0` (log SHA-256
`ea443a4845721a969bb8666861608e6d029f2491d7c9e68df16e653181acf507c`)
returned:

```text
Error:Failed to get thermal warning level with error code 0xe00002bc
Error: Failed to get performance warning level with error code 0xe00002bc
Error: No CPU power status with error code 0xe00002bc
```

Thermal state is **unknown**, not nominal or passing. `pmset -g batt` reported
AC power and an 80% internal battery; power source is not thermal evidence.

## Trace, screenshot, and pixel gates

At `2026-08-22T22:49:11-0400`, the expected retained and recheck paths were
absent:

```text
/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace|absent
/tmp/sm64-modern-m34-recheck.p8V35S/m34-recheck.gputrace|absent
```

`find /tmp -maxdepth 4 -type d -name "*.gputrace"` found no bundles. The
known prior Phase 82f/85at paths were also absent at
`2026-08-22T22:49:24-0400`; no `/private/tmp` trace bundle was found. Older
repository traces under `build/` remain historical (M4/M8d/M9 bundles dated
2026-08-10 through 2026-08-12), not fresh M34 evidence and were not replayed
or substituted. For example, `build/m9-release/m9.gputrace` has mtime
`2026-08-12T20:36:22-0400`; its `capture` payload hash is
`8cd64e445a43fc0b91f07f3516f10e94233188e7e5b1a177f0fef72760106434`.

The direct screenshot attempt at `2026-08-22T22:51:13-0400` was:

```sh
/usr/sbin/screencapture -x -T 1 \
  /private/tmp/sm64-modern-phase85f41-m34-reaudit.TPcWqU/visible-screen.png
```

It returned exit `1` with `could not create image from display`; no PNG was
created (log SHA-256
`871258197d577530127f892532a5c79634d0570b29d6042dbe15e9826ef40fb7`).
`pgrep -x "SM64 Modern"` could not obtain a process list because `sysmond`
was unavailable (exit `3`), and `ps -ax` was denied by the managed host
(exit `126`); no launch was performed.

Because the host gate failed and no M34 trace exists, these operations were
**not admissible and deliberately not run**:

```text
script/test_metal4_production.sh
gpucapture start / gpucapture boundaries against an app PID
gpudebug --oneshot against a retained/fresh M34 trace
Release app launch or m9_release.sh profile
color/depth attachment fetch
reference-pixel comparison
```

## Bounded static contracts

These were the only post-gate validation commands. They do not launch the
game and do not measure physical presentation, pixels, cadence, GPU/RSS, or
thermal behavior:

```text
2026-08-22T22:50:53-0400  bash script/test_metal4_contract.sh
  exit=0  SM64 Modern Metal 4 source contract passed

2026-08-22T22:50:54-0400  bash script/test_metal4_archive_presentation.sh
  exit=0  synthetic healthy/baseline parser cases passed

2026-08-22T22:50:54-0400  bash script/test_metal4_capture_archive_guard.sh
  exit=0  SM64 Modern Metal 4 capture archive guard contract passed

2026-08-22T22:50:54-0400  bash script/test_m9_release_readiness.sh
  exit=0  SM64 Modern M9 release readiness contract passed

2026-08-22T22:50:56-0400  bash script/test_timebase_audit.sh
  exit=0  SM64 Modern timebase audit passed

2026-08-22T22:50:57-0400  bash -n script/test_m34_host_readiness.sh script/test_metal4_production.sh script/test_metal4_contract.sh script/test_metal4_archive_presentation.sh script/test_metal4_capture_archive_guard.sh script/test_m9_release_readiness.sh script/test_timebase_audit.sh script/m9_release.sh
  exit=0
```

The static contract log hashes are in the phase artifact manifest; for
example, `contract-metal4.log` is
`79e8c498ff07eeac5a367ebd32c94c32175b039e19ad752649f6b54995653c4d` and
`contract-m9-readiness.log` is
`57c9dcf32d62609485e82586ea9e100a640da45572221f078fdda8ea8d597ec2`.

## Acceptance matrix

```text
m34_host_ready=0
m34_display_online=0
m34_display_awake=not_verified (no online display record)
m34_console_locked=Yes
m34_session_locked=Yes
m34_user_active=unknown
m34_gputoolsserviced=not_running
m34_gpu_device_enumeration=verified_local_only
m34_gpu_session=none
m34_m34_trace=fresh_and_retained_absent
m34_launch_replay=not_admissible
m34_screenshot=failed (could not create image from display)
m34_color_depth_pixels=not_measured
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
m34_thermal=unknown (pmset 0xe00002bc)
m34_direct_display_resize_pause_resume=not_run
m34_minimize_restore_post_resume=not_run
m34_physical_visual_or_feel=not_run
m34_human_acceptance=not_run
```

## Required unblock and next evidence

An authorized operator must unlock the console session and provide at least
one physical display that reports online/awake. Then rerun the unchanged
`bash script/test_m34_host_readiness.sh` until it returns
`m34_host_ready=1`, with `gputoolsserviced` available and an active GPU
session. Only then should the unchanged Release production harness be run,
followed by a fresh `gpucapture`/`gpudebug` trace, explicit color/depth PNGs,
and a declared-size reference-pixel comparison. M34 closure still separately
requires zero-drop Release cadence, independent 10-/30-minute GPU/RSS/
thermal soak telemetry, direct-display resize/pause/minimize/restore and
post-resume evidence, and physical visual/feel review. None of those claims
can be inferred from the green source/parser contracts, local tool
enumeration, historical build traces, or AC power state.

## Validation boundary

`git diff --check` passed at `2026-08-22T22:50:38-0400` before this handoff
was written and again at `2026-08-22T22:55 EDT` afterward. A direct
trailing-whitespace scan of this handoff returned exit `1` with no matches at
`22:55 EDT`; this is the expected no-match result. No other repository
files were intentionally changed by this phase.
