# Full Swift Twin Handoff — Phase 85f47 WDW Express-Elevator Seam Execute

Date: 2026-08-22

## Verdict

**IMPLEMENTATION COMPLETE / REACHABILITY BLOCKED / NO ADMISSION.** The
source-owned observer, semantic behavior identities, pointer-free route
packet, independent Swift reducer mirror, focused schema-4 C/Swift pair, and
fail-closed matrix script are present. The real Castle Inside painting route
reaches WDW, but its authored destination leaves WDW area 1 for area 2 before
the dynamic express-elevator loop emits a receipt. The route therefore exits
77 and does not substitute the static sibling, inject an object, call the
platform helper from a probe, match coordinates, or create fixture evidence.

## Source boundary

The observer is called once at the end of
`src/game/behaviors/express_elevator.inc.c`, after the source reducer has
evaluated `cur_obj_is_mario_on_platform()` and after the source sound call.
It receives only copied scalar state: source subject slot, action/timer,
position/home/velocity bit patterns, Mario-platform result, and sound intent.
The route packet and schema-4 event contain no object, Mario, behavior, or
surface pointer.

The private route identity header binds both `bhvWdwExpressElevator` and
`bhvWdwExpressElevatorPlatform` to independent semantic identities. Unknown
behavior scripts retain the legacy anchor-relative fallback; the selected
dynamic row and wrong sibling are rejected by the route packet before any
trace comparison. The broader object-snapshot behavior-name map remains an
existing dirty-worktree change and is intentionally not folded into this
isolated seam commit.

## Route identity

```text
shard=0x6e6c6a0fc1b92a45
source_row=behavior|bhvWdwExpressElevator|data/behavior_data.c
source_identity=0x73776902d63209e9
owner_identity=0x4490d0bf72a4dab6
semantic_behavior=0xcba3488bb46b4d7f
static_sibling_identity=0xd50f815812e49dd6
static_sibling_owner=0x57eea3c39811e29f
recipe=Castle Inside area-2 painting node 0x18 -> LEVEL_WDW area 1 node 0x0A
source_objects=levels/wdw/script.c:40-41
observer=src/game/behaviors/express_elevator.inc.c
schema4_domain=script kind=event value_count=8
```

The opt-in lifecycle gate requests Castle Inside area 2 through the existing
source warp path, then requests the compiled WDW painting destination. It
does not load a level directly or register an object. The probe found
`level=11 (LEVEL_WDW), area=2, dynamic=0, static=0`; the authored WDW area-1
object list was not retained by the time the owner step could observe it.

## Files owned by this phase

- `src/pc/sm64_modern_wdw_elevator_route_identity.h`
- `src/pc/sm64_modern_wdw_elevator_route_identity.c`
- `src/game/behaviors/express_elevator.inc.c`
- `src/game/game_init.c` (opt-in Castle → WDW lifecycle gate; preserve other
  agents' existing hunks when staging)
- `tests/sm64_modern_wdw_elevator_route_pair_contract.c`
- `tests/sm64_modern_wdw_elevator_route_swift_smoke.swift`
- `script/test_wdw_express_elevator_route_pair.sh`
- this handoff

## Validation

Passed:

```text
xcrun swiftc -parse-as-library -swift-version 6 -strict-concurrency=complete
  independent route mirror compiled
clang -std=c11 -Wall -Wextra -Werror focused route contract compiled
bash -n script/test_wdw_express_elevator_route_pair.sh
git diff --check (owned paths)
```

The isolated matrix was run with a fresh native Debug build and the real
owner-thread lifecycle:

```text
SM64_WDW_ELEVATOR_ROUTE_BUILD_PARENT=/tmp/sm64-modern-wdw-elevator-route-pair \
  bash script/test_wdw_express_elevator_route_pair.sh
wdw_express_elevator_route_unreachable level=11 area=2 dynamic=0 static=0
SM64 Modern WDW express elevator route pair blocked reachability=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

ASan/Release/rerun byte parity and negative trace fences were intentionally
not admitted after the required real reachability gate returned 77. The
script contains those checks for the next source-reachable run; no C/Swift
pair, admission report, manifest row, canonical ledger, or shared report was
created or changed.

## Follow-up blocker

Re-run the matrix only after the source-authored Castle Inside → WDW area-1
painting lifecycle keeps the dynamic object in area 1 long enough for
`bhv_wdw_express_elevator_loop` to execute. Do not bypass the instant-warp
route, target WDW area 2, inject the object, use the static sibling, or add a
fixture record. Once a positive dynamic receipt exists, the script will run
Debug/ASan/Release/rerun equality plus tamper, partial, wrong-sibling, and
single-artifact rejection before any admission.
