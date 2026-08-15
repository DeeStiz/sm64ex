# Full Swift Twin M18ah Handoff

## Scope

M18ah adopts the common owner-thread effect router for Bullet Bill's
transient smoke child. The child remains a same-frame general-actor spawn and
is still unloaded at the scheduler's end-of-frame boundary, but deletion no
longer mutates the pool directly from the bridge.

## Implementation

- `SM64Modern/BulletBillObjectBridge.swift` owns the router, clears it per
  tick, enqueues smoke deletion, delivers it before scheduler unload, and
  retains the value-only smoke spawn record.
- `script/test_bullet_bill_object_bridge.sh` compiles the router and its Chain
  Chomp effect-record dependencies under strict Swift 6 concurrency.
- `tests/sm64_modern_bullet_bill_object_bridge_smoke.swift` verifies same-frame
  child traversal, routed deletion, and transient unload, then hashes the
  route outcome.
- `tests/sm64_modern_bullet_bill_object_bridge_contract.c` independently
  matches `bulletBillObjectBridgeFingerprint=0x98814f6acf3e0025`.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18ah-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18ah-build.log`.
- `git diff --check` passes.

These checks establish Bullet Bill smoke deletion routing and scheduler
ordering only. They do not establish router adoption across every bridge,
full collision resolution, runtime audio/renderer/camera presentation,
physical device acceptance, distribution, or human gameplay acceptance.

## Next slice

Continue the direct-deletion/effect audit across the remaining migrated
bridges, prioritizing transient children and projectiles, then consolidate
presentation intents into runtime audio/particle/camera owners. M19 may start
only after every spawned/despawned actor has a verified Swift-owned collision,
presentation, reward, and deletion delivery path.
