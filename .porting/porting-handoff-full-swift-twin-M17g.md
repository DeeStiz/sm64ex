# Porting Handoff: SM64 Modern Full Swift Twin M17g

## Scope

M17g installs the Swift progression shadow at the live C boundaries while the
C engine remains the gameplay authority:

- `SwiftProgressionMigrationService` is retained by `EngineHost` on the owner
  thread, loads the atomic Swift bundle, and installs a versioned C callback
  only for Swift authority.
- Save load/persist/reload, red coins, cap switches, and level rewards now
  enter `SM64ProgressionRuntime`; invalid events or persistence failures latch
  a status and fail the C lifecycle tick.
- Schema-4 oracle sessions receive deterministic save-domain event and
  save-byte records, with existing save inventory coverage marks. C
  compatibility mode does not install the bridge.
- The C ABI adds an explicit progression event contract and standalone smoke;
  the native source wildcard includes the bridge in the core archive.

## Validation

- `script/test_progression_migration.sh` —
  `progressionMigrationFingerprint=0x5f56c0c4d6b0e8b1`.
- `script/test_progression_runtime.sh` —
  `progressionRuntimeFingerprint=0x882867d4029082ed`.
- Full `script/test_*.sh` matrix: `runs=100 failures=0`.
- `xcodegen generate` and native macOS Debug build:
  `/tmp/sm64-modern-m17g-build.log`, `** BUILD SUCCEEDED **`.
- `git diff --check`.

## Boundary notes

- This is a differential shadow, not the final Swift gameplay authority: C
  still mutates the canonical save/object graph and the Swift bundle is not
  yet byte-sourced from every C save mutation.
- EEPROM endian detection/I/O, object ownership/spawn/despawn, hidden-star
  identity, dialog/camera/audio/effect delivery, and complete level-specific
  routes remain open.
- Build, focused contracts, and the script matrix do not prove physical input
  feel, visual parity, device behavior, distribution, or human acceptance.

## Next slice

M17h should make the bridge event-complete: add mutation snapshots for erase,
copy, flags, cannon, cap, doors, checkpoints, and warp; reconcile C bytes into
the Swift bundle at load/persist boundaries; and add an owner-thread replay
fixture for fresh-save, recovery, death reload, and level reward routes before
M18 enemy migration.
