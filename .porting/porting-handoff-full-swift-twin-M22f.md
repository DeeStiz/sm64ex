# SM64 Modern Full Swift Twin — M22f Handoff

## Scope

M22f integrates the pointer-free `SM64RespawnerObjectBridge` into
`SM64YoshiObjectBridge`'s live owner-thread scheduler. A Yoshi roof-failure
respawner is now allocated in `OBJ_LIST_DEFAULT`, so the shared 13-list
scheduler visits it after its source Yoshi in the same traversal. The bridge
executes the outside-radius gate, allocates the replacement Yoshi in that
same list walk, copies model/behavior/behavior-parameter/position/home fields,
and delivers respawner deletion before the scheduler retires the source and
respawner generations. The focused C fixture records the live list counts,
updated order, unload order, slot reuse, and replacement record.

This is the first live Yoshi-to-respawner owner integration. It does not prove
whole-level behavior dispatch, migration of the remaining C adapters, durable
progression, presentation consumers, or whole-game parity.

## Evidence

- `script/test_yoshi_object_bridge.sh` — strict Swift/C owner fingerprint
  `0x0d985a32a8a93715`; Swift and C ordering contracts match.
- `script/test_behavior_manifest.sh` — fingerprint
  `0xf8bbfcbc86b888d9`; 534 rows, 72 `swift_value_owner` routes, and 462
  `unmigrated_c_adapter` rows.
- `/tmp/sm64-modern-m22f-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED` (headless CoreSimulator/AppIntents warnings remain
  non-fatal).
- `/tmp/sm64-modern-m22f-final-matrix.log` — complete matrix,
  `runs=204 failures=0`.
- `git diff --check` — clean.
- Strict-concurrency audit — zero `@unchecked Sendable` declarations in the
  audited `SM64Modern` runtime.

## Remaining work

1. Replace the remaining whole-engine C behavior dispatch with Swift-owned
   route selection and execute each mapped behavior from live object records.
2. Migrate the remaining 462 reachable adapters, or record a separately
   approved compatibility exception for each one.
3. Close behavior VM/object parity, collision/effect consumers, child routes,
   durable progression, camera/cutscene/audio, and deterministic C-vs-Swift
   parity shards.
4. Continue M23–M35: save/configuration/HUD/front-end, audio, display-list
   translation, Goddard, whole-engine authority, strict concurrency, replay,
   Metal 4 production, device, performance, visual, and human acceptance.

## Next command

Select the next reachable behavior from the generated manifest, attach its
Swift value/owner route to the live scheduler, add an independent C ordering
fixture, then rerun the native build and complete 204-script matrix before
promoting the next local milestone.
