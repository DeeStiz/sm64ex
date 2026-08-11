# SM64 Modern Porting Memory

## Current Milestone

- M5 success criterion: GameController/keyboard/mouse input and AVAudioEngine output feed the existing engine contracts.
- Start M5 with `/porting-start-milestone m5`; read `porting-handoff-sm64-modern-M4.md` before changing host callbacks or publishing input/audio capabilities.
- Preserve the dedicated engine owner thread, versioned POD C boundary, complete M4 Metal scene path, and legacy portable backends while adding native Apple services.
- Publish input/audio capabilities only after their complete callback tables and native services are installed; M6 deterministic records and M8 fixed 60 Hz simulation remain out of scope.

### M4 Completion Evidence

- M4 implementation is commit `cc6d542`: the legacy `GfxRenderingAPI` feeds a versioned fixed-width C ABI whose Swift recorder publishes immutable scene packets to the existing owner-thread `CAMetalDisplayLink`.
- Dynamic Metal 4 MSL/pipeline caching, private RGBA texture upload, argument tables, samplers, memoryless depth, state translation, barriers, residency, shared-event retirement, and GPU-drained teardown render the complete title scene; rendering capability is published only after bridge/renderer initialization.
- Final current-source trace `build/sm64-modern-m4-validation-accepted.gputrace` contains one labeled command buffer, one scene encoder, 65 draws, a 1920x1440 `BGRA8Unorm` Clear/Store drawable, and a 0-byte memoryless `Depth32Float` Clear/DontCare attachment. The fetched image is `build/sm64-modern-m4-validation-accepted.png`.
- Signed Debug runtime/LLDB, Metal API+GPU validation, full Swift+C ASan, `leaks` (0 leaks/0 bytes), bounded Metal HUD memory, ABI smoke, unsigned Release, legacy macOS link, and x86_64/i686 MinGW syntax checks passed. The user advanced to handoff after the validation report without reporting a visual defect.

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
- M5 must validate real keyboard/mouse/controller input and audible AVAudioEngine output with human/device evidence; automated callback/build evidence alone cannot prove control feel, latency, routing, or audio quality.
- Keep native service callbacks real-time safe and owner-explicit: do not expose the legacy object graph to Swift, block the audio render thread, or publish input/audio capabilities before installation succeeds.

## Feature Status

| Domain | Status |
|---|---|
| macOS legacy build | Implemented — Apple Clang arm64 build, external ROM extraction, OpenGL launch, LLDB/visual evidence, and ASan route pass |
| Callable C core | Implemented — versioned lifecycle/platform/gameplay POD ABI, static archive, legacy adapter, and C/C++ smoke consumer |
| AppKit host | Implemented — signed Swift/AppKit bundle, pixel-sized `CAMetalLayer`, menus/fullscreen, and dedicated 30 Hz C-core owner thread with clean shutdown |
| Metal 4 device/presentation | Implemented — validated raw-layer Metal 4 clear/present, two reusable frame slots, explicit drawable residency, owner-thread display link, resize handoff, and GPU-drained shutdown |
| Metal 4 rendering | Implemented — complete-scene POD bridge/replay with dynamic MSL, private textures, memoryless depth, samplers, state, display lists, explicit residency/barriers, trace inspection, and clean Metal validation |
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
- M4 validation removed the temporary locked-session offscreen/readback route, added owner-thread and texture-size preconditions, suppressed redundant state bindings/compiler warnings, and captured the final scene from the real layer drawable.
- The selected final M4 frame and the local OpenGL baseline show the same title background and Mario-face scene semantics; animation phase changes face scale/lighting and blinking text/sparkles, so deterministic pixel comparison remains M6 work.
- M5 should implement native input/audio through the existing platform contracts without disturbing `gfx_sm64_modern.c`, the immutable render packet boundary, or the M3/M4 presentation owner.
