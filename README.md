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
route 270 as the latest central promotion, and M34b as the latest validated
Metal 4 production/capture slice. One of 7,419 route shards is live-qualified
and 7,418 remain planned. Phase 31 completed the independent two-tick,
byte-identical C/Swift window and promotion gate for the existing
`oracle_hook|input` row (`0xd9446dfed10e189e`); because this is the retained
row, the live ledger remains **1 of 7,419**, not a second admission. Phase 32's
fresh M34 attempt remained locked/headless and stopped at three presented
frames; fetched color/depth attachments were clear-only black and archive reuse
was false. Phase 33 leaves exactly two M35 blockers: no valid Developer ID
Application identity/private key and no notarytool authentication. Phase 34
could not admit `bhvDecorativePendulum` because its real owner path lacks the
manifest's collision-query and script-event schema domains, or
`oracle_hook|global_state` because the Swift side has no schema-4 global-state
emitter or random-seed owner. Phase 37 rechecked those source-backed seams and
again admitted no second route: real collision and behavior-script/lifecycle
owners are still absent, so adding those records would be synthetic evidence.
Phase 39 confirmed that the same global-state candidate also lacks a real
owner-thread emitter for the native global timer and shared random seed (and
does not yet publish the live level/area/act/course lifecycle values). Phase 40
confirmed that the decorative-pendulum path still has no owner-thread collision
world/floor query, per-object behavior-VM/script-PC lifecycle plumbing, or
shared schema-4 trace sink. Phase 41 found the M34 host still locked/asleep and
left exactly the same two M35 blockers: no authorized Developer ID Application
identity/private key and no notarytool authentication.
Route-shard closure, physical/device/performance/thermal evidence,
distribution, and human acceptance are still open; this is not a shipped,
visual-parity, or complete full-game Swift port. See the
[current status](docs/SM64Modern.md), [full-Swift-twin goal](.porting/goal-full-swift-twin.md),
and [Luna-max continuation plan](.porting/goal-continuation-luna-max-2026-08-20.md)
for the evidence ledger and latest handoffs, including the
[Phase 25 route alignment](.porting/porting-handoff-full-swift-twin-phase25-route-alignment.md),
[Phase 26 M34 capture](.porting/porting-handoff-full-swift-twin-phase26-m34-visible-capture.md),
[Phase 27 Release entitlement](.porting/porting-handoff-full-swift-twin-phase27-release-entitlement.md),
[Phase 28 M35 recheck](.porting/porting-handoff-full-swift-twin-phase28-m35-external-recheck.md),
[Phase 29 docs reconciliation](.porting/porting-handoff-full-swift-twin-phase29-docs-reconcile.md),
[Phase 30 completion audit](.porting/porting-handoff-full-swift-twin-phase30-completion-audit.md),
[Phase 31 route window](.porting/porting-handoff-full-swift-twin-phase31-route-multitick.md),
[Phase 32 M34 host refresh](.porting/porting-handoff-full-swift-twin-phase32-m34-host-refresh.md),
[Phase 33 M35 prerequisite refresh](.porting/porting-handoff-full-swift-twin-phase33-m35-prereq-refresh.md),
[Phase 34 next-route qualification](.porting/porting-handoff-full-swift-twin-phase34-next-route.md),
[Phase 35 docs reconciliation](.porting/porting-handoff-full-swift-twin-phase35-docs-reconcile.md),
[Phase 36 completion audit](.porting/porting-handoff-full-swift-twin-phase36-completion-audit.md),
[Phase 37 decorative pendulum seams](.porting/porting-handoff-full-swift-twin-phase37-decorative-pendulum-seams.md),
[Phase 38 final reconciliation](.porting/porting-handoff-full-swift-twin-phase38-final-reconcile.md),
[Phase 38 completion audit](.porting/porting-handoff-full-swift-twin-phase38-completion-audit.md),
[Phase 39 global-state audit](.porting/porting-handoff-full-swift-twin-phase39-global-state.md),
[Phase 40 decorative seams](.porting/porting-handoff-full-swift-twin-phase40-decorative-seams.md),
[Phase 41 external refresh](.porting/porting-handoff-full-swift-twin-phase41-external-refresh.md),
[Phase 42 final reconciliation](.porting/porting-handoff-full-swift-twin-phase42-final-reconcile.md),
and [Phase 42 completion audit](.porting/porting-handoff-full-swift-twin-phase42-completion-audit.md).

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
