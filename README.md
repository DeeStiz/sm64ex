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

### Phase 70 current status

The authoritative current ledger has 534 behavior rows (511 Swift owners and
23 explicit C adapters) and 7,420 route shards: one live-qualified row and
7,419 planned. Phase 57 repaired native schema-4 object-domain routing and
retained 64 real slot-37 object-state records plus six nonzero native
run/header fingerprints. Phase 58 selected the authored Castle Inside area-2
`WARP_NODE(0x35)` through the normal owner-thread warp path; Mario and the
pendulum now both resolve to room 5 and the pendulum is render-active
(`graph_flags=0x21`). Phase 59 re-ran the independent pair and remains
fail-closed: native emits domains `3,6,7`, Swift emits `3,6,7,12`, native
effect domain 12 is absent, and the first canonical divergence is still a
domain-3 record mismatch (`native_records=1057`, `swift_records=1095`). The
sound threshold is reached on a held native step, so forcing a sink, room, or
graph flag would fabricate evidence; no route promotion or ledger mutation
occurred.

Phase 65 fixed the `EngineRuntime.swift:189/:366`
(`SM64ModernStatus`/`Int32`) boundary and a beta-Xcode Release build passed.
Phase 66 reran the fixed M34 harness but failed closed at
`scheduler_dropped_steps=65`; the host displays were asleep, only three
presents were observed, and no capture pass ran. Phase 67's stable-Xcode M35
preflight still finds exactly the Developer ID Application identity/private
key and notary-authentication blockers. Phase 67c preserved the HUD
fingerprints while fixing stable-Xcode type checking, and Phase 67d added
macOS 26/27 AVFAudio SDK compatibility; the stable generic Release build now
passes, but remains unsigned/local. The latest Phase 67b stable M34 rerun
still fails closed at `scheduler_dropped_steps=63` with the screen locked,
three presents, and no new capture. No archive/export/DMG/ZIP/staple/
Gatekeeper, clean-machine, or human result exists.

Phase 71 audited the next `oracle_hook|camera_state` route without admitting
it: the existing input-only row still passes independently, while the full
route coverage guard fails before a camera trace and Mario-face/progression
checks remain source/fixture contracts rather than live qualification. The
route ledger remains 1 of 7,420.

Phase 72 retained the real full-route input receipt, and Phase 73 extended the
C sidecar to replay all nine source-backed full-route records with exact tamper
detection. This composite trace still has no canonical manifest row, so no
additional live shard was admitted and the ledger remains unchanged.

Phase 75 refreshed M35 after the SDK fixes: stable generic Release and both
readiness contracts pass, but Developer ID signing, notary authentication,
distribution artifacts, clean-machine Gatekeeper, and human acceptance remain
unavailable.

Phase 74 adds a read-only M34 host gate; the current console is locked and
both online displays are asleep, so it reports `m34_host_ready=0` without
attempting wake, unlock, or power-state changes.

M34, M35, and fresh-save human 120-star acceptance remain open. These gates
are independent from local build, source, fixture, and headless-host
evidence; this branch is not a shipped, visual-parity, or complete full-game
Swift port. The mapping/live-route indicators remain separate: 511/534
behavior rows (95.693%), 1/7,420 live-qualified route shards (0.013477%),
and a conservative full-goal/acceptance floor of 0%.

The detailed phase notes below are historical through Phase 55; any pre-Phase
55 `7,419` wording is retained as historical evidence and does not override
the current `1 of 7,420` ledger.

### Next admissible gates

1. Repeat M34 on an awake, unlocked visible host and require zero scheduler
   drops, sustained presents, post-resume acknowledgement, archive reuse,
   non-clear pixels, and independent GPU/FPS/memory/thermal evidence.
2. Keep route pairing fail-closed: align common C/Swift fingerprints and tick
   windows, then admit only exact schema-4 parity; the ledger remains 1/7,420.
3. With M34 evidence, obtain Developer ID Application and notary credentials,
   produce signed/stapled artifacts, and verify clean-machine Gatekeeper.
4. Finish the fresh-save human 120-star controls, camera, collision, audio,
   haptics, visual, menu, credits, ending, and recovery checklist.

At the current `nightly` continuation, the full-Swift-twin
qualification ledger has 534 behavior rows (511 Swift owners and 23 explicit C
adapters), with M33nk as the latest numbered behavior slice, Treasure Chest
route 270 as the latest central promotion, and M34c as the latest Metal 4
implementation checkpoint. One of 7,420 route shards is live-qualified and
7,419 remain planned. Phase 31 completed the independent two-tick,
byte-identical C/Swift window and promotion gate for the existing
`oracle_hook|input` row (`0xd9446dfed10e189e`); because this is the retained
row, the live ledger remains **1 of 7,420**, not a second admission. Phase 32's
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
identity/private key and no notarytool authentication. Phase 43 rechecked the
same global-state boundary: the native timer, level/area/act/course lifecycle,
and shared random seed still have no source-backed Swift owner-thread emitter.
Phase 44 added a real `bhvDecorativePendulum` Swift owner seam that can bind
the immutable collision world and decoded behavior program and emit the
source-backed floor, lifecycle, script, effect, and object-state records when
explicitly configured. Phase 45 carried that configuration through central
dispatch and the engine runtime; the configured smoke is source-backed, while
the unconfigured route remains trace-silent. Phase 46 added a source-only
Castle Inside area-2 recipe from the real behavior, level-script, collision,
and room inputs, but no native C pair was captured. Phase 47 confirmed that a
safe C pair is blocked by monolithic `data/behavior_data.c` ownership and the
legacy `gCurrentObject`/level-surface/audio loader boundary. No second route is
admitted and no synthetic records are accepted. Phase 48 reconciled the
public/status documents without changing the historical ledger. Phase 49 then
rechecked the native core: the strict native archive and existing lifecycle
oracle smoke passed (`liveOracleTraceRecords=3151`,
`liveOracleTraceTicks=5`, `liveOracleCoverageEntries=62`), but that smoke is a
general lifecycle route, not Castle Inside area 2 or pendulum-owner evidence.
The public lifecycle API owns `thread5_game_loop()` and `lifecycle_step()` but
does not expose level/area selection or the private `levelCommandAddr`; the
current bootstrap only selects `LEVEL_CASTLE_GROUNDS` or `LEVEL_BOB`. The exact
safe unblock is an owner-thread entrypoint that selects `LEVEL_CASTLE`, runs its
compiled level script through the existing command pointer, performs the normal
Mario-area transition to area 2, and exposes the real pendulum callback while
leaving the existing parity sink as the sole schema-4 emitter. Symbol presence
for `load_area`, `gAreaData`, `gCurrentArea`, and related pendulum callbacks is
not proof that this owner path was initialized or updated.
Phase 50 reconciled the public/status documents and retained the Phase 44–49
owner, dispatch, source-recipe, native-C, and native-core boundaries. Phase 51
then compiled and loaded the Castle Inside script and all three area
definitions, including the real area-2 collision/room/geometry and
`bhvDecorativePendulum` spawn. Phase 52 added an opt-in owner-thread transition
(`SM64_MODERN_AUTOMATED_CASTLE_AREA2=1`) that selects the compiled
`LEVEL_CASTLE` script and completes the normal Mario area-2 warp path. The
native lifecycle evidence observes `castleArea2Loaded=1`, the real pendulum at
`castleArea2PendulumSlot=37`, `castleArea2NativeRecords=3`,
`castleArea2Roll=1464`, and `castleArea2Velocity=224`; no direct `load_area(2)`
or fabricated globals are used. This proves native area-2 selection and
updates, not C/Swift parity or route admission.
Phase 53 pairs that slot-37 native trace with the Phase 46 source-backed Swift
recipe and fails closed: native retains only domains `6,7` (23 filtered
records), while Swift emits the required `3,6,7,12` domains (687 records).
Native is missing the `object_state` (3) and pendulum-specific `effects` (12)
domains; the first canonical divergence is the missing native domain-3 record
at tick 1 for subject 37. The native header leaves the five required
run/content/timebase/configuration/initial-save fingerprints zero while the
Swift source header is nonzero, so no C/Swift pair or route promotion changed.
Phase 54 records this exact divergence in a fresh reconciliation and
completion audit.
Phase 55 corrected the route denominator drift found in that audit: the
regenerated inventory now has 7,420 rows/shards after excluding the Phase 52
`initiate_warp` header declaration while retaining the legitimate `.c`
transition call sites. The retained live row remains **1 of 7,420**, with 7,419
planned; this is an inventory correction only and does not mutate the live
ledger or admit the blocked pendulum route.
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
[Phase 42 completion audit](.porting/porting-handoff-full-swift-twin-phase42-completion-audit.md),
[Phase 43 global-state owner boundary](.porting/porting-handoff-full-swift-twin-phase43-global-state-owner.md),
[Phase 44 decorative owner seam](.porting/porting-handoff-full-swift-twin-phase44-decorative-owner.md),
[Phase 45 central dispatch](.porting/porting-handoff-full-swift-twin-phase45-decorative-dispatch.md),
[Phase 46 source route attempt](.porting/porting-handoff-full-swift-twin-phase46-decorative-route.md),
[Phase 47 native C route boundary](.porting/porting-handoff-full-swift-twin-phase47-native-c-route.md),
[Phase 48 final reconciliation](.porting/porting-handoff-full-swift-twin-phase48-final-reconcile.md),
[Phase 48 completion audit](.porting/porting-handoff-full-swift-twin-phase48-completion-audit.md),
[Phase 49 native-core area boundary](.porting/porting-handoff-full-swift-twin-phase49-native-core-area.md),
[Phase 50 final reconciliation](.porting/porting-handoff-full-swift-twin-phase50-final-reconcile.md),
[Phase 50 completion audit](.porting/porting-handoff-full-swift-twin-phase50-completion-audit.md),
[Phase 51 level/area entrypoint](.porting/porting-handoff-full-swift-twin-phase51-level-area-entrypoint.md),
[Phase 52 final reconciliation](.porting/porting-handoff-full-swift-twin-phase52-final-reconcile.md),
[Phase 52 owner-thread warp](.porting/porting-handoff-full-swift-twin-phase52-warp-transition.md),
[Phase 52 completion audit](.porting/porting-handoff-full-swift-twin-phase52-completion-audit.md),
[Phase 53 pendulum pair](.porting/porting-handoff-full-swift-twin-phase53-pendulum-pair.md),
[Phase 54 final reconciliation](.porting/porting-handoff-full-swift-twin-phase54-final-reconcile.md),
[Phase 54 completion audit](.porting/porting-handoff-full-swift-twin-phase54-completion-audit.md),
[Phase 55 denominator correction](.porting/porting-handoff-full-swift-twin-phase55-denominator-fix.md),
[Phase 57 native object-domain parity](.porting/porting-handoff-full-swift-twin-phase57-native-pendulum-parity.md),
[Phase 58 canonical Castle warp](.porting/porting-handoff-full-swift-twin-phase58-canonical-warp.md),
[Phase 59 pendulum pairing](.porting/porting-handoff-full-swift-twin-phase59-pendulum-pair.md),
[Phase 60 completion audit](.porting/porting-handoff-full-swift-twin-phase60-completion-audit.md),
[Phase 61 M34 production audit](.porting/porting-handoff-full-swift-twin-phase61-m34-production-audit.md),
[Phase 62 M35 release preflight](.porting/porting-handoff-full-swift-twin-phase62-m35-release-preflight.md),
[Phase 64 documentation closeout](.porting/porting-handoff-full-swift-twin-phase64-docs-closeout.md),
[Phase 65 EngineRuntime status fix](.porting/porting-handoff-full-swift-twin-phase65-engine-runtime-status-fix.md),
[Phase 66 fixed-build M34 rerun](.porting/porting-handoff-full-swift-twin-phase66-m34-rerun.md),
[Phase 67 M35 current preflight](.porting/porting-handoff-full-swift-twin-phase67-m35-current-preflight.md),
[Phase 67b stable M34 rerun](.porting/porting-handoff-full-swift-twin-phase67b-m34-stable-rerun.md),
[Phase 67c HUD render fix](.porting/porting-handoff-full-swift-twin-phase67c-hud-render-fix.md),
[Phase 67d AVFAudio SDK compatibility](.porting/porting-handoff-full-swift-twin-phase67d-avfaudio-sdk-compat.md),
[Phase 70 documentation refresh](.porting/porting-handoff-full-swift-twin-phase70-docs-refresh.md),
[Phase 71 camera route pair audit](.porting/porting-handoff-full-swift-twin-phase71-camera-route-pair.md),
[Phase 72 full-route coverage](.porting/porting-handoff-full-swift-twin-phase72-full-route-coverage.md),
[Phase 73 full C sidecar contract](.porting/porting-handoff-full-swift-twin-phase73-full-c-sidecar-contract.md),
[Phase 75 M35 post-SDK preflight](.porting/porting-handoff-full-swift-twin-phase75-m35-post-sdk-preflight.md),
and [Phase 74 M34 host readiness](.porting/porting-handoff-full-swift-twin-phase74-m34-host-readiness.md).

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
