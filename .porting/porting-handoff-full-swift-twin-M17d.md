# Porting Handoff: SM64 Modern Full Swift Twin M17d

## Scope

M17d adds `SM64Modern/ProgressionActors.swift`, a Swift-owned actor boundary
for the product-reachable progression routes that sit above save mutation:

- Eight red coins increment the progression coin count by C's value two,
  advance the hidden-star counter, and emit a spawn-star/cutscene intent on
  the eighth collection.
- Cap-switch indices 0, 1, and 2 map to wing, metal, and vanish flags; repeat
  presses are rejected and successful presses set file-exists/save state.
- Level-completion rewards delegate to `SM64ProgressionReducer`, preserving
  star/coin/key mutation and returning reward/cutscene intents.
- All routes are value-only and return owner-thread effects; they do not call
  object, camera, audio, or legacy save globals.

## Validation

- `script/test_progression_actors.sh` — matching Swift/C fingerprint
  `0x472c41ec2f9f343c`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- `git diff --check`.

## Boundary notes

- The actor boundary does not yet own object spawn/despawn, red-coin parent
  discovery, hidden-star marker lifetime, or per-level route identity.
- Cutscene, camera, dialog, audio, rumble, and render values are intents only;
  owner-thread delivery remains open.
- Durable two-slot persistence and EEPROM endian/I/O remain separate from the
  deterministic reducer/codec layer.
- Local build/test evidence does not establish physical input feel, visual
  parity, store, or human acceptance.

## Next slice

M17e should add route identity and object-lifetime schemas for hidden red-coin
stars and cap-switch actors, then add an owner-thread persistence adapter that
commits the M17b/M17c codecs atomically and publishes save oracle events.
