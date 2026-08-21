# Full Swift Twin Handoff — Phase 26 M34 Visible Capture Attempt

Date: 2026-08-20

## Scope and result

This phase made one bounded attempt at the strongest available M34 production
closure evidence on the current Apple M5 Max host. The existing two-pass rule
was preserved: API/shader validation ran separately from the capture-only
pass. No renderer, compiler, parser, or harness source change was justified
or made. M34 remains blocked for visible sustained presentation, archive
reuse, and non-clear/reference pixel evidence.

The worktree was clean at the start of the attempt. Other agents' unrelated
edits appeared during the run in
`script/test_c_swift_pairing.sh`,
`script/test_oracle_lifecycle_record.sh`,
`tests/sm64_modern_live_route_oracle_contract.c`,
`tests/sm64_modern_live_route_oracle_smoke.swift`, and
`tests/sm64_modern_oracle_lifecycle_record.c`; none of those files were
modified by this phase.

## Host/compositor evidence

- `screencapture` was available and succeeded, but the initial full-screen
  capture was entirely black while `system_profiler SPDisplaysDataType`
  reported both displays asleep.
- A reversible `/usr/bin/caffeinate -u -t 20` wake attempt reached the macOS
  login screen only. The retained screenshot
  `/tmp/sm64-m34-screen-after-wake.png` visibly shows “Touch ID or Enter
  Password”; no credentials were entered, so an unlocked visible GUI session
  and compositor-backed app window were unavailable.
- The exact Screen Recording/compositor boundary therefore remains host-side,
  not a source renderer diagnosis.

## API/shader-validation pass

Command:

```sh
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase26-visible \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
./script/test_metal4_production.sh
```

The Release build and ad-hoc runtime bundle succeeded. The first pass launched
and reached Metal 4 device/scene initialization, pipeline registration-ready,
warmup readiness, four resize/pause cycles, minimize/restore, post-resume
resize observation, and clean status-0 shutdown. It failed the harness's
fail-closed scheduler gate with:

```text
m9_profile_complete steps=600 scheduler_dropped_steps=64 scheduler_catch_up_steps=1 audio_dropped_delta=0
metal_presentation_diagnostic callbacks=3 presented=3 target_gap_ms=1211 callback_idle_ms=9837 paused=0 render_failure=0 host_compositor_evidence=candidate
metal_shutdown_drained frames=3 completion=3
engine_thread_finished status=0 steps=600
application_stopped
```

The log contains no `metal_frame_failed`, Metal validation error, or shader
fault. The archive path remains an explicit descriptor-cache fallback:

```text
metal4_archive_reuse enabled=false source=none fallback=descriptor_cache reason=missing
metal4_archive_flush_result result=deferred fallback=descriptor_cache reason=serializer_false
```

Retained first-pass artifacts:

- `/tmp/sm64-modern-m34-phase26-visible/validation.log`
- `/tmp/sm64-modern-m34-phase26-visible/release-build.log`
- `/tmp/sm64-modern-m34-phase26-visible/release-sign-inspect.log`
- `/tmp/sm64-modern-m34-phase26-visible/local-runtime/SM64 Modern.app`

## Separate capture-only pass

Because the production script stops after the validation gate, the same fresh
Release bundle was relaunched manually with
`MTL_CAPTURE_ENABLED=1` and `MTLCAPTURE_WAIT_FOR_SIGNAL=1`, with validation
disabled. `gpucapture` attached to the `Device` boundary and completed without
an error:

- Capture: `/tmp/sm64-modern-m34-phase26-visible/capture-manual/m34b.gputrace`
  (19 MiB)
- Capture log: `/tmp/sm64-modern-m34-phase26-visible/capture-manual/capture.log`
- Capture output: `/tmp/sm64-modern-m34-phase26-visible/capture-manual/gpucapture-start.txt`
- Boundary listing: `/tmp/sm64-modern-m34-phase26-visible/capture-manual/boundaries.txt`

This pass reached `m9_profile_complete` with
`scheduler_dropped_steps=0`, `audio_dropped_delta=0`, and clean status-0
shutdown, but the presentation diagnostic still recorded only three callbacks
and three presents with `callback_idle_ms=9957` and
`host_compositor_evidence=candidate`. The stress sequence issued all
post-resume resize requests and owner-thread `metal_resize_applied` events,
but no later display-link callback acknowledged them. Archive reuse remained
false and the runtime serializer returned false.

`gpudebug --oneshot` inspected the fresh trace and found:

- 3 reusable MTL4 command buffers, 3 render encoders, and 3 draw calls;
- 3 `CAMetalLayer` drawables at `960x720 BGRA8Unorm`;
- memoryless `Depth32Float` attachments;
- `sm64_vertex / sm64_fragment`, 2 triangles per draw;
- argument-table binding, scene/layer residency declarations, and repeated
  `waitForDrawable`, commit, `signalDrawable`, and `present` API calls.

The structural summary and detail logs are retained at:

- `/tmp/sm64-modern-m34-phase26-visible/capture-manual/gpudebug/summary.txt`
- `/tmp/sm64-modern-m34-phase26-visible/capture-manual/gpudebug/details2.txt`
- `/tmp/sm64-modern-m34-phase26-visible/capture-manual/gpudebug/fetch3.txt`

## Pixel/reference boundary

The fetched color/depth attachments for all three captured command buffers are
retained under:

`/tmp/sm64-modern-m34-phase26-visible/capture-manual/gpudebug/`

All three color PNGs are identical clear-only black
(`4b9e717cce852c52a90696d35fa3d6435634eb94e029861adc1682e6241b94e2`), and
all three depth PNGs are identical black
(`cf96c5aa72f817ced94607e0e15bc8902d9b9657fa3fdee956d49b21e0e18f66`).
Visual inspection confirmed black color and depth images. No checked-in,
same-size non-clear C reference image is available, so a non-clear/reference
comparison cannot be performed. These attachments prove capture structure and
clear/store behavior only; they do not prove rendered-image correctness,
visual parity, physical display quality, or human acceptance.

## Focused validation

Passed on the current checkout:

- `./script/test_metal4_contract.sh`
- `./script/test_metal4_archive_presentation.sh`
- `./script/test_metal_scene_packet.sh`
- `./script/test_render_packet_capture.sh`
- `./script/test_render_trace_adapter.sh`
- `git diff --check`
- explicit searches found no `metal_frame_failed`, Metal validation error, or
  shader fault in either retained runtime log.

## Status and exact next command

**Blocked — no source-local fault proven.** The current host can build, launch,
validate, capture, and structurally inspect the Metal 4 path, but remains
locked/headless from the compositor's point of view; it sustains only three
display-link callbacks and produces clear-only black fetched attachments.
Archive reuse is also unproven because the current device cache has only JSON
descriptor caches and the runtime serializer returns false.

After unlocking the session, leaving the app visible, and granting/confirming
Screen Recording access, rerun:

```sh
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase26-next \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
./script/test_metal4_production.sh
```

Require both passes to complete, then inspect the resulting trace with
`gpudebug` and compare warmed same-size drawable attachments against a declared
non-clear C render-packet/reference image. Do not promote M34 or claim visual
parity from this phase's three-frame/clear-only result.
