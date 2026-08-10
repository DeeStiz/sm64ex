# M0 Legacy macOS Baseline Evidence

## Environment

- Host SDK/toolchain: macOS 27 beta, Apple Clang 21.0.0, Swift 6.4.
- Legacy backends: SDL 2.32.70, GLEW 2.3.1, OpenGL.
- Build command: `make -j8 DEBUG=1 VERSION=us BASEROM=/absolute/path/to/baserom.us.z64`.
- ROM policy: the verified legal ROM remained outside this repository. Extracted
  assets and `.assets-local.txt` are ignored build inputs.

## Build and Runtime Results

- Result: successful Apple-silicon build and clean relink.
- Executable: `build/us_pc/sm64.us.f3dex2e` (Mach-O 64-bit arm64).
- Executable SHA-256:
  `5f2cf5af3375b5f72ec4560f2a83be39b9e105b86ea1a34ec2c8db5c2a7b1a2c`.
- Launch: windowed OpenGL title screen reached, Start input accepted, and the
  Peach intro rendered.
- Shutdown: Command-Q reached the normal shutdown path, saved configuration,
  and returned exit status 0.
- Runtime writes were isolated in a temporary directory. The first-launch
  configuration and save hashes were:
  - config: `8c18e72e50162f7b49649c3344e45238b9ba5683c8ca2a8111035c2d8000a9e1`
  - save: `feed6619f8ec0859df0bb02a88fdd34806ca7e424091da291cc637fdc40544c9`

## Local Evidence

These ignored artifacts are retained locally under
`build/us_pc/baseline-evidence/`:

| Artifact | Evidence | SHA-256 |
|---|---|---|
| `opengl-title.png` | OpenGL title screen and live Mario head | `e10a6ca091fb47b38102b30620e3518cb591a49992eb37bdee969a52c74d93e5` |
| `opengl-after-start.png` | Start input progressed into the Peach intro | `42a9c56a8127ee84cf3f15f3adf4a6ee78467c75c1c83cd7c4757c9a417a0e26` |
| `validation-lldb-title.png` | LLDB validation reached the live title renderer | `e30cecaf3968bf62cf16b5df52a3a17a8e1a2444c1649476d967d8376ce27e82` |
| `validation-lldb-intro.png` | LLDB validation accepted Start and rendered the attract sequence | `f15f1fe2667ea8b7ec722ed40e948d9e8f1dca98d94057a115ce320d6712de43` |
| `game-performance.trace` | Five-second Xcode Game Performance Overview attachment | trace bundle |

The trace completed successfully and contains time-profile plus CPU, GPU,
power, thermal, process, and per-layer metric schemas. It is short baseline
evidence, not a sustained-performance acceptance run.

## Validation Pass

- A forced isolated AddressSanitizer rebuild succeeded with
  `SANITIZE=address BUILD_DIR_BASE=build-asan` and carries its SDL 3 runtime
  search path without requiring a launch-time environment override.
- The first sanitizer run found a global buffer over-read during audio startup:
  the original fixed `0x100`-byte DMA read a 160-byte regional bank-set table.
  `gBankSetsData` is now explicitly zero-padded to the full accessible DMA
  range. The sanitizer build then reached live gameplay and exited normally
  with status 0 and no AddressSanitizer report.
- The isolated sanitizer build also exposed a generated-level-rule dependency
  ordering defect. The primary source rule now retains its recipe and source
  automatic variable while `.assets-local.txt` remains an additional
  extraction dependency.
- A post-fix normal Debug build reached live rendering, accepted Start, ran for
  five seconds, saved state, and exited normally with status 0.
- Apple AddressSanitizer reports that leak detection is unsupported on this
  platform. This pass therefore establishes no leak-sanitizer result.

## Evidence Gaps

- The repository has a TAS playback adapter but no deterministic input recorder,
  canonical gameplay-state hash, or first-divergence reporter. Those are M6
  deliverables, so no deterministic gameplay trace is claimed here.
- The SDL audio path has no pre-device PCM tap. Audio was exercised during the
  live launch, but no deterministic audio checksum is claimed.
- The screenshots were inspected for successful rendering only. They do not
  establish Metal parity, visual acceptance, or rasterization tolerances.
- Physical sustained M1/M5 performance, long-run memory stability, and frame
  delivery acceptance remain future validation work.

## Deferred Markers

- `STUB(M2)`: replace the raw SDL executable host with the native app bundle and
  stable bundle identity; the current host emits AppIntents, linkd, and window
  tabbing warnings on macOS 27 beta.
- `TODO(M5)`: replace SDL AudioQueue output with the AVAudioEngine demand-fed
  ring buffer and validate shutdown without the observed legacy AudioQueue
  `-66671` warning.
- `TODO(M6)`: add deterministic input recording, canonical state/effect hashes,
  first-divergence reports, and an audio-synthesis checksum tap.
