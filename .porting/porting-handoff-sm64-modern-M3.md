# Handoff: M3 Metal 4 Clear

## What Was Done

Implemented and validated the first native Metal 4 presentation path in the Swift/AppKit host. `GameView` configures the existing raw `CAMetalLayer` for an SDR `BGRA8Unorm`, double-buffered surface; `MetalRenderer` owns a Metal 4 queue, two reusable allocator/command-buffer slots, the layer residency set, a shared completion event, labeled clear commands, exact drawable synchronization/presentation ordering, apply-after-present resize handling, and GPU-drained teardown. The dedicated engine thread now runs a `CFRunLoop` that owns both the legacy 30 Hz lifecycle timer and `CAMetalDisplayLink`. The core rendering capability deliberately remains disabled until M4 supplies the scene backend. Validation/capture/HUD launch modes and PID-scoped runtime assertions were added to the canonical script. The implementation checkpoint is commit `8d7a54b`.

## Ground Truth Comparison

The discovery report contains no checked-in GPTK capture, RenderDoc XML, Instruments trace, or memgraph, so no external ground-truth comparison was possible. M3 instead established the first native Metal baseline:

- Fresh capture: `/tmp/sm64-modern-m3-validation-44458.gputrace` (2.7 MB).
- Structure: one labeled reusable command buffer, one labeled clear encoder, and zero draw calls, which is expected for the clear-only milestone.
- Resources: the `CAMetalLayer.residencySet` was attached to the queue, populated with the drawable, and committed; the shared completion event was labeled and present.
- Output: a 960x720 `BGRA8Unorm` render-target drawable using Clear/Store. The fetched ignored texture `build/sm64-modern-m3-validation-gpu.png` is uniformly dark SM64 blue with no seams, black regions, or corruption.
- No shader bindings or inter-pass barriers exist yet; those are expected M4 additions, not M3 discrepancies.

## What's Deferred

- `grep -R "STUB(M4)" SM64Modern` — publish rendering capability only after the native scene backend implements the core rendering callbacks.
- `grep -R "HARDCODED(M3)" SM64Modern` — replace the approved diagnostic clear, double-buffering/configuration defaults, and validation timeout with M4 renderer/scene configuration.
- `grep -R "STUB(M5)" SM64Modern` — install native keyboard/mouse/controller routing and AVAudioEngine callbacks.
- `grep -R "STUB(M6)" include src` — define deterministic gameplay snapshot/effect schemas and record streams.
- `grep -R "STUB(M8)" SM64Modern` — replace the legacy 30 Hz timer with the audited fixed 1/60-second full-world clock.

## Known Issues

- macOS denied `screencapture` because Screen Recording permission was unavailable. The fetched GPU output was self-inspected, but window chrome and human color acceptance were not independently captured.
- The automated environment compositor-throttled `CAMetalDisplayLink` after three frames. A changed window size was queued under LLDB, but a subsequent resized drawable and sustained Metal HUD memory trend were not observable; manually exercise focused resizing and a longer HUD run when practical.
- No checked-in reference artifacts exist, so the M3 capture is a local baseline rather than cross-implementation ground truth.
- Developer ID Application signing/notarization and the provisioned sustained-execution entitlement remain external release prerequisites.

## Watch For

- Extend the existing `MetalRenderer` queue, frame slots, shared event, and presentation path in M4; do not create a second queue or render loop for scene rendering.
- Keep `SM64_MODERN_PLATFORM_CAP_RENDERING` at zero until M4 implements and validates the core rendering callbacks and complete scene.
- The source renderer generates shader variants from N64 combiner IDs at runtime. M4 should generate native MSL/pipelines and cache them rather than using Metal Shader Converter.
- New M4 buffers, textures, depth targets, samplers, and pipelines must remain alive through shared-event completion and join explicit residency. Metal 4 command buffers do not retain resources.
- Add producer/consumer barriers only where M4 introduces real resource dependencies; M3's single clear pass correctly needs none.
- Preserve the raw `CAMetalLayer`, owner-thread display link, exact wait/commit/signal/present sequence, and apply-after-present layer updates.
- Rendering validation remains mandatory in M4: Metal validation, a fresh GPU capture, output-texture inspection, ASan, leaks, and human visual review.

## Key Decisions Made

- AppKit owns surface creation/configuration while one dedicated engine thread owns core lifecycle and every Metal display-link callback.
- The M3 renderer uses two reusable Metal 4 allocator/command-buffer slots and a shared-event completion value instead of allocating command infrastructure per frame.
- The layer's specialized residency set is attached to the queue once and removed only after all submitted frames drain.
- M3 uses the approved `BGRA8Unorm` SDR surface and fixed dark SM64-blue diagnostic clear; M4 scene output replaces the clear-only result.
- Resize changes are published by AppKit and consumed on the owner thread after presentation so they affect the next drawable.
- Debug labels, groups, validation/HUD modes, and capture signaling are permanent bring-up infrastructure rather than temporary diagnostics.

## Skills Needed Next

- `porting-methodology`
- `creating-metal4-shader-pipelines`
- `translating-to-metal4-api`
- `managing-metal4-resources`
- `managing-metal4-synchronization`
- `managing-metal-cpp-lifetimes`
- `presenting-metal-drawables`
- `using-metal-validation`
- `using-gpucapture`
- `using-gpudebug`
- `debugging-rendering-issues` if the first scene is incomplete or visually incorrect
