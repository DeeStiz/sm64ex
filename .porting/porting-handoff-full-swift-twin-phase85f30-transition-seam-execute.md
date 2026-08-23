# Full Swift Twin Phase 85f30 — authored intro transition seam

Date: 2026-08-22

## Verdict

**Complete as an isolated route pair; canonical admission remains deferred.**
The real owner-thread lifecycle starts the authored `level_intro_entry_1`
route with `skip_intro=0`, runs a bounded 320-step source window, and emits
exactly the two existing schema-4 script transition records (`domain=6`,
`record_kind=3`, `record_id=3`):

```text
tick=311 sequence=2 values=[1,16,0,0,0] hash=0xb9e77a797c34bb9e
tick=391 sequence=5 values=[8,20,0,0,0] hash=0x0eb91077dbe72aa4
```

The C contract filters and retains those producer records only. It does not
call `play_transition()`, execute a level opcode, add another trace record,
inject state, or synthesize a transition. Swift receives copied fixed-width
values and recomputes the schema-4 hashes through the isolated
`SM64IntroTransitionMigration` value mirror.

## Pair evidence

The passing run is retained at:

```text
build/sm64-modern-intro-transition-route-pair/run.n1MCvl/
```

The native C, C rerun, ASan, Release, and Swift traces are all 328 bytes
(72-byte header plus two 128-byte records) and have the same SHA-256:

```text
f10d8827ed3e5f83f7f8af8bc1b2abbd7059d5433f38577713d34d8be5c3c821
```

The native Debug summary was:

```text
intro_transition_route_debug oracle_end=0 result_status=0 actual=11424 retained=2 target_ticks=311,391 target_hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4 failures=0 errors=0 coverage=0x8fc5fa3c2cd26867
intro_transition_route_recorded shard=0x9a0f7b4f7ecf6c41 source=levels/intro/script.c entry=level_intro_entry_1 steps=320 records=2 ticks=311,391 hashes=0xb9e77a797c34bb9e,0x0eb91077dbe72aa4 coverage=0x8fc5fa3c2cd26867 owner_thread=1
```

The strict Swift mirror passed exact C/Swift byte pairing. The script also
rejected tampered-hash, reordered, missing-record, truncated/partial,
single-artifact, and persistent Swift-output rerun cases. Fresh ASan and
Release native runs passed with byte-identical traces; ASan emitted no
finding.

## Files added

- `SM64Modern/IntroTransitionMigration.swift` — route-scoped value-only
  receipt and exact two-record window validator.
- `tests/sm64_modern_intro_transition_route_pair_contract.c` — real native
  intro lifecycle harness retaining the existing C schema-4 ID-3 producer.
- `tests/sm64_modern_intro_transition_route_swift_smoke.swift` — strict Swift
  mirror, exact audit, and negative-artifact fences.
- `script/test_intro_transition_route_pair.sh` — fresh Debug/ASan/Release/
  rerun orchestration and all pair/negative checks.

No canonical manifest, cumulative report, route ledger, project file, or
shared migration was changed.

## Validation

```text
./script/test_intro_transition_route_pair.sh                             passed
bash -n script/test_intro_transition_route_pair.sh                        passed
xcrun clang -std=c11 -Wall -Wextra -Werror                               passed
xcrun swiftc -swift-version 6 -Xfrontend -strict-concurrency=complete     passed
git -c core.fsmonitor=false diff --check                                 passed
```

Final route status remains an isolated evidence seam (`manifest_mutation=0`,
`ledger_mutation=0`, `fixture_only=0`); parent-level admission and canonical
promotion are outside this phase.
