# Full Swift Twin M18aj Handoff

## Scope

M18aj adopts the common owner-thread effect router for Goomba regular and
triplet-child deletion. Respawn requests and parent dead flags remain ordered
value records, while mutable child removal crosses the router before the
scheduler unload pass.

## Implementation

- `SM64Modern/GoombaObjectBridge.swift` owns the router, clears it per tick,
  routes regular death and parent-unloaded triplet-child deletion, and keeps
  respawn bookkeeping on the owner thread.
- `script/test_goomba_object_bridge.sh` compiles the router and its Chain
  Chomp effect-record dependencies under strict Swift 6 concurrency.
- `tests/sm64_modern_goomba_object_bridge_smoke.swift` verifies routed regular
  death and triplet-child unload while preserving respawn/parent flags, then
  hashes the route outcomes.
- `tests/sm64_modern_goomba_object_bridge_contract.c` independently matches
  `goombaObjectBridgeFingerprint=0xf2f6f39a90915ec3`.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18aj-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18aj-build.log`.
- `git diff --check` passes.

These checks establish Goomba deletion routing and scheduler/respawn ordering
only. They do not establish router adoption across every bridge, full
collision resolution, runtime audio/renderer/camera presentation, physical
device acceptance, distribution, or human gameplay acceptance.

## Next slice

Continue the direct-deletion/effect audit across Spiny and the remaining
parent/child bridges, then consolidate presentation intents into runtime
audio/particle/camera owners. M19 may start only after every spawned/despawned
actor has a verified Swift-owned collision, presentation, reward, and deletion
delivery path.
