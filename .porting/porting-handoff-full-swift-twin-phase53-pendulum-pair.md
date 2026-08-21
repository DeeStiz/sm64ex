# Full Swift Twin Handoff — Phase 53 Castle Area-2 Pendulum Pair

Date: 2026-08-21

## Scope and verdict

Phase 53 ran the real native Castle Inside area-2 owner route added by Phase
52, decoded its schema-4 trace, paired it with the Phase 46 source-backed
Swift recipe, and failed closed. No promotion tool was invoked and no route
ledger was changed.

The native lifecycle selected the compiled `LEVEL_CASTLE` script, completed
the normal area transition, and reported the actual decorative-pendulum pool
slot as **37**:

```text
castleArea2Loaded=1 castleArea2PendulumSlot=37 castleArea2NativeRecords=3
castleArea2Roll=1464 castleArea2Velocity=224
liveOracleTraceRecords=2891 liveOracleTraceTicks=9
liveOracleTraceDomains=0x00001ff7
liveOracleCoverageFingerprint=0x3ab6eabbd37b9c60 liveOracleCoverageEntries=62
```

The source recipe was rerun for 40 bounded ticks using the real behavior,
level-script, area-2 collision, and room sources. Its output was:

```text
records=687 ticks=40 domains=3,6,7,12
source_program_commands=6 collision_surfaces=2019
floor_height=2253.0 floor_room=5
```

The extraction tool retained only native records for slot 37, source records
for its sole source subject (1), and the floor query whose first three values
are the canonical pendulum position `(-205, 2611, 7140)`. This rejects other
objects' state/effect records and unrelated Castle collision queries. The
filtered result was:

```text
native_slot=37 swift_subject=1
native_records=23 swift_records=687
native_ticks=2,3,4,5,6,7,8,9
swift_ticks=1,2,3,4,5,6,7,8,9,10,...,40
native_domains=6,7 swift_domains=3,6,7,12
required_domains=3,6,7,12 missing_native=3,12 missing_swift=
matched_records=2 canonical_records_native=23 canonical_records_swift=687
```

The native side therefore has no independently retained `object_state` (3)
or pendulum-specific `effects` (12) records in this lifecycle window. The
first canonical divergence is exact and occurs before any admissible match:

```text
missing_c tick=1 domain=3 sequence=0 kind=1 subject=37
  record=400 flags=0 values=[0x006268765f647065]
```

The five required run/content/timebase/configuration/save fingerprints also
diverge. The native lifecycle header currently leaves them zero; the Swift
source header values were:

```text
build         0xe5bdca15d2b72a1d
content       0x53070f5a6ad5112f
timebase      0xc2aab5366934285d
configuration 0xd95d7a24946e9bf2
initial_save  0xcb7842194b6d1b1d
coverage      0x4bd737aca81bc474
```

This is an exact no-admission result, not a C/Swift parity pair. `promotion`
remains `not_attempted` and `canonical_route_admission=0`.

## Tamper, replay, worker, merge, and rerun fences

`script/test_castle_area2_pendulum_pair.sh` exercised the bounded artifacts
and reported:

```text
schema4_decode=1 complete_domain_filter=1 tamper_rejected=1
replay_round_trip=1 worker_result=1 merge=1
persistent_rerun_rejected=1 promotion=not_attempted admission=0
```

The worker and merge checks persisted the exact divergence as a live
`blocked` terminal row (`fixture_only=0`); they did not turn the mismatch into
a pass. A second pairing attempt against the existing report was rejected by
the output rerun fence.

## Files changed

- `tools/SM64PendulumTracePairTool.swift` — schema-4 decode, slot/subject and
  canonical-position extraction, fixed-width comparison, exact divergence,
  tamper and round-trip checks, and fail-closed report.
- `script/test_castle_area2_pendulum_pair.sh` — native C lifecycle capture,
  Phase 46 source recipe invocation, pairing, worker/merge, and rerun fences.
- `script/test_decorative_pendulum_route.sh` — bounded tick-count override for
  the pairing script.
- `tests/sm64_modern_decorative_pendulum_route_smoke.swift` — completed the
  source parser's real F7–FC surface constants and line-wise room-comment
  stripping so the checked-in area-2 recipe decodes all 2,019 triangles and
  room entries.
- `.porting/porting-handoff-full-swift-twin-phase53-pendulum-pair.md` — this
  handoff.

## Validation

Passed:

- `./script/test_castle_area2_pendulum_pair.sh`
- strict Swift 6 compile of `OracleTrace.swift` plus
  `SM64PendulumTracePairTool.swift`
- native `SM64_MODERN_AUTOMATED_CASTLE_AREA2=1` lifecycle recording and file
  validation
- `git -c core.fsmonitor=false diff --check`

No commit was created; the parent agent owns review and any later promotion
decision. The exact remaining unblock is a native Castle area-2 pendulum
owner emitter that supplies the missing object/effect domains and emits the
same nonzero run/content/timebase/save fingerprints as the Swift recipe,
followed by a fresh independently matched multi-tick pair.
