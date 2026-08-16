# SM64 Modern Full Swift Twin — M23d Handoff

## Scope

M23d adds `SM64SaveFileMutator`, a pure Swift 6 value kernel for the C save
helpers that mutate flags, stars, cannons, lost-cap state, and menu sound
mode. It preserves the C secret-star `courseIndex == -1` sentinel, one-based
current-course cannon indexing, `SAVE_FLAG_FILE_EXISTS` restoration after
clear/move operations, unrelated cap-location bits, and checksum-ready
snapshots. The mutator is intentionally side-effect free: owner-thread dirty
bits, menu writes, EEPROM replacement, and timebase admission stay at the
existing persistence boundary.

M23a recovery/legacy upgrade, M23b read-only queries, and M23c owner-thread
copy/erase remain active. This is a value-contract slice, not proof that every
save call site has been switched to Swift authority.

## Evidence

- `script/test_save_file_mutator.sh` — Swift/C fingerprint
  `0x1aa5cef94856d8be`; flag set/clear, secret/course stars, cannon indexing,
  cap placement/relocation, sound-mode preservation, and encoded bytes agree.
- `script/test_progression_mutations.sh` — M23c owner-thread copy/erase
  fingerprint `0x33186d5894562d7b` remains green.
- `script/test_progression_eeprom.sh` — M23a recovery/legacy-upgrade
  fingerprint `0x3fac91b6c0a1f3cd` remains green.
- `script/test_progression_persistence.sh` — persistence-route fingerprint
  `0x40957bb3fcb92681` remains green.
- `script/test_save_file_queries.sh` — M23b query fingerprint
  `0x5562efafd48db61c` remains green.
- `xcodegen generate` plus isolated Swift 6 Debug `xcodebuild` —
  `/tmp/sm64-modern-m23d-build.log`, `BUILD SUCCEEDED`.
- The complete shebang-aware matrix —
  `/tmp/sm64-modern-m23d-final-matrix.log`, `runs=209 failures=0`.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` — no matches.
- `git diff --check` — clean for the M23d patch.

## Remaining work

1. Route each owner-thread flag/star/cannon/cap/sound call through the value
   kernel while preserving C dirty-bit, menu-write, and legacy-timebase order.
2. Add bidirectional Swift-to-C-to-Swift and C-to-Swift-to-C replay traces for
   every save mutation, restart-required selector, and corruption branch.
3. Continue M22 behavior coverage: 453 reachable behavior rows remain
   explicit C adapters after M22bc.
4. Continue M24–M35 configuration, HUD/front-end, audio, rendering,
   whole-engine authority, parity shards, Metal 4 production, distribution,
   and physical/visual/human acceptance.

## Next command

Begin the next bounded M23 owner-thread save slice from this handoff. Keep the
independent C contract and the 209-script matrix as exit gates, regenerate the
Xcode project after every new Swift source file, and preserve unrelated
working-tree edits.
