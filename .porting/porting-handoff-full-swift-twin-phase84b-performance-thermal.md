# Full Swift Twin Handoff — Phase 84b Sustained Performance and Thermal Attempt

Date: 2026-08-21

## Scope and verdict

**COMPLETED / bounded native sustained-performance attempt.** The existing
ad-hoc Release runtime was exercised on the ready M5 Max host with a
3,600-step profile (600-step warmup plus a 3,000-step measurement window).
Two no-validation/no-GPU-capture runs completed with zero scheduler drops,
zero audio drops, zero profile-window audio underruns, approximately 60 Hz
display-link presentation, and bounded resident memory. A separate
Instruments Metal System Trace collected target GPU encoder timings, target
Metal allocation samples, and a nominal device thermal-state interval.

This does **not** close physical-device acceptance or a sustained thermal-soak
gate. The runtime window was approximately 60 seconds, the host thermal tool
reported only that no warning had been recorded, and the trace's GPU counter
set exposed only `RT Unit Active`; no raster utilization, GPU watts, or
temperature sensor series was available. The renderer still reports
`host_compositor_evidence=insufficient`, so no direct-to-display or visual/
feel conclusion is made.

No source, script, route ledger, credential, power policy, lock state, or
distribution artifact was changed.

## Host state and read-only preflight

The read-only host gate passed before, after, and after the Instruments run:

```text
m34_host_os=27.0
m34_host_metal_tool=/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/metal
m34_host_gpucapture=/usr/bin/gpucapture
m34_host_gpudebug=/usr/bin/gpudebug
m34_host_display_count=2 online=2 asleep=0
m34_host_console_locked=No session_locked=unknown user_active=unknown
m34_host_thermal=No thermal warning level has been recorded
m34_host_ready=1
```

`pmset -g therm` additionally reported:

```text
No thermal warning level has been recorded
No performance warning level has been recorded
No CPU power status has been recorded
```

The host was drawing from AC power with the internal battery at 80% and
`IOConsoleLocked = No`. These are host observations, not a thermal or
human-review pass. The retained snapshots are:

```text
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/host-before.log
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/host-after.log
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/host-after-instruments.log
```

## Exact baseline commands and artifacts

The baseline reused the already-produced local Release runtime from Phase
82f; it did not rebuild or change the repository:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
SM64_MODERN_M9_OUTPUT_DIR=/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818 \
SM64_MODERN_M9_RUNTIME_BUNDLE="/tmp/sm64-modern-m34-phase82f-capture-guard-r2/local-runtime/SM64 Modern.app" \
SM64_MODERN_M9_SAVE_DIR=/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/save \
SM64_MODERN_M9_PROFILE_TICKS=3600 \
SM64_MODERN_M9_PROFILE_WARMUP_TICKS=600 \
SM64_MODERN_M9_PROFILE_TIMEOUT_SECONDS=180 \
./script/m9_release.sh profile
```

The corrected sampled run's primary artifacts are:

```text
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/profile.log
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/profile-metrics.txt
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/profile-command.log
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/process-samples.tsv
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/host-before.log
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/host-after.log
```

An independent repeat, before the corrected sampler run, is retained at:

```text
/tmp/sm64-modern-phase84b-perf-20260821-094623/profile.log
/tmp/sm64-modern-phase84b-perf-20260821-094623/profile-command.log
```

The first sampler attempt is not used for CPU/RSS statistics because its
`ps` field list contained unsupported `thcount`; its runtime profile remains
valid and its sampler limitation is not hidden.

## Sustained runtime evidence

The corrected sampled run emitted:

```text
m9_profile_complete steps=3600 elapsed_ns=50000344250 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_rendered_delta=1599829 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=116867072 rss_end_bytes=120602624 rss_delta_bytes=3735552
fixed_step_scheduler_finished step=3600 wakes=10262 late_wakes=1704 catch_up_steps=0 dropped_steps=0 max_late_ns=9683125
metal_presentation_diagnostic callbacks=3596 presented=3596 target_gap_ms=16 callback_idle_ms=21 paused=0 render_failure=0 host_compositor_evidence=insufficient
engine_thread_finished status=0 steps=3600
application_stopped
```

At step 600 the renderer had presented 599 frames. At step 3600 it had
presented 3,596 frames. Therefore the post-warmup window contained 2,997
presentations over 50.000344 seconds, approximately **59.94 Hz**. The
independent repeat measured 2,998 post-warmup presentations over
49.999069 seconds, approximately **59.96 Hz**. The display-link target gap
was 16 ms in both runs; this is cadence evidence from the native runtime, not
a physical visual or feel assessment.

The independent repeat also completed with:

```text
m9_profile_complete steps=3600 elapsed_ns=49999068500 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_rendered_delta=1599829 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=117112832 rss_end_bytes=116113408 rss_delta_bytes=-999424
metal_presentation_diagnostic callbacks=3597 presented=3597 target_gap_ms=16 callback_idle_ms=7 paused=0 render_failure=0 host_compositor_evidence=insufficient
```

## CPU and memory sampling

`process-samples.tsv` contains 58 valid one-second `ps` samples for the
native Release process. The sampled process counters were:

```text
cpu_pct_min=6.5 cpu_pct_avg=8.79 cpu_pct_max=11.6
rss_kb_min=111808 rss_kb_max=117776 rss_kb_delta=5968
```

The `ps` CPU value is a process sample, not a GPU utilization or whole-system
power measurement. The runtime's profile RSS delta was +3,735,552 bytes in
the corrected repeat and -999,424 bytes in the independent repeat; both are
below the local M9 8 MiB growth ceiling.

## Separate Instruments GPU, allocation, and thermal trace

To keep profiling overhead separate from the baseline claim, a separate
all-processes Metal System Trace was run while launching a 900-step profile
with a 300-step warmup. The trace and exports are retained at:

```text
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/metal-system-all-processes.trace
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/metal-system-toc.xml
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/metal-system-runtime.log
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/all-xctrace-metal-gpu-intervals.xml
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/all-xctrace-metal-application-command-buffer-submissions.xml
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/all-xctrace-metal-current-allocated-size.xml
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/all-xctrace-metal-application-event-interval.xml
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/all-xctrace-gpu-counter-info.xml
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/all-xctrace-device-thermal-state-intervals.xml
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/all-xctrace-metal-gpu-counter-intervals.xml
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/xctrace-target-summary.tsv
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/xctrace-metal-current-allocated-target.tsv
```

The trace summary reports:

```text
template=Metal System Trace
duration=25.860726 s
target_process=SM64 Modern (87230)
```

Target runtime records during this separately profiled run were:

```text
m9_profile_complete steps=900 elapsed_ns=10000175833 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_rendered_delta=320171 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=118030336 rss_end_bytes=118554624 rss_delta_bytes=524288
metal_presentation_diagnostic callbacks=898 presented=898 target_gap_ms=25 paused=0 render_failure=0 host_compositor_evidence=insufficient
engine_thread_finished status=0 steps=900
application_stopped
```

The target GPU and allocation exports yielded:

```text
gpu_scene_rows=1796
unique_gpu_frames=898
gpu_duration_ns_min=16380 mean=33383 p50=31620 p95=40290 p99=46750 max=117960 total_ms=59.955
submission_rows=754
command_duration_ns_min=53040 mean=148435 p50=139710 p95=225540 p99=255290 max=1510000 total_ms=111.920
allocated_samples=209 min_bytes=196608 max_bytes=21034435 mean_bytes=16286831
```

The scene-pass rows are bounded GPU encoder timing records from the
profile-overhead trace. They are not a whole-device utilization percentage.
The allocation samples are `MTLDevice.currentAllocatedSize` observations,
not process RSS.

The Instruments thermal table reports a single nominal interval for the full
25.860726-second trace:

```text
thermal_state=Nominal
duration=25.86 s
```

The Instruments counter table exposed only:

```text
RT Unit Active
```

No raster/fragment/tiler utilization or GPU power counter was configured by
the available local template. `powermetrics` was attempted read-only with
`sudo -n` and was blocked without a password (`sudo: a password is required`);
no credentials were requested or entered. Consequently this phase does not
claim GPU utilization, GPU watts, package power, or sensor temperature.

A separate Game Performance attach trace was also retained at:

```text
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/game-performance-attach.trace
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/game-performance-toc.xml
/tmp/sm64-modern-phase84b-perf-sampled-20260821-094818/xctrace-runtime.log
```

Its default windowed recording was 10 seconds and it did not expose target
GPU rows, so it is auxiliary only. The Metal System Trace above is the
authoritative Instruments artifact for this phase.

## Acceptance boundary and follow-up

This phase proves:

- the ready M5 Max host ran two independent native Release 3,600-step
  profiles without scheduler or audio drops;
- the unprofiled baseline sustained approximately 59.9 Hz native
  display-link callbacks/presents for the bounded one-minute run;
- process CPU/RSS samples and runtime RSS deltas were collected;
- a separate Instruments trace captured target GPU encoder timings, target
  Metal allocation samples, and nominal thermal state;
- the host remained awake/unlocked with two online displays and no recorded
  thermal/performance warning before, after, or after Instruments.

This phase does not prove:

- a 10-/30-minute thermal soak or temperature/power ceiling;
- GPU utilization, GPU watts, package power, or a physical sensor trace;
- direct-to-display/compositor visibility, non-clear pixels, screenshot parity,
  physical-device feel, or human acceptance;
- Developer ID signing, notarization, clean-machine Gatekeeper, or M35
  distribution acceptance.

The next performance step is a separately scheduled longer physical soak with
an available privileged power/thermal counter source or an approved
Instruments/Power Profiler counter configuration. Keep that workload separate
from Metal API/shader validation and `gpucapture` runs.

Parent owns review and the automatic local Phase 84b commit. This worker did
not commit or push.
