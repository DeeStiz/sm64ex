# Full Swift Twin M18ai Handoff

## Scope

M18ai adopts the common owner-thread effect router for Swoop's attack/death
path. The value kernel still decides the hitbox attack response; the bridge
now delivers the deletion intent before scheduler unload.

## Implementation

- `SM64Modern/SwoopObjectBridge.swift` owns the router, clears it per tick,
  enqueues Swoop deletion, delivers it before end-of-frame unload, and keeps
  hitbox/record synchronization on the owner thread.
- `script/test_swoop_object_bridge.sh` compiles the router and its Chain Chomp
  effect-record dependencies under strict Swift 6 concurrency.
- `tests/sm64_modern_swoop_object_bridge_smoke.swift` drives an attacked Swoop
  through routed deletion and hashes the delivery/unload outcome.
- `tests/sm64_modern_swoop_object_bridge_contract.c` independently matches
  `swoopObjectBridgeFingerprint=0x17a41c6388260d46`.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18ai-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18ai-build.log`.
- `git diff --check` passes.

These checks establish Swoop attack deletion routing and scheduler ordering
only. They do not establish router adoption across every bridge, full
collision resolution, runtime audio/renderer/camera presentation, physical
device acceptance, distribution, or human gameplay acceptance.

## Next slice

Continue the direct-deletion/effect audit across migrated enemy bridges,
prioritizing parent/child families and reward-bearing routes, then consolidate
presentation intents into runtime audio/particle/camera owners. M19 may start
only after every spawned/despawned actor has a verified Swift-owned collision,
presentation, reward, and deletion delivery path.
