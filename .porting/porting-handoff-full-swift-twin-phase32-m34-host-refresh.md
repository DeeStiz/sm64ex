# Full Swift Twin Handoff — Phase 32 M34 Host/Compositor Refresh

Date: 2026-08-20

## Scope and verdict

This phase made one fresh M34 production attempt from the current checkout,
then repeated the capture-only pass separately because the canonical harness
stops after a failed API/shader-validation gate. No renderer, compiler,
parser, or public-document source change was made. M34 remains blocked: the
host is locked/headless from the compositor's point of view, the runtime
still presents only three frames, archive reuse is false, and every fetched
drawable/depth attachment is clear-only black.

The checkout was `99c3997e0933919381c24eff9938951b06b33cac`. Existing unrelated
worktree edits in `script/test_c_swift_pairing.sh`,
`script/test_live_route_oracle.sh`,
`tests/sm64_modern_live_route_oracle_contract.c`,
`tests/sm64_modern_live_route_oracle_smoke.swift`, and
`tests/sm64_modern_oracle_lifecycle_record.c` were preserved. This handoff is
the only tracked file changed by this phase.

## Host/compositor state

The host is an Apple M5 Max with Metal 4 on macOS 27.0. The selected toolchain
was `/Applications/Xcode-beta.app/Contents/Developer` (Xcode 27.0,
`Build version 27A5237l`). Before the run,
`system_profiler SPDisplaysDataType` reported both the built-in and DELL
displays as `Display Asleep: Yes`; `/tmp/sm64-m34-phase32-host-before.png` is
black. A reversible `/usr/bin/caffeinate -u -t 20` wake attempt reached the
login UI only: `/tmp/sm64-m34-phase32-host-after-wake.png` visibly says
“Touch ID or Enter Password”. No credentials were entered. After the run,
both displays again reported asleep and `/tmp/sm64-m34-phase32-host-after-run.png`
is black. Thus no unlocked visible GUI/compositor or Screen Recording-backed
app window was available for this attempt.

## Fresh two-pass artifacts

The fresh output directory is:

`/tmp/sm64-modern-m34-phase32-host-refresh-232810/`

The API/shader-validation pass used the canonical command:

```sh
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase32-host-refresh-232810 \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
./script/test_metal4_production.sh
```

The Release build/sign inspection completed and the runtime reached pipeline
registration, packet-specific warm-up, all stress resize/pause/minimize/
restore requests, and status-0 shutdown. The production harness correctly
failed closed at:

```text
m9_profile_complete steps=600 elapsed_ns=8999393792 scheduler_dropped_steps=67 scheduler_catch_up_steps=1 audio_rendered_delta=288084 audio_underrun_delta=0 audio_dropped_delta=0
metal_presentation_diagnostic callbacks=3 presented=3 target_gap_ms=1205 callback_idle_ms=9898 paused=0 render_failure=0 host_compositor_evidence=candidate
```

The validation log is
`/tmp/sm64-modern-m34-phase32-host-refresh-232810/validation.log`. It has
`metal4_archive_reuse enabled=false source=none fallback=descriptor_cache
reason=missing`, `metal4_cache_diagnostic archive_reuse=false archive_exists=0
descriptor_cache_fallback=1 load_attempted=0`, and the shutdown telemetry is
`metal_shutdown_drained frames=3 completion=3`, `engine_thread_finished
status=0 steps=600`, and `application_stopped`. There are no Metal API or
shader validation faults/errors in this log. The run has 12 owner-thread
resize applications, four paused and five resumed display-link state records,
but zero `metal_presentation_resize_ack` and zero
`source=display_link_presented_next_callback` records.

Because the validation gate failed, the capture pass was repeated manually
with validation disabled and `MTL_CAPTURE_ENABLED=1` plus
`MTLCAPTURE_WAIT_FOR_SIGNAL=1`. `gpucapture` returned 0 and produced:

`/tmp/sm64-modern-m34-phase32-host-refresh-232810/capture-manual/m34b.gputrace`

(`18 MiB`; boundary listing and capture logs are beside it). The capture log
is
`/tmp/sm64-modern-m34-phase32-host-refresh-232810/capture-manual/capture.log`.
It records three warmed scene presents, then no more display-link callbacks:

```text
m9_profile_complete steps=600 elapsed_ns=9000431750 scheduler_dropped_steps=0 scheduler_catch_up_steps=0 audio_rendered_delta=288086 audio_underrun_delta=0 audio_dropped_delta=0
metal_presentation_diagnostic callbacks=3 presented=3 target_gap_ms=16 callback_idle_ms=9966 paused=0 render_failure=0 host_compositor_evidence=candidate
metal4_archive_flush_result result=deferred fallback=descriptor_cache reason=serializer_false
metal_shutdown_drained frames=3 completion=3
engine_thread_finished status=0 steps=600
application_stopped
```

The capture-only pass has 15 owner-thread resize applications but zero
post-resume acknowledgement/next-callback records. It also has no
`metal_frame_failed`, validation, shader, or API fault/error lines. Both
passes report descriptor-cache fallback, not binary-archive reuse. The exact
runtime serializer/cache output is retained in the two logs, including the
flushed JSON cache paths and `serializer_false` result.

## GPU trace inspection and fetched pixels

The non-interactive `gpudebug --oneshot` outputs are retained at:

- `capture-manual/gpudebug/summary.txt`
- `capture-manual/gpudebug/details2.txt`
- `capture-manual/gpudebug/api-calls-all.txt`
- `capture-manual/gpudebug/details-fetch.txt`

The trace contains three reusable MTL4 command buffers, three render
encoders, three `sm64_vertex / sm64_fragment` draws of two triangles each,
960x720 `BGRA8Unorm` CAMetalLayer color attachments, memoryless
`Depth32Float` attachments, two residency sets, and the expected per-frame
`waitForDrawable`, command-buffer commit, event signal, `signalDrawable`, and
`present` calls. This is valid structural Metal 4 evidence only.

Fetched attachments are under `capture-manual/gpudebug/`:

```text
cb0-color.png cb1-color.png cb2-color.png
  SHA-256 4b9e717cce852c52a90696d35fa3d6435634eb94e029861adc1682e6241b94e2
cb0-depth.png cb1-depth.png cb2-depth.png
  SHA-256 cf96c5aa72f817ced94607e0e15bc8902d9b9657fa3fdee956d49b21e0e18f66
```

All six images are 960x720 and visually black. They are clear/store and
capture-replay diagnostics, not rendered-image correctness, reference parity,
physical-display quality, performance, or human acceptance. No same-size
non-clear C reference image is available in this phase.

## Focused checks

All passed:

- `script/test_metal4_contract.sh`
- `script/test_metal4_archive_presentation.sh`
- `script/test_metal_scene_packet.sh`
- `script/test_render_packet_capture.sh`
- `script/test_render_trace_adapter.sh`
- `bash -n` for the M34/release/build scripts
- `git diff --check`

The archive/presentation smoke remains synthetic diagnostic coverage; it does
not override the failed production run. No M34 acceptance, visual parity,
physical-device, sustained-FPS/GPU/memory/thermal, release, or human claim is
made.

## Exact next command

After an unlocked visible GUI session is available, with the app visible and
Screen Recording/compositor access granted, rerun the unchanged two-pass
harness:

```sh
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase32-unlocked-next \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
./script/test_metal4_production.sh
```

Require the validation and separate capture passes to complete, at least two
post-resume resize acknowledgements, sustained callbacks without scheduler
drops, a valid archive-reuse classification, and non-clear same-size pixels
before considering M34 closure. Do not promote this three-frame/clear-only
artifact.
