# Porting Handoff: SM64 Modern Full Swift Twin M17c

## Scope

M17c adds `SM64Modern/CoinScoreAges.swift`, a value-only counterpart to the C
`touch_coin_score_age` and `touch_high_score_ages` routines plus a
C-compatible `MainMenuSaveData` codec.

- Four 32-bit age words use two bits per each of the 15 course stages.
- Wipe defaults, current-age ordering, zero-age no-ops, and sticky modified
  state match the C menu-data mutation path.
- The 32-byte US menu-data field order is encoded little-endian: four age
  words, sound mode, ten filler bytes, magic, and checksum.
- Recovery returns explicit primary/backup repair intents without performing
  EEPROM or filesystem I/O.

## Validation

- `script/test_coin_score_ages.sh` — matching Swift/C fingerprint
  `0x53abace051c99cff`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- The M17b 95-script matrix and native Debug build remain green before this
  checkpoint; run the full matrix again after project regeneration.
- `git diff --check`.

## Boundary notes

- This is still a deterministic codec/reducer boundary, not durable platform
  persistence: EEPROM reads/writes, endian detection, locking, fsync/atomic
  replacement, and save-oracle event publication remain open.
- Red-coin collection, cap-switch actor ownership, level-completion reward
  routing, dialog/camera/audio delivery, and full load/reload orchestration
  remain open M17 work.
- Local build/test evidence does not establish physical input feel, visual
  parity, store, or human acceptance.

## Next slice

M17d should add Swift-owned red-coin/cap-switch/level-completion actor schemas
and reducers, then compose their reward intents with the progression and save
codecs before introducing a durable owner-thread persistence adapter.
