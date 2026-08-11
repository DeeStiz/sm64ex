# Handoff: M4 Metal 4 Scene

## What Was Done

Implemented and validated the complete SM64 scene on the existing native Metal 4 presentation substrate. The legacy `GfxRenderingAPI` now targets a versioned fixed-width C rendering ABI; Swift records copied, immutable draw/texture/state packets and replays them from the existing owner-thread `CAMetalDisplayLink`. `MetalRenderer` dynamically compiles and caches MSL pipelines, uploads RGBA textures into private storage, binds argument tables and sampler/depth/blend/raster state, uses memoryless depth, explicit upload-to-fragment barriers and residency, retires resources by shared-event completion, and retains M3's exact wait/commit/signal/present and GPU-drained shutdown contracts. Rendering capability is published only after the bridge and renderer initialize. The validated implementation checkpoint is commit `cc6d542`.

## Ground Truth Comparison

The discovery report contains no checked-in GPTK capture, RenderDoc XML, Instruments trace, or memgraph, so external cross-implementation ground truth remains unavailable. M4 compared the native result against the ignored local OpenGL baseline `build/us_pc/baseline-evidence/opengl-title.png` and inspected a fresh current-source Metal trace:

- Native trace: `build/sm64-modern-m4-validation-accepted.gputrace`; fetched output: `build/sm64-modern-m4-validation-accepted.png`.
- Pass structure: one labeled reusable command buffer, one `SM64 Modern Scene Pass`, and 65 draws into a real 1920x1440 `BGRA8Unorm` Clear/Store drawable with a 0-byte memoryless `Depth32Float` Clear/DontCare attachment.
- Bindings: per-draw vertex and uniform addresses, textures, samplers, dynamic pipeline states, and depth/raster state were present through the Metal 4 argument table. Private scene textures and two residency sets were present. The selected steady-state frame had no new uploads; startup packets exercised uploads, while the producer/consumer barrier chain was also verified in source.
- Presentation: the captured API stream preserved `nextDrawable`, allocator reset, `waitForDrawable`, begin/encode/end, commit, completion-event signal, drawable signal, and present ordering.
- Output: both implementations show the tiled title background and complete Mario-face geometry/material semantics without black frames, missing geometry, or obvious corruption. Face scale/lighting and blinking text/sparkles differed by animation phase; deterministic pixel matching is deferred to M6 rather than treated as an M4 defect.
- Validation: the user advanced to handoff after reviewing the validation report and no visual defect was reported.

## What's Deferred

- `grep -R "STUB(M5)" SM64Modern src include` — install native keyboard/mouse/GameController routing and AVAudioEngine callbacks, then publish input/audio capabilities.
- `grep -R "STUB(M6)" SM64Modern src include` — define deterministic gameplay snapshot/effect schemas and record streams for parity comparison.
- `grep -R "STUB(M8)" SM64Modern src include` — replace legacy 30 Hz pacing with the audited fixed 1/60-second full-world clock.

## Known Issues

- No checked-in external rendering ground truth exists; the OpenGL comparison is local/ignored and not deterministic because M6 snapshots do not exist yet.
- Apple ASan leak detection is unavailable. Full Swift+C ASan found no memory error, normal `leaks` reported 0 leaks/0 bytes, and a bounded Metal HUD run showed stable memory, but this is not long-duration leak/performance acceptance.
- The legacy SDL AudioQueue shutdown path can still report `-66671`; native AVAudioEngine work belongs to M5.
- Linux, Windows, and web full product builds remain future regression gates. M4 passed the legacy macOS build and x86_64/i686 MinGW syntax checks; `emcc` was unavailable.
- Developer ID Application signing/notarization and sustained-execution Release provisioning remain external release prerequisites.

## Watch For

- Preserve the complete M3/M4 `MetalRenderer`, raw `CAMetalLayer`, owner-thread display link, immutable rendering packets, shared-event lifetime, and presentation order while adding M5 services.
- Publish input/audio capabilities only after complete callback tables and native services are installed successfully; do not advertise partial stubs.
- Route keyboard/mouse/GameController state through versioned POD platform contracts. Swift must not retain or traverse legacy gameplay object graphs.
- Keep AVAudioEngine render callbacks real-time safe: no blocking, allocation, logging, or engine-state mutation from the audio render thread. Make buffer ownership and underrun behavior explicit.
- M5 acceptance needs real keyboard/mouse/controller and audible-output evidence. Build success and synthetic callbacks do not establish control feel, device routing, latency, or audio quality.
- Preserve legacy SDL/OpenGL/D3D paths and save compatibility; the native Apple service path is parallel, not a replacement for portable backends.

## Key Decisions Made

- The source renderer remains authoritative and calls a narrow versioned C ABI; Swift receives copied POD packets rather than C object-graph pointers.
- M4 extends the single M3 queue, two frame slots, shared event, layer residency, and display-link owner instead of creating a parallel renderer or presentation loop.
- Runtime-generated N64 combiner variants compile as native MSL through Metal 4 compiler/pipeline descriptors and cache by shader/state key; Metal Shader Converter is not used.
- Scene textures use private storage with shared staging, explicit Blit-to-Fragment ordering, queue residency, and completion-fenced retirement. Depth is memoryless because it is cleared and discarded every frame.
- Durable state caches suppress identical pipeline/depth/bias/viewport/scissor calls without changing draw ordering or output.
- Rendering capability is an initialization truth: it becomes visible only after the core bridge and Metal scene renderer are both ready.

## Skills Needed Next

- `porting-methodology`
- `using-game-controller`
- `setting-up-macos-window` for AppKit keyboard/mouse routing conventions
- `build-macos-apps:build-run-debug`
- `build-macos-apps:telemetry`
- Use Apple AVAudioEngine documentation and the existing engine audio contract for the audio slice; no dedicated game-porting audio skill is currently available.
