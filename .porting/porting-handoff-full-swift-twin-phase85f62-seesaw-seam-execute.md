# Full Swift Twin Handoff — Phase 85f62 Bob Seesaw Seam Execute

Date: 2026-08-23

## Verdict

**IMPLEMENTATION COMPLETE / REAL ROUTE UNREACHABLE / FAIL-CLOSED EXIT 77.**
The source-owned Bob seesaw receipt seam, semantic behavior identity, schema-4
Swift mirror, and focused C/Swift matrix are present. The runtime matrix
correctly refused admission because the current owner-thread automation did
not reach Bob area 1 through the Castle Inside painting lifecycle.

No direct Bob load, level registration, object injection, behavior helper call,
coordinate-based selection, variant substitution, synthetic trace, manifest
mutation, canonical report mutation, staging, or commit was performed.

## Frozen authored route

```text
shard=0xb280cfa26a343b48
input_seed=0x67b6bca284c190b0
save_seed=0xeabfbddf911ea319
source=levels/bob/script.c:19-21
entry=levels/castle_inside/script.c:33-35 -> LEVEL_BOB area 1 node 0x0A
model=MODEL_BOB_SEESAW_PLATFORM (0x37)
behavior=bhvSeesawPlatform
behavior_parameter=3
collision_model_index=3
source_order=0
```

The observer is attached after `bhv_seesaw_platform_update` and copies only
fixed-width values: source subject/order, level/area, model/parameter,
collision model index and distance, authored position/yaw, pitch and velocity
before/after, Mario relation, distance/angles, and sound intent. The schema-4
receipt emits the source event across script, object, collision, and effect
domains with pointer-normalized flags. The generic behavior identity boundary
now publishes the established semantic `0x006268765f737377` for
`bhvSeesawPlatform`; no pointer-delta fallback is used for that behavior.

## Files owned by this phase

- `src/pc/sm64_modern_seesaw_platform_route_identity.h`
- `src/pc/sm64_modern_seesaw_platform_route_identity.c`
- `src/game/behaviors/seesaw_platform.inc.c`
- `src/pc/sm64_modern_gameplay_parity.c` (one semantic identity hunk)
- `tests/sm64_modern_seesaw_platform_route_pair_contract.c`
- `tests/sm64_modern_seesaw_platform_route_swift_smoke.swift`
- `script/test_seesaw_platform_route_pair.sh`
- this handoff

## Validation

Passed:

```text
xcrun swiftc -parse-as-library -swift-version 6
  -Xfrontend -strict-concurrency=complete
  SM64Modern/OracleTrace.swift tests/sm64_modern_seesaw_platform_route_swift_smoke.swift
strict C core build with the new observer and route identity
clang -std=c11 -Wall -Wextra -Werror focused route contract link
bash -n script/test_seesaw_platform_route_pair.sh
git diff --check (owned paths)
```

The focused matrix was run from a fresh build root:

```text
SM64_SEESAW_PLATFORM_ROUTE_PAIR_ROOT=/tmp/sm64-seesaw-route-script-run \
  bash script/test_seesaw_platform_route_pair.sh
```

Observed result:

```text
seesaw_platform_route_unreachable level=1 area=1 object=0
SM64 Modern Bob seesaw route blocked reachability=0
source_lifecycle=castle_inside_painting_to_bob_area1
selected_model=MODEL_BOB_SEESAW_PLATFORM parameter=3
synthetic_trace=0 direct_level_load=0 object_injection=0 variant_substitution=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

Because the required real route precondition failed, the matrix did not run
Debug/ASan/Release/rerun byte equality or artifact tamper/partial/wrong-variant
admission. Those checks remain implemented after the reachability gate and
will execute on the first source-reachable run.

## Unblock

Provide an owner-thread automation path that consumes the existing compiled
Castle Inside painting destination to Bob area 1, then rerun the matrix. The
route must produce a positive source receipt before any C/Swift pairing or
admission is considered. Do not replace it with `SM64_MODERN_AUTOMATED_BOBOMB`
direct level selection or a synthetic seesaw.
