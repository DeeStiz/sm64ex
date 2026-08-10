# SM64 Modern Porting Memory

## Current Milestone

- M3 success criterion: device, queue, command allocator, drawable residency, clear, and present validate cleanly.
- Start M3 with `/porting-start-milestone m3`; preserve M2's AppKit/lifecycle boundaries and load `porting-handoff-sm64-modern-M2.md` before changing the layer or engine host.
- M3 may enable rendering capability only after its Metal device and presentation path are complete; native input/audio and 60 Hz simulation remain M5/M8 work.

## Watch List

- The legal US ROM and extracted assets remain local/ignored; future clean builds must receive `BASEROM` or the matching `SM64_BASEROM_*` environment variable.
- macOS still needs `i686-w64-mingw32-as` and `objcopy` for the one source-authored N64 sequence even though all game C/C++ uses Apple Clang.
- The existing `60fps_ex.patch` renders interpolated frames but keeps gameplay at 30 Hz; it is not the target 60 Hz simulation.
- M0/M1 screenshots and the short M0 performance trace are ignored local evidence, not checked-in ground truth or sustained-performance acceptance.
- The native AppKit host resolves the raw SDL bundle-identity warning; the legacy SDL AudioQueue shutdown code `-66671` remains deferred to M5.
- Apple AddressSanitizer leak detection is unavailable on this platform; later long-run leak acceptance needs another supported instrument.
- Full Linux, Windows, and web legacy builds remain regression gates; M1's changed C paths passed MinGW C syntax checks, not full product builds.
- Developer ID Application signing is not currently available; development/App Store identities do not satisfy direct notarized distribution.
- `com.apple.developer.sustained-execution` is retained for provisioned builds; local M2 Debug signing omits it because no matching `io.github.deestiz.sm64modern` development profile is installed.

## Feature Status

| Domain | Status |
|---|---|
| macOS legacy build | Implemented — Apple Clang arm64 build, external ROM extraction, OpenGL launch, LLDB/visual evidence, and ASan route pass |
| Callable C core | Implemented — versioned lifecycle/platform/gameplay POD ABI, static archive, legacy adapter, and C/C++ smoke consumer |
| AppKit host | Implemented — signed Swift/AppKit bundle, pixel-sized `CAMetalLayer`, menus/fullscreen, and dedicated 30 Hz C-core owner thread with clean shutdown |
| Metal 4 device/presentation | Not started |
| Metal 4 rendering | Not started |
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
