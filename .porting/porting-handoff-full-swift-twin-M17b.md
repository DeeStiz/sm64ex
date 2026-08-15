# Porting Handoff: SM64 Modern Full Swift Twin M17b

## Scope

M17b adds `SM64Modern/SaveFileCodec.swift`, a C SaveFile-compatible snapshot
codec around the M17a progression state.

- The 56-byte field order matches `struct SaveFile`: cap location, flags, 25
  course-star bytes, 15 course coin scores, magic, and checksum.
- Little-endian read/write and the C literal 16-bit byte sum are deterministic;
  EEPROM byte-swapping remains a separate platform adapter.
- Primary/backup recovery returns explicit use-primary, use-backup, rewrite,
  or erase intents without performing I/O.

## Validation

- `script/test_save_file_codec.sh` — matching Swift/C fingerprint
  `0xafb06a603bb2d418`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- `xcodegen generate`, the full script matrix, and the native macOS Debug
  build are required before the local checkpoint.
- `git diff --check`.

## Boundary notes

- This is not yet atomic platform persistence: menu-data slots, EEPROM endian
  conversion, file locking, durable writes, and full load/reload orchestration
  remain open.
- Codec recovery selects immutable snapshots; an owner-thread/platform service
  must perform rewrite/erase and publish save oracle events.
- Local build/test evidence does not establish physical input feel, visual
  parity, store, or human acceptance.

## Next slice

M17c should add menu-data/coin-score ages and an atomic two-slot persistence
adapter, then route red-coin, cap-switch, and level-completion actors through
the M17a reducer and M17b codec.
