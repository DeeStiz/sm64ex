# Full Swift Twin Handoff — Phase 81 M34 Ready-Host Production Capture

Date: 2026-08-21

## Scope and result

This phase reran the unchanged M34 production harness after the read-only host
gate reported an awake, unlocked visible session. The run is retained
fail-closed: the Release build and validation profile completed, but the
production gate rejected the validation profile because the fixed-step
scheduler dropped 72 steps. The GPU-capture pass was therefore not started by
the unchanged harness, and no M34 production acceptance is claimed.

Host readiness was checked with:

```text
./script/test_m34_host_readiness.sh
```

Observed host state:

```text
m34_host_os=27.0
m34_host_display_count=2 online=2 asleep=0
m34_host_console_locked=No session_locked=unknown user_active=unknown
m34_host_thermal=No thermal warning level has been recorded
m34_host_ready=1
```

The production command was exactly:

```text
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase81-awake \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
./script/test_metal4_production.sh
```

Exit status: `1`.

The harness stopped with the exact fail-closed message:

```text
test_metal4_production: runtime evidence missing in validation.log: scheduler_dropped_steps=0
```

No source, harness, public documentation, credential, or host-state change was
made in this phase.

## Preserved output

All generated artifacts are retained under:

```text
/tmp/sm64-modern-m34-phase81-awake/
```

The retained top-level evidence is:

- `release-build.log` — Release build completed with `** BUILD SUCCEEDED **`.
- `release-sign-inspect.log` — ad-hoc Release copy and local runtime bundle.
- `bundle-inspection.txt` — arm64 bundle/code-directory inspection.
- `signing.txt` and `spctl.txt` — local ad-hoc signing; `spctl` rejected the
  non-distribution artifact.
- `validation.log` — complete API/shader-validation runtime log.
- `validation.pid` — completed validation process record.
- `save/` — isolated runtime save/config output.
- `derived-data/` and `local-runtime/` — isolated build/runtime products.
- `phase81-command.log` — harness stdout/stderr, including the fail-closed
  rejection.

No `m34b.gputrace`, `gpucapture-*`, `gpudebug.txt`, or fetched GPU attachments
were produced: the unchanged script intentionally requires the validation
profile to pass before entering the capture profile.

## Validation evidence

The app launched and shut down normally on Apple M5 Max / Metal 4:

```text
window_ready layer=CAMetalLayer drawable=960x720 device=Apple M5 Max
metal_device_ready name=Apple M5 Max api=Metal4 format=BGRA8Unorm frame_slots=2
metal_scene_initialized filtering=1
m9_profile_armed target_steps=600 warmup_steps=60
m9_profile_warmup_complete step=60 rss_bytes=124190720 audio_rendered=30581
m9_profile_complete steps=600 elapsed_ns=9000577292 scheduler_dropped_steps=72 scheduler_catch_up_steps=1 audio_rendered_delta=287744 audio_underrun_delta=0 audio_underrun_rate_bps=0 audio_dropped_delta=0 rss_start_bytes=124190720 rss_end_bytes=130220032 rss_delta_bytes=6029312
fixed_step_scheduler_finished step=600 wakes=1703 late_wakes=11 catch_up_steps=1 dropped_steps=72 max_late_ns=1230046334
metal_shutdown_drained frames=548 completion=548
engine_thread_finished status=0 steps=600
application_stopped
```

The decisive production failure is `scheduler_dropped_steps=72`, not a build,
launch, render-failure, or shutdown error. Audio reported zero dropped and
zero new underrun deltas. The runtime reported 548 callbacks/presents and 548
GPU completions, but this is not a sustained cadence pass because the scheduler
drop gate failed.

## Resize, pause, minimize, restore, and post-resume evidence

`validation.log` retains the complete bounded stress sequence:

```text
m34_stress_resize_requested count=14
m34_stress_pause_requested paused=true count=4
m34_stress_pause_requested paused=false count=3
m34_stress_minimize_requested count=1
m34_stress_minimize_observed count=1
m34_stress_restore_requested count=1
m34_stress_restore_observed count=1
m34_stress_post_resume_resize_requested count=3
metal_display_link_pause_state paused=true count=3
metal_display_link_pause_state paused=false count=5
metal_resize_applied count=11
metal_presentation_resize_ack count=2
metal_presentation_drawable_observed count=2
metal_scene_presented count=548
```

The retained log includes post-resume acknowledgements with
`warmed=true`, `warmup_ticks=17`, and `owner_thread=true`, plus clean
`metal_shutdown_drained`/status-0 termination. The log vocabulary does not
emit separate `drawable_wait`, `drawable_commit`, or `drawable_signal` records;
therefore no claim about those low-level ordering events is made. The emitted
presentation records are the available ordering evidence:
`metal_presentation_resize_observed`, `metal_presentation_drawable_observed`,
`metal_scene_presented`, and `metal_presentation_resize_ack`.

## Pipeline/archive and performance boundaries

The validation pass used the descriptor-cache fallback, not archive reuse:

```text
metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=missing
metal4_cache_diagnostic archive_reuse=false archive_exists=0 descriptor_cache_fallback=1 load_attempted=0
metal4_pipeline_registration_ready archive_reuse=false lookup_archives=0 descriptor_cache=true
metal4_descriptor_cache_flushed ... bytes=72071 archive_deferred=runtime serializer returned false
```

The run has runtime memory counters (`rss_start_bytes=124190720`,
`rss_end_bytes=130220032`, `rss_delta_bytes=6029312`) and scheduler/audio/
presentation counters, but no FPS/GPU utilization, thermal trace, screenshot,
or fetched GPU attachment evidence. The host gate only reported no recorded
thermal warning; it does not prove a thermal or device-performance pass.

## Acceptance decision and next step

**M34 remains open.** The awake/unlocked host prerequisite is now proven, but
the unchanged production harness fails at the zero-scheduler-drop requirement
(`72` drops) before capture. The next attempt must preserve this output and
rerun on the same visible host only after diagnosing/removing the cadence
source, then require a fresh validation pass followed by the separate
`gpucapture`/non-interactive `gpudebug` pass. Do not promote M34 from this
run, and do not classify prior structural/clear-only traces as replacement
acceptance evidence.

## Repository validation

```text
git diff --check
```

Passed for the Phase 81 handoff-only change. Parent agent owns the automatic
local Phase 81 commit; this worker did not commit or push.
