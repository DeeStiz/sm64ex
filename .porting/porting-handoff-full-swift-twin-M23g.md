# SM64 Modern Full Swift Twin — M23g Handoff

## Scope

M23g extends the C progression event payload so `SAVE_MUTATION` callbacks carry
operation (set/clear), source slot, flags, course/star operands, cannon course,
cap level/area/coordinates, and sound mode. Every native save helper emits its
exact operands. Swift migration initialization seeds the normalized EEPROM
shadow from canonical C bytes; each payload is replayed through the normalized
adapter and compared byte-for-byte with the post-event C snapshot, latching
`PARITY_DIVERGED` on mismatch. Copy/erase and set/clear/mutation order stay
owner-thread and atomic.

This is shadow parity, not yet production Swift save authority; restart
selector authority and durable bidirectional replay artifacts remain open.

## Evidence

- `./script/test_progression_migration.sh` — payload assertions,
  `progressionMigrationFingerprint=0x5f56c0c4d6b0e8b1`.
- `xcodegen generate` plus Swift 6 Debug `xcodebuild` —
  `/tmp/sm64-modern-m23g-build.log`, `BUILD SUCCEEDED`.
- Complete shebang-aware matrix —
  `/tmp/sm64-modern-m23g-final-matrix-final.log`, `runs=211 failures=0`.
- `rg -n '@unchecked[[:space:]]+Sendable' SM64Modern` — no matches.
- `git diff --check` — clean for the M23g patch.

## Remaining work

1. Add restart-required selector payload/authority and persistent bidirectional
   C↔Swift replay artifacts.
2. Switch production save authority only after event replay and dirty/commit
   parity prove identical across all slots and recovery branches.
3. Continue M22: 453 reachable behavior rows remain explicit C adapters after
   M22bc.
4. Continue M24–M35: configuration, HUD/front end, audio, rendering, input,
   filesystem/network, platform shell, lifecycle, performance, packaging,
   and physical/visual/human acceptance.

## Next command

Begin M23h with restart-selector payload/authority and durable replay artifacts.
Preserve the normalized adapter, independent C contract, 211-script matrix,
project regeneration, and unrelated working-tree edits.
