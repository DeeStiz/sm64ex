# SM64 Modern Porting Memory

## Watch List

- The current macOS Makefile assumes versioned Homebrew GCC and cross-binutils that are not installed.
- SDL2 is available through `sdl2-compat`; GLEW is not installed at discovery time.
- A valid US ROM exists outside the repository and must be referenced without copying it into Git.
- The existing `60fps_ex.patch` renders interpolated frames but keeps gameplay at 30 Hz; it is not the target 60 Hz simulation.
- No reference traces or screenshots are checked into the repository.
- Developer ID Application signing is not currently available; development/App Store identities do not satisfy direct notarized distribution.

## Feature Status

| Domain | Status |
|---|---|
| macOS legacy build | Blocked; M0 in progress |
| AppKit host | Not started |
| Metal 4 device/presentation | Not started |
| Metal 4 rendering | Not started |
| Native input/audio | Not started |
| Gameplay parity | Not started |
| Swift gameplay | Not started |
| Full-world 60 Hz | Not started |
| Signing/notarization | Not started |

