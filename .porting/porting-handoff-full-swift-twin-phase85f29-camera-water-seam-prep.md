# Full Swift Twin Handoff - Phase 85f29 Camera Water-Query Seam Preparation

Date: 2026-08-22

## Verdict

**PREPARATION ONLY / FAIL-CLOSED.** The narrowest source-owned camera water
observer is the `find_water_level` call at `src/game/camera.c:2471` inside
`sm64_modern_camera_evaluate_callback`. It has the explicit camera mode, the
callback's incoming camera position, Mario's position, and the live level/area
at the exact source call. The separate `update_default_camera` call at line
2845 remains a later, distinct route.

No source, ABI, Swift, test, manifest, route ledger, report, or shared
documentation file was changed by this preparation. No generic environment
record was re-labelled, no `find_water_level` helper was called by a probe,
and no canonical state was mutated. The only intended new file in this phase
is this handoff.

## Starting evidence

Phase 85f26 (`.porting/porting-handoff-full-swift-twin-phase85f26-camera-floor-route.md`)
found two source-authored candidates but no camera owner/query receipt. The
existing environment producer is `src/engine/surface_collision.c:676-706`:
`find_water_level` owns the environment-region walk and returns the native
height. Its observer at lines 66-76 emits only four generic values:

```text
query X bits | query Z bits | returned height bits | environment kind
```

`src/pc/sm64_modern_gameplay_parity.c:1576-1605` then hard-codes the generic
collision domain, event ID 4, and `subject_id = 0`. The existing
`SM64Modern/CollisionQueriesMigration.swift:3-45` accepts only domain 7,
event IDs 1-4, and the water/gas four-value shape at event 4. It cannot prove
which camera owner made the query. The existing `SM64ModernCameraCallbackInputV1`
also remains an aggregate callback input, not a source-call receipt.

## Callsite choice

### Selected: `camera.c:2471`

The selected source identity is:

```text
src/game/camera.c:2471:sm64_modern_camera_evaluate_callback:find_water_level
FNV-1a subject ID: 0x340565d4295ea359
```

At `src/game/camera.c:2191-2235`, the callback already has `camera`, the
explicit `mode`, `focus`, and incoming `pos`. At lines 2464-2477, only the
radial, outward-radial, and eight-direction branches query water; line 2471
queries exactly `sMarioCamState->pos[0]`/`[2]`, and line 2473 derives the
existing-water result bit. The observer should copy the incoming callback
`pos` as `camera_position`, copy `sMarioCamState->pos` as `mario_position`,
and copy `gCurrLevelNum`/`gCurrAreaIndex` at that same boundary. It must not
read back a later camera position or infer ownership from the generic
environment record.

The first authored recipe should be DDD area 1:

- `levels/ddd/areas/1/geo.inc.c:16` uses `GEO_CAMERA(2, ...)`, the authored
  `CAMERA_MODE_OUTWARD_RADIAL` mode.
- `levels/ddd/script.c:84-97` loads area 1, water terrain, and the real
  authored level lifecycle; `MARIO_POS` is at line 116.
- The source Sushi/whirlpool objects remain authored inputs, but the probe
  must not inject them, force mode 2, warp directly, or call an internal
  camera/environment helper.

### Deferred: `camera.c:2845`

`update_default_camera` (`src/game/camera.c:2630`) has a valid but broader
source path. At line 2813 it computes `cPos`, line 2845 queries
`find_water_level(cPos[0], cPos[2])`, and lines 2846-2864 apply the
camera-above-water and metal-below-water policy. It has `c->mode`, Mario's
position, and `cPos`, but the owner is shared by default, close, and free-roam
camera paths. JRB area 1 (`levels/jrb/areas/1/geo.inc.c:16`, mode 16) remains
the natural later recipe. It must receive a separate callsite identity and
must not be merged with the selected line-2471 receipt by coordinate or
height matching.

## Narrow API and schema contract

The implementation phase should add only a source-call observer and a
camera-domain schema-4 event. The proposed internal API is:

```c
// src/pc/sm64_modern_camera_water_route_identity.h
SM64ModernStatus sm64_modern_camera_water_route_observe(
    int16_t mode,
    int16_t level,
    int16_t area,
    float camera_x,
    float camera_y,
    float camera_z,
    float mario_x,
    float mario_y,
    float mario_z,
    float query_x,
    float query_z,
    float water_height,
    uint32_t result_flags);
```

`src/game/camera.c:2471` is the only caller, immediately after the native
`find_water_level` return and before the result is folded into
`input.water_height`/`geometry_flags`. The observer copies scalar arguments
immediately, keeps C's environment query authoritative, and emits no fallback
value when the oracle is inactive. `result_flags` should retain the source
result state (`QUERY_EXECUTED` and `HAS_HEIGHT`); the raw sentinel or height
remains in `water_height`.

The existing schema-4 record has eight 64-bit value slots
(`include/sm64_modern.h:102-103,2437-2450`). All required fields fit without
expanding the public ABI when packed as follows:

| Record field | Encoding |
| --- | --- |
| `simulation_tick` | `sm64_modern_oracle_trace_simulation_tick()` at the callsite |
| `domain` | `SM64_MODERN_ORACLE_DOMAIN_CAMERA` (5) |
| `record_kind` | `SM64_MODERN_ORACLE_RECORD_EVENT` (3) |
| `subject_id` | `0x340565d4295ea359`, the exact source identity above |
| `record_id` | New dedicated `SM64_MODERN_ORACLE_CAMERA_EVENT_WATER_QUERY = 307` (the next ID after camera state 300-306) |
| `sequence` | `sm64_modern_oracle_trace_next_sequence(SM64_MODERN_ORACLE_DOMAIN_CAMERA)` before publication |
| `flags` | New route flag `SM64_MODERN_CAMERA_WATER_ROUTE_FLAG = 0x43414d57` (`CAMW`) |
| `values[0]` | Raw `mode` in the low 16 bits |
| `values[1]` | Raw `level` low 32 bits, raw `area` high 32 bits |
| `values[2]` | `camera_x` low 32 bits, `camera_y` high 32 bits |
| `values[3]` | `camera_z` low 32 bits, `mario_x` high 32 bits |
| `values[4]` | `mario_y` low 32 bits, `mario_z` high 32 bits |
| `values[5]` | `query_x` low 32 bits, `query_z` high 32 bits |
| `values[6]` | Raw `water_height` IEEE-754 bits |
| `values[7]` | `result_flags` |
| `canonical_hash` | Schema-4 canonical hash over the canonical record fields and all eight packed values |

Every float is copied as its IEEE-754 bit pattern. Swift must decode the
pairs without arithmetic or normalization. Tick, sequence, source identity,
and hash therefore remain in the canonical record, while mode/level/area,
camera/Mario positions, query coordinates, result bits, and the returned
height are all present in one record. A new generic environment event, a
second post-hoc record, or a schema-capacity increase is not needed.

The route identity implementation should call the existing schema-4 trace
API directly after packing the eight values. A new
`SM64_MODERN_ORACLE_CAMERA_EVENT_WATER_QUERY = 307` constant may live beside
the existing route constants in `src/pc/sm64_modern_gameplay_parity.h`, but
`sm64_modern_parity_record_collision_query` in
`src/pc/sm64_modern_gameplay_parity.{h,c}` must remain untouched. The route
observer must mark only camera event 307 for coverage and call
`sm64_modern_oracle_trace_record` with domain 5/event 307; it must not route
through the generic collision recorder. Add the event to the camera inventory
in `src/pc/sm64_modern_oracle_trace.c` before any coverage fingerprint or
admission is claimed; that source change is deferred to the implementation
phase.

The Swift side should be a separate route mirror, for example
`SM64Modern/CameraWaterQueryMigration.swift`. It must validate domain 5,
record kind 3, event 307, the exact subject/flag, eight values, canonical
hash, and tick/sequence ordering, then decode the packed fields. The existing
`SM64Modern/CollisionQueriesMigration.swift` remains generic and unchanged;
it must reject this camera record rather than broaden its domain or event
range.

## Exact implementation file set (deferred; not changed here)

- `src/game/camera.c` - one observer call at source line 2471 only.
- `src/pc/sm64_modern_camera_water_route_identity.h/.c` - stable identity,
  scalar-copy observer, result flags, and route publication.
- `src/pc/sm64_modern_gameplay_parity.h` - private event-ID constant only; no
  generic collision-hook changes in `.h` or `.c`.
- `src/pc/sm64_modern_oracle_trace.c` - one camera inventory entry for event
  307 so coverage is source-declared rather than post-hoc.
- `SM64Modern/CameraWaterQueryMigration.swift` - independent value-only
  schema-4 decoder/mirror. `CollisionQueriesMigration.swift` is not widened.
- `tests/sm64_modern_camera_water_route_pair_contract.c` - real authored DDD
  lifecycle capture and source-identity/packing assertions.
- `tests/sm64_modern_camera_water_route_swift_smoke.swift` - independent
  Swift record generation/decoding and exact-pair audit.
- `script/test_camera_water_route_pair.sh` - strict C/Swift, lifecycle,
  ASan/Release/rerun, hash, and negative-fence orchestration.
- A later isolated admission tool/handoff may consume the pair; it must not
  be added to the canonical manifest or ledger during this seam phase.

No `include/sm64_modern.h` public ABI expansion, `EngineHost` wiring, or
`update_default_camera` observer belongs in this bounded implementation.

## Required evidence gates

1. **Static source gate.** Confirm the observer call is at the authored line
   2471, the DDD area-1 mode/terrain recipe is real, and no harness contains a
   direct `find_water_level`, camera-mode force, direct level load, Sushi
   injection, or coordinate-based reuse of a generic environment record.
2. **Schema gate.** Compile the C observer/parity contract with strict warnings;
   verify ABI headers, eight packed values, raw float bits, dedicated domain 5
   event 307, subject/flag constants, and canonical-hash recomputation. The
   camera inventory and coverage key must include event 307 exactly once.
3. **Real lifecycle reachability.** Run the ordinary owner-thread DDD area-1
   recipe until the source callback executes. Require at least one positive
   line-2471 receipt and verify its mode/level/area and positions come from
   that callsite. If the authored branch is not reached, report blocked and do
   not synthesize a receipt or pair.
4. **Native reproducibility.** Produce fresh Debug, AddressSanitizer, and
   optimized Release traces plus a fresh-root rerun. Require exact route-record
   bytes, tick/sequence ordering, canonical hashes, coverage, and no sanitizer
   findings. Build success alone is not route evidence.
5. **Independent Swift mirror.** Compile the new Swift mirror with strict
   Swift 6. It must derive the same DDD source recipe independently, never
   consume the C trace as input, never invoke a C query, and reproduce the
   packed values/record hash byte-for-byte. The generic collision mirror must
   remain a negative boundary.
6. **Negative fences.** Tamper with any packed value, source ID, mode/level/
   area, sequence, or hash and require rejection. Also reject truncated or
   partial traces, wrong-domain/event records, wrong callsite subject, a single
   artifact supplied as both sides, duplicate admission, and a persistent
   rerun against a terminal isolated result.
7. **Isolated admission only.** After the pair passes, a separate admission
   run may bind the immutable route row, seeds, header fingerprints, exact
   C/Swift/ASan/Release/rerun artifacts, and report SHA. It must leave the
   canonical manifest, cumulative report, route ledger, and history unchanged
   until a separately authorized serial merge.
8. **Separate acceptance gates.** M34 direct-display/reference-pixel/long-
   soak, M35 signing/notarization/Gatekeeper, physical camera/water feel, and
   human gameplay acceptance remain unproven by this seam.

## Validation performed in this preparation

Read-only source inspection covered both camera callsites, the generic
environment producer, parity recorder, oracle schema/inventory, Swift
collision mirror, DDD/JRB authored camera/level recipes, and the existing
camera `find_floor` route. No build, runtime probe, C/Swift pair, admission,
manifest generation, ledger transition, staging, commit, or push was run.

After writing this note, `git -c core.fsmonitor=false diff --check` passed.
Existing dirty and untracked worktree changes were preserved.

## Remaining risks

- DDD mode 2 may still be unreachable under the current native automated
  recipe; reachability must be demonstrated by the real lifecycle.
- The incoming callback `pos` at line 2471 is the exact camera candidate seen
  by the callback, not a later final `Camera` graph position; substituting the
  latter would change source semantics.
- Camera-domain sequence values include other camera events in the same tick;
  the Swift mirror must preserve the native sequence, not reset or infer it
  from filtered environment records.
- The line-2845 JRB/default-camera candidate remains unpaired and must receive
  its own identity if pursued.
