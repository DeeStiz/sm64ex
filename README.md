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

### Phase 85f122 current status

Phase 85f121 records the authored Castle Grounds special-object contract:
preset `0x88` maps to `MODEL_CASTLE_CASTLE_DOOR` and `bhvDoorWarp`, which sets
`INTERACT_WARP_DOOR`. The common door collision contract is `hitbox radius=80
height=100` with collision distance `1000`. `interact_warp_door` runs only
when Mario is `ACT_WALKING` or `ACT_DECELERATING`, after actual contact with
the object; it computes `should_push_or_pull_door`, stores the interaction
object, and enters the pulling/pushing action. No A-button press is required
for the warp-door interaction itself.

The authored door centers are `(-76,803,-3155)` and `(77,803,-3155)`. The
best fixed samples from Phases 85f116–85f119 were `(-311,803,-3054)` and
`(504,803,-3054)`, still outside the nearest 80-unit collision radius. The
final fixed lateral variant therefore remained `LEVEL_CASTLE_GROUNDS` (level
16) area 1 for all 3,600 steps and exited `77`; no trace, native receipt,
C/Swift runtime pair, route admission, report/ledger/manifest mutation, or
canonical promotion exists. No direct level load/warp, behavior helper,
object injection, coordinate selection, or synthetic trace data was used.

The route remains contact-gated. The next traversal attempt must reach within
the authored hitbox through a source-faithful fixed-input recipe, or use
explicit authorization for a different traversal mechanism. Once Castle
Inside and SSL area 1 are reached, real Pokey C/Swift Debug/ASan/Release/rerun
parity receipts remain required before admission.

Phase 85f111's read-only M34 audit leaves `m34_host_ready=0` because the
display is offline, the console session is locked, and `gputoolsserviced`/GPU
tooling is unavailable. Thermal state is unknown. No current Release launch,
capture/replay, attachment/pixel, cadence/soak, direct-display, physical, or
human evidence is admissible.

Phase 85f112's M35 readiness and distribution contracts pass, but no valid
Developer ID Application identity/private-key pair or supported `notarytool`
authentication is present. No archive/export, notarization/stapling, signed
DMG/ZIP, clean-machine Gatekeeper/first-launch, or human acceptance evidence
exists.

The designated local canonical report remains 7,420 rows with 26 terminal
`passed` and 7,394 `planned` (`26/7394`; `26/7420 = 0.350404313%`) at
SHA-256 `4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.
The byte-identical write-once backup remains 25 terminal `passed` and 7,395
`planned` (`25/7395`; `25/7420 = 0.336927224%`) at SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The route manifest remains unchanged at SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`, and
the behavior manifest remains unchanged at SHA-256
`83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%.

Ordered handoffs: [Phase 85f110 Pokey runtime route](.porting/porting-handoff-full-swift-twin-phase85f110-pokey-runtime-route.md),
[Phase 85f111 M34 production audit](.porting/porting-handoff-full-swift-twin-phase85f111-m34-production-audit.md),
[Phase 85f112 M35 distribution audit](.porting/porting-handoff-full-swift-twin-phase85f112-m35-distribution-audit.md), and
[Phase 85f113 documentation/M34/M35 route](.porting/porting-handoff-full-swift-twin-phase85f113-docs-route-m34-m35.md),
[Phase 85f114 Castle→SSL traversal recipe](.porting/porting-handoff-full-swift-twin-phase85f114-castle-ssl-traversal-recipe.md), and
[Phase 85f115 documentation/traversal recipe](.porting/porting-handoff-full-swift-twin-phase85f115-docs-traversal-recipe.md),
[Phase 85f116 Castle-door input variants](.porting/porting-handoff-full-swift-twin-phase85f116-castle-door-input-variants.md),
[Phase 85f117 Castle-door refinement](.porting/porting-handoff-full-swift-twin-phase85f117-castle-door-refinement.md), and
[Phase 85f118 documentation/Castle-door refinement](.porting/porting-handoff-full-swift-twin-phase85f118-docs-castle-door-refinement.md),
[Phase 85f119 final fixed lateral variant](.porting/porting-handoff-full-swift-twin-phase85f119-castle-door-final-variant.md), and
[Phase 85f120 documentation/final door variant](.porting/porting-handoff-full-swift-twin-phase85f120-docs-final-door-variant.md),
[Phase 85f121 Castle-door contract analysis](.porting/porting-handoff-full-swift-twin-phase85f121-castle-door-contract-analysis.md), and
[Phase 85f122 documentation/door contract](.porting/porting-handoff-full-swift-twin-phase85f122-docs-door-contract.md).
No source, report, route ledger, manifest, release, store, credential,
publication, or acceptance state changed.

### Phase 85f107 current status

Phase 85f106 selected the SSL area-1 authored Pokey parent row
`0x132a22db8f8e0945` and body-part child row `0x41715ab876625588`. Phase
85f107's strengthened static schema-4 seam is recorded by `8af9167a` on top
of the initial seam `22d44cba`; its independent fingerprints are C
`0x82add98bad10547e` and Swift `0x6276741935432706`. The pair reports
`schema4=1`, a generation-safe parent link, all four authored `macro_pokey`
parent tuples, five source-ordered child tuples, and source event ordering
`attack → replenish → unload → collision → effect → deletion`. The verdict
remains **STATIC SEAM COMPLETE / RUNTIME RECEIPT ABSENT / NO ADMISSION**.

The C validator and Swift mirror remain fixed-width value contracts only; no
runtime receipt, C/Swift runtime pairing, or admission exists. The only
acceptable next evidence is the ordinary Castle→SSL area-1 route. No direct
SSL load/warp, synthetic child, object injection, helper/probe call, trace,
manifest/report/ledger mutation, or admission was performed; the parent and
child rows remain planned. Canonical/backup counters remain 26/7,394 and
25/7,395, and M34/M35/human/full floors remain 0%.

### Phase 85f105 current status

Phase 85f103 selected Rainbow Ride's authored `bhvDonutPlatformSpawner` at
route row `0x0114376397887ece`. The discovery froze the source parent and its
31-child position table, plus the ordinary Castle Inside painting boundary at
node `0x2A` to `LEVEL_RR` area 1. Phase 85f104 then committed the static
source-contract seam in `ea1e4772`. Its exact verdict is **STATIC SEAM COMPLETE
/ RUNTIME RECEIPT ABSENT / NO ADMISSION**, with static contract fingerprint
`0x8470fe2a9a74008b`. The seam preserves the semantic
`bhvDonutPlatformSpawner`/`bhvDonutPlatform` identities, source 31-child
table, parent bitmask, squared-distance gate, collision identity, and
effect/deletion lifecycle scalars without crossing native pointers. No runtime
receipt or admission exists; the selected row remains planned.

The only acceptable next runtime evidence is the ordinary Castle Inside
painting route through node `0x2A` into RR area 1, observing the authored
parent and source-ordered children. No direct RR load or warp, synthetic
parent or child, object injection, helper or probe call, coordinate selection,
trace, manifest/report/ledger mutation, or admission was performed.

The designated local canonical route evidence remains
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`
with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`. It
contains 7,420 rows: 26 non-fixture terminal `passed` and 7,394 `planned`
(`26/7420 = 0.350404313%`). The old retained report remains byte-identical
as the write-once backup at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`
with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`. It
contains 25 terminal `passed` and 7,395 `planned`
(`25/7420 = 0.336927224%`); it is historical backup evidence, not the
designated report. The source route manifest remains unchanged at 7,420
rows with SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`, and
the behavior manifest remains unchanged at 534 rows with SHA-256
`83ed2a4dd580e462fa33f88f3fe126ae726f4a1f4139114f0de5d7d695355ccb`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%. No source,
manifest, designated or backup report, route ledger, release, store, or
external publication state changed.

### Phase 85f93 current status

Phase 85f93 committed the source-owned JRB treasure-chest receipt seam in
commit `904bffa3` for authored `bhvTreasureChestsJrb` route row
`0x246e8a98cbad9a7a`. The seam preserves semantic root/bottom/top identities,
source child ordinals 1 through 4, authored scalar state, interaction
outcomes, and effect intents without exposing native pointers.

The ordinary Castle→JRB route followed the normal lifecycle only and remained
at `level=1 area=1 roots=0 bottoms=0 tops=0`; the route-pair matrix failed
closed with exit `77` before creating a trace or admitting a route
(`trace=not-created`, `records=0`, `admission=0`). No direct JRB load, chest
helper call, child injection, variant substitution, coordinate selection, or
synthetic trace was used. The selected row remains planned. No
manifest/report/ledger mutation or canonical publication occurred.

The designated local canonical route evidence remains
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`.
It is SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4` and
contains 7,420 rows: 26 non-fixture terminal `passed` and 7,394 `planned`
(`26/7420 = 0.350404313%`). The old retained report remains byte-identical
as the write-once backup at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`,
with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d` and
25 terminal `passed` / 7,395 `planned` rows
(`25/7420 = 0.336927224%`); it is historical backup evidence, not the
designated report. The source manifest remains unchanged at 7,420 rows with
SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%. No source,
manifest, designated or backup report, route ledger, release, store, or
external publication state changed.

### Phase 85f87 current status

Fresh Phase 85f83–85f86 authored-reachability rechecks remain fail-closed.
The WDW express-elevator, TTC 2D rotator, Bob seesaw, and Spindrift route
pairs each ran from a fresh build root against their committed source-owned
seams. Every route exited `77`, created no C or Swift trace, and produced no
route record or admission. No static sibling or variant substitution,
synthetic trace, direct level load, object injection, or canonical mutation
was used.

The WDW recheck observed `level=11 area=2 dynamic=0 static=0`; the TTC
recheck observed `level=14 area=2 hands=0`; the Bob recheck observed
`level=1 area=1 object=0`; and the Spindrift recheck observed
`level=1 area=1 spindrifts=0`. Their fresh matrices therefore ended with
`trace=not-created` (no trace files), `records=0` where reported, and
`admission=0`.

The designated local canonical route evidence remains
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`.
It is SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4` and
contains 7,420 rows: 26 non-fixture terminal `passed` and 7,394 `planned`
(`26/7420 = 0.350404313%`). The old retained report remains byte-identical
as the write-once backup at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`,
with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d` and
25 terminal `passed` / 7,395 `planned` rows
(`25/7420 = 0.336927224%`); it is historical backup evidence, not the
designated report. The source manifest remains unchanged at 7,420 rows with
SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, implementation, and full-goal floors remain 0%. No source,
manifest, designated or backup report, route ledger, release, store, or
external publication state changed.

### Phase 85f82 current status

Following the committed Phase 85f81 write-once designation, the designated
local canonical route evidence is
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`.
It is SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4` and
contains 7,420 rows: 26 non-fixture terminal `passed` and 7,394 `planned`
(`26/7420 = 0.350404313%`). This is local route evidence only; it does not
claim a push, release, store publication, or human acceptance.

The old retained report is preserved byte-for-byte as the write-once backup at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/pre-publication-backup/canonical-route-ledger.tsv`,
with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d` and
25 terminal `passed` / 7,395 `planned` rows; it is historical backup evidence,
not the designated report. The source manifest remains unchanged at 7,420
rows with SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Behavior mapping remains 95.693%, and the conservative M34, M35,
human-acceptance, and full-goal floors remain 0%. No source, manifest, old
retained report, release, store, or external publication state changed.

### Phase 85f80 current status

The retained checked-in canonical state remains 534 behavior rows (511 Swift
owners and 23 explicit C adapters) and 7,420 route shards: 25 non-fixture
terminal passed rows and 7,395 planned. Its manifest SHA-256 is
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`, and its
retained cumulative report SHA-256 is
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
Retained live-route qualification is `25/7420 = 0.336927224%`; behavior
mapping is 95.693%, and the conservative M34, M35, human-acceptance, and
full-goal floors remain 0%.

Phase 85f30 committed the source-authored intro transition pair with exact
C/Swift/ASan/Release/rerun evidence; canonical admission was deferred at that
stage. Phase 85f31 committed the source-owned camera-water seam, but runtime
remains blocked: the ordinary owner-thread recipe did not reach authored DDD
area 1; the focused gate failed closed with exit 77 and emitted no route
record or admission.
Phase 85f32 then admitted the authored intro shard
`0x9a0f7b4f7ecf6c41` in an isolated root. Phase 85f33 performed a guarded,
phase-local merge: its isolated report contains 26 terminal and 7,394 planned
rows with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, for
`26/7420 = 0.350404313%`. The phase-local canonical ID mapping is
`0x9a0f7b4f7ecf6c41 -> 0xca33981b30cb7815`; this
isolated result is not the checked-in canonical state, and no canonical
manifest or retained report was overwritten.

Phase 85f35 performed a bounded authored DDD camera-water reachability check.
The ordinary owner-thread lifecycle failed closed with exit 77: zero retained
event-307 route records (`retained=0`), no non-recipe records, and no route
admission. The C trace and blocked rerun are both header-only 72-byte files
with identical SHA-256 `a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512`;
the Swift witness is negative-fence machinery, not native DDD evidence. The
exact unblock is a normal source-authored owner-thread traversal from an
existing startup route into Castle area 3's DDD painting and then DDD area 1,
without direct level register/load, forced camera mode, Sushi injection,
coordinate reuse, or a direct `find_water_level` helper call. No canonical
manifest or retained report changed.

Phase 85f37 committed the Castle-to-DDD traversal discovery. The static
source-authored chain through Castle Grounds, Castle area 1, Castle area 3's
DDD painting, and DDD area 1 is present, but no deterministic authored
owner-thread input recipe currently crosses it. The bounded probe therefore
failed closed with exit 77, retained `event-307=0`, and produced no route
record or admission. Its C trace and blocked rerun remain identical 72-byte
header-only files with SHA-256
`a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512`;
static chain evidence is not runtime traversal evidence. Canonical manifest,
retained report, and route ledger state remain unchanged.

Phase 85f39 audited the committed Phase 85f33 serial-publication evidence. The
isolated report is valid at 26 terminal / 7,394 planned rows with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, or
`26/7420 = 0.350404313%`; its target report and proof hashes are
`6563b63155e1b5f4465b30dd51c5c60a02bfe08459f8e6885549ed716ceef7d2` and
`c6de62ac55499a20d92ac5d7ec67cb328d569df276219bfde53f95b85900fc51`.
The retained checked-in canonical report remains 25/7,395 with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`, or
`25/7420 = 0.336927224%`; canonical intro row
`0xca33981b30cb7815` remains planned. A canonical route-ledger
merge/publication requires explicit authorization and was not performed; no
manifest, retained report, or ledger state changed.

Phase 85f40 confirmed that the static Castle-to-DDD source chain still lacks a
complete deterministic owner-thread input recipe through the authored basement
door, Castle area 3, and the DDD painting into DDD area 1. The bounded probe
failed closed with exit 77, retained `event-307=0`, and produced no route
record or admission. The known C trace remains a 72-byte header-only artifact
with SHA-256
`a00652d483085b681254ca74c782bbe5e7bdc9d2672ff724ebd3735a3d706512`;
canonical artifacts remain unchanged.

Phase 85f41's fresh read-only M34 re-audit leaves `m34_host_ready=0`: one
detected display is offline (`online=0`), the console/session is locked,
`gputoolsserviced` is not running, no GPU session is active, and thermal state
is unknown (`0xe00002bc`). Fresh traces were absent and screenshot, replay,
pixel, cadence, soak, direct-display, physical visual/feel, and human-
acceptance evidence were not admissible. The M34 floor remains 0%.

Phase 85f42's fresh read-only M35 re-audit confirms ordinary Xcode 26.6 and
the readiness/distribution contracts pass, but `security find-identity` finds
zero valid identities and notary authentication is unavailable. Readiness and
distribution remain blocked on those two prerequisites; no archive, export,
DMG, ZIP, notarization, stapling, Gatekeeper, or human-acceptance artifact
exists. The M35 and human-acceptance floors remain 0%.

Phase 85f44 performed a read-only inventory of isolated admission evidence.
The retained canonical report remains exactly 25 terminal `passed` and 7,395
`planned` rows. Exactly one unrepresented, source-authored,
`fixture_only=0`, hash-valid candidate was found: the Phase 85f33 intro
transition report, whose local ID `0x9a0f7b4f7ecf6c41` maps under the guarded
crosswalk to canonical ID `0xca33981b30cb7815`. Its phase-local result remains
26 terminal / 7,394 planned; no other isolated evidence is admissible and no
manifest, retained report, or route ledger state changed.

Phase 85f45 discovered the next disjoint authored route: dynamic WDW area-1
`bhvWdwExpressElevator`, candidate
`0x6e6c6a0fc1b92a45`. The authored object lifecycle and existing Swift
value/owner route are present, while the adjacent static-platform identity
`0xd52a32f6de0311da` is deliberately excluded. A source-bound C observer and
semantic identity are still required; no native lifecycle pair, admission, or
canonical merge was performed, so the candidate remains planned.

Phase 85f46 completed a bounded read-only Metal 4 contract re-audit. The
source, archive/presentation, capture-archive guard, M9 readiness, timebase,
and shell contracts passed, but the visible-host gate remains
`m34_host_ready=0` with an offline display, locked session, no active GPU
session, stopped GPU tooling, and unknown thermal state. Release launch,
capture/replay, attachment/pixel, cadence/soak, and direct-display evidence
were not admissible; M34 remains 0% and no Simulator substitute was used.

Phase 85f47 committed the source-owned WDW express-elevator receipt seam
(commit `380f14ae`). The dynamic `bhvWdwExpressElevator` observer, pointer-free
schema-4 route packet, independent Swift mirror, and focused C/Swift contract
are implemented, but the real authored Castle-to-WDW lifecycle reaches
`level=11 (LEVEL_WDW), area=2` before the dynamic object can emit a receipt.
The matrix therefore fails closed with `dynamic=0`, `static=0`, and exit 77;
no route record, admission, manifest, retained report, or canonical ledger
mutation occurred, and the static sibling was not substituted. Runtime
reachability remains blocked at WDW area 2.

Phase 85f49's actual authored Castle-to-WDW reachability result targets warp
node `0x0A`, but the normal owner-thread lifecycle lands in WDW area 2 before
the dynamic `bhvWdwExpressElevator` can tick. The matrix therefore fails
closed with `dynamic=0`, `static=0`, `admission=0`,
`canonical_ledger_mutation=0`, `manifest_mutation=0`, and exit 77. No C or
Swift trace was created (`trace=not-created`, `records=0`), no route record or
admission was produced, and the static sibling was not substituted. The
retained canonical report remains 25 terminal / 7,395 planned, the isolated
Phase 85f33 result remains 26 terminal / 7,394 planned, and the M34, M35,
human-acceptance, and full-goal floors remain 0%.

Phase 85f50 refreshed the first-party status surfaces while preserving the
retained canonical state. Phase 85f51 corrected the f49 ordering and status
wording so the actual f49 reachability blocker supersedes the earlier f47-
pending description; neither correction changed a manifest, report, route
ledger, or acceptance state.

Phase 85f52 discovered the next disjoint source-owned candidate,
`bhvTTC2DRotator`, at route row `0x1af5669b06931d93`. The selected authored
subject is the first TTC area-1 clock hand (`MODEL_TTC_CLOCK_HAND`,
`oBehParams2ndByte=0`) reached through the normal Castle Inside TTC painting
nodes `0x21`–`0x23`; the existing Swift value owner and isolated C contract
are present. No native TTC lifecycle probe, schema-4 pair, admission, or
canonical mutation was performed, so the candidate remains planned.

Phase 85f53 committed the source-owned TTC 2D rotator receipt seam, semantic
behavior identity, pointer-free schema-4 C producer, independent Swift
decoder/mirror, focused contract, and fail-closed matrix. The authored Castle
Inside painting route lands in `level=14 (LEVEL_TTC), area=2` with `hands=0`,
so the matrix exits 77 before a trace or admission; no route record, manifest,
retained report, or canonical ledger mutation occurred. No cog/static sibling
substitution or synthetic trace was used.

Phase 85f56 ran the bounded TTC area-1 reachability audit. The owner-thread
probe ended at `level=14 (LEVEL_TTC), area=2, hands=0` and exited 77. Its
direct gate first enters Castle area 2 and then calls `initiate_warp` directly
for TTC node `0x0A`, bypassing the authored Castle Inside painting nodes
`0x21`–`0x23`; it therefore does not establish a source-authored TTC area-1
lifecycle. No C trace was opened or Swift trace written
(`trace=not-created`, `records=0`), and no C/Swift pairing, admission, route
record, manifest, retained report, or canonical ledger mutation occurred.
No cog/static sibling substitution or synthetic receipt was used, and the
TTC row `0x1af5669b06931d93` remains planned pending a genuine authored
painting route into TTC area 1.

Phase 85f58 discovered the next disjoint source-owned candidate, the Bob
area-1 `bhvSeesawPlatform` row `0xb280cfa26a343b48`. Its authored object,
level lifecycle, fixed-width Swift owner route, and semantic identity are
present, but no native lifecycle pair or admission was performed.

Phase 85f59 audited serial publication read-only and found a wrapper contract
mismatch: `tools/SM64CanonicalRouteLedgerMergeTool.swift` is a 25-target,
104-token path, while `script/test_canonical_route_ledger_merge.sh` still
supplies 23 report/proof pairs (50 tokens) and asserts the stale 23-row output.
The wrapper therefore cannot perform the current merge; no canonical
publication was authorized or performed. The retained 25/7,395 report and
isolated intro 26/7,394 result remain unchanged.

Phase 85f60 rechecked acceptance state. The M34 visible-host gate remains
blocked by an offline/asleep display and locked console, while M35 distribution
remains blocked by missing Developer ID identity and notary authentication.
The timebase audit also fails closed because the retained fixture reports
`object_timer=166 files/715 matches` and `random_calls=79 files/289 matches`,
while current source reports `166/718` and `79/290`; the fixture was not
updated. M34, M35, human-acceptance, and full-goal floors remain 0%.

Phase 85f61 attributed the timebase drift to intentional WDW/TTC receipt
fields: the WDW elevator timer copy, TTC pre/post timer fields, and TTC
`random_u16` receipt field. The actual random-call syntax remains unchanged at
289 matches; this is fixture drift, not a new RNG call, and a fixture update
was not authorized.

Phase 85f62 implemented the source-owned Bob seesaw receipt seam and semantic
identity, but its focused runtime matrix failed closed at
`level=1 area=1 object=0` with exit 77. No source-reachable receipt, C/Swift
pair, admission, route record, manifest/report mutation, or canonical ledger
mutation was produced; no direct level load, object injection, variant
substitution, or synthetic trace was used.

Phase 85f64 ran the non-destructive serial canonical-merge dry-run. Its
preflight fails closed because four retained Phase 85f4 pendulum proof
artifacts have expired, so no first-stage or final output was written and no
publication was performed. No retained proof, report, manifest, route ledger,
or other canonical artifact was substituted or rewritten.

Phase 85f65 performed an isolated timebase-fixture proposal. The retained
audit still fails on exactly two intentional inventory deltas:
`object_timer` is `166 files/715 matches` in the fixture versus `166/718`
currently, and `random_calls` is `79 files/289 matches` versus `79/290`.
The three WDW/TTC timer receipt fields and one TTC `.random_u16` receipt label
account for those rows; actual RNG-call syntax remains 289. The proposal
changes only those two fixture rows and was not applied, so the retained
fixture and audit remain unchanged.

Phase 85f67 refreshed the pendulum evidence in a new build root. The Debug,
ASan, Release, and independent-rerun four-way matrix plus isolated admission
are byte-identical at the pair-report level: `records_each=1056`,
`matched_each=1056`, semantic identity `0x6268765f647065`, coverage
`0x680ff75430bf24ff`, `header_parity=1`, and all tamper, schema-4 replay,
persistent-rerun, artifact-separation, fixture, and freshness fences passed.
The fresh debug/pair/isolated/proof SHA-256 values are
`0e27c4232d1895425555cd0d7e0e4dbe38a1d8e2a368c77ade81508dc607057d`,
`9a71e388901d1b6991782941e634852dbcbb98838d7b2d4b7736e4124f1afc1a`,
`6f66939fa025efb520cbeeffe04d6144c8dc099232de0e5b37dbc8d10127aaeb`, and
`6522bc3e07ac384d287a3ebb6b4a382e874f6b31084788066a39ab095a7b2e7a`.
The canonical manifest remained byte-identical before and after admission
(`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`), so
canonical merge remained deferred.

Phase 85f68 fixed the serial coordinator's immutability snapshot so every
retained proof-artifact URL returned by preflight, including trace and log
paths, is hashed before and after the dry-run. Strict Swift 6 typechecking,
shell syntax, and diff checks passed; no source, manifest, report, route
ledger, fixture, or canonical artifact changed, and publication remained
deferred.

Phase 85f69 then passed the two-stage serial dry-run using the retained inputs
and fresh Phase 85f67 pendulum admission. The first stage passed 25 of 7,395
planned rows with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`; the
phase-local final stage passed 26 of 7,394 planned rows with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`, or
`26/7420 = 0.350404313%`. Duplicate/conflict, fixture-only, missing-artifact,
manifest/report mismatch, output-collision, terminal-rerun, and deterministic
output fences all passed; retained manifest/report/proof mutation and
canonical-ledger overwrite remained 0. The final output is phase-local only:
the retained canonical state remains 25/7,395 at
`25/7420 = 0.336927224%`, and no canonical publication was performed.

Phase 85f71 discovered the next disjoint source-owned candidate,
`bhvSpindrift`, at route row `0x028a122a6b0f0fa2`. The selected subject is the
first authored Snowman's Land area-1 Spindrift macro (source order 0,
position `(-3760,1120,1240)`) reached through the normal Castle Inside
painting route. The existing fixed-width Swift value/owner route has contract
`0x9ac8294303fff174`, but the source semantic identity/receipt seam, native
lifecycle pair, and admission remain pending; the row remains planned. No
direct level load, object injection, sibling substitution, synthetic trace,
native lifecycle probe, or manifest/report/ledger mutation was performed.

Phase 85f72 established publication-ready evidence in an isolated serial
rerun without publishing it. Its first-stage output preserves 25/7,395 with
the retained report SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`; the
exact phase-local final output is 26/7,394 with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`.
The manifest remains
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`;
immutable inputs were unchanged, retained artifacts were not mutated, and
`canonical_ledger_overwrite=0`. Explicit authorization is still required
before canonical promotion.

Phase 85f73 committed the source-owned Spindrift receipt seam in commit
`eb3fbf8a`, including the semantic `bhvSpindrift` identity, pointer-free
schema-4 observer, independent Swift mirror, focused C/Swift route pair, and
fail-closed matrix. The authored Castle Inside painting route reached
`level=1 area=1 spindrifts=0`; the matrix exited 77 with
`trace=not-created`, `records=0`, and `admission=0`. No route record,
manifest, retained report, canonical route ledger, or acceptance state
changed. Phase 85f74's earlier f73 status wording is corrected by this Phase
85f75 documentation update.

Phase 85f76 discovered the next disjoint source-owned candidate,
`bhvSpindel`, at route row `0xdc93743116807bec`. The authored subject is the
SSL area-2 `MODEL_SSL_SPINDEL` object in `script_func_local_4`, reached through
the normal Castle Inside SSL painting route and its authored area-1 warp. The
existing pointer-free Swift owner has contract `0x2f02c221a0c4104e`, but the
source identity/receipt seam, native lifecycle pair, and admission remain
pending; the row remains planned. The regenerated inventory remains 7,420
rows with manifest SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715` and no
manifest, report, ledger, or source mutation was performed.

Phase 85f77 performed a read-only publication-action audit. The isolated
serial candidate remains 26 terminal / 7,394 planned with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`; the
retained canonical report remains 25 terminal / 7,395 planned with SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
The f72/f69 outputs are byte-identical and eligible only for a separately
authorized write-once designation; no report, manifest, ledger, or status
publication was performed. Phase 85f78 committed the source-owned Spindel
receipt seam in commit `91e53c7f`, including the semantic `bhvSpindel`
identity, pointer-free schema-4 observer, independent Swift mirror, focused
C/Swift route pair, and fail-closed matrix. The authored Castle→SSL route
remained at `level=1 area=1 spindels=0`; the matrix exited 77 with
`trace=not-created`, `records=0`, and `admission=0`. No route record,
manifest, retained report, canonical route ledger, or acceptance state
changed. The f79 refresh's stale f78-pending wording is corrected by this
Phase 85f80 documentation update. Retained live-route qualification remains
`25/7420 = 0.336927224%`, the isolated qualification remains
`26/7420 = 0.350404313%`, behavior mapping remains 95.693%, and M34, M35,
human-acceptance, and full-goal floors remain 0%.

Phase 85f81 then completed the write-once local designation after re-reading
the exact candidate, old retained report, and manifest. The designated report
is the 7,420-row `26/7,394` report at
`build/sm64-modern-phase85f81-serial-publication/run.elhzBC/canonical-route-ledger.tsv`
with SHA-256
`4982e0157b94cc1ca940983f9121d89b216c0375d413cccdf30257af7a37adc4`. The old
25/7,395 report remains byte-identical in the designated root's
`pre-publication-backup` at SHA-256
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`; the
manifest remains unchanged at SHA-256
`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`.
Phase 85f82 records this status transition only: source, manifest, old
retained report, push, release, store publication, and human-acceptance state
were not changed. M34, M35, human-acceptance, and full-goal floors remain 0%.

Phase 85f18 rechecked the authored DDD Sushi seam and found no qualifying
pointer-free owner/query receipt; shard `0x023fe9bb4409460b` remains planned.
Phase 85f19 rechecked the authored BBH display-list seam and found no
source-defined pointer-free owner/packet receipt; candidate
`0x000670ec2a57dfa8` remains planned. Phase 85f20 re-audited M34 with one
detected display offline (`online=0`), `gputoolsserviced` not running, no active
GPU session, and thermal state unknown (`0xe00002bc`); no replay, capture,
pixel, soak, or direct-display evidence is claimable. Phase 85f21 rechecked
M35 under ordinary Xcode 26.6: the readiness/distribution contracts pass, but
no Developer ID identity/private key or supported `notarytool` authentication
exists, so no distribution artifact or Gatekeeper/human result exists.
Phase 85f22 regenerated the 7,420-row manifest twice with byte-identical
outputs (`23c9d3f1aff0a8980c0a7e5104867e123681cc681ebe7e10929284e9cac2b715`),
verified the retained 25/7,395 report
(`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`), and
confirmed the historical full replay cannot be rerun because its transient
pendulum artifact expired. No canonical route or manifest state changed.

Phase 85f24 audited the authored environment-effect modes. Five of six
planned envfx rows have source-authored level/geo reachability across the lava,
whirlpool, jet-stream, and snow modes, while the flower mode is unused. No
pointer-free value receipt exists for the RNG, floor, or water-query state, so
no route row or canonical artifact changed.

Phase 85f25 reached the authored intro `SET_TRANSITION` route at the real
155-step owner-thread window (251 script records, transition ID 3 present),
but the existing Swift script observer rejects the intro trace as
`out_of_order` because its contract expects the first record at tick 2. No
independent C/Swift pair or route admission is claimed.

Phase 85f26 identified authored DDD outward-radial and JRB default-camera
`find_water_level` candidates. The shared generic collision receipt lacks the
camera owner, call site, mode, and query-position identity needed to qualify
either candidate; the existing camera `find_floor` row remains current and no
manifest/report mutation occurred.

Phases 85aq–85as used disjoint Luna-max workers to triage remaining route
families and replay authored level/transition recipes. Camera `find_floor`,
display-list, and render-callback now have source-bound terminal rows; pendulum,
audio-asset, geo/collision, and level/transition candidates remain fail-closed
because exact parity or an authored branch is missing. The
canonical audit in Phase 85av re-ran the merge smoke with byte-identical
manifest/report hashes (`23c9d3f1…` / `dfa2dd3c…`) and preserved 15 terminal
rows.

Phase 85at retried M34 attachment replay, cadence/thermal soak, and
direct-display evidence. The host was locked with no online display,
`gputoolsserviced` is launchd-running again, but the GUI session remains locked,
no display is online, and `gpudebug --list-sessions` reports no active session;
no PNG, pixel verdict, long soak, or physical visual/feel result exists. Phase 85au rechecked M35 with ordinary
Xcode 26.6; contracts pass, but no Developer ID identity/private key or
`notarytool` credentials are present, so no archive/export/notarization,
clean-machine Gatekeeper, or human acceptance result exists.

Phase 85aw's final audit passes strict Swift 6, focused C/Swift route-pair,
ASan/UBSan/Release, and Metal 4 source/archive/scene contracts. The separate
conservative floors remain 0%: M34 device/pixel/soak evidence is blocked by
the locked/offline host, no active GPU session, and missing visible-display
evidence, M35 release/Gatekeeper
evidence is blocked by missing Developer ID/notary credentials, and the fresh-
save human 120-star checklist is not run. The historical Phase 85aw route
qualification was 15/7,420 = 0.202156334%, with 7,405 planned; later route
admissions are recorded separately below. The conservative floors remain
historical 0% gates, not a closure claim.

Phase 85f5 extended the cumulative canonical evidence to 25 terminal rows and
7,395 planned; the merged report SHA is
`aa8eadcb63a555ed3cca7bf2d8c592f2798270633dce4c2d16d0acc79bf87c3d`.
Phase 85f2's fresh M34 production re-audit remains fail-closed: the console is
locked, the sole display is offline, no GPU session is active, and thermal
telemetry returns `0xe00002bc`; no new replay, pixel, soak, direct-display, or
physical evidence is admissible.
Phase 85g2's fresh M35 re-audit passes the readiness/distribution contracts but
still finds no valid Developer ID Application identity/private key and no
supported `notarytool` authentication; no archive, notarization, Gatekeeper,
or human-acceptance evidence exists.
Phase 85f3 repaired the pendulum lifecycle boundary and passed exact Debug,
ASan, Release, and rerun pairing: 1,056/1,056 records matched with semantic
identity `0x6268765f647065` and coverage `0x680ff75430bf24ff`. Phases 85f4 and
85f5 then admitted and merged the row; cumulative evidence is 25/7,395.
Phase 85f6 independently admitted the authored JRB `random_u16` route
(`0x00576356a427dbc2`) with exact 40-record C/Swift/ASan/Release parity and
all negative fences. The row was already terminal in the 25-row cumulative
ledger, so this revalidation made no ledger-count change.
Phase 85f8 reached the authored Snowman’s Land Moneybag source but remained
fail-closed: the initialized lifecycle stayed in area 2, runtime Moneybags
were zero, and no source-owned `random_float` receipt was emitted.
Phase 85f9 confirms the planned `find_water_level` route is likewise
fail-closed: the selected JRB lifecycle reaches water data but no authored
Sushi object or Sushi call-site receipt. No synthetic collision route was
created.
Phase 85f10 route-breadth audit found no new candidate satisfying authored
reachability, pointer-free ownership, independent C/Swift parity, four-way
configuration parity, and admission gates; the ledger remains unchanged.
Phase 85f11 confirms DDD is source-reachable for `find_water_level` through two
authored Sushi objects, but no pointer-free owner/query receipt exists yet;
the row remains planned without synthetic instrumentation.
Phase 85ct source-proved the next full-trace actor seam: subject 31 is the
authored `bhvDeathWarp` at `levels/castle_inside/script.c:62`, with semantic
identity `0xa22b7ff16730e047`. Debug, ASan, Release, rerun, and Swift traces
all carry that identity, while PCM/receipt sidecars remain exact. Whole-trace
parity was still fail-closed at record 1496 / byte 191617 for subject 32,
`bhvAirborneStarCollectWarp`; this is historical pre-audio evidence.

Phase 85cx source-triaged subject 32 as the authored 90°
`bhvAirborneStarCollectWarp` at `levels/castle_inside/script.c:61`, with
expected semantic identity `0xa85510394290b349`. The retained values remain
layout-dependent, so a fresh full matrix is required before any promotion.

Phase 85cz re-ran the canonical ledger audit without mutation: the manifest
remains 7,420 rows with SHA `23c9d3f1…2b715`, the report remains 23 terminal /
7,397 planned with SHA `af006829…ff28e`, and duplicate/conflict/fixture-only/
terminal-rerun fences all reject correctly. Object/camera markers remain
`actual=2965` and `actual=11391` (`0x1c41224c64ab005f`).

Phase 85cy added the source-bound `bhvAirborneStarCollectWarp` identity
`0xa85510394290b349` and completed the isolated Debug/ASan/Release/rerun/
Swift matrix with exact C/Swift/rerun, PCM, receipt, and negative-fence seams.
Whole-trace parity now fails closed at record 1524 / byte 195201 for subject
34, the unresolved same-position launch-warp pair; no audio row moved.

Phase 85da source-proved subject 34 as `bhvLaunchDeathWarp` at
`levels/castle_inside/script.c:59`, with semantic identity
`0xbe5dc4c2a1630b6a`; subject 35 is the adjacent line-58
`bhvLaunchStarCollectWarp`. The owner mapping and a fresh parity rerun remain
required.

Phase 85db added that narrow owner mapping and produced complete Debug/ASan
artifacts with matching PCM/receipt sidecars, but the bounded Release build
stopped before Release/Swift/rerun/negative-fence evidence. No parity or
canonical promotion is claimed.

Phase 85dc completed the corrected Debug/ASan/Release/rerun/Swift matrix,
PCM/receipt pairing, and negative fences. Subject 34 now matches
`bhvLaunchDeathWarp` across all five traces, but parity fails next at record
1538 / byte 196992 for subject 35, the adjacent `bhvLaunchStarCollectWarp`;
no audio row moved.

Phase 85dd confirmed the Release native-core build itself is healthy: a fresh
build exits 0 in 24.6 seconds with a valid 355-member archive. The earlier
Release stops were bounded-interruption artifacts, not compiler/linker,
resource, or permission failures.

Phase 85de added `bhvLaunchStarCollectWarp` (`0x0b9ebb9260f83fe6`) and passed
the complete Debug/ASan/Release/rerun/Swift, PCM/receipt, and negative-fence
seams for subject 35. Whole-trace parity now fails closed at record 1566 /
byte 200576 for subject 37; no audio row moved.

Phase 85df source/symbol triage identifies subject 37 as
`bhvHardAirKnockBackWarp` at `levels/castle_inside/script.c:56`, semantic
identity `0x53f6c1e071460d11`; its owner mapping and rerun remain required.

Phase 85dg added that mapping and passed the complete Debug/ASan/Release/
rerun/Swift, PCM/receipt, and negative-fence seams for subject 37. Whole-trace
parity now fails closed at record 1580 / byte 202368 for subject 38; no audio
row moved.

Phase 85dt source/symbol triage identifies subject 55 as `bhvTankFishGroup` at
`levels/castle_inside/script.c:258`, semantic identity `0x82764ca860723a66`;
its owner mapping and rerun remain required.

Phase 85du added that mapping and passed the complete Debug/ASan/Release/
rerun/Swift, PCM/receipt, and negative-fence seams for subject 55. Whole-trace
parity now fails closed at record 1860 / byte 238208 for subject 59; no audio
row moved.

Phase 85dv added `bhvFishGroup` (`0xc6155cb64739208a`) and passed the complete
matrix/fence seams for subject 59. Parity now fails at dynamic sparkle-spawner
effect record 3244 / byte 415368; no audio row moved.

Phase 85dw added `bhvSparkleParticleSpawner` (`0x592bd9fc97e8d9cd`) and
passed the complete effect matrix/fences. Parity now fails at tick 3 record
3347 / byte 428552 for a dynamic `bhvCloud` child; no audio row moved.

Phase 85dx added `bhvCloud` (`0xd5ddc2c0adf7ebee`) and passed the complete
dynamic effect matrix/fences. Parity now fails at tick 3 record 3413 / byte
437000 for a dynamic `bhvCloudPart` child; no audio row moved.

Phase 85dy added `bhvCloudPart` (`0x38efdd59a4a22407`) and passed the complete
effect matrix/fences. Parity now fails at tick 3 record 3865 / byte 494848 for
dynamic `bhvClockMinuteHand`; no audio row moved.

Phase 85dz added `bhvClockMinuteHand` (`0xf65c418441900e3c`) and passed the
complete matrix/fences. Parity now fails at tick 3 record 3879 / byte 496640
for dynamic `bhvClockHourHand`; no audio row moved.

Phase 85ea added `bhvClockHourHand` (`0x670a6acb648286ae`) and closed the full
Castle audio/effect matrix: all five 476,365-record traces share SHA
`15273415…198e5d`, PCM/receipts match, and all negative fences pass. This is
route evidence only; canonical admission is the next phase.

Phase 85eb kept canonical admission fail-closed: the candidate audio-asset
trace header has `coverage_fingerprint=0` and broad unrelated domains, while
the manifest row requires only `audio_sequence,audio_pcm`. A source-backed
audio-only capture with nonzero coverage is required; no synthetic projection
was promoted.

Phase 85ef completed the source-backed repair: opt-in audio-only runtime
capture emits 1,084 audio-only records with coverage `0x553ab8ef49275722`.
Independent C/Swift/ASan/Release/rerun traces, PCM/receipts, and fences pass;
canonical admission followed. Phase 85f0 completed isolated admission for
manifest row `0x03345fc560c65b75`: the report SHA is
`7c22c62f13e25c430069bdfe1c77840fd5f6751737a3c63b3ff6361e88bdb19d` and the
proof SHA is `6dda3168db361324d0283056476be0cef7dc95c249225d757d874303c4bb2081`.
Phase 85f1 then merged the row into cumulative evidence: 24 terminal / 7,396
planned, report SHA `9a68a65a3e20838fab76d35014fd46172e9435de00e8e5b2148d44c0eee4985f`.

Phase 85dl source/symbol triage identifies subject 40 as
`bhvInstantActiveWarp` at `levels/castle_inside/script.c:53`, semantic identity
`0xf961678fe6b653ea`; its owner mapping and rerun remain required.

Phase 85dm added that mapping and passed the complete Debug/ASan/Release/
rerun/Swift, PCM/receipt, and negative-fence seams for subjects 40–41.
Whole-trace parity now fails closed at record 1636 / byte 209536 for subject
42; the additional 85do Warp mapping advances the first remaining mismatch to
subject 49 at record 1734 / byte 222080; no audio row moved.

Phase 85do added `bhvWarp` (`0x2b006194588201ff`) and passed the complete
Debug/ASan/Release/rerun/Swift, PCM/receipt, and negative-fence seams through
subject 42. Parity now fails closed on subject 49 (`bhvStarDoor` candidate).

Phase 85dp source/symbol triage identifies subject 49 as the second authored
8-star `bhvStarDoor` at `levels/castle_inside/script.c:24`, semantic identity
`0xda6397948f7ac5cd`; its owner mapping and rerun remain required.

Phase 85dq added that mapping and passed the complete Debug/ASan/Release/
rerun/Swift, PCM/receipt, and negative-fence seams for subject 49. Whole-trace
parity now fails closed at record 1762 / byte 225664 for subject 51; no audio
row moved.

Phase 85dr source/symbol triage identifies subject 51 as `bhvToadMessage` at
`levels/castle_inside/script.c:262`, semantic identity `0x00c91057a2eb6ffc`;
its owner mapping and rerun remain required.

Phase 85ds added that mapping and passed the complete Debug/ASan/Release/
rerun/Swift, PCM/receipt, and negative-fence seams for subject 51. Whole-trace
parity now fails closed at record 1804 / byte 231040 for subject 55; no audio
row moved.

Phase 85dn source/symbol triage identifies subject 42 as `bhvWarp` at
`levels/castle_inside/script.c:49`, semantic identity `0x2b006194588201ff`;
its owner mapping and rerun remain required.

Phase 85dh source/symbol triage identifies subject 38 as
`bhvAirborneDeathWarp` at `levels/castle_inside/script.c:55`, semantic identity
`0x53e013ea7d7cc8b5`; its owner mapping and rerun remain required.

Phase 85di added that mapping and passed the complete Debug/ASan/Release/
rerun/Swift, PCM/receipt, and negative-fence seams for subject 38. Whole-trace
parity now fails closed at record 1594 / byte 204160 for subject 39; no audio
row moved.

Phase 85dj source/symbol triage identifies subject 39 as `bhvAirborneWarp` at
`levels/castle_inside/script.c:54`, semantic identity `0x3e6af9ed47c59929`;
its owner mapping and rerun remain required.

Phase 85dk added that mapping and passed the complete Debug/ASan/Release/
rerun/Swift, PCM/receipt, and negative-fence seams for subject 39. Whole-trace
parity now fails closed at record 1608 / byte 205953 for subject 40; no audio
row moved.

Phase 85cv rechecked the M34 host gate: one display is detected but offline,
the GPU service is available with no active `gpudebug` session, and thermal
telemetry still fails with `0xe00002bc`. Replay, pixels, soak, direct-display,
and physical acceptance remain unclaimed.

Phase 85cw rechecked M35: stable Xcode 26.6 and both distribution contracts
pass, but no valid signing identity, Developer ID certificate/private key, or
notary credentials exist. No archive/export/notarization, clean-machine
Gatekeeper, or human acceptance evidence is claimable.
Phase 85be restored current camera `find_floor` reproducibility with a fresh
build root: `actual=11391`, coverage `0x1c41224c64ab005f`, and exact
Debug/ASan/Release/rerun parity. The retained camera admission is current
again; remaining planned rows and external gates stay fail-closed.
Phase 85bf added native-only RNG receipts and prepared text/behavior seams, but
none reached independent C/Swift admission; the canonical state remains 18
terminal and 7,402 planned.
Phase 85bg/85bh have an exact 40-record RNG C/Swift/ASan/Release pair and
canonical admission; Phase 85bi/85bj add the authored text row canonically.
Phase 85bk/85bl add and canonically admit a second exact inside-castle
display-list pair; its RNG-float candidate remains unreachable in authored SL
area 1. Phase 85bq independently admits the authored
`inside_castle_seg7_dl_07043A68` shard with byte-identical C/Swift/ASan/Release
traces and packet sidecars. Phase 85br canonically merges it. Phase 85bs/85bt
qualify and admit the authored door leaf `door_seg3_dl_03014EF0`; Phase 85bu
canonically merges it. Current object-state markers are aligned to `actual=2965`,
camera `actual=11391`, and broad legacy C/Swift pairing plus external
M34/M35/human gates remain open.

The final audit handoff is
[Phase 85aw final audit](.porting/porting-handoff-full-swift-twin-phase85aw-final-audit.md).
The current route audit and latest admission/merge handoffs are
[Phase 85bn audit](.porting/porting-handoff-full-swift-twin-phase85bn-route-audit.md),
[Phase 85bq inside-castle admission](.porting/porting-handoff-full-swift-twin-phase85bq-inside-castle-admission.md),
 [Phase 85bt door admission](.porting/porting-handoff-full-swift-twin-phase85bt-door-admission.md),
[Phase 85bu canonical merge](.porting/porting-handoff-full-swift-twin-phase85bu-canonical-merge.md),
[Phase 85ct subject-31 identity](.porting/porting-handoff-full-swift-twin-phase85ct-subject31-identity.md),
[Phase 85cv M34 host gate](.porting/porting-handoff-full-swift-twin-phase85cv-m34-gate.md),
[Phase 85cw M35 gate](.porting/porting-handoff-full-swift-twin-phase85cw-m35-gate.md),
[Phase 85cx subject-32 triage](.porting/porting-handoff-full-swift-twin-phase85cx-next-audio-identity.md),
[Phase 85cy airborne-star mapping](.porting/porting-handoff-full-swift-twin-phase85cy-airborne-star-mapping.md),
[Phase 85cz canonical audit](.porting/porting-handoff-full-swift-twin-phase85cz-canonical-audit.md),
[Phase 85da launch-warp triage](.porting/porting-handoff-full-swift-twin-phase85da-launch-warp-triage.md),
[Phase 85db launch-death mapping](.porting/porting-handoff-full-swift-twin-phase85db-launch-death-mapping.md),
[Phase 85dc launch-death rerun](.porting/porting-handoff-full-swift-twin-phase85dc-launch-death-rerun.md),
[Phase 85dd Release-build diagnosis](.porting/porting-handoff-full-swift-twin-phase85dd-release-build-diagnosis.md),
[Phase 85de launch-star mapping](.porting/porting-handoff-full-swift-twin-phase85de-launch-star-mapping.md),
[Phase 85df hard-air triage](.porting/porting-handoff-full-swift-twin-phase85df-hard-air-triage.md),
[Phase 85dg hard-air mapping](.porting/porting-handoff-full-swift-twin-phase85dg-hard-air-mapping.md),
[Phase 85dh airborne-death triage](.porting/porting-handoff-full-swift-twin-phase85dh-airborne-death-triage.md),
[Phase 85di airborne-death mapping](.porting/porting-handoff-full-swift-twin-phase85di-airborne-death-mapping.md),
[Phase 85dj airborne-warp triage](.porting/porting-handoff-full-swift-twin-phase85dj-airborne-warp-triage.md),
[Phase 85dk airborne-warp mapping](.porting/porting-handoff-full-swift-twin-phase85dk-airborne-warp-mapping.md),
[Phase 85dl instant-active triage](.porting/porting-handoff-full-swift-twin-phase85dl-instant-active-triage.md),
[Phase 85dm instant-active mapping](.porting/porting-handoff-full-swift-twin-phase85dm-instant-active-mapping.md),
[Phase 85dn warp triage](.porting/porting-handoff-full-swift-twin-phase85dn-warp-triage.md),
[Phase 85do warp mapping](.porting/porting-handoff-full-swift-twin-phase85do-warp-mapping.md),
[Phase 85dp star-door triage](.porting/porting-handoff-full-swift-twin-phase85dp-star-door-triage.md),
[Phase 85dq star-door mapping](.porting/porting-handoff-full-swift-twin-phase85dq-star-door-mapping.md),
[Phase 85dr Toad-message triage](.porting/porting-handoff-full-swift-twin-phase85dr-toad-message-triage.md),
[Phase 85ds Toad-message mapping](.porting/porting-handoff-full-swift-twin-phase85ds-toad-message-mapping.md),
[Phase 85dt Tank-fish triage](.porting/porting-handoff-full-swift-twin-phase85dt-tank-fish-triage.md),
[Phase 85du Tank-fish mapping](.porting/porting-handoff-full-swift-twin-phase85du-tank-fish-mapping.md),
[Phase 85dv Fish-group mapping](.porting/porting-handoff-full-swift-twin-phase85dv-fish-group-mapping.md),
[Phase 85dw Sparkle-spawner mapping](.porting/porting-handoff-full-swift-twin-phase85dw-sparkle-spawner-mapping.md),
[Phase 85dx Cloud mapping](.porting/porting-handoff-full-swift-twin-phase85dx-cloud-mapping.md),
[Phase 85dy Cloud-part mapping](.porting/porting-handoff-full-swift-twin-phase85dy-cloud-part-mapping.md),
[Phase 85dz Clock-minute mapping](.porting/porting-handoff-full-swift-twin-phase85dz-clock-minute-mapping.md),
[Phase 85ea Clock-hour mapping](.porting/porting-handoff-full-swift-twin-phase85ea-clock-hour-mapping.md),
[Phase 85eb audio-route admission](.porting/porting-handoff-full-swift-twin-phase85eb-audio-route-admission.md),
[Phase 85ed audio-only coverage](.porting/porting-handoff-full-swift-twin-phase85ed-audio-only-coverage.md),
[Phase 85ef source-backed audio coverage repair](.porting/porting-handoff-full-swift-twin-phase85ef-audio-coverage-source-repair.md),
[Phase 85f0 audio-asset admission](.porting/porting-handoff-full-swift-twin-phase85f0-audio-asset-admission.md),
[Phase 85f1 audio-asset canonical merge](.porting/porting-handoff-full-swift-twin-phase85f1-audio-asset-canonical-merge.md),
[Phase 85f2 pendulum route attempt](.porting/porting-handoff-full-swift-twin-phase85f2-pendulum-route.md),
[Phase 85f2 M34 production re-audit](.porting/porting-handoff-full-swift-twin-phase85f2-m34-production-reaudit.md),
[Phase 85g2 M35 distribution re-audit](.porting/porting-handoff-full-swift-twin-phase85g2-m35-distribution-reaudit.md),
[Phase 85f3 pendulum four-way matrix](.porting/porting-handoff-full-swift-twin-phase85f3-pendulum-matrix.md),
[Phase 85f4 pendulum isolated admission](.porting/porting-handoff-full-swift-twin-phase85f4-pendulum-admission.md),
[Phase 85f5 pendulum canonical merge](.porting/porting-handoff-full-swift-twin-phase85f5-pendulum-canonical-merge.md),
[Phase 85f6 RNG break-particles admission](.porting/porting-handoff-full-swift-twin-phase85f6-rng-break-particles-admission.md),
[Phase 85f6 BBH display-list discovery](.porting/porting-handoff-full-swift-twin-phase85f6-bbh-displaylist-discovery.md),
[Phase 85f8 RNG-float reachability](.porting/porting-handoff-full-swift-twin-phase85f8-rng-float-reachability.md),
[Phase 85f9 water-level reachability](.porting/porting-handoff-full-swift-twin-phase85f9-water-level-reachability.md),
[Phase 85f10 route-breadth audit](.porting/porting-handoff-full-swift-twin-phase85f10-route-breadth.md),
[Phase 85f11 DDD Sushi discovery](.porting/porting-handoff-full-swift-twin-phase85f11-ddd-sushi-route.md),
[Phase 85f17 documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85f17-docs-reconciliation.md),
[Phase 85f18 DDD Sushi source seam](.porting/porting-handoff-full-swift-twin-phase85f18-sushi-seam.md),
[Phase 85f19 BBH display-list seam retry](.porting/porting-handoff-full-swift-twin-phase85f19-bbh-seam-retry.md),
[Phase 85f20 M34 production re-audit](.porting/porting-handoff-full-swift-twin-phase85f20-m34-reaudit.md),
[Phase 85f21 M35 distribution preflight](.porting/porting-handoff-full-swift-twin-phase85f21-m35-preflight.md),
[Phase 85f22 canonical route audit](.porting/porting-handoff-full-swift-twin-phase85f22-canonical-audit.md),
[Phase 85f23 current-status documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f23-docs-current-refresh.md),
[Phase 85f24 envfx RNG route discovery](.porting/porting-handoff-full-swift-twin-phase85f24-envfx-rng-route.md),
[Phase 85f25 authored transition route](.porting/porting-handoff-full-swift-twin-phase85f25-transition-route.md),
[Phase 85f26 camera/water route discovery](.porting/porting-handoff-full-swift-twin-phase85f26-camera-floor-route.md),
[Phase 85f27 current-status documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f27-docs-refresh.md),
[Phase 85f30 intro transition seam pair](.porting/porting-handoff-full-swift-twin-phase85f30-transition-seam-execute.md),
[Phase 85f31 camera-water seam](.porting/porting-handoff-full-swift-twin-phase85f31-camera-water-seam-execute.md),
[Phase 85f32 intro transition isolated admission](.porting/porting-handoff-full-swift-twin-phase85f32-intro-transition-admission.md),
[Phase 85f33 intro transition phase-local guarded merge](.porting/porting-handoff-full-swift-twin-phase85f33-intro-transition-canonical-merge.md),
[Phase 85f34 current-status documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f34-docs-refresh.md),
[Phase 85f35 DDD camera reachability](.porting/porting-handoff-full-swift-twin-phase85f35-ddd-camera-reachability.md),
[Phase 85f36 current-status documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f36-docs-refresh.md),
[Phase 85f37 Castle-to-DDD traversal discovery](.porting/porting-handoff-full-swift-twin-phase85f37-castle-ddd-traversal.md),
[Phase 85f38 final documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f38-docs-final-refresh.md),
[Phase 85f39 serial-publication audit](.porting/porting-handoff-full-swift-twin-phase85f39-serial-publication-audit.md),
[Phase 85f40 Castle-to-DDD recipe audit](.porting/porting-handoff-full-swift-twin-phase85f40-castle-ddd-recipe-audit.md),
[Phase 85f41 M34 host/production re-audit](.porting/porting-handoff-full-swift-twin-phase85f41-m34-reaudit.md),
[Phase 85f42 M35 distribution re-audit](.porting/porting-handoff-full-swift-twin-phase85f42-m35-reaudit.md),
[Phase 85f43 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f43-docs-refresh.md),
[Phase 85f44 isolated-admission inventory](.porting/porting-handoff-full-swift-twin-phase85f44-isolated-admission-inventory.md),
[Phase 85f45 WDW elevator discovery](.porting/porting-handoff-full-swift-twin-phase85f45-next-route-discovery.md),
[Phase 85f46 Metal 4 contract re-audit](.porting/porting-handoff-full-swift-twin-phase85f46-metal4-contract-reaudit.md),
[Phase 85f47 WDW elevator seam](.porting/porting-handoff-full-swift-twin-phase85f47-wdw-elevator-seam-execute.md),
[Phase 85f48 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f48-docs-refresh.md),
[Phase 85f49 WDW area-1 reachability audit](.porting/porting-handoff-full-swift-twin-phase85f49-wdw-area1-reachability.md),
[Phase 85f50 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f50-docs-refresh.md),
[Phase 85f51 f49 documentation correction](.porting/porting-handoff-full-swift-twin-phase85f51-docs-f49-correction.md),
[Phase 85f52 TTC 2D rotator discovery](.porting/porting-handoff-full-swift-twin-phase85f52-next-route-discovery.md),
[Phase 85f53 TTC 2D rotator seam](.porting/porting-handoff-full-swift-twin-phase85f53-ttc-rotator-seam-execute.md),
[Phase 85f54 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f54-docs-refresh.md),
[Phase 85f55 documentation correction](.porting/porting-handoff-full-swift-twin-phase85f55-docs-ttc-correction.md),
[Phase 85f56 TTC area-1 reachability audit](.porting/porting-handoff-full-swift-twin-phase85f56-ttc-area1-reachability.md),
[Phase 85f57 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f57-docs-ttc-blocker-refresh.md),
[Phase 85f58 Bob seesaw discovery](.porting/porting-handoff-full-swift-twin-phase85f58-next-route-discovery.md),
[Phase 85f59 publication-wrapper audit](.porting/porting-handoff-full-swift-twin-phase85f59-publication-wrapper-audit.md),
[Phase 85f60 acceptance-state audit](.porting/porting-handoff-full-swift-twin-phase85f60-acceptance-state-audit.md),
[Phase 85f61 timebase-drift diagnosis](.porting/porting-handoff-full-swift-twin-phase85f61-timebase-drift-diagnosis.md),
[Phase 85f62 Bob seesaw seam](.porting/porting-handoff-full-swift-twin-phase85f62-seesaw-seam-execute.md),
[Phase 85f63 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f63-docs-refresh.md),
[Phase 85f64 serial merge dry-run](.porting/porting-handoff-full-swift-twin-phase85f64-serial-merge-dryrun.md),
[Phase 85f65 timebase fixture proposal](.porting/porting-handoff-full-swift-twin-phase85f65-timebase-fixture-proposal.md),
[Phase 85f66 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f66-docs-refresh.md),
[Phase 85f67 pendulum evidence refresh](.porting/porting-handoff-full-swift-twin-phase85f67-pendulum-evidence-refresh.md),
[Phase 85f68 dry-run immutability fix](.porting/porting-handoff-full-swift-twin-phase85f68-dryrun-immutability-fix.md),
[Phase 85f69 serial dry-run fence fix](.porting/porting-handoff-full-swift-twin-phase85f69-serial-dryrun-fence-fix.md),
[Phase 85f70 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f70-docs-refresh.md),
[Phase 85f71 Spindrift discovery](.porting/porting-handoff-full-swift-twin-phase85f71-next-route-discovery.md),
[Phase 85f72 serial publication readiness](.porting/porting-handoff-full-swift-twin-phase85f72-serial-publication-readiness.md),
[Phase 85f73 Spindrift seam execute](.porting/porting-handoff-full-swift-twin-phase85f73-spindrift-seam-execute.md),
[Phase 85f74 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f74-docs-refresh.md), and
[Phase 85f75 Spindrift documentation correction](.porting/porting-handoff-full-swift-twin-phase85f75-docs-spindrift-correction.md),
[Phase 85f76 Spindel discovery](.porting/porting-handoff-full-swift-twin-phase85f76-next-route-discovery.md),
[Phase 85f77 publication-action audit](.porting/porting-handoff-full-swift-twin-phase85f77-publication-action-audit.md),
[Phase 85f78 Spindel seam execute](.porting/porting-handoff-full-swift-twin-phase85f78-spindel-seam-execute.md),
[Phase 85f79 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f79-docs-refresh.md), and
[Phase 85f80 Spindel documentation correction](.porting/porting-handoff-full-swift-twin-phase85f80-docs-spindel-correction.md),
[Phase 85f81 serial canonical designation](.porting/porting-handoff-full-swift-twin-phase85f81-serial-canonical-designation.md), and
[Phase 85f82 canonical status transition](.porting/porting-handoff-full-swift-twin-phase85f82-docs-canonical-transition.md),
[Phase 85f83 WDW reachability recheck](.porting/porting-handoff-full-swift-twin-phase85f83-wdw-reachability-recheck.md),
[Phase 85f84 TTC reachability recheck](.porting/porting-handoff-full-swift-twin-phase85f84-ttc-reachability-recheck.md),
[Phase 85f85 Bob reachability recheck](.porting/porting-handoff-full-swift-twin-phase85f85-bob-reachability-recheck.md),
[Phase 85f86 Spindrift reachability recheck](.porting/porting-handoff-full-swift-twin-phase85f86-spindrift-reachability-recheck.md),
[Phase 85f87 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f87-docs-refresh.md), and
[Phase 85f88 Snowman wind discovery](.porting/porting-handoff-full-swift-twin-phase85f88-next-route-discovery.md),
[Phase 85f89 Snowman wind seam execute](.porting/porting-handoff-full-swift-twin-phase85f89-snowman-wind-seam-execute.md),
[Phase 85f90 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f90-docs-refresh.md),
[Phase 85f91 Snowman wind documentation correction](.porting/porting-handoff-full-swift-twin-phase85f91-docs-snowman-wind-correction.md),
[Phase 85f92 JRB treasure discovery](.porting/porting-handoff-full-swift-twin-phase85f92-next-route-discovery.md),
[Phase 85f93 JRB treasure-chest seam execute](.porting/porting-handoff-full-swift-twin-phase85f93-treasure-chest-seam-execute.md),
[Phase 85f94 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f94-docs-refresh.md),
[Phase 85f95 JRB documentation correction](.porting/porting-handoff-full-swift-twin-phase85f95-docs-treasure-correction.md),
[Phase 85f96 Whomp discovery](.porting/porting-handoff-full-swift-twin-phase85f96-next-route-discovery.md),
[Phase 85f97 Whomp King seam execute](.porting/porting-handoff-full-swift-twin-phase85f97-whomp-seam-execute.md),
[Phase 85f98 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f98-docs-refresh.md), and
[Phase 85f99 Whomp documentation correction](.porting/porting-handoff-full-swift-twin-phase85f99-docs-whomp-correction.md),
[Phase 85f100 Fire Piranha Plant discovery](.porting/porting-handoff-full-swift-twin-phase85f100-next-route-discovery.md),
[Phase 85f101 Fire Piranha Plant static seam](.porting/porting-handoff-full-swift-twin-phase85f101-fire-piranha-seam-execute.md),
[Phase 85f102 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f102-docs-refresh.md),
[Phase 85f103 Donut Platform discovery](.porting/porting-handoff-full-swift-twin-phase85f103-next-route-discovery.md),
[Phase 85f104 Donut Platform static seam](.porting/porting-handoff-full-swift-twin-phase85f104-donut-platform-seam-execute.md), and
[Phase 85f105 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f105-docs-refresh.md),
[Phase 85f106 Pokey discovery](.porting/porting-handoff-full-swift-twin-phase85f106-next-route-discovery.md),
[Phase 85f107 Pokey static seam](.porting/porting-handoff-full-swift-twin-phase85f107-pokey-seam-execute.md), and
[Phase 85f108 documentation refresh](.porting/porting-handoff-full-swift-twin-phase85f108-docs-refresh.md),
[Phase 85f109 Pokey documentation correction](.porting/porting-handoff-full-swift-twin-phase85f109-docs-pokey-correction.md),
[Phase 85f110 Pokey runtime route](.porting/porting-handoff-full-swift-twin-phase85f110-pokey-runtime-route.md),
[Phase 85f111 M34 production audit](.porting/porting-handoff-full-swift-twin-phase85f111-m34-production-audit.md),
[Phase 85f112 M35 distribution audit](.porting/porting-handoff-full-swift-twin-phase85f112-m35-distribution-audit.md), and
[Phase 85f113 documentation/M34/M35 route](.porting/porting-handoff-full-swift-twin-phase85f113-docs-route-m34-m35.md),
[Phase 85f114 Castle→SSL traversal recipe](.porting/porting-handoff-full-swift-twin-phase85f114-castle-ssl-traversal-recipe.md), and
[Phase 85f115 documentation/traversal recipe](.porting/porting-handoff-full-swift-twin-phase85f115-docs-traversal-recipe.md),
[Phase 85f116 Castle-door input variants](.porting/porting-handoff-full-swift-twin-phase85f116-castle-door-input-variants.md),
[Phase 85f117 Castle-door refinement](.porting/porting-handoff-full-swift-twin-phase85f117-castle-door-refinement.md), and
[Phase 85f118 documentation/Castle-door refinement](.porting/porting-handoff-full-swift-twin-phase85f118-docs-castle-door-refinement.md),
[Phase 85f119 final fixed lateral variant](.porting/porting-handoff-full-swift-twin-phase85f119-castle-door-final-variant.md), and
[Phase 85f120 documentation/final door variant](.porting/porting-handoff-full-swift-twin-phase85f120-docs-final-door-variant.md).

The continuation plan and automatic handoff/commit protocol are recorded in
[`goal-continuation-luna-max-2026-08-20.md`](.porting/goal-continuation-luna-max-2026-08-20.md).

Phases 81–82b moved M34 from the earlier locked/asleep-host failure to a
ready-host, zero-drop API/shader-validation pass. Phase 82a removed the
owner-thread pipeline wait; Phase 82b reproduced the two-pass harness with a
non-empty `.gputrace` and noninteractive `gpudebug` structural inspection.
Capture overhead remains separate from validation cadence and is not a
sustained-performance claim.

Phase 82c leaves M35 fail-closed on exactly two external prerequisites: no
Developer ID Application identity/private key and no supported `notarytool`
authentication. No signed archive/export, stapled app/DMG/ZIP, clean-machine
Gatekeeper result, or human acceptance result exists.

Phase 82d proved ordinary Metal 4 binary archive load/reuse in the validation
profile. Phase 82e retained the separate capture-tool failure. Phase 82f
resolved that archive/capture interaction with a capture-only archive bypass:
the unchanged production harness passed validation, capture, resize/pause,
post-resume, and `gpudebug` structural checks. This remains structural/runtime
evidence, not visual parity.

Phase 84a statically inspected the retained trace (515 render passes and
28,216 draws), but attachment replay failed at an XPC replayer interruption.
No color/depth PNG was produced, so non-clear pixels and source/reference
parity remain unknown. Phase 84b completed two bounded 3,600-step native
Release profiles with zero scheduler/audio drops and approximately 59.94/59.96
Hz presentation, plus a separate Instruments trace with bounded encoder,
allocation, and nominal thermal observations. This does not prove a 10- or
30-minute soak, complete GPU/temperature/power telemetry, direct-to-display
output, or physical feel.

Phases 85a and 85b repaired the native Mario-state owner lifecycle and then
qualified exact C/Swift/ASan schema-4 parity for the two-tick, 38-record state
stream. Phase 85c admitted the canonical `oracle_hook|mario_state` row
(`0x88d04246f94ce9f8`) exactly once. Phases 85d–85f independently repaired the
camera focus and position path until all 14 camera records matched byte-for-byte;
Phase 85g admitted the canonical `oracle_hook|camera_state` row
(`0x4eb19b71d76be0d4`) exactly once. Phase 85h merged the real input, Mario,
and camera terminal results into one cumulative 7,420-row report: 3 terminal
passed and 7,417 planned, report SHA-256
`d9b9927ebf0e49d9ba9c0bf62dab322fddd43e7899642f0716071a1a948c4312`.
Phase 85j added the source-backed global-state owner publication boundary;
Phase 85k independently admitted the canonical `oracle_hook|global_state`
row (`0xb123ff3e997bdc78`) with 12 exact records and global report SHA-256
`c64d6cff061bcd43df5fa1b5551f8d49d0e80be352d51756a471186cc03f0e2e`.
Phase 85l merged all four terminal rows into the current cumulative report:
4 terminal passed and 7,416 planned, cumulative report SHA-256
`139cf48c3768d205f82531d47ae4bcbb20cca6ce178eeb0a0384a99e9453e979`.
Phase 85n produced exact source-backed object-state and script-events pairs
(28 and 1,272 records respectively), while the effects audit remains blocked:
the native window has 58 records and the independent Swift sink has only 2,
so no effects admission was attempted. Phase 85o admitted the object-state
(`0x862c3d78b60d657c`) and script-events (`0x2b0f6063b5463e9c`) rows. Phase
85p merged all six terminal rows into the current cumulative report: 6 terminal
passed and 7,414 planned, cumulative report SHA-256
`e406840d88f1d3ff99109c20cc6e75c164a1da8978350d12265260b8be02baf1`.
Phases 85q and 85r produced and admitted exact collision-query and RNG-draw
pairs: 204 domain-7 records for collision queries and 168 domain-8 records for
RNG draws, each with independent C/Swift/ASan parity and rerun/tamper fences.
Phase 85s merged all eight terminal rows into the current cumulative report:
8 terminal passed and 7,412 planned, cumulative report SHA-256
`91632bff276e0ecc99e845532f6b4d876a80ad237fbb660364a575313cbdc412`.
Phases 85u and 85v produced and admitted exact audio-sequence and save-bytes
pairs: 4 domain-9 audio receipts and 4 domain-10/save receipts, with matching
C/Swift/ASan/optimized traces and save sidecars. Phase 85w merged all ten
terminal rows into the current cumulative report: 10 terminal passed and 7,410
planned, cumulative report SHA-256
`693e70c316756c369577ccdf263f8b40f6d0b0766f92195b23cb4c979a9ccc35`.
Phase 85z audited the native PCM pre-device handoff without retaining PCM
bytes: schema-4 `audio_pcm` receipts remain absent, so the row stays planned.
The same phase produced an exact source-backed render-packet pair with 8
domain-11 records; Phase 85aa admitted that row with GPU/pixel acceptance
explicitly unverified. Phase 85ab merged all eleven terminal rows into the
current cumulative report: 11 terminal passed and 7,409 planned, cumulative
report SHA-256
`a67d6b3415a9327ac73c8fc37d9b529c3edce6fe4aae56c9d08c80f72b59d5d3`.
The render C/Swift/ASan/Release trace SHA-256 is
`379fc6cc84990d2ed67223df19dc78d540b3f7ba1768abc2ebad7a61eea01179`.
Phase 85ac added the owner-thread fixed-width PCM receipt seam after native
synthesis and before device playback; Phase 85ad independently admitted the
two-record `audio_pcm` row with exact C/Swift/ASan/Release and receipt parity.
Phase 85ae merged all twelve terminal rows into the current cumulative report:
12 terminal passed and 7,408 planned, cumulative report SHA-256
`5afa6c4b80f75fa70d18bfc4aab9b499266e69a8fdb61e11bc9a24a18a6cc958`.
This is deterministic pre-device receipt evidence, not audible/device PCM
parity. Phase 85af added an exact source-backed interaction-state pair with 14
domain-4 records; Phase 85ag independently admitted row
`0x3e1cdaca08b21f54` with report SHA-256
`2b8916452ceb54cf85fd18defcc883d211a5f1da41f04fd16c665d5dd5040457`.
Phase 85ah merged all thirteen terminal rows into the current cumulative
report: 13 terminal passed and 7,407 planned, cumulative report SHA-256
`ac3e2c19162fdcab8c938497d48398dbac8eb03004d2918a4524292573f9d8ad`.
Phase 85ai repaired the effects receipt parity seam; Phase 85aj independently
admitted the canonical effects row `0x3951f0333dc3c5da` with isolated report
SHA-256 `0c3fa33cd0d219a0e5347d6131397301e48699f91ee17a82c0c029607115a93d` and
trace SHA-256 `68329f0a22e7d20f5ddb3b22777d74e626523d5c0467ccac569566eb6c998226`.
Phase 85ak merged all fourteen terminal rows into the current cumulative
report: 14 terminal passed and 7,406 planned, cumulative report SHA-256
`4eccd90e978fbcd0cad42f8f64ba96c25774698c49b919ba1e3fdb020b1e0cd2`.
Phase 85am added source-backed level-script, save-mutation, and transition
route probes. The save-mutation row was admitted; its isolated report SHA-256
is `19dc977d7b8927089f7f22d22e1c35f5ab961ccc0a3c8ba62f741e6f221c29d6`.
The authored level-script pair reached global/script records but no transition
record, and the transition reachability probe did not trigger the no-floor warp;
both routes remain blocked and unadmitted. Phase 85ao merged all fifteen
terminal rows into the current cumulative report: 15 terminal passed and 7,405
planned, cumulative report SHA-256
`dfa2dd3c56fa8e5a97e1f1b699843b40aec24dfbcb8d3094825a8ace2cbd5c7c`.
Effects admission remains fixed-width source/value evidence only; device
effects, haptic feel, audible output, visual output, and human acceptance remain
unverified. The remaining rows still require independent route evidence; no
full-game, physical, release, or human-acceptance claim follows.

M34 still needs functioning attachment replay, reference-pixel comparison,
longer/complete performance and thermal evidence, and physical visual/feel
review. M35 still needs credentials, signed/stapled artifacts, clean-machine
checks, and the fresh-save human 120-star checklist. This branch is not shipped,
visual-parity complete, or a complete full-game Swift port.

The detailed phase notes below are historical through Phase 55; any pre-Phase
55 `7,419` wording is retained as historical evidence and does not override
the current `15 of 7,420` ledger.

### Next admissible gates

1. Rerun attachment fetch on a host where the `gpudebug` replayer loads, then
   inspect non-clear color/depth pixels against an explicit source/reference
   artifact. Keep static draw/attachment facts separate from pixel evidence.
2. Complete the declared longer performance/thermal/direct-display evidence;
   do not substitute the bounded 3,600-step or nominal thermal runs for a
   10/30-minute soak or physical visual/feel review.
3. Keep route pairing fail-closed for the remaining 7,405 planned rows: align
   common C/Swift fingerprints and tick windows, then admit only exact
   schema-4 parity with terminal worker results; the cumulative ledger remains
   15/7,420.
4. Obtain Developer ID Application and notary credentials, produce
   signed/stapled artifacts, verify clean-machine Gatekeeper, and finish the
   fresh-save human 120-star controls/camera/collision/audio/haptics/visual/
   menu/credits/ending/recovery checklist.

### Historical continuation record

The historical `nightly` continuation record below preserves the full-Swift-twin
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
[Phase 74b host-gate parser](.porting/porting-handoff-full-swift-twin-phase74b-host-gate-parser.md),
[Phase 75 M35 post-SDK preflight](.porting/porting-handoff-full-swift-twin-phase75-m35-post-sdk-preflight.md),
and [Phase 74 M34 host readiness](.porting/porting-handoff-full-swift-twin-phase74-m34-host-readiness.md),
[Phase 76 route-admission triage](.porting/porting-handoff-full-swift-twin-phase76-route-admission-triage.md),
and [Phase 77 docs/route triage](.porting/porting-handoff-full-swift-twin-phase77-docs-route-triage.md),
and [Phase 79 Mario-state route attempt](.porting/porting-handoff-full-swift-twin-phase79-mario-state-route-pair.md),
and [Phase 80 docs/Mario-state block](.porting/porting-handoff-full-swift-twin-phase80-docs-mario-state-block.md).
The latest production and documentation evidence is in [Phase 81 ready-host
M34 capture](.porting/porting-handoff-full-swift-twin-phase81-m34-ready-host-capture.md),
[Phase 82a scheduler cadence](.porting/porting-handoff-full-swift-twin-phase82a-scheduler-cadence.md),
[Phase 82b M34 reproducibility](.porting/porting-handoff-full-swift-twin-phase82b-m34-repro-audit.md),
[Phase 82c M35 distribution readiness](.porting/porting-handoff-full-swift-twin-phase82c-m35-distribution-readiness.md),
[Phase 82d archive reuse](.porting/porting-handoff-full-swift-twin-phase82d-archive-reuse.md),
[Phase 82e capture recovery](.porting/porting-handoff-full-swift-twin-phase82e-capture-recovery.md),
[Phase 82f capture archive bypass](.porting/porting-handoff-full-swift-twin-phase82f-capture-archive-bypass.md),
[Phase 84a GPU attachments](.porting/porting-handoff-full-swift-twin-phase84a-gpu-attachments.md),
[Phase 84b performance/thermal](.porting/porting-handoff-full-swift-twin-phase84b-performance-thermal.md),
[Phase 84c documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase84c-docs-reconcile.md),
[Phase 85a Mario owner repair](.porting/porting-handoff-full-swift-twin-phase85a-mario-state-route-repair.md),
[Phase 85b Mario parity repair](.porting/porting-handoff-full-swift-twin-phase85b-mario-parity-repair.md),
[Phase 85c Mario admission](.porting/porting-handoff-full-swift-twin-phase85c-mario-state-route-admission.md),
[Phase 85d camera route pair](.porting/porting-handoff-full-swift-twin-phase85d-camera-state-route-pair.md),
[Phase 85e camera focus repair](.porting/porting-handoff-full-swift-twin-phase85e-camera-focus-repair.md),
[Phase 85f camera position repair](.porting/porting-handoff-full-swift-twin-phase85f-camera-position-repair.md),
[Phase 85g camera admission](.porting/porting-handoff-full-swift-twin-phase85g-camera-state-route-admission.md),
[Phase 85h cumulative ledger merge](.porting/porting-handoff-full-swift-twin-phase85h-canonical-ledger-merge.md),
[Phase 85i documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85i-docs-route-update.md),
[Phase 85j global-state owner route](.porting/porting-handoff-full-swift-twin-phase85j-global-state-route.md),
[Phase 85k global-state admission](.porting/porting-handoff-full-swift-twin-phase85k-global-state-route-admission.md),
[Phase 85l four-row cumulative merge](.porting/porting-handoff-full-swift-twin-phase85l-canonical-ledger-merge.md),
[Phase 85m documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85m-docs-route-update.md),
[Phase 85n object-state/script-events/effects audit](.porting/porting-handoff-full-swift-twin-phase85n-object-state-route.md),
[Phase 85n effects audit](.porting/porting-handoff-full-swift-twin-phase85n-effects-route.md),
[Phase 85n script-events pair](.porting/porting-handoff-full-swift-twin-phase85n-script-events-route-pair.md),
[Phase 85o object/script admission](.porting/porting-handoff-full-swift-twin-phase85o-object-script-route-admission.md),
[Phase 85p six-row cumulative merge](.porting/porting-handoff-full-swift-twin-phase85p-six-row-canonical-ledger-merge.md),
[Phase 85q documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85q-docs-route-update.md),
[Phase 85q collision/RNG pairs](.porting/porting-handoff-full-swift-twin-phase85q-collision-queries-route-pair.md),
[Phase 85q RNG-draw pair](.porting/porting-handoff-full-swift-twin-phase85q-rng-draws-route-pair.md),
[Phase 85r collision/RNG admission](.porting/porting-handoff-full-swift-twin-phase85r-collision-rng-route-admission.md),
[Phase 85s eight-row cumulative merge](.porting/porting-handoff-full-swift-twin-phase85s-eight-row-canonical-ledger-merge.md),
[Phase 85t documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85t-docs-route-update.md),
[Phase 85u audio-sequence pair](.porting/porting-handoff-full-swift-twin-phase85u-audio-sequence-route.md),
[Phase 85u save-bytes pair](.porting/porting-handoff-full-swift-twin-phase85u-save-bytes-route-pair.md),
[Phase 85v audio/save admission](.porting/porting-handoff-full-swift-twin-phase85v-audio-save-route-admission.md),
[Phase 85w ten-row cumulative merge](.porting/porting-handoff-full-swift-twin-phase85w-ten-row-canonical-ledger-merge.md),
[Phase 85x documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85x-docs-route-update.md),
[Phase 85z render-packet route](.porting/porting-handoff-full-swift-twin-phase85z-render-packet-route.md),
[Phase 85z audio-PCM audit](.porting/porting-handoff-full-swift-twin-phase85z-audio-pcm-route-audit.md),
[Phase 85aa render-packet admission](.porting/porting-handoff-full-swift-twin-phase85aa-render-packet-route-admission.md),
[Phase 85ab eleven-row cumulative merge](.porting/porting-handoff-full-swift-twin-phase85ab-eleven-row-canonical-ledger-merge.md),
[Phase 85ac documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85ac-docs-route-update.md),
[Phase 85ac PCM receipt seam](.porting/porting-handoff-full-swift-twin-phase85ac-pcm-receipt-seam.md),
[Phase 85ad audio-PCM admission](.porting/porting-handoff-full-swift-twin-phase85ad-audio-pcm-route-admission.md),
[Phase 85ae twelve-row cumulative merge](.porting/porting-handoff-full-swift-twin-phase85ae-twelve-row-canonical-ledger-merge.md),
[Phase 85af documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85af-docs-route-update.md),
[Phase 85af interaction-state route](.porting/porting-handoff-full-swift-twin-phase85af-interaction-state-route.md),
[Phase 85ag interaction-state admission](.porting/porting-handoff-full-swift-twin-phase85ag-interaction-state-route-admission.md),
[Phase 85ah thirteen-row cumulative merge](.porting/porting-handoff-full-swift-twin-phase85ah-thirteen-row-canonical-ledger-merge.md),
[Phase 85ai documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85ai-docs-route-update.md),
[Phase 85ai effects parity repair](.porting/porting-handoff-full-swift-twin-phase85ai-effects-parity-repair.md),
[Phase 85aj effects receipt admission](.porting/porting-handoff-full-swift-twin-phase85aj-effects-receipt-route-admission.md),
[Phase 85ak fourteen-row cumulative merge](.porting/porting-handoff-full-swift-twin-phase85ak-fourteen-row-canonical-ledger-merge.md),
[Phase 85al documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85al-docs-route-update.md),
[Phase 85am level-script route](.porting/porting-handoff-full-swift-twin-phase85am-level-script-route.md),
[Phase 85am save-mutation route](.porting/porting-handoff-full-swift-twin-phase85am-save-mutation-route.md),
[Phase 85am save-mutation admission](.porting/porting-handoff-full-swift-twin-phase85am-save-mutation-route-admission.md),
[Phase 85am transition reachability](.porting/porting-handoff-full-swift-twin-phase85am-transition-route.md),
[Phase 85ao fifteen-row cumulative merge](.porting/porting-handoff-full-swift-twin-phase85ao-fifteen-row-canonical-ledger-merge.md),
and [Phase 85ap documentation reconciliation](.porting/porting-handoff-full-swift-twin-phase85ap-docs-route-update.md),
[Phase 85aq route-family triage](.porting/porting-handoff-full-swift-twin-phase85aq-route-family-triage.md),
[Phase 85ar route batch](.porting/porting-handoff-full-swift-twin-phase85ar-route-batch.md),
[Phase 85as level/transition reachability](.porting/porting-handoff-full-swift-twin-phase85as-level-transition.md),
[Phase 85at M34 production retry](.porting/porting-handoff-full-swift-twin-phase85at-m34-production.md),
[Phase 85au M35 readiness](.porting/porting-handoff-full-swift-twin-phase85au-m35-readiness.md),
and [Phase 85av canonical audit](.porting/porting-handoff-full-swift-twin-phase85av-canonical-audit.md).
The final conservative audit is
[Phase 85aw final audit](.porting/porting-handoff-full-swift-twin-phase85aw-final-audit.md).

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
