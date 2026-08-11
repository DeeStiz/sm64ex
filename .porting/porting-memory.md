# SM64 Modern Porting Memory

## Current Milestone

- M4 success criterion: dynamic MSL shaders, textures, depth, samplers, state, and display lists render a complete scene.
- Start M4 with `/porting-start-milestone m4`; read `porting-handoff-sm64-modern-M3.md` before changing the Metal renderer or publishing rendering capability.
- Build on M3's raw `CAMetalLayer`, owner-thread `CAMetalDisplayLink`, two reusable Metal 4 frame slots, shared-event reuse, layer residency, and GPU-drained shutdown rather than creating a parallel presentation path.
- Keep `SM64_MODERN_PLATFORM_CAP_RENDERING` disabled until the M4 native scene backend implements the core rendering callbacks; native input/audio and 60 Hz simulation remain M5/M8 work.
- Approved M4 scope: add a versioned POD C rendering bridge; record immutable display-list scene packets at 30 Hz; replay them from the existing display link with dynamic MSL/pipeline caching, argument tables, transient vertex/upload buffers, private RGBA textures, samplers, depth, state, residency, barriers, and completion-safe teardown.
- M4 also owns capability publication, ABI/runtime smoke coverage, renderer telemetry, and removal of the M3 diagnostic clear placeholders; it does not own input, audio, gameplay migration, or the fixed 60 Hz simulation.

### M4 Execution Evidence

- The legacy `GfxRenderingAPI` now feeds a versioned fixed-width C ABI whose Swift recorder publishes immutable scene packets to the existing owner-thread `CAMetalDisplayLink`; the rendering capability is published only after the bridge and Metal renderer initialize.
- The Metal 4 replay path dynamically compiles and caches MSL pipelines, uploads RGBA textures into private storage, binds argument tables and sampler/depth/blend/raster state, manages two completion-fenced transient slots and residency, and retains M3's exact wait/commit/signal/present and drain-before-shutdown contracts.
- `make SM64_MODERN_NATIVE=1 DEBUG=1 BUILD_DIR_BASE=build/sm64-modern-debug abi-smoke -j8`, the canonical Debug `./script/build_and_run.sh --verify`, and a clean unsigned Release Xcode build passed during execution.
- Metal API and GPU validation were enabled for complete-scene replay through 33 GPU completions with no Metal validation error or fault; shutdown drained cleanly with engine status 0.
- GPU capture `build/sm64-modern-m4-execute.gputrace` contains 11 command buffers, 22 encoders, and 536 draws. A representative 85-draw command buffer includes explicit texture-upload, scene-render, and evidence-readback encoders, private RGBA8 textures, a memoryless Depth32Float target, point/linear and repeat/clamp/mirror samplers, depth states, and alpha-blended pipelines.
- Ignored local evidence includes `build/sm64-modern-m4-trace-output.png`, fetched from the captured render target, and `build/sm64-modern-m4-dynamic-shader.metal`, fetched from the captured runtime-generated shader source.
- The Mac was locked during automated execution, so the compositor originally delivered only three window display-link callbacks. The separate validation session regained live compositor access, captured the complete scene from the real layer drawable, and removed the temporary locked-session offscreen/readback path before final testing.

## Watch List

- The legal US ROM and extracted assets remain local/ignored; future clean builds must receive `BASEROM` or the matching `SM64_BASEROM_*` environment variable.
- macOS still needs `i686-w64-mingw32-as` and `objcopy` for the one source-authored N64 sequence even though all game C/C++ uses Apple Clang.
- The existing `60fps_ex.patch` renders interpolated frames but keeps gameplay at 30 Hz; it is not the target 60 Hz simulation.
- Discovery has no checked-in GPU ground truth; M0-M3 captures and screenshots are ignored local evidence, not cross-implementation or sustained-performance acceptance.
- The native AppKit host resolves the raw SDL bundle-identity warning; the legacy SDL AudioQueue shutdown code `-66671` remains deferred to M5.
- Apple AddressSanitizer leak detection is unavailable on this platform; later long-run leak acceptance needs another supported instrument.
- Full Linux, Windows, and web legacy builds remain regression gates; M1's changed C paths passed MinGW C syntax checks, not full product builds.
- Developer ID Application signing is not currently available; development/App Store identities do not satisfy direct notarized distribution.
- `com.apple.developer.sustained-execution` is retained for provisioned builds; local M2 Debug signing omits it because no matching `io.github.deestiz.sm64modern` development profile is installed.
- The automated M3 environment compositor-throttled after three frames and blocked `screencapture`; manually confirm focused-window resize, sustained Metal HUD behavior, and window-level visual output when practical.

## Feature Status

| Domain | Status |
|---|---|
| macOS legacy build | Implemented — Apple Clang arm64 build, external ROM extraction, OpenGL launch, LLDB/visual evidence, and ASan route pass |
| Callable C core | Implemented — versioned lifecycle/platform/gameplay POD ABI, static archive, legacy adapter, and C/C++ smoke consumer |
| AppKit host | Implemented — signed Swift/AppKit bundle, pixel-sized `CAMetalLayer`, menus/fullscreen, and dedicated 30 Hz C-core owner thread with clean shutdown |
| Metal 4 device/presentation | Implemented — validated raw-layer Metal 4 clear/present, two reusable frame slots, explicit drawable residency, owner-thread display link, resize handoff, and GPU-drained shutdown |
| Metal 4 rendering | In progress — complete-scene bridge/replay implemented with dynamic MSL, textures, depth, samplers, state, display lists, trace inspection, and clean Metal validation; awaiting the separate M4 validation gate |
| Native input/audio | Not started |
| Gameplay parity | Not started |
| Swift gameplay | Not started |
| Full-world 60 Hz | Not started |
| Signing/notarization | Partial — hardened Apple Development Debug signing works; sustained-execution Release provisioning and Developer ID/notarization remain external/future gates |

## Curated Knowledge

- M0 is committed as `da09521`; the durable validation record is `baseline-m0.md` and local captures live under ignored `build/us_pc/baseline-evidence/`.
- Xcode's GNU Make 3.81 does not support BSD make's `!=`; parse-time commands use `:= $(shell ...)`.
- The macOS default toolchain is Apple Clang, but the sequence-data rule deliberately uses MinGW PE/COFF binutils; do not broaden that exception to game code.
- External ROM precedence is version-specific `SM64_BASEROM_<VERSION>`, then single-version `SM64_BASEROM`, then the legacy repository-relative filename.
- Audio initialization performs a fixed `0x100`-byte DMA, so the generated regional `gBankSetsData` storage must retain its explicit `0x100` zero-padded extent.
- Reproduce the sanitizer route with `SANITIZE=address BUILD_DIR_BASE=build-asan`; the macOS link adds the SDL 3 runtime path needed by `sdl2-compat`.
- M1 is committed as `69b89e0`; `include/sm64_modern.h` is the public ABI, `libsm64core.a` excludes `pc_main_entry.o`, and `make abi-smoke` exercises C/C++ consumption.
- Lifecycle `initialize`, `step`, `request_stop`, and `shutdown` are single-owner-thread calls. Deep `game_exit()` requests a stop; the host loop owns orderly teardown.
- The core copies versioned configuration/platform tables during initialization; the platform `context` remains host-owned. Keep Swift away from the legacy C object graph.
- Gameplay remains at global `cAuthority`; the generic snapshot/effect envelope is intentionally marked `STUB(M6)` until deterministic schemas and record streams exist.
- M2 is committed as `8069b55` plus validation fixes `5f8304a`; `project.yml` generates the Swift 6.4/macOS 27 AppKit target and `script/build_and_run.sh` is the canonical build, sign, launch, logging, debugger, and verification entrypoint.
- The native `SM64_MODERN_NATIVE=1` archive uses `*_NONE`, excludes entry/legacy/API-backend members, and rebuilds when `Makefile` changes; legacy archives retain their original backend objects.
- `GameView.makeBackingLayer()` owns a `CAMetalLayer` whose `drawableSize` is updated in backing pixels. M2 deliberately creates no `MTLDevice`, display link, drawable, or render commands.
- `EngineHost` owns lifecycle calls on one dedicated thread, paces legacy simulation at 30 Hz, and synchronously completes owner-thread stop/shutdown before AppKit termination.
- M2 validation passed LLDB, fullscreen/red-close shutdown, Metal-negative validation, full Swift+C ASan, `leaks` (0 bytes), ABI smoke, signature/package checks, and a clean legacy rebuild; the ignored black-window capture is `build/sm64-modern-m2-validation.png`.
- M3 keeps the core rendering capability at zero while `MetalRenderer` independently proves the native substrate: `BGRA8Unorm`, two reusable Metal 4 command-buffer/allocator slots, the layer residency set on the queue, shared-event slot reuse, exact wait/commit/signal/present ordering, and apply-after-present resize publication.
- The dedicated engine thread now runs a real `CFRunLoop` with a 30 Hz lifecycle timer and an owner-thread `CAMetalDisplayLink`; AppKit only publishes pixel-size changes and synchronously stops the run loop for teardown.
- M3 is committed as `8d7a54b`. Validation on Apple M5 Max passed signed runtime/LLDB, Metal API and GPU validation, full Swift+C ASan, `leaks` (0 bytes), ABI smoke, and clean GPU-drained shutdown.
- The final M3 capture `/tmp/sm64-modern-m3-validation-44458.gputrace` is 2.7 MB with one labeled reusable command buffer, one labeled clear encoder, zero draws, committed layer residency, a shared event, and a 960x720 `BGRA8Unorm` Clear/Store drawable. The fetched ignored output is `build/sm64-modern-m3-validation-gpu.png`.
- M4 execute preserves the M3 presentation owner and adds the existing engine's rendering callbacks through `gfx_sm64_modern.c`; Swift never traverses the legacy display-list object graph and instead consumes copied POD draw/texture/state data.
- `MetalShaderCompiler` uses runtime MSL and Metal 4 compiler/pipeline descriptors; `MetalRenderer` owns packet replay, private textures, explicit blit/fragment barriers, memoryless depth, sampler/depth caches, argument tables, queue residency, retirement, and completion-safe resource reuse.
- M4 execution evidence is strong enough to begin `/porting-validate`, but it is not milestone acceptance: live human window inspection was blocked by the locked session, and native input/audio plus fixed 60 Hz simulation remain M5 and M8 respectively.
