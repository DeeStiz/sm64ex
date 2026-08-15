# Porting Handoff: SM64 Modern Full Swift Twin M17h

## Scope

M17h closes the persistence-side event coverage of the M17g progression bridge
while keeping the retained C engine authoritative:

- `save_file.c` now publishes normalized 56-byte `SaveFile` and 32-byte
  `MainMenuSaveData` snapshots on the owner thread. The serializer writes
  explicit little-endian fields and recomputes canonical magic/checksum bytes,
  so Swift can decode a stable representation at any C mutation boundary.
- Erase, copy, flag, star, cannon, cap, and menu mutations emit the versioned
  `SM64_MODERN_PROGRESSION_EVENT_SAVE_MUTATION` callback with an operation flag.
  Invalid event kinds latch the migration status and fail the lifecycle tick.
- `SwiftProgressionMigrationService` reads and decodes the C snapshot before
  persist and reload, adopts it into `SM64ProgressionRuntime`, then commits the
  reconciled bundle through the owner-thread adapter. Actor events record a
  post-mutation canonical snapshot, preserving secret-star high bits, cap
  fields, course stars, coin scores, sound mode, and backup recovery.
- The Swift codec now persists the seven-bit secret-star count in the high save
  flags byte, and secret-star events no longer require a course index.

This is a shadow/differential bridge. C remains the gameplay and save authority;
Swift authority cutover, object ownership, EEPROM adapters, effect delivery,
and complete level-specific routes are deliberately still open.

## Validation

- `script/test_progression_migration.sh` — pass,
  `progressionMigrationFingerprint=0x5f56c0c4d6b0e8b1`.
- `script/test_progression_runtime.sh` — pass,
  `progressionRuntimeFingerprint=0x882867d4029082ed`.
- `script/test_save_file_codec.sh` — pass,
  `saveFileCodecFingerprint=0xafb06a603bb2d418`.
- All `script/test_*.sh` scripts — `MATRIX_RESULT runs=100 failures=0`;
  log: `/tmp/sm64-modern-m17h-matrix.log`.
- Native Debug build with isolated DerivedData — `** BUILD SUCCEEDED **`;
  log: `/tmp/sm64-modern-m17h-build.log`.
- `git diff --check` — pass.

These checks establish deterministic source/build and C/Swift contract parity.
They do not establish physical-device behavior, visual or audio review,
controller feel, distribution signing/notarization, clean-machine behavior, or
human 120-star acceptance.

## Next slice

M17i should add an owner-thread replay fixture that drives fresh-save, wipe,
checksum-recovery, death/reload, warp, cap-loss, and level-reward routes through
the live bridge and checks the schema-4 save-domain trace. It should then fence
object ownership and surface the endian-aware EEPROM adapter contract before
M18 begins common-enemy migration. Keep the C compatibility selector and the
single-owner-thread boundary intact.
