# Full Swift Twin M18ae Handoff

## Scope

M18ae adopts the common owner-thread effect router for the bouncing-fireball
parent/flame bridge. Deletion is now represented as a sequenced intent and
delivered before the scheduler's end-of-frame unload, preserving the C
ordering while removing the bridge's direct deletion mutation.

## Implementation

- `SM64Modern/BouncingFireballObjectBridge.swift` owns an
  `SM64OwnerThreadEffectRouter`, clears it at each tick, enqueues parent/flame
  deletion intents, and records delivery results for the owner-thread trace.
- `script/test_bouncing_fireball.sh` compiles the router and its Chain Chomp
  type dependencies under strict Swift 6 concurrency.
- `tests/sm64_modern_bouncing_fireball_smoke.swift` exercises the parent
  deletion fence through the router and hashes the delivery/unload outcome.
- `tests/sm64_modern_bouncing_fireball_contract.c` independently matches
  `bouncingFireballFingerprint=0x6ad7b0bf4304989e`.

## Validation evidence

- Focused strict Swift 6/C validation passes.
- Full `script/test_*.sh` matrix passes with `runs=131 failures=0`; log:
  `/tmp/sm64-modern-m18ae-matrix.log`.
- `xcodegen generate --spec project.yml` regenerated the project and the
  native macOS arm64 Debug build succeeds; log:
  `/tmp/sm64-modern-m18ae-build.log`.
- `git diff --check` passes.

These checks establish fireball deletion routing and scheduler ordering only.
They do not establish router adoption across every bridge, full collision
resolution, runtime audio/renderer/camera presentation, physical device
acceptance, distribution, or human gameplay acceptance.

## Next slice

Apply the router to another migrated projectile/enemy bridge, then audit every
remaining direct pool deletion and effect mutation in M18. M19 may start only
after all spawned/despawned actors have verified Swift-owned collision,
presentation, reward, and deletion delivery paths.
