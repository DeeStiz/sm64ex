# Codebase Discovery Report: sm64ex

## Summary

sm64ex is a portable C/C++ port with approximately 51,000 lines of gameplay C, a single-threaded PC main loop, SDL window/input/audio backends, and OpenGL, D3D11, and D3D12 renderers. The renderer is already isolated behind `GfxRenderingAPI`, which makes a parallel Metal 4 backend feasible, but the current macOS Makefile assumes Homebrew GCC and GLEW and does not build on the installed Xcode 27 toolchain.

The native target will preserve the existing portable executable, add a Swift 6.4/AppKit host, and migrate gameplay through versioned POD C interfaces. The source renderer dynamically generates shader variants from N64 combiner IDs; the Metal backend therefore needs native MSL generation, pipeline caching, transient buffers, and explicit residency rather than shader conversion.

## Reference Artifacts

No traces or captures were checked into the repository at discovery. M0's
local evidence and explicit gaps are recorded in `baseline-m0.md`.

## Platform Readiness

| Area | Status | Finding |
|---|---|---|
| macOS build | Blocked | Makefile selects unavailable versioned Homebrew GCC and requires GLEW through pkg-config. |
| Windowing | Partial | SDL2 works on macOS; there is no native AppKit or CAMetalLayer path. |
| Content pipeline | Partial | ROM extraction and generated assets exist, but the extractor assumes a repo-root `baserom.<version>.z64`. |
| Input/audio | Partial | SDL2 backends exist; no GameController or AVAudioEngine backend exists. |
| Deployment | New target required | Existing executable has no app bundle, signing, entitlement, or macOS deployment configuration. |

## Graphics Backend Analysis

| Category | Finding | Metal 4 impact |
|---|---|---|
| Existing backends | OpenGL 2.1/legacy, D3D11, D3D12 | Preserve all; add a build-selected Metal backend. |
| Abstraction | C function tables for rendering and window management | Implement a narrow Objective-C-to-Swift function-table bridge. |
| Shaders | GLSL/HLSL strings generated at runtime from combiner IDs | Generate MSL variants and cache Metal pipeline states. |
| Binding | Per-draw vertex data and at most two sampled textures | One argument table per in-flight frame is sufficient initially. |
| Frame graph | No render graph; one immediate display-list translation path | Start with one color/depth render pass and one queue. |
| Synchronization | OpenGL implicit ordering | Metal uploads and draw consumption need explicit ordering/residency. |
| Threading | Single-threaded gameplay/render orchestration | Keep one engine owner thread; signal it from CAMetalDisplayLink. |
| Memory | C pools plus backend-owned shader/texture pools | Preserve CPU pools; add frame-delayed Metal resource retirement. |

## Platform Gaps and Risks

- `pc_main.c` owns initialization, the infinite loop, audio generation, and shutdown; it must be split into callable lifecycle functions before Swift can host it.
- Gameplay state uses global variables, pointer-rich structs, unions, macro fields, and 30 Hz frame counters. Swift migration requires explicit POD snapshots/effect records rather than importing raw object graphs.
- True 60 Hz world simulation is separate from the existing interpolation patch. Timers, integration rates, animation phase, camera, particles, scripts, rumble, audio scheduling, and RNG gates all require a timebase audit.
- ROM-derived assets must remain untracked. The distributable app must import and extract a user-selected legal ROM after installation.

## Scope Decisions

- **Language:** Swift 6.4 for the AppKit host, Metal 4 backend, and migrated gameplay; C/Objective-C shims at ABI boundaries.
- **Target:** Parallel Apple-silicon macOS 27 app named SM64 Modern (`io.github.deestiz.sm64modern`).
- **Rendering:** Native Metal 4, preserving the existing renderer abstraction and legacy backends.
- **Gameplay:** Mario action systems, interactions, camera intent, and representative Bob-omb Battlefield, Jolly Roger Bay, and first-Bowser actor slices.
- **Simulation:** Full-world fixed 60 Hz; no mixed-rate shipping mode. Legacy builds remain 30 Hz.
- **Distribution:** Asset-free Developer ID application with notarized ZIP/DMG; a Developer ID Application identity is an external prerequisite.
