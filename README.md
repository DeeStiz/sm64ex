# sm64ex
Fork of [sm64-port/sm64-port](https://github.com/sm64-port/sm64-port) with additional features. 

Feel free to report bugs and contribute, but remember, there must be **no upload of any copyrighted asset**. 
Run `./extract_assets.py --clean && make clean` or `make distclean` to remove ROM-originated content.

Please contribute **first** to the [nightly branch](https://github.com/sm64pc/sm64ex/tree/nightly/). New functionality will be merged to master once they're considered to be well-tested.

*Read this in other languages: [Español](README_es_ES.md), [Português](README_pt_BR.md), [简体中文](README_zh_CN.md) or [Bahasa Melayu](README_ms_MY.md).*

This branch also contains the native Apple-silicon **SM64 Modern** application.
Its current architecture, build commands, qualification matrix, and evidence
boundaries are documented in [docs/SM64Modern.md](docs/SM64Modern.md).

## New features

 * Options menu with various settings, including button remapping.
 * Optional external data loading (so far only textures and assembled soundbanks), providing support for custom texture packs.
 * Optional analog camera and mouse look (using [Puppycam](https://github.com/FazanaJ/puppycam)).
 * Optional OpenGL1.3-based renderer for older machines, as well as the original GL2.1, D3D11 and D3D12 renderers from Emill's [n64-fast3d-engine](https://github.com/Emill/n64-fast3d-engine/).
 * Option to disable drawing distances.
 * Optional model and texture fixes (e.g. the smoke texture).
 * Skip introductory Peach & Lakitu cutscenes with the `--skip-intro` CLI option
 * Cheats menu in Options (activate with `--cheats` or by pressing L thrice in the pause menu).
 * Support for both little-endian and big-endian save files (meaning you can use save files from both sm64-port and most emulators), as well as an optional text-based save format.

Recent changes in Nightly have moved the save and configuration file path to `%HOMEPATH%\AppData\Roaming\sm64ex` on Windows and `$HOME/.local/share/sm64ex` on Linux. This behaviour can be changed with the `--savepath` CLI option.
For example `--savepath .` will read saves from the current directory (which not always matches the exe directory, but most of the time it does);
   `--savepath '!'` will read saves from the executable directory.

## Building
For building instructions, please refer to the [wiki](https://github.com/sm64pc/sm64ex/wiki).

**Make sure you have MXE first before attempting to compile for Windows on Linux and WSL. Follow the guide on the wiki.**

### Legacy portable macOS baseline build

The original portable macOS build uses Xcode's Apple Clang and discovers SDL2
and GLEW with `pkg-config`. With those dependencies installed, a legal ROM can
remain outside the repository:

```sh
brew install sdl2-compat glew pkgconf mingw-w64
make VERSION=us BASEROM=/absolute/path/to/baserom.us.z64
```

For an isolated AddressSanitizer build, use a separate build directory:

```sh
make DEBUG=1 SANITIZE=address BUILD_DIR_BASE=build-asan \
  VERSION=us BASEROM=/absolute/path/to/baserom.us.z64
```

`BASEROM` is read directly during local asset extraction; it is not copied into
the repository. `SM64_BASEROM_US`, `SM64_BASEROM_JP`, and
`SM64_BASEROM_EU` provide the equivalent per-version environment variables for
multi-version automation.

### SM64 Modern native macOS app

SM64 Modern is a parallel macOS 27 / Apple-silicon target. Swift 6 and AppKit
own the application shell, owner thread, 60 Hz fixed-step scheduler, Apple
input/audio services, and value-oriented migration boundaries. Metal 4 owns
the native renderer and presentation path. The portable C engine remains the
gameplay oracle and compatibility fallback; raw C object graphs do not cross
the Swift concurrency boundary.

At the current `nightly` continuation, the full-Swift-twin
qualification ledger has 534 behavior rows (511 Swift owners and 23 explicit C
adapters), with M33nk as the latest numbered behavior slice, Treasure Chest
route 270 as the latest central promotion, and M34b as the latest validated Metal 4
production/capture slice. The bounded live-shard executor is now present, but
route-shard closure, physical/device/performance/thermal evidence,
distribution, and human acceptance are still open; this is not a shipped
full-game Swift port.

After extracting local assets as described above, the canonical Debug workflow
is:

```sh
xcodegen generate --spec project.yml
./script/build_and_run.sh run
```

`build_and_run.sh run` executes the native smoke matrix before building and
launching the signed development bundle. For a bounded host check, use
`./script/build_and_run.sh --verify`; for a faster unsigned Release build, use
`./script/build_prod.sh`. See [docs/SM64Modern.md](docs/SM64Modern.md) for
focused ABI, route, cadence, parity, and Metal validation commands.
