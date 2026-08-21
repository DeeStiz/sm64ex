# Full Swift Twin Handoff — Phase 43 Global-State Owner Boundary

Date: 2026-08-21

## Scope and result

Phase 43 rechecked the canonical `oracle_hook|global_state` route and the
owner-thread C/Swift ordering needed to publish its schema-4 records. No C
ABI, parity, Swift runtime, generated route, or ledger file was changed. The
route remains planned/inadmissible because the complete owner boundary cannot
be added safely as a getter-only change.

The native route has six required records, in this exact order:
`global_timer`, `level`, `area`, `act`, `course`, and `random_seed`. The C
record source is `capture_global_snapshot()` at
`src/pc/sm64_modern_gameplay_parity.c:892-905`; the schema-4 inventory names
the same six IDs at `src/pc/sm64_modern_oracle_trace.c:19-25`.

## Before/after authority evidence

Before and after this phase, the authority facts are unchanged:

| Value | Native authority | Swift boundary | Result |
| --- | --- | --- | --- |
| `global_timer` | `gGlobalTimer` (`src/game/game_init.c:62`) | `SM64EngineGlobals.frame` is a separate Swift simulation counter (`SM64Modern/EngineState.swift:15-26`) | Not owned by Swift |
| `level` | `gCurrLevelNum` (`src/game/area.c:56`) | Swift has an initialization value only (`EngineState.swift:69-73`) | No live C lifecycle publication |
| `area` | `gCurrAreaIndex` (`src/game/area.c:37`) | Swift has an initialization value only | No live C lifecycle publication |
| `act` | `gCurrActNum` (`src/game/area.c:36`) | No C lifecycle bridge into the Swift owner | Not owned by Swift |
| `course` | `gCurrCourseNum` (`src/game/area.c:35`) | No C lifecycle bridge into the Swift owner | Not owned by Swift |
| `random_seed` | private `gRandomSeed16`, read by `random_seed_get()` (`src/engine/behavior_script.c:35-43`) | `SM64Random16`/`SM64BehaviorVM` are independently initialized Swift value streams | Shared seed not owned by Swift |

No value was mapped from `frame` to `global_timer`; no default or fixture seed
was emitted.

## Exact implementation blocker

The C snapshot is captured in `game_loop_one_iteration()` at
`src/game/game_init.c:661-667`, before `display_and_vsync()` advances
`gGlobalTimer` at `src/game/game_init.c:333-338`. The C lifecycle then closes
the oracle tick at `src/pc/pc_main.c:317-324`. Swift currently invokes the C
step first and advances its own context afterward
(`SM64Modern/EngineRuntime.swift:524-537`). A post-step Swift getter would
therefore observe a different timer boundary and could not be claimed as the
same native snapshot.

The existing Swift oracle sidecar also opens a separate owner-thread tick for
each Swift record (`SM64Modern/EngineHost.swift:1818-1847`). Adding six global
records there without a shared capture/scheduling contract would append a
second record sequence rather than replay the C six-record sequence. Safe
implementation requires all of the following as one change:

1. a fixed-width, owner-thread snapshot publication at the C capture boundary;
2. a Swift owner mirror fed by that publication, including the actual legacy
   timer and the shared C seed;
3. one canonical six-record emitter with matching sequence/tick ordering in C
   and Swift; and
4. independent multi-tick C/Swift record and replay evidence, including the
   60/30 paired cadence and the timer increment boundary.

Until that shared boundary exists, a direct ABI getter is insufficient and
would risk false authority or replay evidence.

## Validation

The unchanged source contracts and existing ABI/codec boundaries were checked
with:

- `./script/test_engine_runtime.sh` — passed (`SM64 Modern engine runtime smoke passed`).
- `./script/test_oracle_trace.sh` — passed (`SM64 Modern oracle trace smoke passed`).
- `./script/test_oracle_trace_swift.sh` — passed (`SM64 Modern Swift oracle trace smoke passed`).
- `git diff --check` — passed.
- Source inspection confirmed the six native fields, their capture ordering,
  the legacy timer increments, the private C random seed, and the separate
  Swift sidecar tick path cited above.

These checks do not qualify `oracle_hook|global_state`; they only preserve the
existing C/Swift ABI and codec evidence while the owner boundary remains open.
No commit was created; the parent agent owns review and any future
implementation, route admission, or ledger transition.
