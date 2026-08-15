# Porting Handoff: SM64 Modern Full Swift Twin M17i

## Scope

M17i gives the live progression bridge a C-shaped EEPROM image instead of a
single-save fixture:

- `SM64PersistenceImage` is a normalized 512-byte image containing four
  primary 56-byte SaveFiles, four backup SaveFiles, and shared primary/backup
  32-byte MainMenuData blocks.
- `SM64OwnerThreadEEPROMAdapter` selects an explicit save-file index for
  persist, load, and game-over reload. A commit updates the selected save and
  shared menu blocks and replaces the complete image atomically on the owner
  thread.
- The adapter accepts a legacy 176-byte `SM64PersistenceBundle` as slot zero
  when the new image is absent; the next commit upgrades it without changing
  the checksum codecs.
- `SwiftProgressionMigrationService` now uses this adapter and passes the C
  event's save-file index through every persist/reload boundary.

C remains gameplay/save authority. This slice does not claim Swift authority,
object/effect ownership, or full level-route coverage.

## Validation

- `script/test_progression_eeprom.sh` — Swift/C pass,
  `progressionEEPROMFingerprint=0x3fac91b6c0a1f3cd`; the smoke covers two
  slots, shared menu state, primary corruption recovery, menu corruption
  recovery, backup reload, and legacy-bundle upgrade.
- All `script/test_*.sh` scripts — `MATRIX_RESULT runs=101 failures=0`;
  log: `/tmp/sm64-modern-m17i-matrix.log`.
- Native Debug build with isolated DerivedData — `** BUILD SUCCEEDED **`;
  log: `/tmp/sm64-modern-m17i-build.log`.
- `git diff --check` — pass.

These are deterministic source/build and C/Swift contract gates. Physical
behavior, visual/audio review, controller feel, signing/notarization,
clean-machine validation, and human 120-star acceptance remain external gates.

## Next slice

M17j should add an owner-thread route replay fixture that drives fresh-save,
wipe, checksum recovery, death/reload, warp, cap-loss, and level-reward routes
through the same Swift runtime/adapter composition, with explicit route
identity/generation fencing and stable schema-4 event coverage. Then begin M18
common-enemy migration without exposing the legacy C object graph to Swift.
