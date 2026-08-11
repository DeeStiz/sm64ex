# Porting Goal: SM64 Modern

## Target

Create a parallel Apple-silicon macOS 27 application using Swift 6.4, AppKit, Metal 4, native Apple input/audio services, and a deterministic full-world 60 Hz simulation while preserving the legacy portable build and save compatibility.

## Key Decisions

- App identity: SM64 Modern (`io.github.deestiz.sm64modern`).
- Existing Linux, Windows, web, and legacy macOS paths remain supported.
- Swift never owns or shares raw C object-graph pointers across concurrency domains.
- Gameplay migrations use `cAuthority`, `shadowSwift`, and `swiftAuthority` gates.
- ROM-derived assets remain local and are never committed or shipped in public artifacts.

## Milestone Tracker

| Milestone | Success criterion | Status |
|---|---|---|
| M0: Legacy macOS baseline | Apple Clang build launches with externally supplied legal ROM assets and baseline evidence can be collected. | Complete |
| M1: Callable C core | Static core exposes versioned lifecycle/platform/gameplay ABIs while legacy executable still builds. | Complete |
| M2: AppKit host | Signed development app opens, owns a CAMetalLayer, and drives a dedicated engine thread. | Complete |
| M3: Metal 4 clear | Device, queue, command allocator, drawable residency, clear, and present validate cleanly. | Complete |
| M4: Metal 4 scene | Dynamic MSL shaders, textures, depth, samplers, state, and display lists render a complete scene. | Complete |
| M5a: Apple input | GameController, keyboard, and existing mouse-button bindings feed the current controller contracts with focus-safe state clearing. | Complete |
| M5b: Apple audio | AVAudioEngine output feeds the existing 32 kHz stereo PCM contract through a real-time-safe buffer. | Complete |
| M6: Gameplay parity | Deterministic replay and field/effect diagnostics gate Swift authority per subsystem. | In progress |
| M7: Swift gameplay | Approved Mario and representative actor slices run under Swift authority. | Pending |
| M8: Full-world 60 Hz | All interacting logic uses one fixed 1/60-second clock and passes deterministic/time-based gates. | Pending |
| M9: Release | Performance, validation, leaks, signing, notarization, and clean-machine checks pass. | Pending |

## Completed Milestone: M0

### Work Items

1. Replace the unavailable versioned-GCC macOS default with Apple Clang while honoring explicit tool overrides.
2. Discover SDL2/GLEW through pkg-config without changing non-macOS link behavior.
3. Accept an external ROM path through Make configuration/environment and leave it untracked.
4. Build and launch the legacy OpenGL executable, then record the baseline evidence available locally.

### Scope Boundary

Do not add the Swift app, C lifecycle ABI, Metal renderer, gameplay rewrites, or 60 Hz changes in M0. Those changes begin only after the recovered baseline is reviewed and validated.
