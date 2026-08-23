# Full Swift Twin Handoff - Phase 85f31 Camera-Water Seam Execute

Date: 2026-08-22

## Verdict

**IMPLEMENTED / FAIL-CLOSED ON RUNTIME REACHABILITY.** The source-owned
camera-water receipt now observes only the `find_water_level` call at
`src/game/camera.c:2471` inside `sm64_modern_camera_evaluate_callback`.
The selected route is schema-4 camera-domain event 307 with a fixed-width,
pointer-free eight-value payload. The separate `update_default_camera`
call at line 2845 remains untouched.

The ordinary owner-thread lifecycle did not reach authored DDD area 1 in the
current host recipe. The focused gate therefore emitted no synthetic route
record, returned exit status 77, and did not run an admission or mutate any
canonical manifest, report, ledger, or history file.

## Source contract

`src/pc/sm64_modern_camera_water_route_identity.[ch]` owns the private source
identity, subject ID `0x340565d4295ea359`, route flag `0x43414d57`, scalar
copies, raw IEEE-754 float-bit packing, and schema-4 publication. The packed
values are:

```text
0: mode low 16 bits
1: level low 32 bits, area high 32 bits
2: camera x low 32 bits, camera y high 32 bits
3: camera z low 32 bits, Mario x high 32 bits
4: Mario y low 32 bits, Mario z high 32 bits
5: query x low 32 bits, query z high 32 bits
6: returned water-height bits
7: QUERY_EXECUTED | HAS_HEIGHT result flags
```

`src/game/camera.c` calls the observer immediately after the native query and
before folding the result into the callback input. It copies the incoming
callback position, Mario position, live level/area, query coordinates, and
native result. It does not call the query helper itself, synthesize a result,
or reuse the generic collision receipt. The private parity header adds only
`SM64_MODERN_ORACLE_CAMERA_EVENT_WATER_QUERY = 307`; the generic collision
hooks are unchanged. The camera inventory declares event 307 exactly once.

## Swift mirror and focused contracts

`SM64Modern/CameraWaterQueryMigration.swift` independently models the
authored DDD area-1 recipe (`LEVEL_DDD = 23`, area 1,
`CAMERA_MODE_OUTWARD_RADIAL = 2`), validates domain 5/kind 3/event 307,
subject/flag, canonical hash, ordering, packed fields, and the source query
coordinate relationship. Domain-7 generic collision records are rejected.

The C and Swift focused contracts are:

- `tests/sm64_modern_camera_water_route_pair_contract.c`
- `tests/sm64_modern_camera_water_route_swift_smoke.swift`
- `script/test_camera_water_route_pair.sh`

The C harness uses the ordinary lifecycle and a value-preserving camera API
adapter only to make the existing callback authority boundary callable. It
does not select a level, force a mode, inject an object, or call a collision
helper. Only a real event whose packed mode/level/area are DDD area 1/mode 2
is retained.

## Validation

Passed:

- strict C syntax checks (`-std=c11 -Wall -Wextra -Werror`) for the new route
  implementation and focused C contract;
- strict Swift 6 compile with complete concurrency checks for the independent
  mirror and smoke;
- Swift schema witness generation, canonical tamper rejection, generic
  collision-domain rejection, truncated-trace rejection, and single-artifact
  rejection;
- `git -c core.fsmonitor=false diff --check`.

The focused command:

```text
./script/test_camera_water_route_pair.sh
```

produced:

```text
camera_water_route_init status=0 oracle=0 parity=0
camera_water_route_step index=0 status=0 oracle=0 parity=0
camera_water_route_step index=1 status=0 oracle=0 parity=0
camera_water_route_debug oracle_end=0 result_status=0 actual=1797 retained=0 non_recipe=0 failures=0
camera_water_route_blocked authored_ddd_area1_reached=0 route_records=0 non_recipe=0 reason=ordinary_lifecycle_recipe_did_not_reach_ddd_area1
SM64 Modern camera-water route pair blocked fail_closed=1
```

The generated C trace contains only its 72-byte schema header because no
source-owned route receipt was observed. Debug/ASan/Release and persistent
rerun byte-equality evidence is consequently **not claimed**; those gates
remain pending a real authored DDD area-1 lifecycle recipe.

## Remaining unblock

Add or select an ordinary source-authored lifecycle recipe that reaches DDD
area 1 without a direct level register/load, forced camera mode, Sushi
injection, direct helper call, or post-hoc coordinate matching. Then rerun the
focused script and require positive event-307 reachability before attempting
Debug/ASan/Release/fresh-rerun equality or any isolated admission.

No commit, push, manifest regeneration, canonical ledger transition, report
write, or publication was performed by this worker.
