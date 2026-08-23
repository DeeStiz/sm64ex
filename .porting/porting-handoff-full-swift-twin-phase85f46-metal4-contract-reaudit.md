# Full Swift Twin Handoff — Phase 85f46 Metal 4 contract re-audit

Date: 2026-08-22

## Scope and verdict

**COMPLETED / bounded read-only source and production-contract re-audit; M34
remains blocked and fail-closed.** The existing Metal 4 source, archive/
presentation parser, capture-archive guard, M9 release-readiness, timebase,
host-readiness, and shell-syntax checks were rerun against the current
worktree. All non-runtime contracts passed. The visible-host gate failed, so
the Release production harness, app launch, GPU capture/replay, attachment
fetch, screenshot/pixel comparison, cadence/soak, and direct-display
interaction were not admissible and were not attempted. No Simulator was used
or substituted.

The worktree already contained 444 status entries at the start of this phase.
The only repository artifact created by this phase is this handoff. No source,
route/canonical ledger, goal, shared documentation, credential, display/power
setting, release artifact, commit, push, publish, or destructive operation was
performed.

## Repository baseline and contract identity

The baseline was captured at `2026-08-22T23:17:03-0400`:

```text
branch=nightly
HEAD=c78014e3f1ee077b54c39286b17f69c0dc70ea76
status_count=444 pre-existing entries; left untouched
target_handoff=absent before this phase; created only by this phase
```

Relevant script SHA-256 values at the audit snapshot:

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

The source files inspected by the Metal 4 contract and their SHA-256 values
were:

```text
SM64Modern/MetalRenderer.swift       aaef749129f01b70d47785d70e2440a0208a166480c52adfe3f2dacdf6f8e13c
SM64Modern/MetalShaderCompiler.swift 048351fa5798c9598d00678a72cc4dc071c47f6cb2cd435bfcfadb76d63e8b1b
SM64Modern/MetalCompilerBridge.m     0c62515d9256b46b066fb04c79410dea8412505c46f7438593b836e734aab6d4
SM64Modern/GameView.swift             0281be7d7eb5a9b38c48969fbdb834f83ef1b643bfd118ca263b2fb5d7aaec65
SM64Modern/EngineHost.swift           f30ffb5434d22b2571d3c405a1eff10fc03a6d2382a3b3feaa75e1275f67bead
project.yml                            9afcfb6bc8b32e17b5b9e355ae0c4d6df58cb9870e35a54917aac4f3d7fd563c
```

## Host gate and independent read-only evidence

The unchanged host gate ran at `2026-08-22T23:17:30-0400` and returned exit
`1`:

```sh
bash script/test_m34_host_readiness.sh
```

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

An independent read-only snapshot ran from `2026-08-22T23:18:23-0400` through
`2026-08-22T23:18:23-0400`:

```text
macOS 27.0 / build 26A5416b
metal=/Applications/Xcode-beta.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
GPU=Apple M5 Max, 40 cores; system_profiler reported no Online: Yes display record
IOConsoleLocked=Yes; CGSSessionScreenIsLocked=Yes
gputoolsserviced=state not running; active count=0; program=/usr/libexec/gputoolsserviced
gpudebug --list-devices=ID 0 MacBook-Pro-3 / Mac17,6 / macOS 27.0
gpudebug --list-sessions=No active sessions.
gpucapture --list-devices=ID 0 MacBook-Pro-3 / Mac17,6 / macOS 27.0
gpudebug=1.0; gpucapture=2027.0.39
pmset -g therm=all three thermal/power queries returned error 0xe00002bc
pmset -g batt=AC Power; internal battery 80%; power state only, not thermal evidence
```

Device enumeration is tooling readiness only; it does not prove an app
session, drawable presentation, trace replay, or pixels. Thermal state is
**unknown**, not nominal or passing.

## Contract and shell-check results

These commands were run without launching the game:

```text
2026-08-22T23:17:23-0400 .. 2026-08-22T23:17:24-0400  bash script/test_metal4_capture_archive_guard.sh
  exit=0  SM64 Modern Metal 4 capture archive guard contract passed

2026-08-22T23:17:24-0400 .. 2026-08-22T23:17:24-0400  bash script/test_metal4_contract.sh
  exit=0  SM64 Modern Metal 4 source contract passed

2026-08-22T23:17:24-0400 .. 2026-08-22T23:17:24-0400  bash script/test_metal4_archive_presentation.sh
  exit=0  archive/presentation diagnostic smoke passed
  healthy synthetic case: archive=binary_archive_reuse scheduler=clear scheduler_dropped_steps=0 callbacks=120 presented=120
  baseline synthetic case: archive=descriptor_cache_fallback scheduler=dropped scheduler_dropped_steps=58 callbacks=3 presented=3

2026-08-22T23:17:24-0400 .. 2026-08-22T23:17:26-0400  bash script/test_m9_release_readiness.sh
  exit=0  SM64 Modern M9 release readiness contract passed

2026-08-22T23:17:24-0400 .. 2026-08-22T23:17:25-0400  bash script/test_timebase_audit.sh
  exit=0  SM64 Modern timebase audit passed

2026-08-22T23:17:36-0400 .. 2026-08-22T23:17:36-0400  bash -n script/test_m34_host_readiness.sh script/test_metal4_production.sh script/test_metal4_contract.sh script/test_metal4_archive_presentation.sh script/test_metal4_capture_archive_guard.sh script/test_m9_release_readiness.sh script/test_timebase_audit.sh script/m9_release.sh
  exit=0
```

`script/test_metal4_production.sh` was syntax-checked but deliberately not
executed: it builds and opens the Release app, drives the validation profile,
starts `gpucapture`, and invokes `gpudebug`. The failed visible-host gate and
the locked/offline host make those runtime operations inadmissible in this
phase.

## Trace and production evidence boundary

At `2026-08-22T23:18:30-0400`, expected retained/recheck paths were absent:

```text
/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace|absent
/tmp/sm64-modern-m34-recheck.p8V35S/m34-recheck.gputrace|absent
/private/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace|absent
```

No `*.gputrace` bundle was found under `/tmp` at that time. Historical bundles
under `build/` remain historical M4/M6/M8b/M8c/M8d/M9 evidence (for example,
`build/m9-release/m9.gputrace` mtime `2026-08-12T20:36:22-0400`); none was
replayed or substituted for fresh M34 evidence.

Because `m34_host_ready=0`, these operations were **not run**:

```text
Release production harness / m9_release build-profile path
app launch or process attach
gpucapture boundaries/start or fresh trace creation
gpudebug replay/attachment inspection
color/depth attachment fetch
reference-pixel comparison
10-/30-minute Release cadence or GPU/RSS/thermal soak
direct-display resize, pause/resume, minimize/restore interaction
```

## Acceptance matrix

```text
m34_host_ready=0
m34_display_online=0
m34_console_locked=Yes
m34_session_locked=Yes
m34_gputoolsserviced=not_running
m34_gpu_device_enumeration=verified_local_only
m34_gpu_session=none
m34_fresh_trace=absent
m34_release_launch=not_admissible
m34_capture_replay=not_admissible
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
m34_thermal=unknown (0xe00002bc)
m34_direct_display_resize_pause_resume=not_run
m34_minimize_restore_post_resume=not_run
m34_physical_visual_or_feel=not_run
m34_human_acceptance=not_run
```

## Required unblock and next evidence

An authorized operator must unlock the console session and bring at least one
physical display online and awake. Rerun the unchanged
`bash script/test_m34_host_readiness.sh` until it returns
`m34_host_ready=1`; a running `gputoolsserviced` and active GPU session are
still required for fresh capture/replay. Only after that gate passes should
the existing Release production harness be run, followed by a fresh
`gpucapture`/`gpudebug` trace, explicit color/depth attachments, and a
declared-size reference-pixel comparison. M34 closeout still separately
requires zero-drop Release cadence, independent 10-/30-minute GPU/RSS/thermal
telemetry, direct-display resize/pause/minimize/restore and post-resume
evidence, and physical visual/feel review. None of those claims can be
inferred from green source/parser contracts, local tool enumeration, AC power,
or historical traces.

## Validation boundary

`git diff --check` passed at `2026-08-22T23:18:42-0400` before this handoff
was written and again at `2026-08-22T23:20:19-0400` afterward. A direct
trailing-whitespace scan of this file returned exit `1` with no matches at
`23:20:19-0400`; this is the expected no-match result. No staging, commit,
push, publish, or destructive operation was performed by this worker.
