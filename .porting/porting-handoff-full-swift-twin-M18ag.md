# Full Swift Twin M18ag Handoff

## Scope

M18ag adopts the common owner-thread effect router for the water-bomb family.
Spawner-created bomb explosion cleanup, shadow deletion, and missing-parent
cleanup now use sequenced deletion intents delivered before the scheduler's
end-of-frame unload.

## Implementation

- `SM64Modern/WaterBombObjectBridge.swift` owns the router, clears it per tick,
  routes bomb/shadow deletion, and records delivery results without exposing C
  object pointers.
- `script/test_water_bomb_object_bridge.sh` compiles the router and its Chain
  Chomp effect-record dependencies under strict Swift 6 concurrency.
- `tests/sm64_modern_water_bomb_object_bridge_smoke.swift` verifies normal
  shadow impact and bomb cleanup through the router and hashes both delivery
  and unload outcomes.
- `tests/sm64_modern_water_bomb_object_bridge_contract.c` independently
  matches `waterBombObjectBridgeFingerprint=0x2c7546919aa992ae`.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18ag-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18ag-build.log`.
- `git diff --check` passes.

These checks establish water-bomb deletion routing and scheduler ordering
only. They do not establish router adoption across every bridge, full
collision resolution, runtime audio/renderer/camera presentation, physical
device acceptance, distribution, or human gameplay acceptance.

## Next slice

Continue the direct-deletion audit across migrated enemy/projectile bridges,
then consolidate presentation intents into the runtime audio/particle/camera
owners. M19 may start only after every spawned/despawned actor has a verified
Swift-owned collision, presentation, reward, and deletion delivery path.
