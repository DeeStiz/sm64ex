# Full Swift Twin Handoff — Phase 21 M34 Metal 4 Closure Audit

Date: 2026-08-20

## Scope

This phase audited the current Metal 4 renderer/compiler, runtime evidence
parser, retained captures, and capture scripts for a source-local production
closure. No source change was justified: the source contracts and the live
trace both show the required MTL4 submission path, while the remaining failed
gates are host/compositor, archive/tooling, visual-reference, and physical
acceptance boundaries.

## Source and parser result

- `SM64Modern/MetalRenderer.swift` retains reusable MTL4 command
  buffers/allocators, per-submit scene/layer residency declarations, private
  uploads, memoryless depth, explicit blit-to-fragment barriers, drawable
  wait/commit/signal/present ordering, and owner-thread resize/presentation
  ownership.
- `SM64Modern/MetalShaderCompiler.swift` drains compiler enqueue and
  registration work before scene submission, keeps asynchronous MTL4 pipeline
  compilation, and reports binary-archive versus descriptor-cache fallback
  explicitly. The current host still reports `archive_reuse=false` with
  descriptor-cache fallback and the runtime serializer returns false when
  flushing a binary archive; this does not identify a source renderer fault.
- `SM64Modern/MetalCompilerBridge.m` and the source contract retain the MTL4
  compiler, argument-table, residency, and barrier APIs and reject legacy
  Metal binding/storage APIs and display-link `nextDrawable` acquisition.
- `script/test_metal4_archive_presentation.sh` remains fail-closed: it accepts
  a binary-archive reuse classification or an explicit descriptor-cache/
  compile fallback, requires registration readiness and first-frame evidence,
  and rejects incomplete, failed, or misordered shutdown logs.

No renderer/compiler/parser edit was made in this phase. In particular, the
clear-only fetched images are not a basis for inventing a source color or
geometry change and are not visual-parity evidence.

## Focused validation

Passed on the current checkout:

- `./script/test_metal4_contract.sh`
- `./script/test_metal4_archive_presentation.sh`
- `./script/test_metal_scene_packet.sh`
- `./script/test_render_packet_capture.sh`
- `./script/test_render_trace_adapter.sh`
- `bash -n script/test_metal4_contract.sh script/test_metal4_archive_presentation.sh script/test_metal4_production.sh script/build_and_run.sh script/m9_release.sh`
- `git diff --check`

The source/parser smoke classified the healthy synthetic case as
`binary_archive_reuse` and the retained baseline as
`descriptor_cache_fallback` with scheduler drops, three callbacks/presents,
and a clean drain. The fresh runtime log also passed the parser as
`descriptor_cache_fallback`, `scheduler_dropped_steps=0`, three callbacks/
presents, host-compositor candidate, and clean drain. These are diagnostic
classifications, not acceptance.

## Fresh bounded live diagnostic

Using the retained Release app bundle with a fresh 60-step profile and
`MTL_CAPTURE_ENABLED=1`/`MTLCAPTURE_WAIT_FOR_SIGNAL=1`:

- Runtime log: `/tmp/sm64-modern-m34-closure-live.9sRvJi/runtime.log`
- Capture: `/tmp/sm64-modern-m34-closure-live.9sRvJi/closure.gputrace`
- GPU summary: `/tmp/sm64-modern-m34-closure-live.9sRvJi/gpudebug.txt`
- The prior retained captures `/tmp/sm64-modern-m34-runtime-current/current-capture.gputrace`
  and `/tmp/sm64-modern-m34-recheck.p8V35S/m34-recheck.gputrace` were also
  re-opened with `gpudebug`; their summaries/details/fetch logs are retained
  beside the traces and agree with the fresh structural result.
- Fresh run reached `metal4_pipeline_registration_ready`, warmup readiness,
  three `metal_scene_presented` frames, zero scheduler/catch-up drops, clean
  `metal_shutdown_drained`, `engine_thread_finished status=0`, and
  `application_stopped`.
- `gpudebug` reports three reusable MTL4 command buffers, three render
  encoders and two-triangle draws, three `BGRA8Unorm` CAMetalLayer drawables,
  memoryless `Depth32Float` attachments, two residency sets, per-command
  residency declarations, three drawable waits/signals/presents, and the MTL4
  compiler completion path. No captured Metal fault/error was reported.
- The fresh runtime still reports only three display-link callbacks/presents
  followed by approximately one second of callback idle, classifying as a
  host/compositor candidate. It also reports
  `archive_reuse=false`, descriptor-cache fallback, and
  `metal4_archive_flush_result result=deferred`.
- Fresh fetched drawable attachments are clear-only black, as were the prior
  M34 captures. They cannot establish rendered-image correctness, reference
  parity, physical-display quality, or human approval.

## Remaining gates and blocker separation

Source/build/API/GPU structural evidence is healthy. M34 production closure
remains open for:

- an unlocked, visible GUI host with Screen Recording/compositor access that
  sustains callbacks and acknowledges post-resume resizes without scheduler
  drops;
- a valid MTL4 binary archive load/reuse on the target toolchain/device (the
  current runtime serializer returns false and uses the explicit descriptor
  cache fallback);
- a warmed capture whose drawable is compared against a declared C render
  packet/reference at the same size;
- minimize/device-loss, physical-display, sustained FPS/GPU/RSS/thermal,
  controller/audio, release, and human acceptance evidence.

These are not cleared by the black attachments or by the three-frame capture.

## Exact next acceptance command

After unlocking a visible GUI session and granting Screen Recording access,
close other Metal/capture clients and rerun the production two-pass harness:

```sh
SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-closure-next \
SM64_MODERN_M34_PROFILE_TICKS=600 \
SM64_MODERN_M34_PROFILE_WARMUP_TICKS=60 \
DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
./script/test_metal4_production.sh
```

Require both the API/shader-validation and separate GPU-capture passes to
finish; then inspect the emitted `m34b.gputrace` with `gpudebug` and compare
same-size warmed attachments to the C render packet. Do not promote M34 or
claim visual parity unless those independently captured pixels are non-clear
and match the declared reference.
