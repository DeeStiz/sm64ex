# Porting Handoff: SM64 Modern Full Swift Twin M17j

## Scope

M17j adds a deterministic owner-thread route replay over the live Swift
progression runtime and four-slot EEPROM adapter:

- Fresh image load records wipe/erase admission, then establishes a durable
  primary/backup image before replaying recovery.
- Primary checksum corruption is repaired through the backup decision path.
- Eight red coins, a cap switch, and a course-star reward run through the
  actor runtime; the reward is committed through the selected EEPROM slot.
- Death/game-over reload adopts the backup snapshot; cap relocation and
  warp/checkpoint requests run through the progression reducer and are
  committed/recorded at the owner boundary.
- A hidden-red-coin route lifetime accepts one activation, rejects a duplicate,
  increments generation, and accepts one deactivation. Records contain route
  ID, generation, acceptance, and canonical save/menu hashes.

This is a bounded Swift shadow/replay harness. The retained C engine remains
the gameplay/save differential authority; live C callback route closure,
Swift authority, object/effect ownership, and complete level-specific routes
remain open.

## Validation

- `script/test_progression_route_replay.sh` — Swift/C pass,
  `progressionRouteReplayFingerprint=0xad7e7c422bc9d0b8`.
- All `script/test_*.sh` scripts — `MATRIX_RESULT runs=102 failures=0`;
  log: `/tmp/sm64-modern-m17j-matrix-final.log`.
- Native Debug build with isolated DerivedData — `** BUILD SUCCEEDED **`;
  log: `/tmp/sm64-modern-m17j-build.log`.
- `git diff --check` — pass.

The evidence is deterministic source/build and Swift/C contract evidence. It
does not establish physical behavior, visual/audio review, controller feel,
signing/notarization, clean-machine validation, or human 120-star acceptance.

## Next slice

M18 should inventory common-enemy/projectile families against the behavior
dispatch table, choose one bounded family, and add a copied-POD Swift shadow
with exact object-list/owner-thread/effect ordering. Keep the C compatibility
selector and do not expose C object pointers to Swift.
