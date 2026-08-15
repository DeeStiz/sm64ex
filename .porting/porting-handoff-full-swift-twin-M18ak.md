# Full Swift Twin M18ak Handoff

## Scope

M18ak routes Spiny distance/unload deletion through the common owner-thread
effect router and repairs the strict Enemy Lakitu composite harness to include
the router's type dependencies. Lakitu parent links and thrown/landed state
remain unchanged.

## Implementation

- `SM64Modern/SpinyObjectBridge.swift` owns the router, clears it per tick,
  enqueues Spiny deletion, delivers it before scheduler unload, and preserves
  the parent-relative record boundary.
- `script/test_spiny_enemy.sh` and
  `script/test_enemy_lakitu_object_bridge.sh` compile the router and its Chain
  Chomp effect-record dependencies under strict Swift 6 concurrency.
- `tests/sm64_modern_spiny_enemy_smoke.swift` verifies routed distance unload
  and hashes the outcome.
- `tests/sm64_modern_spiny_enemy_contract.c` independently matches
  `spinyEnemyFingerprint=0xf7737180e4f09b3f`.

## Validation evidence

- Focused strict Swift 6/C validation passes for Spiny and Enemy Lakitu.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18ak-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18ak-build.log`.
- `git diff --check` passes.

These checks establish Spiny deletion routing and composite harness closure
only. They do not establish router adoption across every bridge, full
collision resolution, runtime audio/renderer/camera presentation, physical
device acceptance, distribution, or human gameplay acceptance.

## Next slice

Continue the direct-deletion/effect audit across remaining parent/child
bridges, then consolidate presentation intents into runtime audio/particle/
camera owners. M19 may start only after every spawned/despawned actor has a
verified Swift-owned collision, presentation, reward, and deletion delivery
path.
