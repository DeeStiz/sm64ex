# Full Swift Twin Handoff — Phase 85f18 DDD Sushi Source Seam

Date: 2026-08-22

## Verdict

**BLOCKED — NO QUALIFYING OWNER/QUERY RECEIPT — KEEP PLANNED.**

Target shard:

```text
0x023fe9bb4409460b|collision|find_water_level|src/game/behaviors/sushi.inc.c|0x47cfe0294fb1216b|0x2b03aeede7da4538|collision_queries,object_state|planned
```

This bounded retry used read-only source and observer inspection. It did not
run a runtime probe, create a synthetic Sushi object, call `find_water_level`
directly, mutate the manifest/ledger, or claim route admission.

## Authored DDD route

The source-owned DDD area-1 script contains two all-acts Sushi objects in
source order at `levels/ddd/script.c:18-20`:

```text
source order 1: MODEL_SUSHI, (-3071, -270,     0), bhvSushiShark
source order 2: MODEL_SUSHI, (-3071, -4270,    0), bhvSushiShark
```

The level interpreter copies each command's position, angles, behavior
parameters, model node, and behavior pointer into a `SpawnInfo`
(`src/engine/level_script.c:462-487`). It prepends each new entry to the
area's linked list (`spawnInfo->next = ...`), and `SpawnInfo` has no source
order field. `spawn_objects_from_info` then creates the real object and copies
the behavior and position (`src/game/object_list_processor.c:483-530`), but it
does not call the dynamic object-spawn parity hook. The normal object update
wrapper only enters/leaves a subsystem around `cur_obj_update`
(`src/game/object_list_processor.c:301-310,349-359`).

The selected source call is the first operation in the authored owner loop:

```text
src/game/behaviors/sushi.inc.c:6-10
    sp1C = find_water_level(o->oPosX, o->oPosZ);
```

The behavior script also owns the source wave-trail child and water sound
side effects, but those do not identify the `find_water_level` call site.

## Existing observer/trace seam audit

- `src/engine/surface_collision.c:66-76` records every environment query as
  four values: query `x`, query `z`, returned height, and environment kind.
  `find_water_level` invokes this generic hook at
  `src/engine/surface_collision.c:676-706` after calculating the result.
- `sm64_modern_parity_record_collision_query`
  (`src/pc/sm64_modern_gameplay_parity.c:1576-1605`) records the generic
  environment event with `subject_id=0`, `record_id=4`, and no owner or
  source-object order. The current Swift mirror in
  `SM64Modern/CollisionQueriesMigration.swift:6-45` accepts exactly that
  generic four-value shape; it has no Sushi-owner fields.
- `sm64_modern_parity_enter_object_update`
  (`src/pc/sm64_modern_gameplay_parity.c:1748-1750`) receives an object but
  retains only the subsystem. DDD falls through the level-to-subsystem map to
  `GLOBAL`; no object identity, source order, or source position is attached
  to the collision record.
- `behavior_identity` has no `bhvSushiShark` source-name mapping and otherwise
  falls back to a behavior-pointer delta. That value is not a stable
  Debug/ASan/Release owner identity. The generic actor snapshot path is also
  enabled only for Castle, RR, and HMC (`capture_actor_snapshot`,
  `src/pc/sm64_modern_gameplay_parity.c:1268-1277`), not DDD.
- The existing Swift Sushi bridge (`SM64Modern/SushiSharkObjectBridge.swift`)
  exposes a synthetic `spawnSushi` API and accepts a caller-supplied
  `waterLevel`; its value contract is not evidence that the authored DDD
  `SpawnInfo` lifecycle reached `bhv_sushi_shark_loop`.

## Determination

The requested stable, pointer-free owner/order/position plus
`find_water_level` query/result receipt **cannot be emitted by the existing
seam**. Reusing the generic environment record, matching its coordinates to
the two DDD entries, using an object-pool slot, hashing a `SpawnInfo` pointer,
or relying on the Swift `spawnSushi` bridge would infer or synthesize source
ownership. A direct helper invocation would bypass the authored call site.
Each is therefore fail-closed for this shard.

## Exact unblock evidence

An independent bounded DDD lifecycle probe must retain the authored area-1
objects and emit, from the actual C Sushi owner/call-site boundary, a
pointer-free schema-4 receipt containing at least:

- a stable source behavior identity for `bhvSushiShark`;
- an explicit source object order (1 or 2), not an object-pool slot or linked
  list/pointer identity;
- authored owner position (IEEE-754 bits) and the actual query `x/z` bits;
- the returned water-level bits, simulation tick, per-domain sequence, and
  canonical record hash.

The Swift side must independently decode and validate those receipts without
creating a Sushi object or evaluating `find_water_level`. Before any isolated
admission, the same source-authored run needs C/Swift equality plus byte-
identical Debug, ASan, Release, and persistent rerun traces/receipt sidecars;
tamper, truncated/partial, single-artifact, and fixture-only fences must
reject. The route must remain isolated and leave the generated manifest,
cumulative ledger, and canonical report untouched.

## Validation

Only this handoff note was added. No source, Swift, test, manifest, ledger, or
shared documentation file was changed by this phase. `git diff --check` was
run after writing the note.
