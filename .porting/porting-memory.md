# SM64 Modern Porting Memory

## Current Milestone

- M5b success criterion: AVAudioEngine output feeds the existing 32 kHz stereo PCM contract through a real-time-safe buffer.
- Preserve the dedicated engine owner thread, versioned POD C boundary, complete M4 Metal scene path, validated M5a input service, and legacy portable backends.
- Publish audio capability only after the complete callback table, buffer ownership, underrun behavior, and native service are installed successfully.
- Approved M5b work: add a preallocated C11-atomic SPSC PCM ring and an Objective-C AVAudioSourceNode real-time-safe adapter; Swift remains lifecycle-only.
- Preserve the existing 1,100-frame target and 6,000-frame backlog ceiling, zero-fill underruns, drop excess new input, and expose bounded owner-thread telemetry.
- Start, recover default-output configuration changes, and stop AVAudioEngine on the engine owner thread; never allocate, lock, log, message Objective-C, call Swift, or mutate engine state from the render callback.
- Wire the existing audio callbacks/capability only after successful service startup, then cover ring behavior, ABI validation, canonical runtime verification, legacy-build preservation, and human audible/routing evidence.

### M5a Completion Evidence

- M5a implementation is commit `33c4db2`: a versioned fixed-width input snapshot and capability, the `CAPI_NONE` controller adapter, Swift GameController/AppKit capture, focus clearing, plist metadata, ABI checks, and bounded launch/activity telemetry.
- Native Debug launch verified the input bridge and snapshot callback on the engine owner thread; real AppKit L-key and left-mouse events reached the service, and Space advanced the C game from the title screen into gameplay. An Xbox Wireless Controller then enumerated and supplied analog-stick plus menu input, exposing missed short face-button edges at the opening dialog.
- The controller service now configures Apple's physical-input queue to depth 20 and drains immutable buffered states each 30 Hz engine tick, carrying a press/release pair forward for one tick while preserving the latest analog/held state. The signed build and runtime verifier pass; live telemetry recorded `controller_buffered_press_recovered buttons=0x4`, and the corresponding Xbox X / SM64 B input cleared the opening dialog.
- `make abi-smoke`, the Swift 6 Debug app build, signed `script/build_and_run.sh --verify`, and the legacy SDL/OpenGL macOS link pass.
- Physical Xbox acceptance now covers movement, A/jump, right-stick camera rotation, and menu input. The user reported that the C-stick camera direction feels inverted; source comparison confirms the native left/right/up/down translation matches both SDL backends exactly, so this is a legacy Lakitu/C-button ergonomics caveat rather than an accidental GameController axis-sign regression. Do not reverse the compatibility mapping without an explicit camera-control product decision.
- M5a validation passed signed runtime/LLDB, visual scene inspection, Metal API+GPU validation, full Swift+C ASan, `leaks` (0 leaks/0 bytes), bounded Metal HUD/RSS memory, ABI smoke, unsigned Release, the legacy macOS link, and x86_64/i686 MinGW syntax checks. GPU capture and reference-artifact comparison were not applicable to this input-only slice. The validation pass also added one-tick keyboard/mouse press latches, corrected negative full-scale axis mapping to -32768, and limited controller queue configuration to connection time.
- Automated and functional evidence still do not prove every controller model or subjective camera feel.

### M4 Completion Evidence

- M4 implementation is commit `cc6d542`: the legacy `GfxRenderingAPI` feeds a versioned fixed-width C ABI whose Swift recorder publishes immutable scene packets to the existing owner-thread `CAMetalDisplayLink`.
- Dynamic Metal 4 MSL/pipeline caching, private RGBA texture upload, argument tables, samplers, memoryless depth, state translation, barriers, residency, shared-event retirement, and GPU-drained teardown render the complete title scene; rendering capability is published only after bridge/renderer initialization.
- Final current-source trace `build/sm64-modern-m4-validation-accepted.gputrace` contains one labeled command buffer, one scene encoder, 65 draws, a 1920x1440 `BGRA8Unorm` Clear/Store drawable, and a 0-byte memoryless `Depth32Float` Clear/DontCare attachment. The fetched image is `build/sm64-modern-m4-validation-accepted.png`.
- Signed Debug runtime/LLDB, Metal API+GPU validation, full Swift+C ASan, `leaks` (0 leaks/0 bytes), bounded Metal HUD memory, ABI smoke, unsigned Release, legacy macOS link, and x86_64/i686 MinGW syntax checks passed. The user advanced to handoff after the validation report without reporting a visual defect.

## Watch List

- The legal US ROM and extracted assets remain local/ignored; future clean builds must receive `BASEROM` or the matching `SM64_BASEROM_*` environment variable.
- macOS still needs `i686-w64-mingw32-as` and `objcopy` for the one source-authored N64 sequence even though all game C/C++ uses Apple Clang.
- The existing `60fps_ex.patch` renders interpolated frames but keeps gameplay at 30 Hz; it is not the target 60 Hz simulation.
- Discovery has no checked-in GPU ground truth; local captures and screenshots are ignored evidence, not cross-implementation or sustained-performance acceptance.
- The native AppKit host resolves the raw SDL bundle-identity warning; the legacy SDL AudioQueue shutdown code `-66671` remains deferred to M5b.
- Apple AddressSanitizer leak detection is unavailable on this platform; later long-run leak acceptance needs another supported instrument.
- Full Linux, Windows, and web legacy builds remain regression gates; M1's changed C paths passed MinGW C syntax checks, not full product builds.
- Developer ID Application signing is not currently available; development/App Store identities do not satisfy direct notarized distribution.
- `com.apple.developer.sustained-execution` is retained for provisioned builds; local M2 Debug signing omits it because no matching `io.github.deestiz.sm64modern` development profile is installed.
- M5a physical acceptance covered Xbox movement, jump, camera, and menu input; other controller models, subjective camera feel, and input latency remain unproven.
- M5b must validate audible AVAudioEngine output and routing with human/device evidence; automated callback/build evidence alone cannot prove latency or audio quality.
- Keep native service callbacks real-time safe and owner-explicit: do not expose the legacy object graph to Swift, block the audio render thread, or publish input/audio capabilities before installation succeeds.

## Feature Status

| Domain | Status |
|---|---|
| macOS legacy build | Implemented — Apple Clang arm64 build, external ROM extraction, OpenGL launch, LLDB/visual evidence, and ASan route pass |
| Callable C core | Implemented — versioned lifecycle/platform/gameplay POD ABI, static archive, legacy adapter, and C/C++ smoke consumer |
| AppKit host | Implemented — signed Swift/AppKit bundle, pixel-sized `CAMetalLayer`, menus/fullscreen, and dedicated 30 Hz C-core owner thread with clean shutdown |
| Metal 4 device/presentation | Implemented — validated raw-layer Metal 4 clear/present, two reusable frame slots, explicit drawable residency, owner-thread display link, resize handoff, and GPU-drained shutdown |
| Metal 4 rendering | Implemented — complete-scene POD bridge/replay with dynamic MSL, private textures, memoryless depth, samplers, state, display lists, explicit residency/barriers, trace inspection, and clean Metal validation |
| Native input | Implemented — keyboard/mouse runtime passed; Xbox movement, jump, camera, and menu passed; legacy C-camera ergonomics caveat recorded |
| Native audio | Not started |
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
- M5a and M5b should implement native input and audio through separate existing platform contracts without disturbing `gfx_sm64_modern.c`, the immutable render packet boundary, or the M3/M4 presentation owner.
- M5a maps AppKit hardware key codes and GameController semantic controls into the persisted SDL virtual-key namespace. `GCController.current` supplies one active controller; immutable queued states recover short button edges while live captures retain current analog/held state.
- Configure `GCControllerInput.inputStateQueueDepth = 20` only when a controller connects, then drain `nextInputState()` once per 30 Hz engine tick. One-tick keyboard/mouse press latches cover the same between-tick edge case; focus loss clears held and pending state.
- GameController already supplies normalized deadzone/saturation behavior, so the native adapter adds no second deadzone. Full-scale axes preserve the signed `-32768...32767` range before legacy `/ 256` conversion.
- Native right-stick signs intentionally match both SDL controller backends' C-button mapping. The user's inverted-camera impression is a legacy Lakitu ergonomics caveat; do not reverse compatibility signs without an explicit camera-control decision.
