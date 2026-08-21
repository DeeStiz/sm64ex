# Full Swift Twin Handoff — Phase 82a M34 Scheduler Cadence

Date: 2026-08-21

## Scope and result

This phase diagnosed and fixed the M34 fixed-step cadence failure observed on
the awake/unlocked host. The fixed-step scheduler itself was correct: it was
being blocked by a synchronous Metal pipeline wait from the engine-owned
display-link callback. The callback and scheduler share the owner thread, so a
cold/registration pipeline burst made the scheduler miss approximately 1.2 s
of deadlines and report explicit dropped steps.

The source fix is intentionally bounded. Display-link rendering now probes the
packet's pipeline readiness without waiting. If a pipeline is still compiling,
the callback returns without submitting a clear-only frame; the immutable scene
packet remains available and the next callback retries. Pipeline/compiler
failures other than `pipelineNotReady` still propagate as render failures. The
fixed-step scheduler's rational deadlines, `max_catch_up=2`, explicit drop
counter, and production zero-drop gate were not weakened or reset.

## Before evidence

The Phase 81 ready-host output is retained at:

```text
/tmp/sm64-modern-m34-phase81-awake/
```

Its API/shader-validation profile reported:

```text
m9_profile_complete steps=600 elapsed_ns=9000577292 scheduler_dropped_steps=72 scheduler_catch_up_steps=1 audio_rendered_delta=287744 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=124190720 rss_end_bytes=130220032 rss_delta_bytes=6029312
fixed_step_scheduler_finished step=600 wakes=1703 late_wakes=11 catch_up_steps=1 dropped_steps=72 max_late_ns=1230046334
metal_presentation_diagnostic callbacks=548 presented=548 target_gap_ms=1246 callback_idle_ms=10 paused=0 render_failure=0 host_compositor_evidence=insufficient
```

The descriptor cache was retained and a second unchanged run was made at:

```text
/tmp/sm64-modern-m34-phase82a-cachecheck.KJPAYK/
```

That run still reported `scheduler_dropped_steps=71` with
`max_late_ns=1211909209`, proving that merely retaining the descriptor cache
did not remove the owner-thread stall. The original scheduler smoke passed
before any source change.

## Source change

Only `SM64Modern/MetalRenderer.swift` was changed. In the display-link callback
path:

- `warmPipelines` now returns a readiness boolean rather than synchronously
  calling `waitUntilReady`.
- Missing keys are still prepared through the compiler's asynchronous queue.
- `pipeline(for:)` is used as a nonblocking readiness probe.
- A not-ready packet returns before command-buffer encoding/presentation and is
  retried by the next callback.
- Compiler failures other than `pipelineNotReady` remain throwing failures.

This removes the blocking wait from the fixed-step owner thread while retaining
source-backed rendering and the no-clear-only-frame behavior.

## Validation

Focused checks passed after the change:

```text
./script/test_fixed_step_scheduler.sh
SM64 Modern fixed-step scheduler smoke passed

./script/test_metal4_contract.sh
SM64 Modern Metal 4 source contract passed

./script/test_metal4_archive_presentation.sh
SM64 Modern Metal 4 archive/presentation diagnostic smoke passed

git diff --check
passed
```

The canonical two-pass production command was run with the stable Xcode
toolchain:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase82a-fix.nOukFS \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
./script/test_metal4_production.sh
```

The command exited `0` and produced:

```text
M34b_RESULT validation=pass capture=pass resize_pause=pass post_resume_presentation=pass trace=/tmp/sm64-modern-m34-phase82a-fix.nOukFS/m34b.gputrace
```

The Release build completed with `** BUILD SUCCEEDED **`.

## After evidence — API/shader-validation profile

The validation log is:

```text
/tmp/sm64-modern-m34-phase82a-fix.nOukFS/validation.log
```

Decisive runtime evidence:

```text
m9_profile_complete steps=600 elapsed_ns=8999301583 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_rendered_delta=288086 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=117456896 rss_end_bytes=124403712 rss_delta_bytes=6946816
fixed_step_scheduler_finished step=600 wakes=1709 late_wakes=426 catch_up_steps=0 dropped_steps=0 max_late_ns=11159542
metal_presentation_diagnostic callbacks=520 presented=520 target_gap_ms=588 callback_idle_ms=22 paused=0 render_failure=0 host_compositor_evidence=insufficient
metal_shutdown_drained frames=520 completion=520
engine_thread_finished status=0 steps=600
application_stopped
```

The stress sequence remained present and acknowledged:

```text
resize_requests=14
pause_true=4
pause_false=3
minimize_observed=1
restore_observed=1
post_resume_resize_requests=3
display_link_pause_true=5
display_link_pause_false=5
post_resume_drawable_observed=3
post_resume_resize_ack=3
```

The validation profile therefore satisfies the fixed-step zero-drop gate while
retaining resize, pause, minimize, restore, and post-resume presentation
evidence.

## After evidence — capture profile

The capture log and noninteractive GPU inspection are:

```text
/tmp/sm64-modern-m34-phase82a-fix.nOukFS/capture.log
/tmp/sm64-modern-m34-phase82a-fix.nOukFS/gpudebug.txt
/tmp/sm64-modern-m34-phase82a-fix.nOukFS/m34b.gputrace
```

`gpudebug` contains CAMetalLayer `BGRA8Unorm` drawables, `Depth32Float`
attachments, `sm64_vertex / sm64_fragment` draws, and
`MTL4RenderCommandEncoder drawPrimitives:Triangle` calls. The capture profile
also retained the complete stress sequence and three post-resume resize
acknowledgements.

The capture instrumentation itself reported:

```text
m9_profile_complete steps=600 elapsed_ns=9000461458 scheduler_dropped_steps=7 scheduler_catch_up_steps=1 audio_rendered_delta=288085 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=126959616 rss_end_bytes=220758016 rss_delta_bytes=93798400
fixed_step_scheduler_finished step=600 wakes=1647 late_wakes=314 catch_up_steps=1 dropped_steps=7 max_late_ns=138905666
metal_presentation_diagnostic callbacks=518 presented=518 target_gap_ms=586 callback_idle_ms=22 paused=0 render_failure=0 host_compositor_evidence=insufficient
```

The capture pass is retained as GPU structural evidence and is not used to
claim a zero-drop runtime profile; the canonical harness gates zero drops on
the separate API/shader-validation pass, which passed. The capture overhead
must remain a documented boundary for any future sustained-performance claim.

## Remaining acceptance boundaries

This phase closes the source-level scheduler-cadence blocker and produces a
passing validation/capture harness result. It does not prove:

- binary archive reuse (`metal4_archive_reuse` remains
  `enabled=false ... fallback=descriptor_cache` and serializer flush remains
  deferred);
- visible screenshot correctness, reference-image parity, or clear/store
  interpretation;
- sustained FPS/GPU utilization, memory, thermal, or physical-device feel;
- clean-machine Gatekeeper acceptance, Developer ID signing, notarization, or
  stapling; or
- the 120-star human/device acceptance gate.

No credentials, host lock state, toolchain selection, distribution artifact, or
human-acceptance record was changed. Parent owns review and the automatic local
Phase 82a commit; this worker did not commit or push.
