# Handoff: M1 Callable C Core

## What Was Done

The legacy process entry was separated from initialization, stepping, stop requests, and shutdown. A public versioned POD C interface now exposes lifecycle, platform, and gameplay tables through `include/sm64_modern.h`; the engine is packaged as `libsm64core.a`, the legacy SDL/OpenGL executable hosts that same API through a private adapter, and `make abi-smoke` links an external C consumer while syntax-checking C++ compatibility. Gameplay remains at `cAuthority`, filesystem mounts and the main pool are released during orderly shutdown, and the milestone is committed as `69b89e0`.

## Ground Truth Comparison

- M1 is a non-rendering milestone, so no GPU capture, RenderDoc XML, Metal pass structure, draw-count, resource-binding, residency, or barrier comparison applied.
- No external translation-layer capture or checked-in independent reference artifact is available.
- The fresh ignored local capture `build/us_pc/baseline-evidence/m1-validation-window.png` (SHA-256 `f48c5f2ccbc4cde9c63b1b36d621c65078e893c6ba81817e6ee4c3c44ba8bf02`) was compared with M0's OpenGL title capture. Mario geometry, textures, background, text, colors, blending, and depth relationships remained consistent; animation pose and capture timing differed as expected.
- The current OpenGL executable was also launched under LLDB and AddressSanitizer. Both reached live title rendering, and normal Command-Q shutdown saved configuration and returned status 0.

## What's Deferred

- `grep -R "STUB(M2)" .porting` — replace the raw SDL executable host with the native AppKit application, stable bundle identity, `CAMetalLayer`, and dedicated engine thread.
- `grep -R "TODO(M5)" .porting` — replace SDL AudioQueue output with the AVAudioEngine demand-fed ring buffer and validate clean shutdown.
- `grep -R "STUB(M6)" include/sm64_modern.h` — define deterministic snapshot/effect payload schemas and record streams without exposing the C object graph.
- `grep -R "TODO(M6)" .porting` — add deterministic input recording, canonical state/effect hashes, first-divergence reports, and an audio checksum tap.

## Known Issues

- The raw SDL executable still emits bundle-identity, AppIntents/linkd, and window-tabbing warnings on macOS 27 beta; M2 replaces that host.
- Apple AddressSanitizer leak detection is unsupported on this platform. M1 passed an ASan runtime route without a memory-safety report, but no leak-sanitizer result is claimed.
- Full Linux, Windows, and web product builds were not run. The public header passed MinGW C/C++ checks and every M1-changed C path passed MinGW Windows syntax checks only.
- There are no external GPU/reference artifacts; the visual comparison is a local successful-rendering regression check, not an independent parity result.

## Watch For

- Keep `SM64ModernAbiHeader` first in every versioned structure, validate `abi_version` and `struct_size`, and preserve forward-compatible buffer handling.
- Keep lifecycle calls on one owner thread. `game_exit()` now requests a stop, while the host loop owns shutdown after the current frame returns.
- The core copies configuration and platform tables, but the platform `context` is host-owned. Do not pass the legacy engine's pointer-rich object graph into Swift or across concurrency domains.
- Preserve `libsm64core.a` as entry-point-free: `pc_main_entry.o` belongs only to the legacy executable.
- Continue isolating runtime writes with a temporary save path during validation, and provide `BASEROM` or `SM64_BASEROM_*` for future clean asset builds.
- Do not treat the existing interpolation patch as a 60 Hz simulation; gameplay remains at the legacy 30 Hz authority until M8.

## Key Decisions Made

- The host boundary uses versioned fixed-width POD values and function tables instead of sharing raw engine structures.
- M1 exposes one global gameplay authority gate and generic record envelopes only; stable subsystem identifiers and payload schemas wait for M6/M7.
- The private legacy adapter supplies SDL/OpenGL/audio callbacks to the same public lifecycle API that the AppKit host will consume, keeping the portable executable as a regression path.
- Stop requests are non-destructive inside gameplay code. Orderly shutdown saves configuration, stops controller/audio/graphics services, unmounts the virtual filesystem, and releases the main pool from the owner thread.

## Skills Needed Next

- `game-porting-skills:porting-start-milestone` to prepare M2 from this handoff and the goal document.
- `game-porting-skills:porting-methodology` for phase gates, ownership boundaries, and evidence discipline.
- `game-porting-skills:setting-up-macos-window` for the AppKit window, `CAMetalLayer`, display timing, and engine-thread contract.
- `build-macos-apps:appkit-interop` for the narrow Swift/AppKit bridge.
- `build-macos-apps:build-run-debug` for the signed development-app build, launch, LLDB, and runtime verification route.
