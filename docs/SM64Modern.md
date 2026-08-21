# SM64 Modern native macOS

This checkout contains two supported macOS paths:

* the original portable C/SDL/OpenGL build described in the root README; and
* **SM64 Modern**, a parallel Apple-silicon application built with Swift 6,
  AppKit, Metal 4, GameController, and AVFAudio.

SM64 Modern keeps the portable C engine and save compatibility while adding a
native host and incrementally migrating value-only gameplay and product
systems into Swift. The C engine remains the oracle and compatibility
fallback until a subsystem has passed its C-to-Swift parity gates.

## Current status

The status below is pinned to the current `nightly` continuation
(2026-08-20).

* **M33nk** remains the latest numbered behavior-qualification slice. The
  continuation has centrally promoted every Phase 2/3 route-local owner
  through Treasure Chest route 270; the latest focused contract is
  `0x2dc072092ddbe3ed`.
* The deterministic behavior manifest contains **534 rows**: **511 Swift
  value/owner routes** and **23 explicit C adapters**. Its current fingerprint
  is `0x5e5d8c00a7fab8a3`.
* **M34c** is the latest Metal 4 implementation checkpoint; **M34b** remains
  the latest validated production/capture slice. Its two-pass
  harness keeps API/shader validation separate from GPU capture and exercises
  a real `CAMetalLayer`, resize/pause stress, three captured MTL4 command
  buffers, `BGRA8Unorm` color, and `Depth32Float` depth.
* Commit `9509dfe0` closes the compiler-queue enqueue race; the latest stress
  run presents three frames and drains cleanly, but remains rejected for 62
  scheduler-dropped steps, host/compositor throttling, and `archive_reuse=false`.
* Commit `055b577e` drains registration-time compiler work before the profile;
  the latest log proves registration readiness, while the same scheduler,
  presentation, and archive-reuse gates remain open.
* Commit `631f7c69` adds a fail-closed diagnostic smoke that distinguishes
  binary archive reuse, descriptor-cache fallback, scheduler drops, and
  host-compositor candidates without weakening the M34 production gate.
* The retained M34 GPU trace rechecks with 3 MTL4 command buffers/draws,
  BGRA8Unorm/Depth32Float attachments, and `sm64_vertex/sm64_fragment`; its
  fetched color is clear-only black, so visual parity and human review remain
  open.
* The latest full host verifier can still be blocked before engine startup by
  LaunchServices `kLSNoExecutableErr (-10827)` (the direct AppKit diagnostic
  exits `134`). The retained complete host proof is M33nc; this is a host
  limitation, not evidence of a gameplay or Metal fault.
* The route inventory contains **7,419 reachable shards**. Full shard
  execution, sanitizer reruns, physical visual/audio/controller checks,
  sustained performance and thermal checks, release packaging, and human
  acceptance remain open. M35 external distribution and human acceptance
  remain open; local readiness and fail-closed distribution-flow checks exist,
  but no distributable artifact or human acceptance has started.
* The first real live shard (`0xd9446dfed10e189e`, `oracle_hook|input`) now
  passes C/Swift replay, live executor, and worker-result validation with
  `fixture_only=0`; **7,418** manifest rows remain planned.
* No other rows are promoted from the current traces: the C contract replays
  hard-coded arrays, and fixture byte matches remain explicitly ineligible for
  live qualification. Further rows require independently recorded C and Swift
  traces.
* The native-C record harness now emits 2,839 validated schema-4 records across
  five lifecycle ticks; pairing those records with a matching Swift trace is
  still required before any additional shard can qualify.

The source-of-truth tracker and the complete milestone ledger are in
[`../.porting/goal-full-swift-twin.md`](../.porting/goal-full-swift-twin.md).
The compact evidence history is in
[`../.porting/porting-memory.md`](../.porting/porting-memory.md), and the most
recent route handoff is
[`../.porting/porting-handoff-full-swift-twin-phase9-central-route-closure.md`](../.porting/porting-handoff-full-swift-twin-phase9-central-route-closure.md).

## Architecture and ownership

| Layer | Owns | Boundary |
| --- | --- | --- |
| C engine | The legacy object graph, scripts, levels, physics, actors, camera, compatibility behavior, and C fallback | Versioned fixed-width POD records and owner-thread callbacks in `include/sm64_modern.h` and `src/pc/` |
| Swift/AppKit host | Application lifecycle, the dedicated engine owner thread, the monotonic fixed-step scheduler, Apple input/audio services, migration kernels, observers, and orchestration | Copied value types only; Swift does not retain or traverse raw C engine graphs across concurrency domains |
| Metal 4 renderer | `CAMetalLayer`, display-link presentation, command allocators/buffers, shader/pipeline compilation, resource residency, barriers, and scene packets | Explicit frame/resource contracts; command buffers do not replace the owner-thread lifecycle |

The native timebase runs simulation at **60/1 Hz** while preserving the
legacy domain at **30/1 Hz** (`paired_ticks=2`). Input is sampled at the native
rate; legacy scripts, timers, RNG, transitions, saves, HUD/menu/dialog state,
and one-shot effects advance at their paired boundary. The course-exit fix in
`6859e232` keeps one-shot dialog/menu/cutscene admissions from being dropped
on the held half of a native pair and is guarded by
`script/test_course_exit_cadence.sh`.

The generated Xcode project is not the source of truth. Edit
[`../project.yml`](../project.yml), then regenerate with:

```sh
xcodegen generate --spec project.yml
```

The principal implementation areas are:

* [`../SM64Modern/`](../SM64Modern/) — Swift/AppKit/Metal and Apple service
  code;
* [`../include/sm64_modern.h`](../include/sm64_modern.h) — public fixed-width
  native ABI;
* [`../src/pc/`](../src/pc/) — C host adapters and migration seams; and
* [`../tools/SM64BehaviorCoverageManifestTool.swift`](../tools/SM64BehaviorCoverageManifestTool.swift)
  — deterministic Swift/C behavior ownership manifest generation.

## Prerequisites and ROM/assets

The native target is macOS 27 on Apple silicon with Xcode's Swift 6 toolchain,
`xcodebuild`, `xcrun`, `make`, Python 3, and XcodeGen. The legacy asset/tool
build also uses the dependencies listed by the root README:

```sh
brew install xcodegen sdl2-compat glew pkgconf mingw-w64
```

ROMs and ROM-derived assets are local inputs, never repository artifacts. On a
fresh checkout, extract the U.S. assets with a legally obtained ROM path:

```sh
cd /absolute/path/to/sm64ex
SM64_BASEROM_US=/absolute/path/to/baserom.us.z64 ./extract_assets.py us
```

Use `SM64_BASEROM_JP` or `SM64_BASEROM_EU` for the other supported versions.
`BASEROM` on the legacy `make` command remains supported. To remove extracted
content before sharing a worktree, run `./extract_assets.py --clean && make
clean` (or `make distclean`).

## Build and run

The canonical Debug workflow regenerates the project, runs the native smoke
matrix, builds the C core and Swift app, signs a local development bundle, and
launches it:

```sh
./script/build_and_run.sh run
```

Useful focused modes are:

```sh
./script/build_and_run.sh --verify            # bounded host startup/shutdown checks
./script/build_and_run.sh --parity-verify     # 90-tick C record/replay check
./script/build_and_run.sh --logs              # launch and stream app logs
./script/build_and_run.sh --telemetry         # stream the SM64 Modern subsystem
./script/build_and_run.sh --metal-validation  # Metal API and shader validation
./script/build_and_run.sh --metal-hud         # Apple Metal HUD logging
./script/build_and_run.sh --metal-capture     # signal-driven Metal capture
```

For a faster unsigned Release build without the full smoke matrix:

```sh
./script/build_prod.sh
```

This produces `build/xcode-derived-prod/Build/Products/Release/SM64 Modern.app`.
It is a build artifact, not a notarized or distribution-ready application.

## Qualification commands

Run the smallest relevant check while developing a route, then run the broader
gates before recording a milestone handoff.

| Check | Command | Evidence |
| --- | --- | --- |
| C/Swift ABI | `make abi-smoke` | Versioned POD layout and callable-core contract |
| Behavior ownership | `./script/test_behavior_manifest.sh` | Reproducible 534-row manifest and matching Swift/C fingerprint |
| Route inventory | `./script/test_route_shards.sh` | Canonical 7,419-shard inventory and ledger schema (inventory status remains planned) |
| Live shard executor | `./script/test_route_shard_live_executor.sh` | Bounded canonical live-trace admission and isolated worker-result gate (does not launch all gameplay shards) |
| Live shard batch | `./script/test_live_route_shard_batch.sh` | Real `oracle_hook|input` C/Swift replay plus one live worker-result; reports remaining planned rows |
| Live route oracle | `./script/test_live_route_oracle.sh input-only` or `full` | Reachable owner-thread route execution and C/Swift oracle comparison |
| Focused route | `./script/test_<route>.sh` | The route's C contract, Swift smoke, dispatch, and integration gates |
| Cadence regression | `./script/test_course_exit_cadence.sh` | One-shot menu/dialog/cutscene admissions across the 60/30 pair |
| Deterministic replay | `./script/build_and_run.sh --parity-verify` | 90-tick record/replay with no first divergence |
| Native host | `./script/build_and_run.sh --verify` | Layer/device/bridge/frame-one/start/stop telemetry when the host can launch |
| Metal 4 production | `./script/test_metal4_production.sh` | Separate API/shader-validation and GPU-capture passes plus `gpudebug` inspection |
| M35 readiness | `./script/m9_release.sh readiness` or `./script/test_m9_release_readiness.sh` | Read-only distribution prerequisite check; it fails closed without Developer ID/notary/toolchain prerequisites |
| M35 distribution flow | `./script/m9_release.sh distribution` or `./script/test_m35_distribution_flow.sh` | Fail-closed archive/export/notarize/staple/DMG/ZIP flow; blocked prerequisites perform no mutation |

`test_metal4_production.sh` requires the macOS Metal capture/debug tools and
uses a new output directory by default; it refuses to overwrite an existing
capture. Keep API/shader validation and GPU capture as separate passes because
Apple's capture tooling rejects simultaneous shader validation.

Always finish documentation or code-only changes with:

```sh
git diff --check
```

## Evidence boundaries

The project deliberately reports evidence by layer:

* a focused contract or Swift smoke proves a value/ABI relationship, not full
  gameplay parity;
* a successful build, signed bundle, or LaunchServices launch does not prove
  physical visual quality, controller feel, audio parity, FPS, memory,
  thermal behavior, or clean-machine distribution; and
* a Metal capture or fetched GPU texture is automated renderer evidence, not a
  substitute for a human display review.

Do not describe SM64 Modern as a completed full-game Swift port or a shipped
macOS product until the route ledger, runtime/device, release, and human gates
in the full-Swift-twin goal are closed.

## Related documentation

* [`../README.md`](../README.md) — portable build and repository overview.
* [`../.porting/goal-sm64-modern.md`](../.porting/goal-sm64-modern.md) — the
  completed M0–M14 native-host baseline goal.
* [`../.porting/goal-full-swift-twin.md`](../.porting/goal-full-swift-twin.md)
  — current M33–M35 qualification and release plan.
* [`../.porting/porting-memory.md`](../.porting/porting-memory.md) — concise
  evidence, caveats, and handoff history.
