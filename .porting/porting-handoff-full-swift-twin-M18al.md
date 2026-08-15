# Full Swift Twin M18al Handoff

## Scope

M18al adopts the common owner-thread effect router for Boo and Whomp actor
deletion. The focused bridge tests now force each actor through its real
value-kernel death path and verify that the stable object ID is delivered to
the owner-thread pool before end-of-frame scheduler unload.

## Implementation

- `SM64Modern/BooObjectBridge.swift` owns a router and delivery log, begins a
  fresh route sequence per tick, and routes Boo attack/death deletion through
  `.markForDeletion` instead of mutating the pool directly.
- `SM64Modern/WhompObjectBridge.swift` applies the same boundary for normal
  Whomp pound/fall/on-ground/death behavior; King Whomp state and presentation
  records remain value-only.
- `script/test_boo_object_bridge.sh` and
  `script/test_whomp_object_bridge.sh` compile the shared router plus its
  Chain Chomp effect-record dependencies under strict Swift 6 concurrency.
- `tests/sm64_modern_boo_object_bridge_smoke.swift` and
  `tests/sm64_modern_whomp_object_bridge_smoke.swift` assert routed delivery
  and scheduler unload while preserving the independent C fingerprints:
  `booObjectBridgeFingerprint=0x7505d05143270ec7` and
  `whompObjectBridgeFingerprint=0x672073b350af199a`.

## Validation evidence

- Focused strict Swift 6/C validation passes for Boo and Whomp.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18al-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18al-build.log`.
- `git diff --check` passes.

These checks establish Boo/Whomp deletion routing and scheduler ordering only.
They do not establish router adoption across every bridge, full collision
resolution, runtime audio/renderer/camera presentation, physical device
acceptance, distribution, or human gameplay acceptance.

## Next slice

Continue the direct-deletion/effect audit across the remaining parent/child
bridges, then make routed presentation intents consumable by the runtime audio,
particle, camera, reward, and render owners. M19 may start only after every
spawned/despawned actor has a verified Swift-owned collision, presentation,
reward, and deletion delivery path.
