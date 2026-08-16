# SM64 Modern Full Swift Twin — M23c Handoff

## Scope

M23c adds owner-thread `copy` and `erase` operations to
`SM64OwnerThreadEEPROMAdapter`. They mirror the C order in
`save_file_copy`/`save_file_erase`: validate the destination, touch all
destination high-score ages first, then copy a source SaveFile or clear the
destination SaveFile, recompute C checksums, and atomically replace both save
copies and the shared menu pair. Sound mode and filler bytes survive the menu
mutation. Recovery repair runs before either operation, so corrupt unrelated
slots cannot remain hidden behind a selected-file operation.

M23a recovery/legacy upgrade and M23b read-only query parity remain active.
Flag/star/cannon/cap/sound mutators, full save-image replay, and restart
selector authority are still open.

## Evidence

- `script/test_progression_mutations.sh` — Swift/C complete-image fingerprint
  `0x33186d5894562d7b`; copy destination, erase zero-save, age-touch order,
  menu preservation, checksums, and backup equality pass.
- `script/test_progression_eeprom.sh` — recovery/legacy-upgrade regression
  remains green with fingerprint `0x3fac91b6c0a1f3cd`.
- `script/test_progression_persistence.sh` — legacy bundle/route regression
  remains green with fingerprint `0x40957bb3fcb92681`.
- `script/test_save_file_queries.sh` — M23b query fingerprint
  `0x5562efafd48db61c` remains green.
- `xcodegen generate` plus isolated Swift 6 Debug `xcodebuild` —
  `/tmp/sm64-modern-m23b-build.log`, `BUILD SUCCEEDED` before this
  persistence-only source addition; a fresh M23c build is required before
  commit.
- The next full matrix must use each script's declared interpreter and should
  report 208 runs with zero failures after the new mutation script is present.

## Remaining work

1. Add exact flag/star/cannon/cap-location and sound-mode mutators, including
   dirty-bit and menu-write ordering.
2. Add Swift-to-C-to-Swift and C-to-Swift-to-C replay traces for every save
   mutation and restart-required selector choice.
3. Continue M22 behavior coverage: 453 reachable behavior rows remain
   explicit C adapters after M22bc.
4. Continue M24–M35 configuration, HUD/front-end, audio, rendering,
   whole-engine authority, parity shards, Metal 4 production, distribution,
   and human acceptance.

## Next command

Run the fresh M23c native build and 208-script matrix. If green, commit this
handoff and proceed with the next source-backed mutator family, preserving the
owner-thread token and independent C fingerprint gates.
