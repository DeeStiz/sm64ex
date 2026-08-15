# Full Swift Twin M18af Handoff

## Scope

M18af adopts the common owner-thread effect router for Snufit's bowling-ball
projectile child. The existing wall/ground death decision remains in the
value kernel, while the mutable deletion and end-of-frame unload now cross a
sequenced owner-thread boundary.

## Implementation

- `SM64Modern/SnufitObjectBridge.swift` owns the router, clears it per tick,
  enqueues bullet deletion, delivers it before scheduler unload, and records
  the delivery result.
- `script/test_snufit_object_bridge.sh` compiles the router and its Chain
  Chomp effect-record dependencies under strict Swift 6 concurrency.
- `tests/sm64_modern_snufit_object_bridge_smoke.swift` drives a spawned
  bowling-ball child into wall death and hashes the routed deletion/unload
  result.
- `tests/sm64_modern_snufit_object_bridge_contract.c` independently matches
  `snufitObjectBridgeFingerprint=0xf6221010ed5e3f78`.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18af-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18af-build.log`.
- `git diff --check` passes.

These checks establish Snufit bullet deletion routing and scheduler ordering
only. They do not establish router adoption across every bridge, full
collision resolution, runtime audio/renderer/camera presentation, physical
device acceptance, distribution, or human gameplay acceptance.

## Next slice

Apply the router to another migrated projectile/enemy bridge and audit all
remaining direct pool deletion/effect mutations in M18. M19 may start only
after every spawned/despawned actor has a verified Swift-owned collision,
presentation, reward, and deletion delivery path.
