# Full Swift Twin Handoff — Phase 85a Mario-State Native Route Repair

Date: 2026-08-21

## Verdict

**NATIVE OWNER REPAIRED / C QUALIFIED, C↔SWIFT ADMISSION BLOCKED.** The
Phase 79 `status=4` failure was a harness lifecycle error, not a fabricated
Mario record or a source bypass. The route harness opened schema-4 recording
before opening an oracle tick, so real save/audio records emitted during
`lifecycle.initialize` called `sm64_modern_oracle_trace_record` outside an
open tick. That set the gameplay parity status to `SM64_MODERN_STATUS_INVALID_STATE`
(`4`), after which each lifecycle step failed closed and `oracle_trace_end`
reported `10`.

The repaired C owner harness now opens and closes an explicit initialization
tick, defers the filtered row coverage until after the real owner run, and
retains the complete Mario state inventory (`domain=2`, record IDs `100..118`)
so canonical per-domain sequence values are preserved. The generated
`oracle_hook|mario_state` row remains planned because the independent Swift
trace has the same header/coverage/record count but its record bytes first
diverge at record index `1`.

## Native evidence

The focused command:

```text
./script/test_mario_state_route_pair.sh
```

reported:

```text
mario_state_route_header mode=1 schema=4 coverage=0x0000000000000000
mario_state_route_init status=0 oracle=0
mario_state_route_step index=0 status=0 oracle=0 parity=0
mario_state_route_step index=1 status=0 oracle=0 parity=0
mario_state_route_debug oracle_end=0 result_status=0 actual=1831 observed_coverage_entries=58 retained_records=38
c_mario_state_route_recorded shard=0x88d04246f94ce9f8 records=38 ticks=3 coverage=0x67446c5f2e231b25
```

The retained C artifact contains the schema-4 72-byte header followed by 38
128-byte records: all 19 Mario-state IDs across gameplay ticks `2` and `3`.
The final header coverage is `0x67446c5f2e231b25`. Initialization records are
executed and observed by the real oracle but are not silently relabeled as
Mario-state evidence.

## Independent Swift evidence and admission boundary

The Swift smoke builds a source-backed `SM64MarioState` route and emits an
independent 38-record schema-4 artifact with the same route fingerprints and
coverage:

```text
swift_mario_state_route_recorded records=38 ticks=2,3 coverage=0x67446c5f2e231b25
mario_state_pairing_audit admitted=0 c_records=38 swift_records=38 blockers=record_bytes first_divergence=1
mario_state_pairing_tamper_rejected=1
```

This is intentionally fail-closed evidence. The equal counts and common
header do not establish parity; no C/Swift pair, worker-result, merge,
promotion, or route-ledger mutation was performed. The next route worker must
trace the first divergence from the source-backed Swift state/action owner,
then rerun Debug, sanitizer, and optimized C/Swift artifacts before any
admission attempt.

## Files changed

- `tests/sm64_modern_mario_state_route_pair_contract.c` — repaired native
  owner harness and complete domain-2/state stream contract.
- `tests/sm64_modern_mario_state_route_swift_smoke.swift` — independent
  source-backed Swift trace writer, pairing audit, and tamper decoder.
- `script/test_mario_state_route_pair.sh` — strict C/Swift build, runtime,
  artifact-size, pairing, tamper, and `git diff --check` gate.

No production source, route manifest, route ledger, credentials, or external
host state was changed. The parent may review and make the automatic local
Phase 85a commit.
