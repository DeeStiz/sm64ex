# Full Swift Twin Handoff — Phase 66 M34 Fixed-Build Rerun

Date: 2026-08-21

## Verdict

**OPEN.** This phase reran the unchanged M34 production harness from the
fixed `e182aa01` checkout with an invocation-scoped Xcode beta and an isolated
output directory. The Release build completed, but the live validation pass
failed closed because the fixed-step scheduler dropped 65 steps rather than
the required zero. No M34 acceptance claim is made, and the capture pass was
not reached.

This phase changed no source files or public documentation. Its only
workspace artifact is this handoff; the build and runtime artifacts remain in
the isolated `/tmp` directory listed below. No commit was made by this worker.

## Host and tool state

- Checkout: `e182aa01` (`fix: normalize engine runtime status types`), clean at
  invocation and after the run.
- Host: macOS 27.0 build `26A5406e`, Apple M5 Max, 40 GPU cores, Metal 4.
- Selected developer directory: `/Applications/Xcode-beta.app/Contents/Developer`.
  Xcode reports `27.0`, build `27A5237l`; the selected macOS SDK is `27.0`.
- `/usr/bin/gpucapture` is available (`2027.0.39`) and `/usr/bin/gpudebug`
  is available (`1.0`). No SM64 Modern process remained after the failed
  validation pass.
- `system_profiler SPDisplaysDataType` reported both the built-in Liquid
  Retina XDR display and the DELL S3220DGF as `Display Asleep: Yes`. It also
  reported no recorded thermal or performance warning in `pmset -g therm`.
  These are host observations, not FPS/GPU/thermal acceptance evidence.

## Canonical rerun

Exact command:

```sh
env DEVELOPER_DIR=/Applications/Xcode-beta.app/Contents/Developer \
  SM64_MODERN_M34_OUTPUT_DIR=/tmp/sm64-modern-m34-phase66.qELxRw \
  ./script/test_metal4_production.sh
```

The script exited `1` after the first (API/shader-validation) profile:

```text
test_metal4_production: runtime evidence missing in validation.log: scheduler_dropped_steps=0
```

The output directory is `/tmp/sm64-modern-m34-phase66.qELxRw/`.
The primary retained artifacts are:

- `release-build.log` (264,551 bytes)
- `release-sign-inspect.log`
- `bundle-inspection.txt`
- `signing.txt`
- `spctl.txt`
- `validation.log` (30,861 bytes)
- `validation.pid`

There is no `capture.log`, `gpucapture-start.txt`, `gpucapture-boundaries.txt`,
`gpudebug.txt`, or `m34b.gputrace` in this directory because the harness
correctly stopped before the capture profile.

## Release build and signing evidence

- Xcode Release build: **passed** (`** BUILD SUCCEEDED **`).
- Release bundle:
  `/tmp/sm64-modern-m34-phase66.qELxRw/derived-data/Build/Products/Release/SM64 Modern.app`
- Runtime bundle:
  `/tmp/sm64-modern-m34-phase66.qELxRw/local-runtime/SM64 Modern.app`
- The local runtime was ad hoc signed (`signing_state=ad hoc`, identity `-`),
  not Developer ID signed.
- `spctl.txt` reports the ad hoc distribution bundle as `rejected`; this is
  expected for a local ad hoc signature and is not a distribution verdict.
- Bundle inspection confirms arm64, bundle ID
  `io.github.deestiz.sm64modern`, Release entitlements with
  `get-task-allow=false` and `sustained-execution=true`.

## Live validation evidence

The validation profile was launched through `open --env` with
`MTL_DEBUG_LAYER=1`, `MTL_SHADER_VALIDATION=1`, and
`MTL_SHADER_VALIDATION_REPORT_TO_STDERR=1`, before Metal device creation.

- API/shader validation: no explicit Metal API, shader-validation, GPU-fault,
  or render-failure diagnostic appears in `validation.log`; however, the
  profile is **not a pass** because the required scheduler invariant failed.
- Profile completed its requested 600 steps and exited cleanly:
  `engine_thread_finished status=0 steps=600` and `application_stopped`.
- Warmup: `m9_profile_warmup_complete step=60 rss_bytes=110051328`.
- Profile summary:

  ```text
  m9_profile_complete steps=600 elapsed_ns=9000096875
    scheduler_dropped_steps=65 scheduler_catch_up_steps=12
    audio_rendered_delta=288085 audio_underrun_delta=0
    audio_underrun_rate_bps=0 audio_dropped_delta=0
    rss_start_bytes=110051328 rss_end_bytes=107823104 rss_delta_bytes=-2228224
  ```

- Scheduler detail:
  `wakes=1237 late_wakes=494 catch_up_steps=12 dropped_steps=65
  max_late_ns=1114567001`.
- The runtime emitted `host_compositor_evidence=candidate` with only three
  display-link callbacks/presents and `callback_idle_ms=9864`. Combined with
  both displays being asleep, this is consistent with a host/display
  scheduling problem, but the rerun does not prove that as the root cause.

## Metal 4 lifecycle and resize evidence

- Scene initialized: `metal_scene_initialized filtering=1`.
- Display-link scene presentations observed: 3 total:
  - frame 1: 960x720, one draw;
  - frame 2: 960x720, eight draws;
  - frame 3: 800x600, eight draws.
- Resize requests: 14 (`index=0` through `index=13`). Owner-thread
  `metal_resize_applied` records: 11.
- Pause requests: 4 true and 3 false. Display-link pause records: 4 true and
  5 false. Resume-waiting records: 4.
- One post-resume resize observation was emitted:
  `metal_presentation_resize_observed post_resume=true ... drawable=800x600
  source=display_link_post_present`.
- The requested `metal_presentation_resize_ack` and
  `metal_presentation_drawable_observed` strings were not reached in the
  required harness sequence before the scheduler failure.

## Archive and scheduler evidence

- Archive reuse was disabled for this fresh isolated run:
  `metal4_archive_reuse enabled=false source=none fallback=descriptor_cache
  reason=missing`.
- Pipeline cache reported `archive_loaded=false lookup_archives=0
  descriptor_cache_found=true`.
- 52 `metal4_pipeline_ready` records were emitted, all with
  `archive_reuse=false`.
- Shutdown reported descriptor-cache fallback rather than a binary archive:
  `metal4_archive_flush_result result=deferred fallback=descriptor_cache
  reason=serializer_false`.
- Scheduler acceptance is **failed**: `scheduler_dropped_steps=65`, not zero.

## Drawable ordering, capture, and pixel evidence

The source implementation still presents in the Metal 4 queue-level order
`waitForDrawable` → `commit` → `signalDrawable` → `present` at
`SM64Modern/MetalRenderer.swift:1047-1053`, with the completion event signaled
between commit and drawable signaling. This rerun did not produce a GPU trace,
so the ordering was not independently proven by `gpudebug` here.

- GPU capture: **not attempted by the harness after the validation failure**.
- `.gputrace`: none produced by this phase.
- `gpudebug` inspection: not applicable to a new trace.
- Fetched color/depth pixels: none produced by this phase.
- FPS/GPU time/Metal HUD: not collected by the unchanged harness.
- RSS was collected as above; no thermal sample, GPU timing, or physical
  display-quality evidence was collected.

## Validation and next unblock

- `git diff --check`: passed.
- Worktree remained clean apart from this new handoff artifact.
- No source/public-doc edits and no commit were made by this worker.

The next unblock is a fresh unchanged-harness run on an unlocked, awake,
visible GUI host with compositor/display access, where the validation profile
must first produce `scheduler_dropped_steps=0`. Only after that clear runtime
gate should the capture pass run and produce a new `.gputrace`; then inspect it
non-interactively with `gpudebug`, fetch attachments only if replay is ready,
and record actual wait/commit/signal/present structure and pixels. Developer ID
signing, notarization, FPS/GPU timing, thermal, clean-machine, and human
acceptance remain separate open M34/M35 gates.
