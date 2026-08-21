# Full Swift Twin Handoff — Phase 39 Global-State Trace Audit

Date: 2026-08-21

## Scope and verdict

Phase 39 audited the next canonical `oracle_hook|global_state` route and the
owner-thread Swift runtime for a source-backed schema-4 global-state emitter.
No implementation, route manifest/ledger, public status document, or
Decorative Pendulum file was changed. The route remains **inadmissible**.

The native schema-4 global snapshot requires six records in source order:
`global_timer`, `level`, `area`, `act`, `course`, and `random_seed`. Swift has
an owner-thread value boundary for a subset of engine globals, but it has no
authority for the native global timer contract and no owner for the native
process-global random seed. Emitting a zero/default or locally seeded value
would be synthetic and was deliberately not added.

## Native authority trace

The required C records are emitted by `capture_global_snapshot()` in
`src/pc/sm64_modern_gameplay_parity.c:892-905`, after the real game-loop level
script path at `src/game/game_init.c:645-667`:

| Schema-4 record | Native authority | Finding |
| --- | --- | --- |
| `1 / global_timer` | `gGlobalTimer`, declared in `src/game/game_init.c:61-63` | A lifecycle/presentation clock incremented only at legacy boundaries (`game_init.c:289-292`, `333-338`, `639-643`). Swift `SM64EngineGlobals.frame` is a native simulation-frame counter, not an owner of this legacy timer. |
| `2 / level` | `gCurrLevelNum`, `src/game/area.c:55-56` | Mutated by C level/warp lifecycle code; no Swift lifecycle bridge publishes the C value into the Swift owner. |
| `3 / area` | `gCurrAreaIndex`, `src/game/area.c:35-38` | Swift stores an initialization/area value, but does not own the live C area transition path. |
| `4 / act` | `gCurrActNum`, `src/game/area.c:35-36` | C level-script/credits lifecycle authority; no Swift owner publication exists. |
| `5 / course` | `gCurrCourseNum`, `src/game/area.c:35-36` | C level/warp lifecycle authority; no Swift owner publication exists. |
| `6 / random_seed` | `static u16 gRandomSeed16`, `src/engine/behavior_script.c:35-43` | Process-global C state consumed by behavior, environment, camera, and object code. The schema snapshot reads it via `random_seed_get()` (`sm64_modern_gameplay_parity.c:903-904`). |

The schema and inventory require all six IDs (`include/sm64_modern.h:98-103,
163-168`; `src/pc/sm64_modern_oracle_trace.c:19-25`). A partial set cannot
qualify this route's complete expected-domain contract.

## Swift owner audit

`SM64Modern/EngineState.swift:15-26` contains a real owner-thread value
boundary for level/area/course/act, time-stop flags, object counters, object
IDs, `frame`, and `resetEpoch`; `SM64SwiftEngineState` owns those values on the
engine thread (`EngineState.swift:39-47`). This is useful state substrate, but
it is not yet a live mirror of the C lifecycle globals or the C legacy timer.

`SM64Modern/EngineRuntime.swift:93-115` owns only the Swift context's state,
scheduler, input, Mario, progression, and existing receipt records. Its
owner-thread `step()` emits the scheduler receipt at `EngineRuntime.swift:319-343`;
there is no global snapshot emitter. `SM64Modern/OracleTrace.swift` supplies
the fixed-width schema-4 codec, but not a global-state authority.

The Swift random implementation is not an engine-global owner. `SM64Random16`
(`SM64Modern/DeterministicPrimitives.swift:187-220`) is value state, and
`SM64BehaviorVM` stores one independently initialized stream per VM
(`SM64Modern/BehaviorScriptVM.swift:136-177`). No runtime path wires that VM
stream to the C `gRandomSeed16` owner, and no Swift owner receives or publishes
the native seed before/after C behavior execution. The C source also exposes
only `random_seed_get`/`random_seed_set` around the static variable
(`behavior_script.c:35-43`); there is no C-to-Swift seed publication seam for
this route.

The existing EngineHost sidecar (`SM64Modern/EngineHost.swift:1819-1847`)
forwards records already produced by Swift and opens a separate owner-thread
schema-4 tick per record. It cannot create the missing global authority or
repair a record with a synthetic seed.

## Decision

No `EngineRuntime.swift` emitter was added. In particular, the audit does not
map `SM64EngineGlobals.frame` to `global_timer`, does not treat a default
`SM64Random16(seed: 0)` as the C seed, and does not copy a test/fixture seed
into a production route record. The `oracle_hook|global_state` route remains
planned/inadmissible until a real owner-thread contract publishes the native
legacy timer, live level/area/act/course lifecycle values, and shared
`gRandomSeed16` before the independent two-tick C/Swift trace and replay gates.

## Validation

The existing focused checks passed without source changes:

- `./script/test_engine_runtime.sh` — strict Swift 6 engine-runtime/state
  lifecycle and receipt smoke.
- `./script/test_oracle_trace.sh` — C schema-4 fixed-width record/replay and
  canonical-hash lifecycle smoke.
- `./script/test_oracle_trace_swift.sh` — Swift schema-4 codec and
  cross-language trace decode/tamper smoke.
- An explicit `xcrun swiftc -swift-version 6
  -Xfrontend -strict-concurrency=complete` build of
  `OracleTrace.swift` plus the same trace smoke — strict Swift 6 codec
  evidence.
- `git diff --check`.

These checks validate the existing runtime and schema boundaries. They do not
qualify the global-state route, because the required Swift authority is still
missing.

No commit was created; the parent agent owns review and any future route or
ledger transition.
