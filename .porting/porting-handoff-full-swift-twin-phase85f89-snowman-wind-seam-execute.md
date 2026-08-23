# Full Swift Twin Handoff — Phase 85f89 Snowman Wind Seam Execute

Date: 2026-08-23

## Verdict

**SEAM IMPLEMENTED / ROUTE FAIL-CLOSED AT REAL REACHABILITY.** The private
source-owned Snowman wind receipt seam, semantic `bhvSLSnowmanWind` identity,
independent schema-4 Swift mirror, focused C contract, and route-pair harness
are present for planned shard `0xa98dae7d4d4559ab`. The ordinary host lifecycle
remained in Castle Inside area 1 for the bounded run, so no native Snowman wind
receipt or route trace was emitted; the harness correctly returned exit 77.
No direct Snowman's Land selection, helper call, object injection, sibling or
coordinate selection, synthetic trace, manifest mutation, ledger mutation, or
canonical report write was performed.

## Source seam

`src/game/behaviors/sl_snowman_wind.inc.c` preserves the source reducer and
copies only scalar values after its existing owner update: exact source tuple,
pre/post sub-action and timer, original/move yaw, Mario angle/distance and
height, textbox probe position/result, dialog ID/result, and strong-wind
particle/sound intent. The observer does not receive an Object, behavior
script, Mario, temporary-position, particle, or sound pointer. The source
textbox, dialog, particle, and sound helpers remain authoritative.

`src/pc/sm64_modern_gameplay_parity.c` publishes the FNV semantic identity
`0xcdefb84fe8f44059` for `bhvSLSnowmanWind`, independent of the linked behavior
address. The private receipt identity uses the frozen planned-row seeds:

```text
shard=0xa98dae7d4d4559ab
input_seed/source_identity=0x55770e09d66b130b
save_seed/owner_identity=0x7bd3187854922858
semantic_behavior=0xcdefb84fe8f44059
source=levels/sl/script.c:script_func_local_3 source_order=1
tuple=MODEL_NONE position=(700,3428,700) face_yaw=30 parameter=0
route=Castle Inside painting nodes 0x24/0x25/0x26 -> SL area 1
schema4_domains=script,object,collision,effect
```

The private C identity writes four value-only schema-4 records per owner
update. The object-domain behavior snapshot is required to carry the semantic
identity; the route-specific collision record is the copied source textbox
query/result, not a recycled generic water/environment record.

## Pair and negative fences

- `tests/sm64_modern_snowman_wind_route_pair_contract.c` starts from the normal
  owner-thread lifecycle and selects the authored behavior subject only after
  SL area 1 is genuinely reached. It validates source/object/collision/effect
  receipts and never fabricates route data.
- `tests/sm64_modern_snowman_wind_route_swift_smoke.swift` independently
  decodes schema 4, validates the exact source tuple and reducer/effect
  invariants, and supports C/Swift byte pairing plus wrong-subject,
  generic-shared-identity, fixture-only, duplicate, partial, tamper,
  persistent-rerun, and single-artifact rejection.
- `script/test_snowman_wind_route_pair.sh` checks the authored Castle/SL
  recipe, strict C/Swift compilation, Debug/ASan/Release/rerun parity behind
  the real-reachability gate, and owned-path hygiene. It does not touch route
  manifests, canonical ledgers, designated reports, or backups.

## Validation

Passed:

```text
bash -n script/test_snowman_wind_route_pair.sh
Swift 6 strict schema-4 mirror compile
C11 -Wall -Wextra -Werror focused contract compile
make SM64_MODERN_NATIVE=1 DEBUG=1 ... native-core
bash script/test_snowman_wind.sh
  Swift/C Snowman wind contract matched
owned-path git diff --check
```

Fresh route-pair root:

```text
/tmp/sm64-snowman-wind-route-run/run.yiDPzf
```

The native Debug owner-thread run logged:

```text
snowman_wind_route_unreachable level=1 area=1 wind=0
SM64 Modern Snowman wind route pair blocked reachability=0
source_lifecycle=castle_inside_painting_nodes_0x24_0x25_0x26_to_sl_area1
first_snowman_wind_receipt=absent sibling_substitution=0 coordinate_matching=0 fixture_only=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

Because the source-authored lifecycle did not reach the direct subject, the
matrix correctly did not claim ASan/Release/rerun parity, schema-4 pairing,
tamper/negative runtime checks, or route admission. The value-only preexisting
Snowman wind contract remains green.

## Files owned by this phase

- `src/pc/sm64_modern_snowman_wind_route_identity.h`
- `src/pc/sm64_modern_snowman_wind_route_identity.c`
- `src/game/behaviors/sl_snowman_wind.inc.c`
- `src/pc/sm64_modern_gameplay_parity.c` (semantic identity)
- `tests/sm64_modern_snowman_wind_route_pair_contract.c`
- `tests/sm64_modern_snowman_wind_route_swift_smoke.swift`
- `script/test_snowman_wind_route_pair.sh`
- this handoff

Unrelated dirty and untracked worktree changes, public ABI, canonical
manifests/reports, route ledgers, and prior handoffs were left untouched.

## Follow-up blocker

Provide a normal source-authored Castle Inside Snowman painting traversal that
genuinely establishes Snowman's Land area 1 and keeps its direct
`script_func_local_3` Snowman wind object alive long enough for the observer to
emit a receipt. Then rerun the route matrix. Do not replace that lifecycle with
direct level selection, injection, helper probes, coordinate shortcuts, or a
neighboring Penguin/wind-particle object.
