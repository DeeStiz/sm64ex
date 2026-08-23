# Full Swift Twin Handoff — Phase 85f26 Camera/Environment Floor-Query Route

Date: 2026-08-22

## Verdict

**FAIL-CLOSED — NO NEW CAMERA FLOOR/ENVIRONMENT ROUTE QUALIFIES.** The
already-qualified camera `find_floor` row remains the source-bound
`src/game/camera.c:788:set_camera_height:find_floor` route
(`0x1e3500f9eb2b95d4`). This discovery found two distinct source-authored
water-query leads, but neither has the required pointer-free owner, query
position, result, and schema-4 receipt. No C/Swift pair, admission, manifest
mutation, cumulative-ledger mutation, or synthetic call was performed.

## Exact candidates

### DDD outward-radial camera water query

The clearest static source-authored candidate is:

```text
manifest row: 0xd279e42385c646ac
identity: find_water_level
source: src/game/camera.c
source call: src/game/camera.c:2471-2472
owner: sm64_modern_camera_evaluate_callback
recipe: LEVEL_DDD, area 1, CAMERA_MODE_OUTWARD_RADIAL (2)
```

The call is inside the mode-2/1/14 geometry branch and queries Mario's
source position before placing the camera:

```c
input.water_height = find_water_level(
    sMarioCamState->pos[0], sMarioCamState->pos[2]);
```

The authored route is present in `levels/ddd/areas/1/geo.inc.c:16` as
`GEO_CAMERA(2, ...)`; `levels/ddd/script.c:84-97` loads that area with
`TERRAIN_TYPE(TERRAIN_WATER)`, and its source object list contains the two
authored Sushi owners at `levels/ddd/script.c:19-20`. The mode-2 callback is
not rejected by the source-authored area exceptions at
`src/game/camera.c:2199-2208` (only Bob-omb/WDW/THI radial exceptions and
DDD's area-2 eight-direction exception are held on C).

This is source reachability evidence only. There is no current DDD lifecycle
trace bound to this call, and the callback input's `water_height` field is an
aggregate ABI value, not a source-call receipt or route identity.

### JRB default-camera water query

The strongest existing runtime recipe lead is:

```text
manifest row: 0xd279e42385c646ac
identity: find_water_level
source: src/game/camera.c
source call: src/game/camera.c:2845
owner: update_default_camera (mode_lakitu_camera / CAMERA_MODE_FREE_ROAM)
recipe: authored JRB area 1, existing SM64_MODERN_AUTOMATED_JRB_BREAK_PARTICLES
```

JRB area 1 is authored with `GEO_CAMERA(16, ...)` at
`levels/jrb/areas/1/geo.inc.c:16`, water terrain and its normal area script at
`levels/jrb/script.c:144-158`. The existing JRB selector is installed by
`src/game/game_init.c:670-694` and is exercised by the Phase 85f6
break-particles route. In `update_default_camera`, the source computes the
camera path and then calls:

```c
waterHeight = find_water_level(cPos[0], cPos[2]);
```

This query is distinct from the already-qualified `set_camera_height` floor
call: its owner is the default camera, its position is the computed camera
path position (`cPos`), and its result controls the camera-above-water and
metal-below-water policy. The existing JRB route evidence retains RNG
receipts only; it does not identify or retain this camera water call.

## Why neither candidate qualifies

The authoritative environment producer is the shared
`src/engine/surface_collision.c:676-706` `find_water_level` implementation.
Its current observer at lines 66-76 emits only four generic values (query X,
query Z, returned height, environment kind). The parity bridge at
`src/pc/sm64_modern_gameplay_parity.c:1576-1605` hard-codes `subject_id=0`
and the environment event ID; it does not carry the camera owner, source
callsite, mode, Mario/camera position, or authored recipe. The Swift mirror in
`SM64Modern/CollisionQueriesMigration.swift:14-45` accepts that same generic
four-value shape and therefore cannot distinguish either camera call from
all other `find_water_level` callers.

The remaining camera callers are also not new receipts: Mario's shared
`calc_y_to_curr_floor` water query (`camera.c:678-716`), behind-Mario
floor/water (`camera.c:2041-2070`), the per-frame
`find_mario_floor_and_ceil` prepass (`camera.c:7615-7642`), and the other
camera floor checks all feed the same generic collision hook. Reusing those
records, matching positions after the fact, or treating the callback ABI
input as a route receipt would infer source ownership and is fail-closed.

## Required unblock

Choose one source callsite and add a narrowly scoped native observer at that
callsite, not inside the shared `find_water_level` helper. For example:

```text
src/game/camera.c:2471:sm64_modern_camera_evaluate_callback:find_water_level
or
src/game/camera.c:2845:update_default_camera:find_water_level
```

The receipt must carry a stable source identity, simulation tick and sequence,
camera mode/level/area, owner Mario/camera position as float bits, query X/Z,
returned water-level bits, and canonical record hash. Keep the C surface and
environment query authoritative. Then retain the authored DDD or JRB recipe
through an independent C trace, an independent Swift value-only receipt
mirror, Debug/ASan/Release and persistent-rerun byte equality, and tamper /
partial / single-artifact rejection before any isolated admission. Do not
inject Sushi, force a camera mode, call `find_water_level` directly, or reuse
the generic environment trace.

## Validation and scope

Static source/manifest inspection covered all `find_floor` and
`find_water_level` callers in `src/game/camera.c`, the DDD/JRB authored camera
and level recipes, the generic collision observer, and the existing Swift
mirror. No source, Swift, test, manifest, ledger, or shared documentation file
was changed by this phase. The only file added is this handoff.

`git -c core.fsmonitor=false diff --check` passed after writing this note.
