# Full Swift Twin M34b Handoff

## Scope

M34b closes the repeatable Metal 4 API-validation, GPU-capture, and
resize/pause stress slice. It does not claim rendered-image parity, physical
display behavior, device-loss recovery, full Swift gameplay authority, or
human acceptance.

## Implementation

- `GameViewController` has an opt-in `SM64_MODERN_M34_STRESS=1` harness. It
  requests eight 4:3 content sizes, publishes backing-pixel sizes through the
  existing `EngineHost` resize mailbox, and requests presentation pause and
  resume without touching `CAMetalDisplayLink` from AppKit.
- `EngineHost` consumes presentation pause at an owner-thread simulation
  boundary and drains queued drawable sizes on every tick. `MetalRenderer`
  applies the size on the owner thread even when the display link is paused or
  has no drawable; its presentation callback remains the sole drawable owner.
- `script/test_metal4_production.sh` builds and ad-hoc-signs an isolated
  Release artifact, runs API/shader validation, runs a separate GPU-capture
  pass, and inspects the trace with stable `gpudebug find` queries. The passes
  are intentionally separate because Apple's capture tooling rejects
  `MTL_SHADER_VALIDATION=1` together with `MTL_CAPTURE_ENABLED=1`.

## Validation evidence

- `script/test_metal4_contract.sh` passes.
- `script/test_metal_scene_packet.sh` passes.
- Regenerated native Swift 6 Debug build succeeds; log:
  `/tmp/sm64-modern-m34b-build-3.log`.
- The production harness passes with a Release build/sign, API/shader
  validation, GPU capture, and trace inspection. Evidence directory:
  `/var/folders/th/x9l5jv8j6n76y9n941xty1440000gn/T/sm64-modern-m34b.g1UXSg/`.
  Key artifacts are `release-build.log`, `validation.log`, `capture.log`,
  `m34b.gputrace/`, `gpudebug.txt`, and `gpucapture-start.txt`.
- Validation log proves `m9_profile_complete steps=600`,
  `scheduler_dropped_steps=0`, `audio_dropped_delta=0`, four or more
  `metal_resize_applied` events, pause true/false, `metal_shutdown_drained`,
  `engine_thread_finished status=0`, and `application_stopped`, with no
  Metal validation/frame failure record.
- Capture log proves a real CAMetalLayer and three presented frames with
  clean shutdown. `gpudebug` finds the BGRA8Unorm drawable, memoryless
  Depth32Float attachment, `sm64_vertex / sm64_fragment` two-triangle draw,
  and MTL4 render-command encoder draw calls.

## Evidence boundary

This is source/build/runtime/API/GPU evidence on the local Apple M5 Max. It
does not prove that the fetched drawable matches the original game's pixels,
that warm-pipeline output is visually correct, or that resize/minimize,
display-scale, device-loss, controller, audio, or physical/human acceptance
is complete. M33 still has unexecuted live route shards, and M31 still reports
the C lifecycle/content bridge for unmigrated domains.

## Next slice

Start M31 authority closure: inventory the remaining C lifecycle/content
callbacks, promote the next complete value-only domain behind an explicit
Swift owner route, emit a C-replayable schema-4 oracle record, and run the
focused route contract plus the full native matrix. Keep M34's warm-pipeline
visual comparison, archive-reuse, minimize/device-loss, and physical/human
gates separate until their evidence exists.
