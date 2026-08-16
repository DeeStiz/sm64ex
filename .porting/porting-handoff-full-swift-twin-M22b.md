# SM64 Modern Full Swift Twin — M22b Handoff

## Scope

M22b closes one more explicit behavior seam from the shared explosion child
route. `bhvBobombExplosionBubble3600` now enters the Swift value kernel with a
deterministic `microOffset` rather than relying on an implicit/randomized
position mutation. The owner bridge preserves that offset in the spawned
bubble record, and the fail-closed behavior manifest maps the reachable route
to `ExplosionObjectBridge`.

This is a bounded migration slice. It does not claim that every behavior is
Swift-owned, that the live behavior VM is complete, or that C-vs-Swift parity
has been proven for the whole game.

## Evidence

- `script/test_explosion_children.sh` — child fingerprint
  `0x03fdfa6ee829478b`; Swift/C child contract matched.
- `script/test_behavior_manifest.sh` — manifest fingerprint
  `0xaa7628249ad5adf3`; 534 rows, 42 `swift_value_owner` routes, and 492
  `unmigrated_c_adapter` rows; double generation and Swift/C contract matched.
- `/tmp/sm64-modern-m22b-final-matrix.log` — complete 203-script matrix,
  `runs=203 failures=0`.
- `/tmp/sm64-modern-m22b-build.log` — regenerated native Debug build,
  `BUILD SUCCEEDED`.
- `git diff --check` — clean.
- Strict-concurrency audit — zero `@unchecked Sendable` declarations in the
  audited Swift runtime.

## Changed boundary

- `SM64ExplosionBubbleSpawnInput.microOffset` is an explicit, `Sendable` value
  input and is added to the bubble's initial position.
- The explosion-child smoke contract covers the offset while retaining the
  stable child fingerprint and all existing timing/lifetime assertions.
- The behavior manifest records `bhvBobombExplosionBubble3600` as a Swift
  owner route and updates its deterministic fingerprint.

## Remaining work

1. Migrate the remaining 492 manifest rows from explicit C adapters, or obtain
   a documented, separately approved compatibility exception for each row.
2. Add a live behavior VM/object execution ledger; manifest accounting alone is
   not runtime proof.
3. Close water-splash consumption, duplicate Bowser child-route unification,
   collision authority, durable rewards/warps, real camera/cutscene/audio
   consumers, and deterministic parity shards.
4. Continue M23–M35: save/config/HUD/front-end, audio, display-list translation,
   Goddard, whole-engine authority, replay/parity, production Metal 4, and
   device/human acceptance.

## Next command

Inspect the next reachable manifest rows and select one bounded owner/value
route for M22c; do not mark an adapter migrated until its focused Swift/C
contract, full matrix, native build, and live execution evidence are present.
