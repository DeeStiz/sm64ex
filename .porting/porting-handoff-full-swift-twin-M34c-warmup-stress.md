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

The updated production harness ran in:

`/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-modern-m34b.LtxxU0/`

The validation run reached 600 profile ticks, zero scheduler drops, zero audio
drop delta, repeated pause/resume, minimize/restore notifications, and clean
status-0 shutdown. It did not satisfy the new warmed presentation gate:
the display link stopped after three initial presents, all at the initial
drawable size, and no `metal_presentation_resize_ack` was emitted. The harness
therefore stopped before accepting the capture pass.

## Evidence boundary and blocker

This is an implementation/build/validation attempt, not new M34 visual or
physical acceptance. The current run reports
`metal4_archive_reuse enabled=false` with descriptor-cache fallback; a valid
flushed archive was not loaded. The remaining issue is live display-link/
compositor presentation after the initial three frames, not a claimed gameplay
or shader failure. Preserve this as a failed gate and recapture on a host where
post-resume drawable callbacks are observable.

## Next actions

1. Reproduce the M34 stress harness with a live post-resume drawable callback
   and prove at least two `metal_presentation_resize_ack` records.
2. Produce and reload a valid MTL4 archive so `archive_reuse enabled=true` is
   observed in a second isolated run.
3. Capture and inspect the warmed resized framebuffer with `gpudebug`; compare
   it to the C render packet/reference at a declared size.
4. Keep physical display, FPS/GPU/RSS, thermal, controller, audio, and human
   acceptance as independent gates.
