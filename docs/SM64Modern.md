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
(2026-08-21).

### Phase 70 current status

The authoritative current counters are **534 behavior rows** (511 Swift
value/owner rows and 23 explicit C adapters) and **7,420 route shards**: one
non-fixture live-qualified row and 7,419 planned. Phase 57 repaired native
schema-4 object-domain routing and retained 64 real slot-37 object-state
records plus six nonzero native run/header fingerprints. Phase 58 selected the
authored Castle Inside area-2 `WARP_NODE(0x35)` through the normal owner-thread
warp path; Mario and the pendulum both resolve to room 5 and the pendulum is
render-active (`graph_flags=0x21`). Phase 59 re-ran the independent pair and
remains fail-closed: native emits domains `3,6,7`, Swift emits `3,6,7,12`,
native effect domain 12 is absent, and the first canonical divergence remains a
domain-3 record mismatch (`native_records=1057`, `swift_records=1095`). The
sound threshold is reached on a held native step, so a direct sink, room, or
graph-flag override would fabricate evidence; no route promotion or ledger
mutation occurred.

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

Phase 71 audited `oracle_hook|camera_state` without admitting a second live
row: the input-only route still passes independently, the full-route coverage
guard fails before a camera trace, and Mario-face/progression results remain
source/fixture contracts rather than live qualification. The ledger remains
1 of 7,420.

Phase 72 retained the real full-route input receipt, and Phase 73 extended the
C sidecar to replay all nine source-backed full-route records with exact tamper
detection. This composite trace still has no canonical manifest row, so no
additional live shard was admitted and the ledger remains unchanged.

M34, M35, and fresh-save human 120-star acceptance remain open. These gates
are independent from local build, source, fixture, and headless-host
evidence; this is not a shipped, visual-parity, or complete full-game Swift
port. The mapping/live-route indicators remain separate: 511/534 behavior
rows (95.693%), 1/7,420 live-qualified route shards (0.013477%), and a
conservative full-goal/acceptance floor of 0%.

The older Phase 20–55 bullets below are retained as historical evidence. Any
pre-Phase-55 `7,419` denominator in those notes is historical and does not
override the current 7,420-row inventory.

### Next admissible phase sequence

1. **M34 awake-host rerun:** repeat the unchanged production harness on an
   awake, unlocked visible GUI host; require zero scheduler/catch-up drops,
   sustained callbacks, post-resume drawable acknowledgement, archive reuse,
   non-clear fetched pixels, and retained GPU/FPS/memory/thermal evidence.
2. **Route qualification:** keep C/Swift recording independent and fail closed;
   align common fingerprints and tick windows, then admit only exact
   schema-4 parity with a terminal worker result. The ledger remains 1/7,420
   until that evidence exists.
3. **M35 signing/notary:** after M34, obtain Developer ID Application
   credentials and one supported `notarytool` authentication mode; rerun
   readiness, archive/export, notarization/stapling, and clean-machine
   Gatekeeper checks without mutating blocked prerequisites.
4. **Human acceptance:** after signed artifacts pass clean-machine checks,
   run and record the fresh-save 120-star controls, camera, collision, audio,
   haptics, visual, menu, credits, ending, and recovery checklist.

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
* A fresh bounded capture recheck proves zero scheduler/catch-up drops over 240
  steps and valid residency/present structure, but still has only three display
  callbacks, no post-resume acknowledgement, descriptor-cache fallback, and
  clear-only black attachments.
* The latest full host verifier can still be blocked before engine startup by
  LaunchServices `kLSNoExecutableErr (-10827)` (the direct AppKit diagnostic
  exits `134`). The retained complete host proof is M33nc; this is a host
  limitation, not evidence of a gameplay or Metal fault.
* The route inventory contains **7,420 reachable shards**. Full shard
  execution, sanitizer reruns, physical visual/audio/controller checks,
  sustained performance and thermal checks, release packaging, and human
  acceptance remain open. M35 external distribution and human acceptance
  remain open; local readiness and fail-closed distribution-flow checks exist,
  but no distributable artifact or human acceptance has started.
* The first real live shard (`0xd9446dfed10e189e`, `oracle_hook|input`) now
  passes C/Swift replay, live executor, and worker-result validation with
  `fixture_only=0`; **1 of 7,420** manifest rows is live-qualified and **7,419**
  remain planned.
* No other rows are promoted from the current traces: the C contract replays
  hard-coded arrays, and fixture byte matches remain explicitly ineligible for
  live qualification. Further rows require independently recorded C and Swift
  traces.

### Historical phase notes (Phases 20–55)

* Phase 20's bounded common-input probe writes byte-identical 200-byte
  schema-4 C/Swift files with shared fingerprints, exact record parity, C/Swift
  replay, and tamper rejection. It reports
  `bounded_common_input_admitted=1` but
  `current_route_shard_admitted=0`; no additional route row was admitted.
* After `f5fed499`, the native-C record harness emits 3,151 validated schema-4
  records across five lifecycle ticks, including 300 render-domain records/
  288 draws; exact C/Swift pairing is still required.
* The C/Swift pairing audit found mismatched framing/fingerprints, timebases,
  save/configuration inputs, and selected render records; no additional live
  route row was admitted.
* The independent C recorder now emits canonical schema-4 framing; M35 can use
  stable Xcode 26.6 via an invocation-scoped override, but signing, entitlement,
  and notary prerequisites remain external.
* The Phase 21 M34 closure audit found no source-local renderer/compiler/parser
  fault. Its fresh diagnostic reached registration/warm-up, three presents,
  zero scheduler/catch-up drops, and clean drain, but then idled after three
  callbacks with `archive_reuse=false`, descriptor-cache fallback, and
  clear-only black attachments. This is a host/compositor, archive/tooling,
  visual/reference, and physical-acceptance boundary, not M34 closure or visual
  parity evidence.
* Phase 25's route-alignment attempt for `oracle_hook|input`
  (`0xd9446dfed10e189e`) remains non-admitted: the paired files report
  `pairing_audit admitted=0 c_records=1 swift_records=1 c_ticks=2 swift_ticks=2 blockers=coverage_deferred`,
  while the route gate reports
  `current_route_shard_admitted=0 synthetic_one_record_rejected=1 coverage_or_window_gate=1 fixture_only=0`.
  `real_route_alignment_attempted=1 records=1 exact_bytes=1 common_fingerprints=5`
  is alignment evidence only; the complete coverage and independent multi-tick
  window were missing from that attempt. Phase 31 later completed the same
  existing row without changing the live ledger from **1 of 7,419**.
* Phase 26's M34 visible-capture attempt was run from a locked/headless host:
  the screen capture was black with displays asleep and the wake attempt ended
  at the login screen. The API/shader-validation log reached
  `scheduler_dropped_steps=64`; the separate capture-only pass reached
  `scheduler_dropped_steps=0` but only three callbacks/presents
  (`callback_idle_ms=9957`, `host_compositor_evidence=candidate`), with
  `archive_reuse=false`. `gpudebug` found three MTL4 command buffers/draws and
  valid drawable/residency/present structure, but all fetched color/depth
  attachments were clear-only black. M34 visual/device/reference acceptance
  remains open.
* Phase 27 corrected the Release source entitlement to
  `com.apple.security.get-task-allow=false` while preserving
  `com.apple.developer.sustained-execution=true`; Debug remains
  `get-task-allow=true` without sustained execution. Plist, build-setting,
  readiness, and distribution-flow checks passed, and the former Release
  entitlement blocker is cleared.
* Phase 28 rechecked M35 with invocation-scoped stable Xcode 26.6 without
  changing global `xcode-select`. Readiness and distribution remain fail-closed
  with exactly two blockers: no authorized Developer ID Application identity/
  private key and no notarytool authentication. No archive, export, DMG, ZIP,
  notarization, stapling, Gatekeeper, physical, or human acceptance state was
  changed or claimed; clean-machine and human acceptance remain open.
* Phase 31 completed the independent two-tick C/Swift window and promotion gate
  for the existing `oracle_hook|input` row (`0xd9446dfed10e189e`): the retained
  artifacts are byte-identical, carry complete row coverage, and pass replay,
  tamper, worker-result, and persistent-rerun gates. This closes the existing
  row's evidence only; the live ledger remains **1 of 7,419**, with 7,418 rows
  still planned.
* Phase 32 made a fresh M34 two-pass attempt from a locked/headless host. The
  runtime stopped at three frames/presents, archive reuse remained false, and
  all fetched color/depth attachments were clear-only black. This is structural
  diagnostic evidence only; M34 visual, physical-device, performance, and
  human acceptance remain open.
* Phase 33 rechecked M35 with invocation-scoped stable Xcode 26.6 and leaves
  exactly two blockers: no valid Developer ID Application identity/private key
  and no notarytool authentication. The fail-closed flow performed no archive,
  export, DMG, ZIP, notarization, or stapling mutation.
* Phase 34 did not admit a second route. `bhvDecorativePendulum` is blocked by
  real missing `collision_queries` and `script_events` schema domains in its
  C/Swift owner path; `oracle_hook|global_state` is blocked by the missing
  schema-4 global-state Swift emitter and random-seed owner. Adding either row
  without those source-backed domains would be synthetic evidence and is
  rejected.
* Phase 37 rechecked the decorative-pendulum source path and still admitted no
  second route. Its real Swift pair has object-state and clock-sound effect
  ownership, but no terrain/collision owner or behavior-script/lifecycle owner
  from which the required `collision_queries` and `script_events` records could
  be emitted. The `oracle_hook|global_state` candidate still has no schema-4
  global-state Swift emitter or random-seed owner; adding either route would be
  synthetic evidence.
* Phase 39 audited `oracle_hook|global_state` against the native schema-4
  snapshot and found no source-backed Swift owner-thread emitter for the native
  `global_timer` or shared `random_seed`; live level/area/act/course lifecycle
  publication is also not wired. Mapping `SM64EngineGlobals.frame` or a local
  default seed would be synthetic and remains rejected.
* Phase 40 re-audited `bhvDecorativePendulum`. Its real Swift pair owns the
  fixed-point roll/object state and clock-sound effect, but has no bound
  collision world/floor query, per-object `SM64BehaviorVM`/script-PC lifecycle
  events, or shared schema-4 snapshot/trace sink. No second route is admitted.
* Phase 41 performed a read-only external refresh: the host reports a locked
  console session and both displays asleep, so M34 remains blocked without a
  visible capture. M35 remains blocked by exactly the same two prerequisites—
  an authorized Developer ID Application identity/private key and one supported
  notarytool authentication mode—and no artifact, Gatekeeper, physical, or
  human-acceptance state changed.
* Phase 43 rechecked the `oracle_hook|global_state` owner boundary. The native
  `gGlobalTimer`, live level/area/act/course lifecycle values, and shared
  `gRandomSeed16` still have no source-backed Swift owner-thread schema-4
  emitter; the planned route remains inadmissible.
* Phase 44 added a real `bhvDecorativePendulum` Swift owner seam. When the
  caller supplies the immutable collision world and decoded behavior program,
  it emits the source-backed floor, lifecycle, script, effect, and object-state
  records through the fixed-width schema-4 sink; no defaults stand in for the
  missing owner inputs.
* Phase 45 carried that explicit owner configuration through central dispatch
  and the engine runtime. The configured smoke observes source-backed records
  at the scheduler tick, while the unconfigured identity-only route remains
  trace-silent and does not imply a live level-content loader.
* Phase 46 added a source-only Castle Inside area-2 recipe from the real
  `bhvDecorativePendulum[]` program, level script, collision, and room streams.
  It remains diagnostic-only because no native C owner trace, C/Swift pair, or
  route promotion was captured.
* Phase 47 confirmed the exact native-C blocker: `data/behavior_data.c` is a
  monolithic pointer-bearing translation unit, and the real callbacks depend on
  `gCurrentObject`, the global level/surface loader, and global audio/effect
  ownership. No safe C schema-4 pendulum pair exists yet; no second route is
  admitted.
* Phase 48 reconciled the public/status documents and retained the Phase 44–47
  owner, dispatch, source-recipe, and native-C boundaries without changing the
  historical ledger or route counters.
* Phase 49 passed the strict native archive build and the existing lifecycle
  oracle smoke, which emitted `liveOracleTraceRecords=3151`,
  `liveOracleTraceTicks=5`, `liveOracleCoverageEntries=62`, and coverage
  fingerprint `0x5ad92028e4bd8daf`. This is general lifecycle evidence, not a
  Castle Inside area-2 or pendulum-owner trace; archive symbol presence for
  `load_area`, `gAreaData`, `gCurrentArea`, `gMarioSpawnInfo`, and the pendulum
  callbacks does not prove those owners were initialized or updated.
* The exact Phase 49 source boundary is the missing owner-thread level/area
  selection entrypoint. The public lifecycle API owns
  `thread5_game_loop()`/`lifecycle_step()` but does not expose level/area
  selection or private `levelCommandAddr`; the current bootstrap selects only
  `LEVEL_CASTLE_GROUNDS` or `LEVEL_BOB`, not `LEVEL_CASTLE` area 2. A safe
  unblock must select `LEVEL_CASTLE`, run its compiled level script through the
  existing command pointer, perform the normal Mario-area transition to area 2,
  and expose the real pendulum callback on the lifecycle owner thread while
  retaining the existing parity sink as the sole schema-4 emitter. Direct
  `load_area(2)` or fabricated globals would not be valid route evidence.
* Phase 50 reconciled the public/status documents and retained the Phase 44–49
  owner, dispatch, source-recipe, native-C, and native-core boundaries. Phase 51
  compiled and loaded the Castle Inside script and all three area definitions,
  including the real area-2 collision/room/geometry and
  `bhvDecorativePendulum` spawn. Phase 52 then added an opt-in owner-thread
  transition (`SM64_MODERN_AUTOMATED_CASTLE_AREA2=1`) that selects the compiled
  `LEVEL_CASTLE` script and completes the normal Mario area-2 warp path. Its
  native lifecycle smoke reports `castleArea2Loaded=1`,
  `castleArea2PendulumSlot=37`, `castleArea2NativeRecords=3`,
  `castleArea2Roll=1464`, and `castleArea2Velocity=224`; it does not call
  `load_area(2)` directly or fabricate legacy globals. This is native area-2
  lifecycle evidence, not C/Swift parity or route admission.
* Phase 53 pairs that real slot-37 native trace with the Phase 46 source-backed
  Swift recipe and fails closed. The filtered native trace retains 23 records
  over domains `6,7`, while the Swift recipe emits 687 records over the
  required `3,6,7,12` domains. Native is missing the `object_state` (3) and
  pendulum-specific `effects` (12) domains; the first canonical divergence is
  `missing_c tick=1 domain=3 sequence=0 kind=1 subject=37`. The native header
  leaves the five required run/content/timebase/configuration/initial-save
  fingerprints zero while Swift has nonzero values, so the pair is not
  admissible and no route promotion changed. Phase 54 records this exact
  divergence in a fresh reconciliation and completion audit.
* Phase 55 corrected the denominator drift found in the Phase 54 inventory:
  `./script/test_route_shards.sh` now regenerates **7,420** rows/shards,
  excludes the Phase 52 `initiate_warp` header declaration, and retains the
  legitimate `.c` transition call sites. The retained live row remains **1 of
  7,420**, with **7,419** planned; no route ledger entry or pendulum admission
  changed.

The source-of-truth tracker and the complete milestone ledger are in
[`../.porting/goal-full-swift-twin.md`](../.porting/goal-full-swift-twin.md).
The proposed Luna-max continuation plan is
[`../.porting/goal-continuation-luna-max-2026-08-20.md`](../.porting/goal-continuation-luna-max-2026-08-20.md).
The latest bounded handoffs are [Phase 25 route alignment](../.porting/porting-handoff-full-swift-twin-phase25-route-alignment.md),
[Phase 26 M34 capture](../.porting/porting-handoff-full-swift-twin-phase26-m34-visible-capture.md),
[Phase 27 Release entitlement](../.porting/porting-handoff-full-swift-twin-phase27-release-entitlement.md),
[Phase 28 M35 recheck](../.porting/porting-handoff-full-swift-twin-phase28-m35-external-recheck.md),
[Phase 29 docs reconciliation](../.porting/porting-handoff-full-swift-twin-phase29-docs-reconcile.md),
[Phase 30 completion audit](../.porting/porting-handoff-full-swift-twin-phase30-completion-audit.md),
[Phase 31 route window](../.porting/porting-handoff-full-swift-twin-phase31-route-multitick.md),
[Phase 32 M34 host refresh](../.porting/porting-handoff-full-swift-twin-phase32-m34-host-refresh.md),
[Phase 33 M35 prerequisite refresh](../.porting/porting-handoff-full-swift-twin-phase33-m35-prereq-refresh.md),
[Phase 34 next-route qualification](../.porting/porting-handoff-full-swift-twin-phase34-next-route.md),
[Phase 35 docs reconciliation](../.porting/porting-handoff-full-swift-twin-phase35-docs-reconcile.md),
[Phase 36 completion audit](../.porting/porting-handoff-full-swift-twin-phase36-completion-audit.md),
[Phase 37 decorative pendulum seams](../.porting/porting-handoff-full-swift-twin-phase37-decorative-pendulum-seams.md),
[Phase 38 final reconciliation](../.porting/porting-handoff-full-swift-twin-phase38-final-reconcile.md),
[Phase 38 completion audit](../.porting/porting-handoff-full-swift-twin-phase38-completion-audit.md),
[Phase 39 global-state audit](../.porting/porting-handoff-full-swift-twin-phase39-global-state.md),
[Phase 40 decorative seams](../.porting/porting-handoff-full-swift-twin-phase40-decorative-seams.md),
[Phase 41 external refresh](../.porting/porting-handoff-full-swift-twin-phase41-external-refresh.md),
[Phase 42 final reconciliation](../.porting/porting-handoff-full-swift-twin-phase42-final-reconcile.md),
[Phase 42 completion audit](../.porting/porting-handoff-full-swift-twin-phase42-completion-audit.md),
[Phase 43 global-state owner boundary](../.porting/porting-handoff-full-swift-twin-phase43-global-state-owner.md),
[Phase 44 decorative owner seam](../.porting/porting-handoff-full-swift-twin-phase44-decorative-owner.md),
[Phase 45 central dispatch](../.porting/porting-handoff-full-swift-twin-phase45-decorative-dispatch.md),
[Phase 46 source route attempt](../.porting/porting-handoff-full-swift-twin-phase46-decorative-route.md),
[Phase 47 native C route boundary](../.porting/porting-handoff-full-swift-twin-phase47-native-c-route.md),
[Phase 48 final reconciliation](../.porting/porting-handoff-full-swift-twin-phase48-final-reconcile.md),
[Phase 48 completion audit](../.porting/porting-handoff-full-swift-twin-phase48-completion-audit.md),
[Phase 49 native-core area boundary](../.porting/porting-handoff-full-swift-twin-phase49-native-core-area.md),
[Phase 50 final reconciliation](../.porting/porting-handoff-full-swift-twin-phase50-final-reconcile.md),
[Phase 50 completion audit](../.porting/porting-handoff-full-swift-twin-phase50-completion-audit.md),
[Phase 51 level/area entrypoint](../.porting/porting-handoff-full-swift-twin-phase51-level-area-entrypoint.md),
[Phase 52 final reconciliation](../.porting/porting-handoff-full-swift-twin-phase52-final-reconcile.md),
[Phase 52 owner-thread warp](../.porting/porting-handoff-full-swift-twin-phase52-warp-transition.md),
[Phase 52 completion audit](../.porting/porting-handoff-full-swift-twin-phase52-completion-audit.md),
[Phase 53 pendulum pair](../.porting/porting-handoff-full-swift-twin-phase53-pendulum-pair.md),
[Phase 54 final reconciliation](../.porting/porting-handoff-full-swift-twin-phase54-final-reconcile.md),
[Phase 54 completion audit](../.porting/porting-handoff-full-swift-twin-phase54-completion-audit.md),
[Phase 55 denominator correction](../.porting/porting-handoff-full-swift-twin-phase55-denominator-fix.md),
[Phase 57 native object-domain parity](../.porting/porting-handoff-full-swift-twin-phase57-native-pendulum-parity.md),
[Phase 58 canonical Castle warp](../.porting/porting-handoff-full-swift-twin-phase58-canonical-warp.md),
[Phase 59 pendulum pairing](../.porting/porting-handoff-full-swift-twin-phase59-pendulum-pair.md),
[Phase 60 completion audit](../.porting/porting-handoff-full-swift-twin-phase60-completion-audit.md),
[Phase 61 M34 production audit](../.porting/porting-handoff-full-swift-twin-phase61-m34-production-audit.md),
[Phase 62 M35 release preflight](../.porting/porting-handoff-full-swift-twin-phase62-m35-release-preflight.md),
[Phase 64 documentation closeout](../.porting/porting-handoff-full-swift-twin-phase64-docs-closeout.md),
[Phase 65 EngineRuntime status fix](../.porting/porting-handoff-full-swift-twin-phase65-engine-runtime-status-fix.md),
[Phase 66 fixed-build M34 rerun](../.porting/porting-handoff-full-swift-twin-phase66-m34-rerun.md),
[Phase 67 M35 current preflight](../.porting/porting-handoff-full-swift-twin-phase67-m35-current-preflight.md),
[Phase 67b stable M34 rerun](../.porting/porting-handoff-full-swift-twin-phase67b-m34-stable-rerun.md),
[Phase 67c HUD render fix](../.porting/porting-handoff-full-swift-twin-phase67c-hud-render-fix.md),
[Phase 67d AVFAudio SDK compatibility](../.porting/porting-handoff-full-swift-twin-phase67d-avfaudio-sdk-compat.md),
[Phase 70 documentation refresh](../.porting/porting-handoff-full-swift-twin-phase70-docs-refresh.md),
[Phase 71 camera route pair audit](../.porting/porting-handoff-full-swift-twin-phase71-camera-route-pair.md),
[Phase 72 full-route coverage](../.porting/porting-handoff-full-swift-twin-phase72-full-route-coverage.md),
and [Phase 73 full C sidecar contract](../.porting/porting-handoff-full-swift-twin-phase73-full-c-sidecar-contract.md).
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
| Route inventory | `./script/test_route_shards.sh` | Canonical 7,420-shard inventory and ledger schema (inventory status remains planned) |
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
