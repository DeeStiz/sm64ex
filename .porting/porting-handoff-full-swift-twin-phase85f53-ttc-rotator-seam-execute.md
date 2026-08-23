# Full Swift Twin Handoff — Phase 85f53 TTC 2D Rotator Seam Execute

Date: 2026-08-23

## Verdict

**IMPLEMENTATION COMPLETE / REAL REACHABILITY BLOCKED / NO ADMISSION.** The
private source-owned TTC 2D rotator receipt seam, semantic behavior identity,
pointer-free schema-4 C producer, independent Swift decoder/mirror, focused
contract, and fail-closed matrix script are present. The real owner-thread
Castle Inside painting route reaches level 14 (TTC) but observes area 2 with
zero authored clock-hand objects, so no route receipt or trace is opened.

The required fail-closed result is exit 77. No cog/static sibling, direct TTC
load, macro injection, behavior-helper call, coordinate match, or synthetic
trace was used.

## Source boundary

`src/game/behaviors/ttc_2d_rotator.inc.c` copies the source reducer's scalar
state immediately after the hand's existing `load_object_collision_model()`
branch. It preserves the source random calls and copies the random results,
timer/min-time, face/target yaw, increment/speed, angle velocity, collision
branch, render/effect bits, and stable object slot. The receipt contains no
Object, behavior-script, collision, or graph pointer.

The opt-in owner-thread gate in `src/game/game_init.c` follows Castle Inside's
compiled area-2 path and then requests the source-authored TTC painting
destination represented by nodes `0x21`/`0x22`/`0x23` (TTC area 1 node `0x0A`).
It is enabled only by `SM64_MODERN_AUTOMATED_CASTLE_TTC_ROTATOR`; normal launch
behavior is unchanged.

`src/pc/sm64_modern_gameplay_parity.c` adds the semantic
`bhvTTC2DRotator` identity (`0xec145f4c8aaec281`) and enables TTC object
snapshots. Unknown behavior identities retain their existing behavior, while
the selected hand route never falls back to a pointer delta.

## Route identity

```text
shard=0x1af5669b06931d93
source_row=behavior|bhvTTC2DRotator|data/behavior_data.c
source_identity=0x8e76517f46608f58
owner_identity=0xef39eb821eba1fe3
semantic_behavior=0xec145f4c8aaec281
variant_source=0xa767fa6b5b3528c5
variant_owner=0x6ac58d865b35ba3d
recipe=Castle Inside painting nodes 0x21/0x22/0x23 -> TTC area 1 node 0x0A
source_object=levels/ttc/areas/1/macro.inc.c:first macro_ttc_clock_hand
model=MODEL_TTC_CLOCK_HAND (0x41)
behavior_parameter=0
schema4_domains=script,object,collision,effect
```

The route identity header is private:
`src/pc/sm64_modern_ttc_rotator_route_identity.h/.c`. The source observer emits
four fixed-width receipts per selected hand update: script state, script
motion/random, collision-branch receipt, and effect receipt. The selected
subject is the first source-authored hand encountered by the native object
owner; the second hand is ignored as a sibling, not substituted.

## Validation

Passed:

```text
xcrun swiftc -parse-as-library -swift-version 6
  -Xfrontend -strict-concurrency=complete
  independent route mirror compiled
clang -std=c11 -Wall -Wextra -Werror focused route contract compiled
bash -n script/test_ttc_2d_rotator_route_pair.sh
git -c core.fsmonitor=false diff --check (owned paths)
```

The focused matrix was run with a fresh native Debug build:

```text
SM64_TTC_ROTATOR_ROUTE_BUILD_PARENT=/tmp/ttc-route-script2 \
  bash script/test_ttc_2d_rotator_route_pair.sh

ttc_2d_rotator_route_unreachable level=14 area=2 hands=0
SM64 Modern TTC 2D rotator route pair blocked reachability=0
source_lifecycle=castle_inside_painting_nodes_0x21_0x22_0x23_to_ttc_area1
first_clock_hand_receipt=absent cog_substitution=0 fixture_only=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

Because the real authored hand was absent before the trace window opened, the
script correctly did not run ASan, Release, rerun byte parity, Swift pairing,
tamper/partial/wrong-variant/duplicate/single-artifact fences, or admission.
No C/Swift trace artifact was created by the blocked run.

## Files owned by this phase

- `src/pc/sm64_modern_ttc_rotator_route_identity.h`
- `src/pc/sm64_modern_ttc_rotator_route_identity.c`
- `src/game/behaviors/ttc_2d_rotator.inc.c`
- `src/game/game_init.c` (opt-in source lifecycle gate)
- `src/pc/sm64_modern_gameplay_parity.c` (semantic identity/TTC object snapshot)
- `tests/sm64_modern_ttc_2d_rotator_route_pair_contract.c`
- `tests/sm64_modern_ttc_2d_rotator_route_swift_smoke.swift`
- `script/test_ttc_2d_rotator_route_pair.sh`
- this handoff

No manifest, canonical report, route ledger, public ABI, staging, commit, or
push was changed.

## Follow-up blocker

Re-run the matrix only after the normal source-authored Castle Inside → TTC
painting lifecycle retains TTC area 1 long enough for the macro object list to
spawn and tick its first clock hand. Do not bypass the area transition, target
TTC area 2, inject a macro object, select either cog, or emit fixture evidence.
