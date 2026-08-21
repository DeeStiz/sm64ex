# Full Swift Twin Handoff — Phase 20 C/Swift Pairing Audit

Date: 2026-08-20

## Result

The current independent lifecycle/live-route captures remain non-admissible.
The new gate records that boundary explicitly, then proves the admission
contract on one bounded common-input window. The probe is contract evidence
only; it does not promote a route shard or alter the route ledger.

## Current capture audit

`./script/test_c_swift_pairing.sh` freshly regenerated and audited:

```
pairing_audit admitted=0 c_records=3151 swift_records=1 c_ticks=5 swift_ticks=1 blockers=build_fingerprint,configuration_fingerprint,content_fingerprint,coverage_deferred,initial_save_fingerprint,record_bytes,record_count,timebase_fingerprint,trace_bytes
```

The C capture is the independent canonical schema-4 lifecycle recorder. Its
header still has zero build/content/timebase/configuration/initial-save and
coverage fingerprints and contains five 30/30 lifecycle ticks. The independent
Swift input-only capture has one 60/30-normalized input record and its own
hard-coded fingerprints. The two files therefore cannot admit the existing
live route row.

## Bounded common-input probe

`tests/sm64_modern_c_swift_pairing_record.c` independently records and replays
one canonical input-domain record. The Swift peer in
`tests/sm64_modern_c_swift_pairing_smoke.swift` independently derives the same
record from the same raw sample and writes a canonical schema-4 file. Both use
the same explicit 60/30, ratio-two, max-catch-up-two timebase and nonzero
coverage fingerprint for `(domain=1, record_id=1)`.

The fresh gate proves:

- C and Swift files are byte-identical (`72 + 128 = 200` bytes) with matching
  schema, build, content, timebase, configuration, initial-save, and coverage
  fingerprints.
- Per-domain tick/sequence ordering and exact record values match.
- The C oracle replays both the C-written and Swift-written files with one
  matched record and one coverage entry.
- Swift rejects a mutated canonical hash, and C rejects replay of the same
  tampered file.

The bounded probe is reported as `bounded_common_input_admitted=1`; this is not
route-shard admission. The route boundary remains
`current_route_shard_admitted=0`.

## Changed files

- `script/test_c_swift_pairing.sh`
- `tests/sm64_modern_c_swift_pairing_record.c`
- `tests/sm64_modern_c_swift_pairing_smoke.swift`
- `.porting/porting-handoff-full-swift-twin-phase20-c-swift-pairing.md`

## Validation

- `./script/test_c_swift_pairing.sh` — passed; includes native C compile,
  strict Swift 6 compile, fresh current-capture audit, exact byte comparison,
  C replay, Swift tamper rejection, and C tamper rejection.
- `bash -n script/test_c_swift_pairing.sh` — passed.
- `git diff --check` — passed.

## Remaining blockers

No route row is admitted from this phase. A future route admission still needs
the actual same build/content/configuration/initial-save/timebase inputs and
aligned independent C and Swift lifecycle windows over the route's complete
schema-4 coverage. The one-record common-input probe does not establish full
gameplay, rendering, audio, save, device, performance, or human parity.
