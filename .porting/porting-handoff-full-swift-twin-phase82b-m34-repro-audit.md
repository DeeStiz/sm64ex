# Full Swift Twin Handoff — Phase 82b M34 Reproducibility Audit

Date: 2026-08-21

## Scope and verdict

**COMPLETED / M34 structural production evidence passed.** This phase reran
the unchanged M34 two-pass production harness on the current awake, unlocked
host with the stable Xcode toolchain. The API/shader-validation pass passed
with zero scheduler drops; the separate capture pass passed its runtime and
trace checks but recorded capture-overhead scheduler drops. The trace and
noninteractive `gpudebug` inspection are retained for parent review.

This phase does not close M34's archive-reuse, screenshot/reference-parity,
sustained-performance, thermal, or physical-device acceptance gates.

## Exact run and host state

The unchanged command was:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase82b-audit.1fE3hs \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
./script/test_metal4_production.sh
```

The command exited `0` with:

```text
M34b_RESULT validation=pass capture=pass resize_pause=pass post_resume_presentation=pass trace=/tmp/sm64-modern-m34-phase82b-audit.1fE3hs/m34b.gputrace
```

The invocation-scoped toolchain was Xcode 26.6, build `17F113`, using the
macOS 26.5 SDK on the arm64 Release target. The read-only host gate reported:

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

The Release build succeeded and the local runtime is ad-hoc signed with
identity `-`; this is a runnable diagnostic candidate, not Developer ID or
distribution evidence. The build's inspected entitlements were
`get-task-allow=false` and `sustained-execution=true`. No source, credential,
keychain, host lock state, or acceptance ledger was changed.

## Retained artifacts

All artifacts are under:

```text
/tmp/sm64-modern-m34-phase82b-audit.1fE3hs/
```

Important files:

```text
validation.log
capture.log
m34b.gputrace/
gpucapture-boundaries.txt
gpucapture-start.txt
gpudebug.txt
release-build.log
release-sign-inspect.log
bundle-inspection.txt
signing.txt
spctl.txt
```

The GPU trace bundle is approximately `2,985,705,472` bytes. `gpucapture`
reported a Device boundary on the Apple M5 Max, captured 516 command buffers,
and completed in 28.8 seconds. It also printed:

```text
warning: failed to revert capture configuration (Target destination for message doesn't exist)
```

The trace was nevertheless created and passed the required noninteractive
`gpudebug` inspection. Preserve this tooling warning as a capture-infrastructure
caveat; it is not evidence of a renderer failure.

## API/shader-validation pass

The validation pass was launched with API and shader validation enabled before
Metal device creation. The decisive records in `validation.log` are:

```text
m9_profile_complete steps=600 elapsed_ns=8999364875 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_rendered_delta=288086 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=117473280 rss_end_bytes=124567552 rss_delta_bytes=7094272
fixed_step_scheduler_finished step=600 wakes=1750 late_wakes=224 catch_up_steps=0 dropped_steps=0 max_late_ns=3742126
metal_scene_status step=600 latest_packet=600 latest_draws=75 presented=519 gpu_completed=519 pending_uploads=0
metal_presentation_diagnostic callbacks=519 presented=519 target_gap_ms=607 callback_idle_ms=19 paused=0 render_failure=0 host_compositor_evidence=insufficient
metal_shutdown_drained frames=519 completion=519
engine_thread_finished status=0 steps=600
application_stopped
```

The bounded stress sequence was observed and acknowledged: 14 resize requests,
4 pause=true records, 3 pause=false records, one minimize observation, one
restore observation, 3 post-resume resize requests, 5 display-link pause=true
records, 5 pause=false records, 3 post-resume drawable observations, and 3
post-resume resize acknowledgements. The wrapper's validation error scan found
no Metal frame, API-validation, or shader-validation error/fault records.

The validation RSS delta was `7,094,272` bytes (`6.77 MiB`) for this bounded
run. This is a point-to-point process counter, not a sustained memory or leak
verdict.

## Capture pass and overhead boundary

The capture profile retained the same stress sequence and completed cleanly:

```text
m9_profile_complete steps=600 elapsed_ns=8999605125 scheduler_dropped_steps=5 scheduler_catch_up_steps=1 audio_rendered_delta=288086 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=127139840 rss_end_bytes=220495872 rss_delta_bytes=93356032
fixed_step_scheduler_finished step=600 wakes=1594 late_wakes=175 catch_up_steps=1 dropped_steps=5 max_late_ns=116335291
metal_scene_status step=600 latest_packet=600 latest_draws=75 presented=516 gpu_completed=516 pending_uploads=0
metal_presentation_diagnostic callbacks=516 presented=516 target_gap_ms=597 callback_idle_ms=28 paused=0 render_failure=0 host_compositor_evidence=insufficient
metal_shutdown_drained frames=516 completion=516
engine_thread_finished status=0 steps=600
application_stopped
```

The capture RSS delta was `93,356,032` bytes (`89.03 MiB`), and the wrapper's
capture error scan found no Metal frame or validation error/fault records. The
five dropped scheduler steps and one catch-up step are capture-overhead
evidence; they must not be conflated with the separate zero-drop validation
pass and must not support a sustained-performance claim.

## GPU trace inspection

The canonical script ran:

```sh
gpudebug --oneshot -q -t /tmp/sm64-modern-m34-phase82b-audit.1fE3hs/m34b.gputrace \
  -c 'go commands' -c 'list --all' -c 'find draw' -c 'find render' \
  -c 'find depth' -c 'find MTL4RenderCommandEncoder'
```

`gpudebug.txt` reports 516 command buffers and includes multiple
`CAMetalLayer Display Drawable` color attachments in `BGRA8Unorm`,
`Depth32Float` attachments, `sm64_vertex / sm64_fragment` draws, and
`MTL4RenderCommandEncoder drawPrimitives:Triangle` calls. It includes drawable
sizes of `960x720`, `800x600`, and `1024x768`, matching the resize stress
sequence. The noninteractive inspection produced no replayer or trace error.

This is structural GPU evidence only. It does not prove visible screenshot
correctness, non-clear reference pixels, visual parity, or human acceptance.

## Pipeline/archive and presentation boundary

Both `validation.log` and `capture.log` report:

```text
metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=missing
metal4_cache_diagnostic archive_reuse=false archive_exists=0 descriptor_cache_fallback=1 load_attempted=0
metal4_pipeline_cache_ready schema=2 archive_schema=1 archive_loaded=false
```

Shutdown records show archive serialization deferred with
`serializer_false`; the descriptor cache was flushed instead. Therefore the
binary archive-reuse gate remains **open/blocked** despite successful pipeline
warm-up and draw submission.

The logs prove owner-thread resize application, pause/resume transitions,
minimize/restore observations, post-resume drawable observations and resize
acknowledgements, and clean GPU drain. The host gate's single thermal query
reported no recorded warning, but no sustained FPS/GPU-time, memory-trend,
thermal, direct-to-display, or physical-device evidence was collected.

## Remaining gates

- Produce a valid loaded/reused Metal 4 binary archive; current runs remain
  descriptor-cache fallback.
- Independently inspect fetched non-clear attachments/reference pixels and
  perform screenshot/visual-parity review.
- Collect sustained FPS/GPU/memory/thermal evidence on the physical display;
  host readiness and a bounded run are not that evidence.
- Complete Developer ID/notarized/stapled distribution, clean-machine
  Gatekeeper/import/save/relaunch checks, and the human 120-star/device run.

Parent owns review and the automatic local Phase 82b commit. This worker did
not commit, push, publish, or mutate external state.

