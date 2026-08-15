# Porting Handoff: SM64 Modern Full Swift Twin M17f

## Scope

M17f adds `SM64Modern/ProgressionRuntime.swift`, which composes the M17 actor,
menu-age, codec, and persistence boundaries on the owner thread.

- Actor events advance progression and high-score ages in C order; ages change
  only when a course score beats the saved score.
- Runtime results carry actor/progression effects, dirty/persistence admission,
  and deterministic event values suitable for schema-4 save/event records.
- `commitIfNeeded` emits one atomic four-slot bundle and clears dirty state only
  after the write succeeds.
- `reloadFromBackup` restores persisted save fields, resets transient actor
  route state, and leaves non-persisted runtime counters under caller policy.

## Validation

- `script/test_progression_runtime.sh` — matching Swift/C fingerprint
  `0x882867d4029082ed`.
- Swift 6 strict-concurrency focused compilation and independent C contract.
- `git diff --check`.

## Boundary notes

- The runtime is not yet installed in `EngineHost`/`GameplayTick`; no live
  game frame currently dispatches actor events through it.
- Schema-4 oracle records are represented as deterministic values but are not
  yet emitted through `sm64_modern_oracle_trace_record`.
- EEPROM endian detection, physical I/O retries, object lifetime callbacks,
  camera/dialog/audio delivery, and full level-route coverage remain open.
- Local build/test evidence does not establish physical input feel, visual
  parity, store, or human acceptance.

## Next slice

M17g should install this runtime in the owner-thread `EngineHost`/gameplay tick,
emit save/event records into the schema-4 oracle when active, and add a replay
fixture covering collect, reward, commit, corruption repair, death reload, and
warp boundaries.
