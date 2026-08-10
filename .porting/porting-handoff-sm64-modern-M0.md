# Handoff: M0 Legacy macOS Baseline

## What Was Done

The legacy Apple-silicon macOS target now builds with Apple Clang under Xcode's GNU Make 3.81 while preserving explicit toolchain overrides and non-macOS conditionals. The build accepts a legal ROM outside the repository, discovers SDL/GLEW through `pkg-config`, retains MinGW binutils only for the source-authored N64 sequence, and has explicit generated-file dependencies for clean parallel builds. The OpenGL executable launches, accepts Start, renders live title and gameplay scenes, and exits normally. LLDB, visual captures, a short performance trace, and an isolated AddressSanitizer route established the local M0 baseline. Validation fixed a generated-level-rule dependency error and zero-padded the regional bank-set table to the fixed `0x100`-byte audio DMA contract. The milestone implementation is committed as `da09521`.

## Ground Truth Comparison

- No external translation-layer capture, RenderDoc XML, or checked-in reference image was available, and M0 did not change rendering code.
- Fresh OpenGL title and attract-gameplay screenshots were inspected for successful scene output: expected geometry, textures, HUD, blending, and depth relationships were present without black frames or obvious corruption.
- The fresh captures were recorded beside the initial local OpenGL captures with SHA-256 values in `baseline-m0.md`; they establish new local baseline evidence rather than an independent renderer-parity result.
- No render-pass structure, draw-count, output-texture, or resource-binding comparison was performed because Metal rendering begins in M3/M4.
- The normal and sanitizer runtime routes produced the same initial save-file SHA-256, but deterministic gameplay-state and audio comparisons remain unavailable until M6.

## What's Deferred

- `grep -R "STUB(M2)" .porting` — replace the raw SDL executable host with the native app bundle and stable bundle identity.
- `grep -R "TODO(M5)" .porting` — replace SDL AudioQueue output with the AVAudioEngine demand-fed ring buffer and validate clean shutdown.
- `grep -R "TODO(M6)" .porting` — add deterministic input recording, canonical state/effect hashes, first-divergence reports, and an audio checksum tap.

## Known Issues

- The raw executable emits macOS 27 beta bundle-identity, AppIntents/linkd, and window-tabbing warnings; it still exits normally.
- SDL AudioQueue shutdown emitted error `-66671`; audio played during validation, but no deterministic PCM checksum exists.
- Apple AddressSanitizer reports leak detection as unsupported, so M0 establishes no leak-sanitizer result.
- Linux and Windows legacy targets were not compiled during this macOS-only milestone.
- Screenshots and the short Xcode performance trace are ignored local artifacts and are not portable repository evidence.

## Watch For

- Keep Makefile syntax compatible with GNU Make 3.81; do not reintroduce BSD make's `!=` assignments.
- Preserve the external-ROM policy and never add ROM-derived assets or baseline ROM files to Git.
- Keep the MinGW assembler/object-copy exception scoped to the source-authored sequence; game C/C++ should remain on Apple Clang.
- Do not remove the explicit `0x100` extent of `gBankSetsData`; the legacy audio initializer copies that complete range.
- M1 must introduce a callable static C core without breaking the existing executable, save format, or platform builds. ABI structs must remain versioned POD values and must not expose engine object pointers.

## Key Decisions Made

- Apple Clang is the supported macOS default because the former versioned Homebrew GCC discovery was unavailable and unnecessary.
- ROM configuration resolves version-specific environment paths first and permits the shared environment path only for single-version extraction, avoiding ambiguous multi-region builds.
- Sanitizer builds use a separate build directory and embed the SDL 3 runtime search path required by `sdl2-compat`; no launch-time `DYLD_LIBRARY_PATH` workaround remains.
- M0 deliberately stopped at baseline recovery. The Swift app, C lifecycle ABI, Metal renderer, native services, gameplay migration, and 60 Hz conversion remain separate milestones.

## Skills Needed Next

- `game-porting-skills:porting-start-milestone` to open M1 from this handoff and the goal document.
- `game-porting-skills:porting-methodology` for milestone scope and evidence discipline.
- `build-macos-apps:build-run-debug` for shell-first mixed C/Swift build and runtime validation.
