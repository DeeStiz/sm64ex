# SM64 Modern Porting Memory

## Current Milestone

- M2 success criterion: a signed development app opens, owns a `CAMetalLayer`, and drives a dedicated engine thread.
- Start M2 with `/porting-start-milestone`; use the M1 handoff and callable C ABI rather than moving legacy engine object pointers into Swift.

## Watch List

- The legal US ROM and extracted assets remain local/ignored; future clean builds must receive `BASEROM` or the matching `SM64_BASEROM_*` environment variable.
- macOS still needs `i686-w64-mingw32-as` and `objcopy` for the one source-authored N64 sequence even though all game C/C++ uses Apple Clang.
- The existing `60fps_ex.patch` renders interpolated frames but keeps gameplay at 30 Hz; it is not the target 60 Hz simulation.
- M0/M1 screenshots and the short M0 performance trace are ignored local evidence, not checked-in ground truth or sustained-performance acceptance.
- The raw SDL host emits bundle-identity/AppIntents warnings, and SDL AudioQueue shutdown emitted `-66671`; these are deferred to M2 and M5.
- Apple AddressSanitizer leak detection is unavailable on this platform; later long-run leak acceptance needs another supported instrument.
- Full Linux, Windows, and web legacy builds remain regression gates; M1's changed C paths passed MinGW C syntax checks, not full product builds.
- Developer ID Application signing is not currently available; development/App Store identities do not satisfy direct notarized distribution.

## Feature Status

| Domain | Status |
|---|---|
| macOS legacy build | Implemented — Apple Clang arm64 build, external ROM extraction, OpenGL launch, LLDB/visual evidence, and ASan route pass |
| Callable C core | Implemented — versioned lifecycle/platform/gameplay POD ABI, static archive, legacy adapter, and C/C++ smoke consumer |
| AppKit host | Not started |
| Metal 4 device/presentation | Not started |
| Metal 4 rendering | Not started |
| Native input/audio | Not started |
| Gameplay parity | Not started |
| Swift gameplay | Not started |
| Full-world 60 Hz | Not started |
| Signing/notarization | Not started |

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
