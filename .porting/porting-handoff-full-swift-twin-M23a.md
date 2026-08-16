# SM64 Modern Full Swift Twin — M23a Handoff

## Scope

M23a closes the first save-system authority gap in the normalized Swift
EEPROM adapter. `SM64OwnerThreadEEPROMAdapter.load` now mirrors the C
`save_file_load_all` recovery boundary: a valid primary repairs its invalid
backup, a valid backup repairs its invalid primary, and two invalid copies are
replaced with the encoded wipe default. The shared menu pair follows the same
policy. The replacement is one atomic 512-byte image write, and all external
file access remains protected by the engine token and construction pthread.

The adapter also upgrades a valid legacy 176-byte M17 bundle to the normalized
512-byte image on the first owner-thread load. This is persistence parity only;
save mutation breadth, options, restart-selector parity, and whole-engine save
authority remain open.

## Evidence

- `script/test_progression_eeprom.sh` — Swift/C fingerprint
  `0x3fac91b6c0a1f3cd`; legacy upgrade, one-bad-copy repair, and post-repair
  primary/backup verification pass.
- `script/test_progression_persistence.sh` — legacy bundle recovery and route
  lifetime regression pass with Swift/C fingerprint
  `0x40957bb3fcb92681`.
- `tests/sm64_modern_progression_eeprom_contract.c` — independent C repair
  assertions verify both save and menu copies after the recovery decision.
- `git diff --check` — clean for the milestone patch.

## Remaining work

1. Finish M23 save mutation coverage: erase/copy, coin-score ages, key/cap
   flags, options, restart-required selector behavior, and full
   Swift-to-C-to-Swift byte-identity traces.
2. Continue M22 behavior coverage separately; 453 reachable behavior rows are
   still explicit C adapters after M22bc, and no compatibility exception has
   been approved for them.
3. Continue M24–M35: configuration, HUD/front-end, audio, display-list and
   Goddard rendering, whole-engine authority, parity-shard closure, Metal 4
   production evidence, distribution, and human acceptance.

## Next command

Run the save mutation inventory against `save_file.c` and
`SM64ProgressionRuntime`, select the next source-backed mutation seam, add a
Swift reducer plus independent C contract, then rerun both progression smoke
tests, the regenerated native Swift 6 build, the shebang-aware full matrix,
strict-concurrency audit, and `git diff --check` before committing.
