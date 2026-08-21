# Full Swift Twin Handoff — Phase 59 Pendulum Pairing

Date: 2026-08-21

## Verdict

Phase 59 re-ran the independent native/Swift Castle area-2 pendulum pair on
the Phase 58 authored `WARP_NODE 0x35` route. The route remains **blocked** and
was not promoted. The source-backed room/render gates pass, but the native
effect domain required by the canonical shard is still absent and the
independent trace headers and records do not match.

No source or route behavior change is admitted in this phase. The existing
timebase contract intentionally lets a held native step run the pendulum body
but drops logical `play_sound` requests; manufacturing a direct sink call,
graph flag, or record would invalidate the C oracle.

## Pair evidence

The fresh `./script/test_castle_area2_pendulum_pair.sh` run retained:

```text
native_slot=37 swift_subject=1
native_records=1057 swift_records=1095
native_domains=3,6,7 swift_domains=3,6,7,12
required_domains=3,6,7,12 missing_native=12 missing_swift=
matched_records=701 canonical_records_native=1057 canonical_records_swift=1095
tamper_rejected=1 schema4_replay_round_trip=1
independent_c_swift_pair=0 exact_bytes=0 promotion=not_attempted canonical_route_admission=0
first_divergence=record_mismatch c={tick=1 domain=3 sequence=0 kind=1 subject=37 record=400 flags=0 values=[0xffffffffffa9eb80]} swift={tick=1 domain=3 sequence=0 kind=1 subject=37 record=400 flags=0 values=[0x006268765f647065]}
source_warp_room=5 mario_room=5 object_room=5 graph_active=1
worker_result=1 merge=1 persistent_rerun_rejected=1
```

The native route headers are nonzero, but all six header fingerprints diverge
from the standalone Swift source recipe. The Swift trace still emits the
source-backed effects domain (12); native has no corresponding sound record.
The worker-result and merge artifacts correctly preserve the terminal blocked
state with `fixture_only=0`.

## Boundary and next step

`src/audio/external.c` rejects `play_sound` when
`sm64_modern_timebase_should_advance_legacy_domain()` is false. The pendulum
threshold is reached on a held native step in this route, so the native effect
domain remains empty even though object-state, lifecycle, and collision
records are present. A future attempt must supply a source-authored initial
phase or independently paired timebase window that causes the same threshold
on a logical boundary in both C and Swift. It must keep all six fingerprints,
required domains, and exact canonical bytes aligned; relaxing the domain-12
requirement or rewriting headers is not admissible.

## Validation

Passed:

- `./script/test_castle_area2_warp.sh`
- `./script/test_castle_area2_pendulum_pair.sh`
- `bash -n script/test_castle_area2_pendulum_pair.sh`
- `git diff --check`

No route ledger mutation, promotion, or commit was performed by the worker;
the parent closes this handoff as the automatic local Phase 59 checkpoint.
