# Full Swift Twin Handoff — Phase 82f Capture Archive Bypass

Date: 2026-08-21

## Scope and verdict

**COMPLETED / capture archive interaction resolved for the M34 harness.** The
capture profile now bypasses Metal 4 binary-archive loading, direct archive
pipeline lookup, and shutdown archive flushing only when
`MTL_CAPTURE_ENABLED=1`. It keeps the existing descriptor-cache/compiler
fallback and emits explicit capture-bypass telemetry. Ordinary processes keep
the Phase 82d binary archive path, and the API/shader-validation profile still
loads and preserves the binary archive evidence.

The unchanged two-pass M34 harness then passed on the awake host, produced a
non-empty GPU trace, and completed the canonical noninteractive `gpudebug`
inspection. This closes the prior GPUTools archive-interaction capture
failure, but it does not close visual parity, sustained performance/thermal,
physical-display, human-acceptance, or M35 distribution gates.

## Source and contract changes

- `SM64Modern/MetalShaderCompiler.swift`
  - Detects `MTL_CAPTURE_ENABLED=1` at compiler initialization.
  - Skips `SM64ModernLoadArchive` and leaves `lookupArchives` empty in the
    capture profile.
  - Logs `metal4_archive_capture_bypass ... lookup_archives=0
    compiler_fallback=enabled` and classifies the fallback as
    `reason=capture_enabled`.
  - Reports `load_attempted=0` when an archive exists but capture bypass is
    active, preserving truthful archive/file telemetry.
  - Skips shutdown archive serialization in the capture profile.
  - Leaves ordinary archive loading/reuse and validation-profile archive flush
    behavior unchanged.
- `script/test_metal4_capture_archive_guard.sh`
  - Adds static source/order checks and a synthetic capture-bypass log contract.
- `script/test_metal4_contract.sh`
  - Requires the capture guard and explicit bypass/flush markers.
- `script/test_metal4_archive_presentation.sh`
  - Accepts the explicit capture-bypass state while retaining the normal
    archive/load-attempt consistency checks.

No renderer scheduler, validation gate, capture harness, host state, route
ledger, credentials, or distribution artifact was changed.

## Focused validation

All focused checks passed:

```text
./script/test_metal4_capture_archive_guard.sh
SM64 Modern Metal 4 capture archive guard contract passed

./script/test_metal4_contract.sh
SM64 Modern Metal 4 source contract passed

./script/test_metal4_archive_presentation.sh
SM64 Modern Metal 4 archive/presentation diagnostic smoke passed

bash -n script/test_metal4_capture_archive_guard.sh \
  script/test_metal4_contract.sh script/test_metal4_archive_presentation.sh
git diff --check
passed
```

The stable Release build used by the harness completed with:

```text
** BUILD SUCCEEDED **
```

The existing deployment-target warning remains: the source target is 27.0
while the stable 26.5 SDK advertises support through 26.5.99.

## Host and exact M34 command

The read-only host gate passed immediately before and after the run:

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

The unchanged harness command was:

```sh
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer \
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase82f-capture-guard-r2 \
./script/test_metal4_production.sh
```

It returned:

```text
M34b_RESULT validation=pass capture=pass resize_pause=pass post_resume_presentation=pass trace=/tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace
```

## API/shader-validation evidence

Artifacts:

```text
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/validation.log
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/release-build.log
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/release-sign-inspect.log
```

Decisive records:

```text
metal4_archive_loaded path=/Users/derek/Library/Caches/io.github.deestiz.sm64modern/Metal4/pipelines-v2-s1-device-4294968887.metallib lookup_archives=1
metal4_archive_reuse enabled=true source=binary_archive fallback=none
metal4_pipeline_cache_ready schema=2 archive_schema=1 device=4294968887 archive_loaded=true lookup_archives=1 descriptor_cache_found=true
m9_profile_complete steps=600 elapsed_ns=9000299250 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_underrun_delta=0 audio_dropped_delta=0
fixed_step_scheduler_finished step=600 wakes=1675 late_wakes=99 catch_up_steps=0 dropped_steps=0 max_late_ns=2860042
metal_presentation_diagnostic callbacks=521 presented=506 target_gap_ms=570 callback_idle_ms=13 paused=0 render_failure=0 host_compositor_evidence=insufficient
metal4_archive_flush_result result=deferred fallback=descriptor_cache reason=metal_validation_profile
metal_shutdown_drained frames=506 completion=506
engine_thread_finished status=0 steps=600
application_stopped
```

The harness found no Metal API/shader validation error or fault marker. This
is independent validation and archive-reuse evidence, not visual acceptance.

## Capture evidence

Artifacts:

```text
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/capture.log
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/gpucapture-boundaries.txt
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/gpucapture-start.txt
/tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace
```

The trace bundle is non-empty (`du -sk` reports `2,923,004` KiB; 771 files).
`gpucapture start` completed in 28.0 seconds and wrote the trace. Its final
line was the tool warning `failed to revert capture configuration (Target
destination for message doesn't exist)` after capture completion; it did not
prevent trace creation, and the subsequent `gpudebug --oneshot` run completed
with no active debug session left behind.
The capture profile's decisive compiler/cadence records are:

```text
metal4_archive_capture_bypass enabled=true reason=MTL_CAPTURE_ENABLED archive_exists=1 descriptor_cache_found=1 lookup_archives=0 compiler_fallback=enabled
metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=capture_enabled
metal4_cache_diagnostic archive_reuse=false archive_exists=1 descriptor_cache_fallback=1 load_attempted=0
metal4_pipeline_cache_ready schema=2 archive_schema=1 device=4294968887 archive_loaded=false lookup_archives=0 descriptor_cache_found=true
m9_profile_complete steps=600 elapsed_ns=9001128042 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_underrun_delta=0 audio_dropped_delta=0
fixed_step_scheduler_finished step=600 wakes=1646 late_wakes=325 catch_up_steps=0 dropped_steps=0 max_late_ns=6111917
metal_presentation_diagnostic callbacks=522 presented=515 target_gap_ms=555 callback_idle_ms=21 paused=0 render_failure=0 host_compositor_evidence=insufficient
metal4_archive_flush_skipped path=/Users/derek/Library/Caches/io.github.deestiz.sm64modern/Metal4/pipelines-v2-s1-device-4294968887.metallib reason=capture_enabled
metal_shutdown_drained frames=515 completion=515
engine_thread_finished status=0 steps=600
application_stopped
```

The capture log contains no `metal4_archive_loaded` or
`metal4_archive_pipeline_hit` records. The capture profile also retained the
14 resize requests, 4 pause=true events, 3 pause=false events, 3 post-resume
resize requests, 5 display-link pause=true events, 5 pause=false events, and
3 post-resume resize acknowledgements required by the unchanged harness.

The separate capture profile is subject to capture overhead; its zero-drop
observation does not become a sustained performance claim. The host/compositor
classification remains `insufficient`, not a visible-layer or physical
display verdict.

## GPU-debug evidence

The harness ran the canonical selectors and the explicit rerun was:

```sh
gpudebug --oneshot -q \
  -t /tmp/sm64-modern-m34-phase82f-capture-guard-r2/m34b.gputrace \
  -c 'go commands' -c 'list --all' -c 'find draw' -c 'find render' \
  -c 'find depth' -c 'find MTL4RenderCommandEncoder' \
  > /tmp/sm64-modern-m34-phase82f-capture-guard-r2/gpudebug-rerun.txt 2>&1
```

The explicit rerun exited `0` and reported populated structural Metal 4
workload evidence, including:

```text
CAMetalLayer Display Drawable ... BGRA8Unorm
Depth32Float
MTL4RenderCommandEncoder drawPrimitives:Triangle
sm64_vertex / sm64_fragment ... 2 triangles
```

No error/failure marker was present in the retained `gpudebug-rerun.txt`.
This is structural trace evidence only; no screenshot/reference parity or
non-clear pixel claim is made here.

## Remaining acceptance gates

- Fetch and independently inspect non-clear color/depth attachments and
  compare against a source/reference image.
- Collect sustained FPS, GPU time, memory trend, thermal, direct-to-display,
  and physical-device feel evidence.
- Complete Developer ID signing, notarization/stapling, clean-machine
  Gatekeeper/import/save/relaunch evidence, and 120-star human acceptance.

Parent owns review and the automatic local Phase 82f commit. This worker did
not commit, push, publish, mutate credentials, change host power/lock state,
or alter route ledgers.
