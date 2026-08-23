# Full Swift Twin Handoff — Phase 85f97 WF Whomp King Seam Execute

Date: 2026-08-23

## Verdict

**SEAM IMPLEMENTED / REAL ROUTE BLOCKED / FAIL-CLOSED EXIT 77.** The private
source-owned WF King Whomp schema-4 seam, semantic King and reward-child
identities, independent Swift mirror, focused C lifecycle contract, and
route-pair harness are present for planned shard `0x28e0617bfc286cbe`. The
normal owner-thread lifecycle remained in the initial level (`level=1 area=1`)
and did not reach Castle Inside's authored WF painting nodes, so no native King
receipt or positive route trace was emitted. The route harness correctly
returned exit `77`; it did not direct-load/register WF, invoke a behavior or
collision helper, inject a Whomp or star, substitute a small Whomp, select by
coordinates, or mutate a manifest, report, ledger, or backup.

## Frozen source route

The selected planned row remains:

```text
0x28e0617bfc286cbe|behavior|bhvWhompKingBoss|data/behavior_data.c|0x425f2ecc0685117a|0xa811784982556e63|collision_queries,effects,object_state,script_events|planned|deterministic route shard; execution remains an M33 gate
```

The source lifecycle is the Castle Inside painting family `0x06`, `0x07`, and
`0x08` to WF area 1, ACT_1. The exact authored object is source ordinal `0`
of `levels/wf/script.c:script_func_local_4`:

```text
model=MODEL_WHOMP
position=(0,3584,0)
face_angles=(0,0,0)
behavior_parameter=0x00000000
behavior=bhvWhompKingBoss
acts=ACT_1
```

The source behavior program sets the runtime King variant
`oBehParams2ndByte=1` and health `3` before entering the shared
`bhv_whomp_loop`; both the authored parameter `0` and runtime variant `1` are
retained in the receipt. The reward intent is source child ordinal `1`,
semantic `bhvStar`, `MODEL_STAR`, and exact position `(180,3880,340)`.

## Owned implementation

- `src/pc/sm64_modern_whomp_king_route_identity.h/.c` defines fixed-width
  route/source/owner IDs, semantic FNV identities for `bhvWhompKingBoss` and
  `bhvStar`, the named Whomp collision identity, scalar owner receipt fields,
  source tuple validation, reward-child validation, and schema-4
  `script/object/collision/effect` records.
- `src/game/behaviors/whomp.inc.c` observes only after the native
  `cur_obj_update_floor_and_walls` → action reducer → `cur_obj_move_standard`
  → collision-model load order. It copies scalar state/effect outcomes and
  never publishes `o`, Mario, camera, collision, or spawned-object pointers.
- `src/pc/sm64_modern_gameplay_parity.c` publishes semantic identities for the
  King owner and source star helper across Debug, ASan, and Release layouts.
- `tests/sm64_modern_whomp_king_route_pair_contract.c` follows the real
  lifecycle, binds the exact `bhvWhompKingBoss` subject/variant, and rejects
  missing reachability as a blocked precondition.
- `tests/sm64_modern_whomp_king_route_swift_smoke.swift` independently decodes
  schema 4, validates the source tuple/action fields/semantic reward child,
  and provides tamper, partial, wrong-variant, wrong-subject,
  generic-identity, fixture-only, duplicate, persistent-rerun, and
  single-artifact rejection paths.
- `script/test_whomp_king_route_pair.sh` enforces strict C/Swift compilation,
  source-route and pointer/helper fences, fresh Debug/ASan/Release/rerun
  parity when reachable, and exit-77 reachability behavior.

## Validation evidence

Passed:

```text
bash -n script/test_whomp_king_route_pair.sh
Swift 6 strict schema-4 mirror compile
C11 -Wall -Wextra -Werror focused contract syntax/link compile
make SM64_MODERN_NATIVE=1 DEBUG=1 ... native-core
owned-path git diff --check
```

The focused native contract and the full route harness both reached the
fail-closed boundary:

```text
whomp_king_route_unreachable level=1 area=1 whomps=0
SM64 Modern Whomp King route pair blocked reachability=0
source_lifecycle=castle_inside_painting_nodes_0x06_0x07_0x08_to_wf_area1_act1
first_king_receipt=absent small_whomp_substitution=0 coordinate_matching=0 fixture_only=0
admission=0 canonical_ledger_mutation=0 manifest_mutation=0 exit=77
```

Because the authored Castle → WF lifecycle did not reach the direct subject,
the positive receipt, C/Swift byte pairing, ASan/Release/rerun parity, and
runtime negative matrix were not claimed. No admission or canonical merge is
authorized by this phase. The follow-up is to provide a real source-authored
Castle Inside painting traversal that establishes WF area 1, then rerun the
route matrix without any direct-level, helper, injection, sibling, coordinate,
or synthetic-trace substitute.

Unrelated dirty and untracked worktree changes, public ABI, canonical
manifests/reports, route ledgers, and backups were left untouched.
