# SM64 Modern Porting Memory

## Current Milestone

- M1 success criterion: a callable static C core exposes versioned lifecycle, platform, and gameplay ABIs while the legacy executable still builds and runs.
- Approved scope: split process entry from init/step/stop/shutdown, add versioned POD ABI headers and a private legacy backend adapter, build/link a static core plus ABI smoke consumer, and keep gameplay at `cAuthority` with only generic snapshot/effect envelopes until M6/M7.

## Watch List

- The legal US ROM and extracted assets remain local/ignored; future clean builds must receive `BASEROM` or the matching `SM64_BASEROM_*` environment variable.
- macOS still needs `i686-w64-mingw32-as` and `objcopy` for the one source-authored N64 sequence even though all game C/C++ uses Apple Clang.
- The existing `60fps_ex.patch` renders interpolated frames but keeps gameplay at 30 Hz; it is not the target 60 Hz simulation.
- M0 screenshots and the short performance trace are ignored local evidence, not checked-in ground truth or sustained-performance acceptance.
- The raw SDL host emits bundle-identity/AppIntents warnings, and SDL AudioQueue shutdown emitted `-66671`; these are deferred to M2 and M5.
- Apple AddressSanitizer leak detection is unavailable on this platform; later long-run leak acceptance needs another supported instrument.
- Linux and Windows legacy builds were not rerun during M0; preservation remains an explicit regression gate.
- Developer ID Application signing is not currently available; development/App Store identities do not satisfy direct notarized distribution.

## Feature Status

| Domain | Status |
|---|---|
| macOS legacy build | Implemented — Apple Clang arm64 build, external ROM extraction, OpenGL launch, LLDB/visual evidence, and ASan route pass |
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
