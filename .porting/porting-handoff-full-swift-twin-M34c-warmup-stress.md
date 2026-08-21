# SM64 Modern Full Swift Twin — M34c Warm-Pipeline/Stress Handoff

## What was done

M34c adds source-backed Metal 4 pipeline warm-up before scene submission,
truthful binary-archive/descriptor-cache telemetry, owner-thread drawable
request IDs, post-resume resize acknowledgement, repeated pause/resume stress,
and optional minimize/restore stress. The existing M34 two-pass rule remains:
API/shader validation and GPU capture are run separately.

## Validation evidence

Passed:

- `./script/test_metal4_contract.sh`.
- Metal scene packet smoke.
- Strict Swift 6 arm64 Debug and Release builds.
- `bash -n` and `git diff --check`.

The first warmup run exposed a real enqueue race: `waitUntilReady` could drain
Metal compiler tasks before the Swift compiler queue had enqueued them. Commit
`9509dfe0` adds an explicit `compileQueue.sync {}` barrier before waiting. The
follow-up run was `/tmp/sm64-modern-m34-afterwarmup.Nw05Wx`.

After the fix, Release reached three real presented frames, four resize/pause
cycles, post-resume resize observation, and clean Metal drain/status-0
shutdown. It no longer reports `metal_frame_failed` or a pending pipeline.
The harness still rejects the run because host/compositor pressure produced
`scheduler_dropped_steps=62` and presentation stopped at three frames after
the initial callbacks.

## Evidence boundary and blocker

This is an implementation/build/validation attempt, not new M34 visual or
physical acceptance. The current run reports
`metal4_archive_reuse enabled=false` with descriptor-cache fallback; a valid
flushed archive was not loaded. The remaining issue is host/compositor
presentation and scheduler pressure after the initial callbacks, not a
pipeline-readiness or shader failure. Preserve this as a failed gate and
recapture on an unlocked visible GUI host with Screen Recording access.
Commit `055b577e` additionally drains all registration-time pipeline tasks
before the profile starts. The latest validation log records
`metal4_pipeline_registration_ready` before the first scene packet; the same
host still reports 62 scheduler-dropped steps under API/shader validation, so
this improves readiness truthfulness without clearing the runtime gate.

## Next actions

1. Reproduce the M34 stress harness on a host without scheduler drops and
   prove at least two `metal_presentation_resize_ack` records after resume.
2. Produce and reload a valid MTL4 archive so `archive_reuse enabled=true` is
   observed in a second isolated run.
3. Capture and inspect the warmed resized framebuffer with `gpudebug`; compare
   it to the C render packet/reference at a declared size.
4. Keep physical display, FPS/GPU/RSS, thermal, controller, audio, and human
   acceptance as independent gates.
