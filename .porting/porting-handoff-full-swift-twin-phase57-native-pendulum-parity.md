# Full Swift Twin Handoff — Phase 57 Native Castle Pendulum Parity

Date: 2026-08-21

## Scope and verdict

Phase 57 repaired the concrete native schema-4 object-domain gap for Castle
actors without changing the legacy schema-3 subsystem selector. The opt-in
Castle Inside area-2 capture is now a bounded 64-step route, publishes six
nonzero native run/header fingerprints, and retains object snapshots for the
real pendulum at pool slot 37.

The route remains **blocked** and promotion was not attempted. The native
pendulum reaches the real ±0x10 velocity threshold window, but the native
sound gateway correctly emits no effect because the owner route leaves Mario
in room 1 while the pendulum is in room 5. Producing a sound record by
forcing room/render state or calling the sink directly would fabricate route
evidence, so no such workaround was added.

## Native Castle area-2 capture

The fresh bounded lifecycle output was:

```text
castleArea2Loaded=1 castleArea2PendulumSlot=37 castleArea2NativeRecords=31
castleArea2ObjectStateRecords=64 castleArea2SoundRecords=0
castleArea2ClockSoundRecords=0 castleArea2Roll=1240 castleArea2Velocity=-224
castleArea2MarioRoom=1 castleArea2ObjectRoom=5 castleArea2GraphFlags=0x20
castleArea2HeaderBuild=0x8ba7fd2e73846564
castleArea2HeaderContent=0x8dd5f4044e87a91a
castleArea2HeaderTimebase=0xccc19787cd09f0c2
castleArea2HeaderConfiguration=0x46dc724f0ae51d36
castleArea2HeaderInitialSave=0x3c6297ee7c18e62d
castleArea2HeaderCoverage=0xafa8759562c1663f
liveOracleTraceRecords=51875 liveOracleTraceTicks=65
liveOracleTraceDomains=0x00001fff liveOracleCoverageEntries=76
```

`castleArea2ObjectStateRecords=64` is counted from real schema-4 object-domain
state records for actor field 400 at slot 37. `castleArea2ClockSoundRecords=0`
is an explicit blocker, not a filtered or substituted record. The default
lifecycle smoke remains unchanged and passed with its historical five-tick
trace.

## Pairing result

`./script/test_castle_area2_pendulum_pair.sh` passed its fail-closed route
checks after the 64-tick extension. The pair tool reported:

```text
native_slot=37 swift_subject=1
native_records=1059 swift_records=1095
native_domains=3,6,7 swift_domains=3,6,7,12
required_domains=3,6,7,12 missing_native=12 missing_swift=
matched_records=701 canonical_records_native=1059 canonical_records_swift=1095
tamper_rejected=1 schema4_replay_round_trip=1
independent_c_swift_pair=0 exact_bytes=0 promotion=not_attempted canonical_route_admission=0
first_divergence=record_mismatch c={tick=1 domain=3 sequence=0 kind=1 subject=37 record=400 flags=0 values=[0xffffffffffa9eab0]} swift={tick=1 domain=3 sequence=0 kind=1 subject=37 record=400 flags=0 values=[0x006268765f647065]}
```

The six native header values are carried into the blocked worker result and
merge artifact. They are nonzero but do not equal the Swift source recipe's
header values, so the pair remains non-admissible. Worker/merge, tamper,
schema-4 replay, and persistent rerun fences all remained fail-closed.

## Files changed

- `src/pc/sm64_modern_gameplay_parity.c` — schema-4-only Castle object-domain
  snapshot routing; schema-3 GLOBAL authority behavior is unchanged.
- `tests/sm64_modern_oracle_lifecycle_record.c` — bounded 64-step Castle route,
  nonzero route headers/coverage finalization, slot-37 object/effect counters,
  and exact room/effect evidence.
- `script/test_castle_area2_pendulum_pair.sh` — 64-tick Swift source window,
  blocked missing-effect expectations, and native header propagation into the
  worker result.
- `.porting/porting-handoff-full-swift-twin-phase57-native-pendulum-parity.md`
  — this handoff.

## Validation

Passed:

- strict native-core rebuild after the parity change;
- `./script/test_oracle_lifecycle_record.sh` (default route);
- `SM64_MODERN_AUTOMATED_CASTLE_AREA2=1 ./script/test_oracle_lifecycle_record.sh`;
- `./script/test_castle_area2_pendulum_pair.sh` (blocked, no promotion);
- shell syntax checks and `git -c core.fsmonitor=false diff --check`.

The exact remaining unblock is a real owner-thread room-transition route that
places Mario in the pendulum's room and produces the native effect-domain
sound record, followed by matching native behavior identity, header
fingerprints, and complete C/Swift records. No route ledger or promotion state
was changed and no commit was created.
