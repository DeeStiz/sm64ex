# Full Swift Twin Handoff — Phase 84d Pixel and Soak Retry

Date: 2026-08-21

## Scope and verdict

**COMPLETED / read-only evidence retry.** This phase retried resource replay
for the retained M34 trace, attempted a longer no-validation native Release
profile, and collected a separate all-processes Metal System Trace with GPU,
allocation, display, and thermal exports. No source, script, route ledger,
credential, host power/lock state, or distribution artifact was changed.

The pixel retry remains **BLOCKED**. Static `gpudebug` navigation works, but
both default and explicit local-device replay fail with an XPC replayer error
before `fetch`; no color/depth PNG was produced, so pixel content and
reference parity remain undetermined.

The clean no-validation soak lane remains **NOT ACCEPTED**. One run exceeded
ten minutes and reached status 0 with zero scheduler/audio drops, but the
requested 43,200-step target was not reached and the runtime stopped at the
observed 40,006-step boundary without emitting `m9_profile_complete`. Two
follow-up attempts were interrupted by host/display scheduling events before
their targets. They are retained as fail-closed evidence, not as soak passes.

The separate Instruments profile **PASSED as profiling-only evidence**: the
900-step no-validation target completed with zero scheduler drops, zero
catch-up steps, zero profile-window audio underruns/drops, 899 presents, and
status 0. Its Metal System Trace overhead is separate from the longer
unprofiled attempts.

## Host gate

The read-only M34 host gate passed before and after the relevant runs:

```text
m34_host_os=27.0
m34_host_metal_tool=/var/run/com.apple.security.cryptexd/mnt/com.apple.MobileAsset.MetalToolchain-v27.1.5237.12.iYB904/Metal.xctoolchain/usr/bin/metal
m34_host_gpucapture=/usr/bin/gpucapture
m34_host_gpudebug=/usr/bin/gpudebug
m34_host_display_count=2 online=2 asleep=0
m34_host_console_locked=No session_locked=unknown user_active=unknown
m34_host_thermal=No thermal warning level has been recorded
m34_host_ready=1
```

The exact snapshots are retained in each output directory's
`host-before.log`, `host-after.log`, `therm-before.log`, and display logs.
`pmset -g therm` reported no thermal, performance, or CPU-power warning.

## Pixel/replayer retry

Trace under test:

```text
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace
```

The first isolated retry was:

```sh
OUT=/tmp/sm64-modern-phase84d-gpudebug-retry-20260821-101500
TRACE=/tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace
mkdir -p "$OUT"
gpudebug --oneshot -q -t "$TRACE" -o "$OUT" \
  -c 'status' \
  -c 'go /commands/cb0/grp0/re0' \
  -c 'info color0' \
  -c 'info depth' \
  -c "fetch color0 --out $OUT/cb0-color.png" \
  -c "fetch depth --out $OUT/cb0-depth.png" \
  -c 'status' \
  > "$OUT/cb0-fetch.log" 2>&1
```

Static navigation and attachment `info` succeeded. The fetches returned
`error: replayer failed`; the final status was:

```text
Replayer:  error — failed to load trace: Encountered an XPC error: Connection invalid
```

No PNG exists in the output directory.

The explicit local-device retry used `gpudebug --list-devices` (device 0 was
the local Apple M5 Max) and:

```sh
OUT=/tmp/sm64-modern-phase84d-gpudebug-retry-20260821-101500-device0
TRACE=/tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace
gpudebug --oneshot -q --device 0 -t "$TRACE" -o "$OUT" \
  -c 'status' \
  -c 'go /commands/cb0/grp0/re0' \
  -c 'info color0' \
  -c "fetch color0 --out $OUT/cb0-color.png" \
  -c "fetch depth --out $OUT/cb0-depth.png" \
  -c 'status' \
  > "$OUT/fetch.log" 2>&1
```

This attempt returned `error: replayer failed` and:

```text
Replayer:  macbook-pro-3 (Mac17,6) — error — failed to load trace: Encountered an XPC error: Connection interrupted
```

No active `gpudebug` session remains. The static trace facts remain valid
(515 command buffers, 518 encoders, 28,216 draws), but the repeated XPC
failure prevents a non-clear-pixel or screenshot/reference-parity claim.

## Unprofiled native Release attempts

All attempts used the existing bundle without rebuilding it:

```text
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/local-runtime/SM64 Modern.app
```

The core invocation was run with ordinary Xcode and with all validation and
capture variables removed:

```sh
env -u MTL_DEBUG_LAYER -u MTL_SHADER_VALIDATION \
  -u MTL_SHADER_VALIDATION_REPORT_TO_STDERR -u MTL_CAPTURE_ENABLED \
  -u MTLCAPTURE_WAIT_FOR_SIGNAL \
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  SM64_MODERN_M9_OUTPUT_DIR="$OUT" \
  SM64_MODERN_M9_DERIVED_DATA="$OUT/derived-data" \
  SM64_MODERN_M9_RUNTIME_BUNDLE="/tmp/sm64-modern-m34-phase82f-capture-guard-r2/local-runtime/SM64 Modern.app" \
  SM64_MODERN_M9_SAVE_DIR="$OUT/save" \
  SM64_MODERN_M9_PROFILE_TICKS="$TARGET_STEPS" \
  SM64_MODERN_M9_PROFILE_WARMUP_TICKS=600 \
  SM64_MODERN_M9_PROFILE_TIMEOUT_SECONDS=1500 \
  ./script/m9_release.sh profile
```

### Target 43,200 — clean but target-missed boundary

Artifacts:

```text
/tmp/sm64-modern-phase84d-soak-20260821-103000/profile.log
/tmp/sm64-modern-phase84d-soak-20260821-103000/process-samples.tsv
/tmp/sm64-modern-phase84d-soak-20260821-103000/profile-command.log
/tmp/sm64-modern-phase84d-soak-20260821-103000/host-before.log
/tmp/sm64-modern-phase84d-soak-20260821-103000/host-after.log
```

The runtime armed `target_steps=43200`, reached warmup step 600 at
10:28:47.031, then ran until 10:39:43.874:

```text
fixed_step_scheduler_finished step=40006 ... catch_up_steps=0 dropped_steps=0
m9_profile_audio_final audio_rendered_delta=21017258 audio_underrun_delta=0 audio_dropped_delta=0
metal_presentation_diagnostic callbacks=39973 presented=39973 target_gap_ms=33 callback_idle_ms=16 paused=0 render_failure=0 host_compositor_evidence=insufficient
engine_thread_finished status=0 steps=40006
```

The measurement interval was approximately 656.838 seconds (10 minutes,
56.838 seconds) after warmup. The external sampler retained 331 samples:

```text
cpu_pct_min=5.5 cpu_pct_avg=9.39 cpu_pct_max=13.9
rss_kb_min=111888 rss_kb_max=130320 rss_delta_kb=18432
```

This is useful bounded runtime/cadence/RSS evidence, but it is not a passing
M9 profile gate: `m9_profile_complete` is absent, the requested 43,200 steps
were not reached, and `m9_release.sh` reported `M9 profile did not emit
m9_profile_complete`.

### Target 40,000 — host/display interruption

Artifacts:

```text
/tmp/sm64-modern-phase84d-soak-20260821-105000/profile.log
/tmp/sm64-modern-phase84d-soak-20260821-105000/process-samples.tsv
```

The run reached only step 4,500 before the retained log ended. During the
run the drawable changed from 960x720 to 1920x1440 and input focus toggled;
the latest scheduler record showed `catch_up_steps=2 dropped_steps=3`, and
audio had `underrun=1126`. No completion summary or clean shutdown record was
available. This attempt is failed evidence.

### Target 39,900 — later scheduler interruption

Artifacts:

```text
/tmp/sm64-modern-phase84d-soak-20260821-110000/profile.log
/tmp/sm64-modern-phase84d-soak-20260821-110000/process-samples.tsv
```

The run reached step 26,985 after a large host scheduling delay:

```text
fixed_step_scheduler_finished step=26985 ... catch_up_steps=3 dropped_steps=20 max_late_ns=211259250
m9_profile_audio_final audio_rendered_delta=14072491 audio_underrun_delta=0 audio_dropped_delta=0
metal_presentation_diagnostic callbacks=26873 presented=26873 target_gap_ms=283 callback_idle_ms=28 paused=0 render_failure=0 host_compositor_evidence=insufficient
engine_thread_finished status=0 steps=26985
```

The run therefore did not reach its 39,900-step target and is not accepted
as a soak pass. The target-missed and interruption boundaries are retained
instead of being reclassified as a complete long-run result.

## Separate Metal System Trace and thermal evidence

An initial `xctrace` command incorrectly combined `--all-processes` and
`--launch`; `xctrace` rejected it before launch (rc 47), and no artifact was
claimed from that attempt.

The corrected profiling-only run used an all-processes recorder and a
separately launched no-validation 900-step app:

```sh
OUT=/tmp/sm64-modern-phase84d-instruments-20260821-111000
RUNTIME="/tmp/sm64-modern-m34-phase82f-capture-guard-r2/local-runtime/SM64 Modern.app"
env -u MTL_DEBUG_LAYER -u MTL_SHADER_VALIDATION \
  -u MTL_SHADER_VALIDATION_REPORT_TO_STDERR -u MTL_CAPTURE_ENABLED \
  -u MTLCAPTURE_WAIT_FOR_SIGNAL \
  DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
  xcrun xctrace record --template 'Metal System Trace' --all-processes \
    --no-prompt --time-limit 60s --output "$OUT/metal-system.trace" &
/usr/bin/open -n "$RUNTIME" \
  --env SM64_MODERN_GAME_DIR=/Users/derek/Developer/sm64ex \
  --env SM64_MODERN_SAVE_DIR="$OUT/save" \
  --env SM64_MODERN_M9_PROFILE_TICKS=900 \
  --env SM64_MODERN_M9_PROFILE_WARMUP_TICKS=300
```

Recorder result:

```text
xctrace_rc=0
template=Metal System Trace
duration=61.159728 s
end-reason=Time limit reached
trace=/tmp/sm64-modern-phase84d-instruments-20260821-111000/metal-system.trace
```

The target PID was 80910. Its isolated runtime record was:

```text
m9_profile_complete steps=900 elapsed_ns=10000305583 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_rendered_delta=320171 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=118341632 rss_end_bytes=102694912 rss_delta_bytes=-15646720
fixed_step_scheduler_finished step=900 ... catch_up_steps=0 dropped_steps=0
metal_presentation_diagnostic callbacks=899 presented=899 target_gap_ms=21 callback_idle_ms=17 paused=0 render_failure=0 host_compositor_evidence=insufficient
engine_thread_finished status=0 steps=900
```

The trace table exports all completed with rc 0:

```text
/tmp/sm64-modern-phase84d-instruments-20260821-111000/metal-system-toc.xml
/tmp/sm64-modern-phase84d-instruments-20260821-111000/metal-gpu-intervals.xml
/tmp/sm64-modern-phase84d-instruments-20260821-111000/metal-application-command-buffer-submissions.xml
/tmp/sm64-modern-phase84d-instruments-20260821-111000/metal-current-allocated-size.xml
/tmp/sm64-modern-phase84d-instruments-20260821-111000/device-thermal-state-intervals.xml
/tmp/sm64-modern-phase84d-instruments-20260821-111000/gpu-counter-info.xml
/tmp/sm64-modern-phase84d-instruments-20260821-111000/metal-gpu-counter-intervals.xml
/tmp/sm64-modern-phase84d-instruments-20260821-111000/display-vsyncs-interval.xml
/tmp/sm64-modern-phase84d-instruments-20260821-111000/displayed-surfaces-per-second.xml
```

Derived target-PID summaries are retained at:

```text
/tmp/sm64-modern-phase84d-instruments-20260821-111000/derived-gpu-stats.txt
/tmp/sm64-modern-phase84d-instruments-20260821-111000/derived-submission-stats.txt
/tmp/sm64-modern-phase84d-instruments-20260821-111000/derived-allocation-stats.txt
```

They report:

```text
GPU intervals: target_rows=1819, scene_pass_rows=1798,
  duration_min=10620 ns mean=33085 ns max=139620 ns total=60.181 ms
Command submissions: target_rows=834,
  duration_min=60710 ns mean=187444 ns max=1430000 ns total=156.328 ms
Metal allocations: target_rows=209,
  bytes_min=196608 mean=16286831 max=21034435
Thermal: Nominal for 61.159727811 s
```

The GPU counter catalog exposes only `RT Unit Active`. No raster/fragment/
tiler utilization, GPU watts, package power, or sensor-temperature series was
available. These are profiling traces and bounded encoder/allocation facts,
not physical visual, direct-display, power, or thermal-closure proof.

## Acceptance boundary and follow-up

This phase proves:

- the exact retained trace remains statically navigable on the local host;
- the local `gpudebug` replayer still fails before attachment fetch with two
  distinct XPC connection errors;
- one unprofiled Release run exceeded ten minutes and reached status 0 with
  zero scheduler/audio drops, while explicitly missing its 43,200-step target;
- later long-run retries fail closed on host/display scheduling interruptions;
- a separate Metal System Trace captured target GPU intervals, submissions,
  allocations, display/vsync data, and a nominal thermal interval;
- the separate 900-step profiling target completed with zero profile-window
  scheduler/audio drops and status 0.

This phase does not prove:

- non-clear color/depth pixels or source/reference image parity;
- a completed zero-drop 10-minute M9 target profile;
- direct-to-display/compositor visibility, physical feel, temperature,
  power, or long physical-device acceptance;
- Developer ID signing, notarization, clean-machine Gatekeeper, M35
  distribution, route-shard closure, or human 120-star acceptance.

The next M34 retry requires a stable host/display interval and a target that
the runtime can complete (the observed 40,006-step boundary must be handled
explicitly), while the pixel retry requires a functioning `gpudebug`
replayer. Do not substitute the 900-step Instruments run or the target-missed
40,006-step run for those gates.

## Shared worktree ownership note

The worktree was clean before this Phase 84d worker started. During the
read-only evidence collection, concurrent shared-repository activity produced
the following additional uncommitted or untracked paths:

```text
SM64Modern/Configuration.swift
SM64Modern/MarioState.swift
script/test_mario_state_route_pair.sh
src/engine/level_script.c
src/game/level_update.c
src/game/level_update.h
src/pc/configfile.c
tests/sm64_modern_configuration_contract.c
tests/sm64_modern_mario_state_route_pair_contract.c
tests/sm64_modern_mario_state_route_swift_smoke.swift
.porting/porting-handoff-full-swift-twin-phase85b-mario-parity-repair.md
```

This worker did not edit, stage, commit, revert, or inspect those changes for
correctness. Parent review must preserve or isolate them. No Phase 84d commit
was created and nothing was pushed.
